import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _cachedUser;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
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
            role: UserRole.member,
            batch: '',
            bio: '',
            domainsFollowing: [],
            streak: UserStreak(count: 0, lastActiveDate: null),
            createdAt: DateTime.now(),
          );
        }
        return _cachedUser;
      } catch (e) {
        return null;
      }
    });
  }

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<UserModel> signIn(String loginId, String password) async {
    String email = loginId.trim();

    // Support Club ID login (convert e.g. MEM001 to mem001@kriva.app)
    if (!email.contains('@')) {
      email = '${email.toLowerCase()}@kriva.app';
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // Fetch Firestore Profile
    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (doc.exists && doc.data() != null) {
      _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
    } else {
      // Create initial shell user
      _cachedUser = UserModel(
        uid: firebaseUser.uid,
        clubId: loginId.contains('@') ? '' : loginId.toUpperCase(),
        name: '',
        email: email,
        photoUrl: '',
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
