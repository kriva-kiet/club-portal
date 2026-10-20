import 'dart:convert';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/auth_repository.dart';
import 'auth/firebase_auth_repository.dart';
import 'database/database_repository.dart';
import 'database/firestore_database_repository.dart';
import '../models/user_model.dart';
import '../models/domain_model.dart';
import '../models/user_progress_model.dart';
import '../models/team_request_model.dart';
import '../models/broadcast_model.dart';
import '../models/session_model.dart';
import '../models/standalone_quiz_model.dart';
import '../models/hackathon_model.dart';
import '../models/post_model.dart';
import '../models/message_model.dart';
import '../models/complaint_model.dart';
import '../models/authority_model.dart';
import '../models/authority_group_model.dart';
import 'notification_service.dart';

// Provider for SharedPreferences (initialized in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
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

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return FirestoreDatabaseRepository();
});

// Auth State Changes Provider
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

// Stream Provider that listens to Firestore updates for the current user
final _currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.streamUser(user.uid);
});

// Current UserModel Provider (derived from authStateChangesProvider and Firestore stream)
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final firestoreUser = ref.watch(_currentUserStreamProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  // Prefer the real-time Firestore user, fallback to the Auth user
  final user = firestoreUser.valueOrNull ?? authState.valueOrNull;
  if (user != null) {
    // Save to Cache
    prefs.setString('cached_user_v1', json.encode(user.toJsonMap()));
    prefs.setString('cached_user_id', user.uid);
    // Initialize FCM Push Notifications for active user session
    NotificationService.initialize(user.uid);
    return user;
  }

  // A cached profile must never keep a signed-out account authenticated.
  // Clear it whenever the repository confirms that there is no session.
  if (!authState.isLoading) {
    prefs.remove('cached_user_v1');
    prefs.remove('cached_user_id');
  }
  return null;
});

// Streams of Domains
final domainsProvider = StreamProvider<List<DomainModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
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

// Stream of progress for a specific student and domain (used by Leads)
final studentProgressProvider =
    StreamProvider.family<UserProgressModel?, ({String uid, String domainId})>((
      ref,
      args,
    ) {
      final dbRepo = ref.watch(databaseRepositoryProvider);
      return dbRepo.getUserProgress(args.uid, args.domainId);
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
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getSessions();
});

// Hackathons Stream Provider
final hackathonsProvider = StreamProvider<List<HackathonModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getHackathons();
});

// Pending Hackathons Stream Provider
final pendingHackathonsProvider = StreamProvider<List<HackathonModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || (user.role != UserRole.admin && user.role != UserRole.developer)) {
    return const Stream.empty();
  }
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getPendingHackathons();
});

// Teams Stream Provider
final teamsProvider = StreamProvider.family<List<TeamModel>, String>((
  ref,
  hackathonId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getTeams(hackathonId);
});

// Social Posts Stream Provider
final postsProvider = StreamProvider.family<List<PostModel>, String?>((
  ref,
  tagFilter,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getPosts(tagFilter);
});

// Members Stream Provider
final membersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getMembers();
});

// Standalone Quizzes Provider
final standaloneQuizzesProvider = StreamProvider<List<StandaloneQuizModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getStandaloneQuizzes();
});

// Comments Stream Provider
final commentsProvider = StreamProvider.family<List<CommentModel>, String>((
  ref,
  postId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
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
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getMessages(channelId);
});

// Leaderboard Stream Provider (aggregates users sorted by streak count)
final leaderboardProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getMembers().map((members) {
    // Sort descending by streak count
    final sorted = List<UserModel>.from(members);
    sorted.sort((a, b) => b.streak.count.compareTo(a.streak.count));
    return sorted;
  });
});

// Team Formation Requests Stream Provider
final teamRequestsProvider = StreamProvider<List<TeamRequestModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getTeamRequests();
});

// Complaints / Grievances Stream Provider (Admin view)
final complaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getComplaints();
});

// User's own submitted complaints
final myComplaintsProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getUserComplaints(user.uid);
});

// Authorities Stream Provider (All members & public)
final authoritiesProvider = StreamProvider<List<AuthorityModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getAuthorities();
});

// Authority Groups / Cells Stream Provider (e.g. Women Cell)
final authorityGroupsProvider = StreamProvider<List<AuthorityGroupModel>>((ref) {
  final dbRepo = ref.watch(databaseRepositoryProvider);
  return dbRepo.getAuthorityGroups();
});

