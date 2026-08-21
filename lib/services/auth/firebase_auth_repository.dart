import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _cachedUser;

  /// Determines the correct role for an email address
  static UserRole _roleForEmail(String? email) {
    if (email == 'admin@kriva.app') return UserRole.admin;
    return UserRole.member;
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }

      // If we already have a cached user for this uid, return it immediately
      // This prevents the race condition where authStateChanges fires
      // before signIn has finished setting up the user
      if (_cachedUser != null && _cachedUser!.uid == firebaseUser.uid) {
        return _cachedUser;
      }

      try {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
        } else {
          // Profile not yet complete in Firestore (e.g. newly signed up)
          _cachedUser = UserModel(
            uid: firebaseUser.uid,
            clubId: '',
            name: firebaseUser.displayName ?? '',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL ?? '',
            role: _roleForEmail(firebaseUser.email),
            batch: '',
            bio: '',
            domainsFollowing: [],
            streak: UserStreak(count: 0, lastActiveDate: null),
            createdAt: DateTime.now(),
          );
        }
        return _cachedUser;
      } catch (e) {
        // Firestore permission denied or network error — 
        // Still return a shell user so the router can redirect correctly
        // instead of returning null (which makes router think user is signed out)
        _cachedUser = UserModel(
          uid: firebaseUser.uid,
          clubId: '',
          name: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL ?? '',
          role: _roleForEmail(firebaseUser.email),
          batch: '',
          bio: '',
          domainsFollowing: [],
          streak: UserStreak(count: 0, lastActiveDate: null),
          createdAt: DateTime.now(),
        );
        return _cachedUser;
      }
    });
  }

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<UserModel> signIn(String loginId, String password) async {
    String email = loginId.trim();

    // Support Club ID login (convert e.g. ADM001 to adm001@kriva.app)
    if (!email.contains('@')) {
      email = '${email.toLowerCase()}@kriva.app';
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // Set _cachedUser BEFORE Firestore read so the authStateChanges
    // stream (which fires immediately on sign-in) finds it already set
    _cachedUser = UserModel(
      uid: firebaseUser.uid,
      clubId: loginId.contains('@') ? '' : loginId.toUpperCase(),
      name: '',
      email: email,
      photoUrl: '',
      role: _roleForEmail(email),
      batch: '',
      bio: '',
      domainsFollowing: [],
      streak: UserStreak(count: 0, lastActiveDate: null),
      createdAt: DateTime.now(),
    );

    // Now try to enrich from Firestore (may fail if rules aren't set)
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
      } else {
        // Write shell user to Firestore
        try {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(_cachedUser!.toMap());
        } catch (_) {
          // Firestore write failed (permission-denied) — continue with cached user
        }
      }
    } catch (_) {
      // Firestore read failed — continue with the shell user we already set
    }

    return _cachedUser!;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    // google_sign_in v7 uses a singleton instance and authenticate()
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    // idToken is available directly on GoogleSignInAuthentication
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Fetch Firestore Profile
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (doc.exists && doc.data() != null) {
      _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
    } else {
      // Create profile from google credentials
      _cachedUser = UserModel(
        uid: firebaseUser.uid,
        clubId: '',
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        role: UserRole.member,
        batch: '',
        bio: '',
        domainsFollowing: [],
        streak: UserStreak(count: 0, lastActiveDate: null),
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(_cachedUser!.toMap());
    }

    return _cachedUser!;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // Also sign out of Google if using Google Sign-In
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      // No persistent session to clear on v7; Firebase sign-out is sufficient
    }
    _cachedUser = null;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  @override
  Future<UserModel> completeProfile({
    required String name,
    required String bio,
    required String batch,
    required List<String> domains,
    required String photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No Firebase user authenticated');

    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    UserModel updated;
    if (doc.exists && doc.data() != null) {
      final old = UserModel.fromMap(doc.data()!, user.uid);
      updated = old.copyWith(
        name: name,
        bio: bio,
        batch: batch,
        domainsFollowing: domains,
        photoUrl: photoUrl.isNotEmpty ? photoUrl : old.photoUrl,
      );
    } else {
      updated = UserModel(
        uid: user.uid,
        clubId: '', // Set by admin beforehand or left empty
        name: name,
        email: user.email ?? '',
        photoUrl: photoUrl,
        role: UserRole.member,
        batch: batch,
        bio: bio,
        domainsFollowing: domains,
        streak: UserStreak(count: 1, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now(),
      );
    }

    await docRef.set(updated.toMap(), SetOptions(merge: true));
    _cachedUser = updated;
    return _cachedUser!;
  }
}
