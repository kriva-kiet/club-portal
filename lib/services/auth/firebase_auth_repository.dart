import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StreamController<UserModel?> _userStreamController =
      StreamController<UserModel?>.broadcast();

  UserModel? _cachedUser;

  FirebaseAuthRepository() {
    _firebaseAuth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        if (_cachedUser != null && _cachedUser!.uid == firebaseUser.uid) {
          _userStreamController.add(_cachedUser);
          return;
        }

        try {
          final doc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (doc.exists && doc.data() != null) {
            _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
            if (!_cachedUser!.isActive) {
              await _firebaseAuth.signOut();
              _cachedUser = null;
              _userStreamController.add(null);
              return;
            }
          } else {
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
          _userStreamController.add(_cachedUser);
        } catch (_) {
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
          _userStreamController.add(_cachedUser);
        }
      } else {
        if (_cachedUser == null) {
          _userStreamController.add(null);
        }
      }
    });
  }

  /// Determines the correct role for an email address
  static UserRole _roleForEmail(String? email) {
    switch (email?.toLowerCase()) {
      case 'admin@kriva.app':
      case 'adm001@kriva.app':
        return UserRole.admin;
    }
    return UserRole.member;
  }

  /// Computes the new streak based on lastActiveDate relative to today, appends
  /// today to activityDays, and writes the updated streak to Firestore.
  /// Rules:
  ///   same day  → no change (already counted today)
  ///   yesterday → streak += 1 (consecutive day, keep going!)
  ///   gap > 1d  → streak resets to 1 (oh no, broken)
  ///   never active → streak starts at 1
  Future<UserStreak> _computeAndSaveStreak(
      String uid, UserStreak current) async {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayDate = DateTime(now.year, now.month, now.day);

    // Calculate new count
    int newCount;
    if (current.lastActiveDate == null) {
      newCount = 1; // First ever login
    } else {
      final lastDay = DateTime(
        current.lastActiveDate!.year,
        current.lastActiveDate!.month,
        current.lastActiveDate!.day,
      );
      final diff = todayDate.difference(lastDay).inDays;
      if (diff == 0) {
        newCount = current.count; // Already logged in today
      } else if (diff == 1) {
        newCount = current.count + 1; // Perfect consecutive day
      } else {
        newCount = 1; // Streak broken
      }
    }

    // Build updated activityDays list (unique, keep last 30 days)
    final updatedDays = List<String>.from(current.activityDays);
    if (!updatedDays.contains(todayStr)) {
      updatedDays.add(todayStr);
    }
    // Prune to last 30 days
    final cutoff = DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 30)));
    updatedDays.removeWhere((d) => d.compareTo(cutoff) < 0);
    updatedDays.sort();

    final newStreak = UserStreak(
      count: newCount,
      lastActiveDate: now,
      activityDays: updatedDays,
    );

    // Write to Firestore (fire-and-forget — don't block login)
    _firestore.collection('users').doc(uid).update({
      'streak': newStreak.toMap(),
    }).catchError((_) {});

    return newStreak;
  }

  @override
  Stream<UserModel?> get authStateChanges => _userStreamController.stream;

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Future<UserModel> signIn(
    String loginId,
    String password, {
    UserRole? expectedRole,
  }) async {
    String email = loginId.trim();

    // Support Club ID login (convert e.g. ADM001 to adm001@kriva.app)
    if (!email.contains('@')) {
      email = '${email.toLowerCase()}@kriva.app';
    }

    fb.UserCredential? credential;
    try {
      credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        final cleanId = loginId.trim().toUpperCase();
        final rawId = loginId.trim();

        // ignore: avoid_print
        print('===> [LOGIN DEBUG] Firebase Auth failed for loginId="$loginId", e.code="${e.code}". Trying Firestore fallback...');

        // 1. Search /user_passwords collection
        var passQuery = await _firestore
            .collection('user_passwords')
            .where('clubId', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (passQuery.docs.isEmpty) {
          passQuery = await _firestore
              .collection('user_passwords')
              .where('email', isEqualTo: rawId)
              .limit(1)
              .get();
        }

        // 2. Search /users collection if not found in /user_passwords
        QuerySnapshot<Map<String, dynamic>>? userQuery;
        if (passQuery.docs.isEmpty) {
          userQuery = await _firestore
              .collection('users')
              .where('clubId', isEqualTo: cleanId)
              .limit(1)
              .get();

          if (userQuery.docs.isEmpty) {
            userQuery = await _firestore
                .collection('users')
                .where('clubId', isEqualTo: rawId)
                .limit(1)
                .get();
          }

          if (userQuery.docs.isEmpty) {
            userQuery = await _firestore
                .collection('users')
                .where('email', isEqualTo: rawId)
                .limit(1)
                .get();
          }
        }

        String? storedPassword;
        String? uid;
        Map<String, dynamic>? userData;

        if (passQuery.docs.isNotEmpty) {
          final data = passQuery.docs.first.data();
          storedPassword = data['password'] as String?;
          uid = data['uid'] as String? ?? passQuery.docs.first.id;
          // ignore: avoid_print
          print('===> [LOGIN DEBUG] Found match in /user_passwords for uid=$uid, storedPassword="$storedPassword"');
        } else if (userQuery != null && userQuery.docs.isNotEmpty) {
          userData = userQuery.docs.first.data();
          storedPassword = userData['password'] as String?;
          uid = userQuery.docs.first.id;
          // ignore: avoid_print
          print('===> [LOGIN DEBUG] Found match in /users for uid=$uid, storedPassword="$storedPassword"');
        } else {
          // ignore: avoid_print
          print('===> [LOGIN DEBUG] NO match found in /user_passwords OR /users for loginId="$loginId" (cleanId="$cleanId")');
        }

        if (storedPassword != null && uid != null) {
          // Hash entered password with SHA-256 for secure comparison
          final enteredHash = sha256.convert(utf8.encode(password.trim())).toString();
          // ignore: avoid_print
          print('===> [LOGIN DEBUG] Comparing stored hash vs entered hash (passwords hidden for security)');
          if (storedPassword.trim() == enteredHash) {
            if (userData != null) {
              _cachedUser = UserModel.fromMap(userData, uid);
            } else {
              try {
                final userDoc = await _firestore.collection('users').doc(uid).get();
                if (userDoc.exists && userDoc.data() != null) {
                  _cachedUser = UserModel.fromMap(userDoc.data()!, uid);
                }
              } catch (_) {}
            }

            _cachedUser ??= UserModel(
              uid: uid,
              clubId: cleanId,
              name: '',
              email: loginId.contains('@') ? loginId.trim() : '${cleanId.toLowerCase()}@kriva.app',
              photoUrl: '',
              role: _roleForEmail(loginId),
              batch: '',
              bio: '',
              domainsFollowing: [],
              streak: UserStreak(count: 0, lastActiveDate: null),
              createdAt: DateTime.now(),
            );

            if (!_cachedUser!.isActive) {
              _cachedUser = null;
              _userStreamController.add(null);
              throw Exception('This club account is no longer active.');
            }

            if (expectedRole != null &&
                !_cachedUser!.role.canAccessPortal(expectedRole)) {
              _cachedUser = null;
              _userStreamController.add(null);
              throw Exception(
                'This account is assigned to the ${_cachedUser?.role.name} portal. '
                'Select that portal to sign in.',
              );
            }

            // ✅ Update streak on successful login
            final updatedStreak = await _computeAndSaveStreak(
                _cachedUser!.uid, _cachedUser!.streak);
            _cachedUser = _cachedUser!.copyWith(streak: updatedStreak);

            _userStreamController.add(_cachedUser);
            return _cachedUser!;
          }
        }

        throw Exception('Incorrect Club ID or password.');
      }
      throw Exception(e.message ?? 'An authentication error occurred.');
    }

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
      githubId: '',
      linkedinId: '',
      instagramId: '',
    );

    // Now try to enrich from Firestore (may fail if rules aren't set)
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = UserModel.fromMap(doc.data()!, firebaseUser.uid);
        if (!_cachedUser!.isActive) {
          await _firebaseAuth.signOut();
          _cachedUser = null;
          _userStreamController.add(null);
          throw Exception('This club account is no longer active.');
        }
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

    final user = _cachedUser!;
    if (expectedRole != null && !user.role.canAccessPortal(expectedRole)) {
      await _firebaseAuth.signOut();
      _cachedUser = null;
      _userStreamController.add(null);
      throw Exception(
        'This account is assigned to the ${user.role.name} portal. '
        'Select that portal to sign in.',
      );
    }
    // ✅ Update streak on successful Firebase credential login
    final updatedStreak = await _computeAndSaveStreak(
        _cachedUser!.uid, _cachedUser!.streak);
    _cachedUser = _cachedUser!.copyWith(streak: updatedStreak);

    _userStreamController.add(_cachedUser!);
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
    _cachedUser = null;
    _userStreamController.add(null);
    await _firebaseAuth.signOut();
    // Also sign out of Google if using Google Sign-In
    if (GoogleSignIn.instance.supportsAuthenticate()) {
      // No persistent session to clear on v7; Firebase sign-out is sufficient
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  @override
  Future<void> verifyCurrentPassword(String password) async {
    final user = _firebaseAuth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw Exception('Please sign in again before continuing.');
    }
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> updateProfilePhoto(String photoUrl) async {
    await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
    if (_cachedUser != null) {
      _cachedUser = _cachedUser!.copyWith(photoUrl: photoUrl);
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
        clubId: _cachedUser?.clubId ?? '',
        name: name,
        email: user.email ?? '',
        photoUrl: photoUrl,
        role: _cachedUser?.role ?? _roleForEmail(user.email),
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
