import 'dart:convert';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_repository.dart';
import 'auth/mock_auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'database/database_repository.dart';
import 'database/mock_database_repository.dart';
import 'database/firestore_database_repository.dart';
import '../models/user_model.dart';
import '../models/domain_model.dart';
import '../models/user_progress_model.dart';
import '../models/broadcast_model.dart';
import '../models/session_model.dart';
import '../models/hackathon_model.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';

// Provider for SharedPreferences (initialized in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

// Notifier to manage and toggle Mock Mode
class MockModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'use_mock_mode_v1';

  MockModeNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> toggle(bool val) async {
    state = val;
    await _prefs.setBool(_key, val);
  }
}

final useMockModeProvider = StateNotifierProvider<MockModeNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MockModeNotifier(prefs);
});

// Notifier to manage and update Locale
class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const _key = 'app_locale_code';

  LocaleNotifier(this._prefs) : super(Locale(_prefs.getString(_key) ?? 'en'));

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _prefs.setString(_key, languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

// Singletons for Mock repositories to maintain state in-memory during execution
final mockAuthRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

final mockDatabaseRepositoryProvider = Provider<MockDatabaseRepository>((ref) {
  return MockDatabaseRepository();
});

// Dynamic Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final useMock = ref.watch(useMockModeProvider);
  if (useMock) {
    return ref.watch(mockAuthRepositoryProvider);
  } else {
    return FirebaseAuthRepository();
  }
});

// Dynamic Database Repository Provider
final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  final useMock = ref.watch(useMockModeProvider);
  if (useMock) {
    return ref.watch(mockDatabaseRepositoryProvider);
  } else {
    return FirestoreDatabaseRepository();
  }
});

// Auth State Changes Provider
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// Current UserModel Provider (derived from authStateChangesProvider)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  final user = authState.valueOrNull;
  if (user != null) {
    // Save to Cache
    prefs.setString('cached_user_v1', json.encode(user.toJsonMap()));
    prefs.setString('cached_user_id', user.uid);
    return user;
  }

  // Fallback to Offline Cache if loading or null
  final cachedStr = prefs.getString('cached_user_v1');
  final cachedId = prefs.getString('cached_user_id') ?? '';
  if (cachedStr != null) {
    try {
      final map = json.decode(cachedStr) as Map<String, dynamic>;
      return UserModel.fromMap(map, cachedId);
    } catch (_) {}
  }
  return null;
});

// Streams of Domains
final domainsProvider = StreamProvider<List<DomainModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getDomains();
});

// Stream of progress for a specific domain
final userProgressProvider = StreamProvider.family<UserProgressModel?, String>((
  ref,
  domainId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getUserProgress(user.uid, domainId);
});

// Streams of Broadcasts filtered for current user
final broadcastsProvider = StreamProvider<List<BroadcastModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getBroadcasts(user);
});

// Sessions Stream Provider
final sessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getSessions();
});

// Hackathons Stream Provider
final hackathonsProvider = StreamProvider<List<HackathonModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getHackathons();
});

// Teams Stream Provider
final teamsProvider = StreamProvider.family<List<TeamModel>, String>((
  ref,
  hackathonId,
) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getTeams(hackathonId);
});

// Social Posts Stream Provider
final postsProvider = StreamProvider.family<List<PostModel>, String?>((
  ref,
  tagFilter,
) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getPosts(tagFilter);
});

// Comments Stream Provider
final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getComments(postId);
});

// Chat Channels Stream Provider
final channelsProvider = StreamProvider<List<ChatChannelModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getChannels(user);
});

// Messages Stream Provider
final messagesProvider = StreamProvider.family<List<MessageModel>, String>((
  ref,
  channelId,
) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getMessages(channelId);
});

// Leaderboard Stream Provider (aggregates users sorted by streak count)
final leaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getMembers().map((members) {
    // Sort descending by streak count
    final sorted = List<UserModel>.from(members);
    sorted.sort((a, b) => b.streak.count.compareTo(a.streak.count));
    return sorted;
  });
});
