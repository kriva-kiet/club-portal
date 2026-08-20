import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../models/access_request_model.dart';
import 'database_repository.dart';

class FirestoreDatabaseRepository implements DatabaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Roadmaps & Domains
  @override
  Stream<List<DomainModel>> getDomains() {
    return _firestore.collection('domains').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return DomainModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<DomainModel> getDomainById(String domainId) async {
    final doc = await _firestore.collection('domains').doc(domainId).get();
    if (!doc.exists) throw Exception('Domain $domainId not found');
    return DomainModel.fromMap(doc.data()!, doc.id);
  }

  @override
  Stream<List<ModuleModel>> getModules(String domainId) {
    return _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ModuleModel.fromMap(doc.data(), doc.id, domainId);
          }).toList();
        });
  }

  @override
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId) {
    return _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .collection('topics')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TopicModel.fromMap(doc.data(), doc.id, moduleId);
          }).toList();
        });
  }

  // Progress Tracking
  @override
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId) {
    final docId = '${uid}_$domainId';
    return _firestore.collection('userProgress').doc(docId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) {
        return UserProgressModel(
          uid: uid,
          domainId: domainId,
          topicsCompleted: {},
          percentComplete: 0.0,
        );
      }
      return UserProgressModel.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<void> toggleTopicCompletion(
    String uid,
    String domainId,
    String topicId,
    bool isCompleted,
    int totalTopicsInDomain,
  ) async {
    final docId = '${uid}_$domainId';
    final docRef = _firestore.collection('userProgress').doc(docId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      Map<String, dynamic> topicsCompleted = {};

      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (data['topicsCompleted'] is Map) {
          topicsCompleted = Map<String, dynamic>.from(data['topicsCompleted']);
        }
      }

      if (isCompleted) {
        topicsCompleted[topicId] = {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        };
      } else {
        topicsCompleted.remove(topicId);
      }

      final double computedPercent = totalTopicsInDomain > 0
          ? (topicsCompleted.length / totalTopicsInDomain)
          : 0.0;

      final double percentComplete = double.parse(
        computedPercent.toStringAsFixed(2),
      );

      transaction.set(docRef, {
        'uid': uid,
        'domainId': domainId,
        'topicsCompleted': topicsCompleted,
        'percentComplete': percentComplete,
      }, SetOptions(merge: true));
    });
  }

  // Broadcasts
  @override
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user) {
    // Note: To avoid complex client-side filter overheads or Firestore composite index demands,
    // we fetch the recent broadcasts (e.g. limit to 50) and filter them in memory.
    return _firestore
        .collection('broadcasts')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return BroadcastModel.fromMap(doc.data(), doc.id);
          }).toList();

          // Perform memory audience filtering
          return list.where((bc) {
            if (bc.audienceType == 'all') return true;
            if (bc.audienceType == 'batch' && bc.audienceValue == user.batch)
              return true;
            if (bc.audienceType == 'domain' &&
                user.domainsFollowing.contains(bc.audienceValue))
              return true;
            return false;
          }).toList();
        });
  }

  @override
  Future<void> markBroadcastAsRead(String uid, String broadcastId) async {
    await _firestore.collection('broadcasts').doc(broadcastId).update({
      'readBy': FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Future<void> createBroadcast(BroadcastModel broadcast) async {
    await _firestore.collection('broadcasts').add(broadcast.toMap());
  }

  // Admin roadmaps management
  @override
  Future<void> createDomain(DomainModel domain) async {
    await _firestore.collection('domains').doc(domain.id).set(domain.toMap());
  }

  @override
  Future<void> createModule(String domainId, ModuleModel module) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(module.id)
        .set(module.toMap());
  }

  @override
  Future<void> createTopic(
    String domainId,
    String moduleId,
    TopicModel topic,
  ) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .collection('topics')
        .doc(topic.id)
        .set(topic.toMap());
  }

  // Member Directory
  @override
  Stream<List<UserModel>> getMembers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Sessions (Phase 2)
  @override
  Stream<List<SessionModel>> getSessions() {
    return _firestore
        .collection('sessions')
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SessionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> createSession(SessionModel session) async {
    await _firestore
        .collection('sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  @override
  Future<void> toggleRSVP(String uid, String sessionId, bool rsvp) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'rsvps': rsvp
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  // Hackathons & Teams (Phase 2)
  @override
  Stream<List<HackathonModel>> getHackathons() {
    return _firestore.collection('hackathons').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return HackathonModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> createHackathon(HackathonModel hackathon) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathon.id)
        .set(hackathon.toMap());
  }

  @override
  Stream<List<TeamModel>> getTeams(String hackathonId) {
    return _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TeamModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> createTeam(String hackathonId, TeamModel team) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(team.id)
        .set(team.toMap());
  }

  @override
  Future<void> requestToJoinTeam(
    String hackathonId,
    String teamId,
    String uid,
  ) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(teamId)
        .update({
          'pendingRequests': FieldValue.arrayUnion([uid]),
        });
  }

  @override
  Future<void> manageJoinRequest(
    String hackathonId,
    String teamId,
    String uid,
    bool approve,
  ) async {
    final docRef = _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Team not found');

      final team = TeamModel.fromMap(snapshot.data()!, snapshot.id);
      final updatedPending = List<String>.from(team.pendingRequests)
        ..remove(uid);
      final updatedMembers = List<String>.from(team.memberUids);

      if (approve) {
        if (!updatedMembers.contains(uid)) updatedMembers.add(uid);
      }

      final newStatus = updatedMembers.length >= 4 ? 'full' : 'open';

      transaction.update(docRef, {
        'pendingRequests': updatedPending,
        'memberUids': updatedMembers,
        'status': newStatus,
      });
    });
  }

  // Community Feed & Comments (Phase 3)
  @override
  Stream<List<PostModel>> getPosts(String? tagFilter) {
    Query query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true);
    if (tagFilter != null && tagFilter != 'all') {
      query = query.where('tag', isEqualTo: tagFilter);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> createPost(PostModel post) async {
    await _firestore.collection('posts').doc(post.id).set(post.toMap());
  }

  @override
  Future<void> toggleLikePost(String uid, String postId) async {
    final docRef = _firestore.collection('posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final likes = List<String>.from(snapshot.data()?['likes'] ?? []);
      if (likes.contains(uid)) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }
      transaction.update(docRef, {'likes': likes});
    });
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CommentModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc(comment.id);

    await _firestore.runTransaction((transaction) async {
      transaction.set(commentRef, comment.toMap());
      transaction.update(postRef, {'commentCount': FieldValue.increment(1)});
    });
  }

  // Chats & Messaging (Phase 3)
  @override
  Stream<List<ChatChannelModel>> getChannels(UserModel user) {
    return _firestore.collection('channels').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatChannelModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<MessageModel>> getMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> sendMessage(String channelId, MessageModel message) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.value});
  }

  @override
  Future<void> updateFollowedDomains(String uid, List<String> domains) async {
    await _firestore.collection('users').doc(uid).update({
      'domainsFollowing': domains,
    });
  }

  // Admissions & Password resets (Phase 4 completion)
  @override
  Stream<List<AccessRequestModel>> getAccessRequests() {
    return _firestore
        .collection('access_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AccessRequestModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  @override
  Future<void> submitAccessRequest(AccessRequestModel request) async {
    await _firestore
        .collection('access_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  @override
  Future<void> approveAccessRequest(
    String requestId,
    String email,
    String password,
  ) async {
    final doc = await _firestore
        .collection('access_requests')
        .doc(requestId)
        .get();
    final data = doc.data();
    final name = data?['name'] ?? 'Admitted Student';
    final requestedRole = data?['requestedRole'] ?? 'member';
    final List domainInterest = data?['domainInterest'] ?? [];

    await _firestore.collection('access_requests').doc(requestId).update({
      'status': 'approved',
    });

    final cleanId = email.split('@')[0].toUpperCase();
    final uid = 'user_${cleanId.toLowerCase()}';
    await _firestore.collection('users').doc(uid).set({
      'clubId': cleanId,
      'name': name,
      'email': email,
      'photoUrl': 'https://api.dicebear.com/7.x/avataaars/png?seed=$name',
      'role': requestedRole,
      'batch': 'Batch of 2027',
      'bio': 'Admitted via Access Request form.',
      'domainsFollowing': domainInterest,
      'streak': {'count': 0, 'lastActiveDate': null},
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<void> rejectAccessRequest(String requestId) async {
    await _firestore.collection('access_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  @override
  Future<void> changeUserPassword(String uid, String newPassword) async {
    // In production Firebase, password updates are done via Firebase Auth client/admin APIs.
  }
}
