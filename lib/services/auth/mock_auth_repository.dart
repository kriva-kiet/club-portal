import 'dart:async';
import '../../models/user_model.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  // ── Seed Users ─────────────────────────────────────────────────────────────
  static final Map<String, UserModel> _mockUsers = {
    'MEM001': UserModel(
      uid: 'user_mem001',
      clubId: 'MEM001',
      name: 'Abhisht Singh',
      email: 'member@kriva.app',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Abhisht',
      role: UserRole.member,
      batch: 'Batch of 2026',
      bio: 'Flutter enthusiast & competitive programmer. Building cool stuff!',
      domainsFollowing: ['dsa', 'web_dev'],
      streak: UserStreak(
        count: 7,
        lastActiveDate: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    'LED001': UserModel(
      uid: 'user_led001',
      clubId: 'LED001',
      name: 'Elena Rostova',
      email: 'lead@kriva.app',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Elena',
      role: UserRole.lead,
      batch: 'Batch of 2025',
      bio: 'Domain Lead for Data Structures & Algorithms. Ask me anything about graphs!',
      domainsFollowing: ['dsa'],
      streak: UserStreak(count: 24, lastActiveDate: DateTime.now()),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    'ADM001': UserModel(
      uid: 'user_adm001',
      clubId: 'ADM001',
      name: 'Club President',
      email: 'admin@kriva.app',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=President',
      role: UserRole.admin,
      batch: 'Batch of 2024',
      bio: 'Core Organizer. Managing sessions, roadmaps, and broadcasts.',
      domainsFollowing: [],
      streak: UserStreak(count: 0, lastActiveDate: null),
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    'DEV001': UserModel(
      uid: 'user_dev001',
      clubId: 'DEV001',
      name: 'Abhisht Singh (Dev)',
      email: 'dev@kriva.app',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Developer',
      role: UserRole.developer,
      batch: 'Batch of 2026',
      bio: 'App Developer. Master privileges enabled.',
      domainsFollowing: ['dsa', 'web_dev', 'ml'],
      streak: UserStreak(count: 99, lastActiveDate: DateTime.now()),
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  };

  // ── Passwords (keyed by UPPERCASE club ID) ─────────────────────────────────
  static final Map<String, String> _mockPasswords = {
    'MEM001': 'password',
    'LED001': 'password',
    'ADM001': 'password',
    'DEV001': 'password',
  };

  // ── Email → Club ID lookup ─────────────────────────────────────────────────
  // Supports both shorthand (member@kriva.app) and full-format (mem001@kriva.app)
  static final Map<String, String> _emailToClubId = {
    // Shorthand emails
    'member@kriva.app': 'MEM001',
    'lead@kriva.app':   'LED001',
    'admin@kriva.app':  'ADM001',
    'dev@kriva.app':    'DEV001',
    // Full-format emails
    'mem001@kriva.app': 'MEM001',
    'led001@kriva.app': 'LED001',
    'adm001@kriva.app': 'ADM001',
    'dev001@kriva.app': 'DEV001',
  };

  // Public getters to allow MockDatabaseRepository to add users on approval
  static Map<String, UserModel> get mockUsers => _mockUsers;
  static Map<String, String> get mockPasswords => _mockPasswords;

  MockAuthRepository() {
    // Start as signed-out
    _controller.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  UserModel? get currentUser => _currentUser;

  /// Resolves a login input (Club ID or email) to a club ID key.
  String _resolveToClubId(String input) {
    final trimmed = input.trim();

    // 1. Email format — look up in email map
    if (trimmed.contains('@')) {
      final lowerEmail = trimmed.toLowerCase();
      final fromMap = _emailToClubId[lowerEmail];
      if (fromMap != null) return fromMap;

      // 2. Try extracting prefix from email (e.g. "MEM001@..." → "MEM001")
      final prefix = lowerEmail.split('@')[0].toUpperCase();
      if (_mockUsers.containsKey(prefix)) return prefix;
    }

    // 3. Direct Club ID (case-insensitive)
    final upperId = trimmed.toUpperCase();
    if (_mockUsers.containsKey(upperId)) return upperId;

    // 4. Not found — return as-is so the error is descriptive
    return upperId;
  }

  @override
  Future<UserModel> signIn(String loginId, String password) async {
    await Future.delayed(const Duration(milliseconds: 700)); // Simulate network

    final clubId = _resolveToClubId(loginId);

    if (!_mockUsers.containsKey(clubId)) {
      throw Exception(
        'Account "$loginId" is not admitted in the system.\n'
        'Use your Club ID (e.g. MEM001) or email (e.g. member@kriva.app), '
        'or submit an Access Request.',
      );
    }

    final actualPassword = _mockPasswords[clubId] ?? 'password';
    if (actualPassword != password) {
      throw Exception('Incorrect password for account $loginId.');
    }

    final user = _mockUsers[clubId]!;
    _currentUser = user;
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = UserModel(
      uid: 'google_user_123',
      clubId: 'GGL999',
      name: 'Google User',
      email: 'user@gmail.com',
      photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Google',
      role: UserRole.member,
      batch: 'Batch of 2026',
      bio: 'Logged in with Google.',
      domainsFollowing: [],
      streak: UserStreak(count: 1, lastActiveDate: DateTime.now()),
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<UserModel> completeProfile({
    required String name,
    required String bio,
    required String batch,
    required List<String> domains,
    required String photoUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (_currentUser == null) throw Exception('No user logged in');

    _currentUser = _currentUser!.copyWith(
      name: name,
      bio: bio,
      batch: batch,
      domainsFollowing: domains,
      photoUrl: photoUrl.isNotEmpty ? photoUrl : _currentUser!.photoUrl,
    );

    // Update the seed map so logging back in retains changes in this session
    if (_mockUsers.containsKey(_currentUser!.clubId)) {
      _mockUsers[_currentUser!.clubId] = _currentUser!;
    }

    _controller.add(_currentUser);
    return _currentUser!;
  }

  void updateStreak(int increment) {
    if (_currentUser != null) {
      final currentStreak = _currentUser!.streak;
      _currentUser = _currentUser!.copyWith(
        streak: currentStreak.copyWith(
          count: currentStreak.count + increment,
          lastActiveDate: DateTime.now(),
        ),
      );
      _controller.add(_currentUser);
    }
  }
}
