import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../models/access_request_model.dart';

abstract class DatabaseRepository {
  // Roadmaps & Domains
  Stream<List<DomainModel>> getDomains();
  Future<DomainModel> getDomainById(String domainId);
  Stream<List<ModuleModel>> getModules(String domainId);
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId);

  // Progress Tracking
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId);
  Future<void> toggleTopicCompletion(
    String uid,
    String domainId,
    String topicId,
    bool isCompleted,
    int totalTopicsInDomain,
  );

  // Broadcasts
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user);
  Future<void> markBroadcastAsRead(String uid, String broadcastId);
  Future<void> createBroadcast(BroadcastModel broadcast);

  // Sessions (Phase 2)
  Stream<List<SessionModel>> getSessions();
  Future<void> createSession(SessionModel session);
  Future<void> toggleRSVP(String uid, String sessionId, bool rsvp);

  // Hackathons & Teams (Phase 2)
  Stream<List<HackathonModel>> getHackathons();
  Future<void> createHackathon(HackathonModel hackathon);
  Stream<List<TeamModel>> getTeams(String hackathonId);
  Future<void> createTeam(String hackathonId, TeamModel team);
  Future<void> requestToJoinTeam(String hackathonId, String teamId, String uid);
  Future<void> manageJoinRequest(
    String hackathonId,
    String teamId,
    String uid,
    bool approve,
  );

  // Community Feed & Comments (Phase 3)
  Stream<List<PostModel>> getPosts(String? tagFilter);
  Future<void> createPost(PostModel post);
  Future<void> toggleLikePost(String uid, String postId);
  Stream<List<CommentModel>> getComments(String postId);
  Future<void> addComment(String postId, CommentModel comment);

  // Chats & Messaging (Phase 3)
  Stream<List<ChatChannelModel>> getChannels(UserModel user);
  Stream<List<MessageModel>> getMessages(String channelId);
  Future<void> sendMessage(String channelId, MessageModel message);

  // Admin / Leads management
  Future<void> createDomain(DomainModel domain);
  Future<void> createModule(String domainId, ModuleModel module);
  Future<void> createTopic(String domainId, String moduleId, TopicModel topic);
  Stream<List<UserModel>> getMembers();
  Future<void> updateUserRole(String uid, UserRole role);
  Future<void> updateFollowedDomains(String uid, List<String> domains);

  // Admissions & Password resets (Phase 4 completion)
  Stream<List<AccessRequestModel>> getAccessRequests();
  Future<void> submitAccessRequest(AccessRequestModel request);
  Future<void> approveAccessRequest(
    String requestId,
    String email,
    String password,
  );
  Future<void> rejectAccessRequest(String requestId);
  Future<void> changeUserPassword(String uid, String newPassword);
}
