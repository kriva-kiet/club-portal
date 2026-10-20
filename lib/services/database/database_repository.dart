import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/team_request_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../models/access_request_model.dart';
import '../../models/standalone_quiz_model.dart';
import '../../models/profile_update_request_model.dart';
import '../../models/complaint_model.dart';
import '../../models/authority_group_model.dart';
import '../../models/authority_model.dart';

abstract class DatabaseRepository {
  // Roadmaps & Domains
  Stream<List<DomainModel>> getDomains();
  Future<DomainModel> getDomainById(String domainId);
  Stream<List<ModuleModel>> getModules(String domainId);
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId);

  // User Profile
  Stream<UserModel?> streamUser(String uid);

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
  Future<void> deleteBroadcast(String broadcastId);

  // Sessions (Phase 2)
  Stream<List<SessionModel>> getSessions();
  Future<void> createSession(SessionModel session);
  Future<void> deleteSession(String sessionId);
  Future<void> toggleRSVP(String uid, String sessionId, bool rsvp);
  Future<void> markAttendance(String sessionId, String uid);
  Future<void> toggleAttendance(String sessionId, String uid, bool isPresent);

  // Hackathons & Teams (Phase 2)
  Stream<List<HackathonModel>> getHackathons();
  Stream<List<HackathonModel>> getPendingHackathons();
  Future<void> createHackathon(HackathonModel hackathon);
  Future<void> updateHackathonStatus(String id, String status);
  Future<void> updateHackathon(HackathonModel hackathon);
  Future<void> deleteHackathon(String hackathonId);
  Stream<List<TeamModel>> getTeams(String hackathonId);
  Future<void> createTeam(String hackathonId, TeamModel team);
  Future<void> updateTeamParticipationStatus(
    String hackathonId,
    String teamId,
    String participationStatus,
    String statusDescription,
  );
  Future<void> deleteTeam(String hackathonId, String teamId);
  Future<void> leaveTeam(String hackathonId, String teamId, String uid);
  Future<void> requestToJoinTeam(String hackathonId, String teamId, String uid);
  Future<void> manageJoinRequest(
    String hackathonId,
    String teamId,
    String uid,
    bool approve,
  );

  /// Update a user's streak and activity-day log in Firestore.
  Future<void> updateUserStreak(String uid, UserStreak streak);

  // Team Formation Requests (Phase 2)
  Stream<List<TeamRequestModel>> getTeamRequests();
  Future<void> createTeamRequest(TeamRequestModel request);
  Future<void> updateTeamRequestStatus(String requestId, String status);
  Future<void> toggleTeamInterest(String uid, String requestId, bool isInterested);

  // Community Feed & Comments (Phase 3)
  Stream<List<PostModel>> getPosts(String? tagFilter);
  Future<void> createPost(PostModel post);
  Future<void> deletePost(String postId);
  Future<void> toggleLikePost(String uid, String postId);
  Stream<List<CommentModel>> getComments(String postId);
  Future<void> addComment(String postId, CommentModel comment);

  // Chats & Messaging (Phase 3)
  Stream<List<ChatChannelModel>> getChannels(UserModel user);
  Stream<List<MessageModel>> getMessages(String channelId);
  Future<void> sendMessage(String channelId, MessageModel message);
  Future<String> getOrCreateDirectChat(String currentUserId, String targetUserId);

  // Admin / Leads management
  Future<void> createDomain(DomainModel domain);
  Future<void> updateDomain(DomainModel domain);
  Future<void> deleteDomain(String domainId);
  Future<void> createModule(String domainId, ModuleModel module);
  Future<void> updateModule(String domainId, ModuleModel module);
  Future<void> deleteModule(String domainId, String moduleId);
  Future<void> createTopic(String domainId, String moduleId, TopicModel topic);
  Future<void> updateTopic(String domainId, String moduleId, TopicModel topic);
  Future<void> deleteTopic(String domainId, String moduleId, String topicId);
  Future<void> createStandaloneQuiz(StandaloneQuizModel quiz);
  Future<void> deleteStandaloneQuiz(String quizId);
  Stream<List<StandaloneQuizModel>> getStandaloneQuizzes();
  Future<void> submitQuizResult(String uid, String quizId, int score, int total);
  Stream<List<UserModel>> getMembers();
  Stream<List<UserModel>> getPastMembers();
  Future<void> toggleFollowMember(String currentUserId, String targetUserId, bool follow);
  Future<void> updateUserRole(String uid, UserRole role);
  Future<void> updateUser(UserModel user);
  Future<void> archiveMember(UserModel member, String archivedBy);
  Future<void> updateFollowedDomains(String uid, List<String> domains);

  // Admissions & Password resets (Phase 4 completion)
  Stream<List<AccessRequestModel>> getAccessRequests();
  Future<void> submitAccessRequest(AccessRequestModel request);
  Future<void> approveAccessRequest(
    String requestId,
    String contactEmail,
    String clubId,
    String password,
  );
  Future<void> rejectAccessRequest(String requestId);
  Future<void> changeUserPassword(String uid, String newPassword);

  // Profile Update Requests (Approval Workflow)
  Stream<List<ProfileUpdateRequestModel>> getProfileUpdateRequests();
  Future<void> submitProfileUpdateRequest(ProfileUpdateRequestModel request);
  Future<void> approveProfileUpdateRequest(String requestId);
  Future<void> rejectProfileUpdateRequest(String requestId);

  // Anonymous Complaints (Grievance Box - visible only to admins)
  Stream<List<ComplaintModel>> getComplaints();
  Stream<List<ComplaintModel>> getUserComplaints(String uid);
  Future<void> submitComplaint(ComplaintModel complaint);
  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? adminNotes,
    String? resolvedBy,
  });
  Future<void> deleteComplaint(String complaintId);

  // Authorities & Leadership
  Stream<List<AuthorityModel>> getAuthorities();
  Future<void> createAuthority(AuthorityModel authority);
  Future<void> updateAuthority(AuthorityModel authority);
  Future<void> deleteAuthority(String authorityId);

  // Authority Groups & Cells (e.g. Women Cell)
  Stream<List<AuthorityGroupModel>> getAuthorityGroups();
  Future<void> createAuthorityGroup(AuthorityGroupModel group);
  Future<void> updateAuthorityGroup(AuthorityGroupModel group);
  Future<void> deleteAuthorityGroup(String groupId);
}
