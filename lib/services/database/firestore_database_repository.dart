import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import '../../models/standalone_quiz_model.dart';
import '../../models/session_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../models/access_request_model.dart';
import '../../models/team_request_model.dart';
import '../../models/profile_update_request_model.dart';
import '../../models/complaint_model.dart';
import '../../models/authority_group_model.dart';
import '../../models/authority_model.dart';
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

  @override
  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
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
            if (bc.audienceType == 'batch' && bc.audienceValue == user.batch) {
              return true;
            }
            if (bc.audienceType == 'domain' &&
                user.domainsFollowing.contains(bc.audienceValue)) {
              return true;
            }
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

  @override
  Future<void> deleteBroadcast(String broadcastId) async {
    await _firestore.collection('broadcasts').doc(broadcastId).delete();
  }

  // Admin roadmaps management
  @override
  Future<void> createDomain(DomainModel domain) async {
    await _firestore.collection('domains').doc(domain.id).set(domain.toMap());
  }

  @override
  Future<void> updateDomain(DomainModel domain) async {
    await _firestore.collection('domains').doc(domain.id).update(domain.toMap());
  }

  @override
  Future<void> deleteDomain(String domainId) async {
    final domainRef = _firestore.collection('domains').doc(domainId);
    final modules = await domainRef.collection('modules').get();
    final batch = _firestore.batch();
    for (final module in modules.docs) {
      final topics = await module.reference.collection('topics').get();
      for (final topic in topics.docs) {
        batch.delete(topic.reference);
      }
      batch.delete(module.reference);
    }
    batch.delete(domainRef);
    await batch.commit();
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
  Future<void> updateModule(String domainId, ModuleModel module) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(module.id)
        .update(module.toMap());
  }

  @override
  Future<void> deleteModule(String domainId, String moduleId) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .delete();
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

  @override
  Future<void> updateTopic(
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
        .update(topic.toMap());
  }

  @override
  Future<void> deleteTopic(
    String domainId,
    String moduleId,
    String topicId,
  ) async {
    await _firestore
        .collection('domains')
        .doc(domainId)
        .collection('modules')
        .doc(moduleId)
        .collection('topics')
        .doc(topicId)
        .delete();
  }

  @override
  Future<void> createStandaloneQuiz(StandaloneQuizModel quiz) async {
    await _firestore
        .collection('standalone_quizzes')
        .doc(quiz.id)
        .set(quiz.toMap());
  }

  @override
  Future<void> deleteStandaloneQuiz(String quizId) async {
    await _firestore.collection('standalone_quizzes').doc(quizId).delete();
  }

  @override
  Stream<List<StandaloneQuizModel>> getStandaloneQuizzes() {
    return _firestore
        .collection('standalone_quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StandaloneQuizModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> submitQuizResult(
    String uid,
    String quizId,
    int score,
    int total,
  ) async {
    final docId = '${uid}_$quizId';
    await _firestore
        .collection('quiz_results')
        .doc(docId)
        .set({
      'uid': uid,
      'quizId': quizId,
      'score': score,
      'total': total,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  // Member Directory
  @override
  Stream<List<UserModel>> getMembers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((member) => member.isActive)
          .toList();
    });
  }

  @override
  Stream<List<UserModel>> getPastMembers() {
    return _firestore
        .collection('past_members')
        .orderBy('archivedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<void> archiveMember(UserModel member, String archivedBy) async {
    final archive = Map<String, dynamic>.from(member.toMap())
      ..addAll({'archivedAt': Timestamp.now(), 'archivedBy': archivedBy});
    final batch = _firestore.batch();
    batch.set(_firestore.collection('past_members').doc(member.uid), archive);
    batch.update(_firestore.collection('users').doc(member.uid), {
      'isActive': false,
    });
    await batch.commit();
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
  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).delete();
  }

  @override
  Future<void> toggleRSVP(String uid, String sessionId, bool rsvp) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'rsvps': rsvp
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<void> markAttendance(String sessionId, String uid) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'attendees': FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Future<void> toggleAttendance(String sessionId, String uid, bool isPresent) async {
    await _firestore.collection('sessions').doc(sessionId).update({
      'attendees': isPresent
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }


  // Hackathons & Teams (Phase 2)
  @override
  Stream<List<HackathonModel>> getHackathons() {
    return _firestore
        .collection('hackathons')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HackathonModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<HackathonModel>> getPendingHackathons() {
    return _firestore
        .collection('hackathons')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HackathonModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> updateHackathonStatus(String id, String status) async {
    await _firestore.collection('hackathons').doc(id).update({
      'status': status,
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
  Future<void> deleteHackathon(String hackathonId) async {
    await _firestore.collection('hackathons').doc(hackathonId).delete();
  }

  @override
  Future<void> updateHackathon(HackathonModel hackathon) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathon.id)
        .set(hackathon.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUserStreak(String uid, UserStreak streak) async {
    await _firestore.collection('users').doc(uid).update({
      'streak': streak.toMap(),
    });
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
  Future<void> updateTeamParticipationStatus(
    String hackathonId,
    String teamId,
    String participationStatus,
    String statusDescription,
  ) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(teamId)
        .update({
          'participationStatus': participationStatus,
          'statusDescription': statusDescription,
        });
  }

  @override
  Future<void> deleteTeam(String hackathonId, String teamId) async {
    await _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(teamId)
        .delete();
  }

  @override
  Future<void> leaveTeam(String hackathonId, String teamId, String uid) async {
    final docRef = _firestore
        .collection('hackathons')
        .doc(hackathonId)
        .collection('teams')
        .doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final team = TeamModel.fromMap(snapshot.data()!, snapshot.id);
      final updatedMembers = List<String>.from(team.memberUids)..remove(uid);
      final updatedPending = List<String>.from(team.pendingRequests)..remove(uid);

      if (updatedMembers.isEmpty) {
        transaction.delete(docRef);
      } else {
        final newLead = team.leadUid == uid ? updatedMembers.first : team.leadUid;
        transaction.update(docRef, {
          'memberUids': updatedMembers,
          'pendingRequests': updatedPending,
          'leadUid': newLead,
          'status': 'open',
        });
      }
    });
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
  Future<void> deletePost(String postId) async {
    // Delete comments in subcollection first, then post
    final comments = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();
    for (final doc in comments.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('posts').doc(postId).delete();
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
    return _firestore
        .collection('channels')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
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
    final batch = _firestore.batch();
    
    final messageRef = _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(message.id);
    
    batch.set(messageRef, message.toMap());
    
    final channelRef = _firestore.collection('channels').doc(channelId);
    batch.update(channelRef, {
      'lastMessage': message.text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<String> getOrCreateDirectChat(String currentUserId, String targetUserId) async {
    // Generate a consistent ID for 1-on-1 chats so it's unique between any two users
    final participants = [currentUserId, targetUserId];
    participants.sort(); // sort alphabetically to ensure uniqueness regardless of who starts it
    final channelId = 'direct_${participants[0]}_${participants[1]}';
    
    final channelRef = _firestore.collection('channels').doc(channelId);
    final doc = await channelRef.get();
    
    if (!doc.exists) {
      // Create new chat channel
      final newChannel = ChatChannelModel(
        id: channelId,
        name: 'Direct Chat',
        type: 'direct',
        participants: participants,
        updatedAt: DateTime.now(),
      );
      await channelRef.set(newChannel.toMap());
    }
    
    return channelId;
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.value});
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  @override
  Future<void> toggleFollowMember(String currentUserId, String targetUserId, bool follow) async {
    final batch = _firestore.batch();
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    if (follow) {
      batch.update(currentUserRef, {
        'followingIds': FieldValue.arrayUnion([targetUserId])
      });
      batch.update(targetUserRef, {
        'followerIds': FieldValue.arrayUnion([currentUserId])
      });
    } else {
      batch.update(currentUserRef, {
        'followingIds': FieldValue.arrayRemove([targetUserId])
      });
      batch.update(targetUserRef, {
        'followerIds': FieldValue.arrayRemove([currentUserId])
      });
    }

    await batch.commit();
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
    String contactEmail,
    String clubId,
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
    final githubId = data?['githubId'] ?? '';
    final linkedinId = data?['linkedinId'] ?? '';
    final instagramId = data?['instagramId'] ?? '';

    final cleanId = clubId.trim().toUpperCase();
    final batch = data?['batch'] ?? 'Batch of 2028';
    final loginEmail = '${cleanId.toLowerCase()}@kriva.app';

    // Retrieve Web API Key from the default Firebase options
    final apiKey = Firebase.app().options.apiKey;

    // Call Firebase Identity Toolkit REST API to create user account
    // This avoids disrupting the local browser session (IndexedDB)
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': loginEmail,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode != 200) {
      if (responseData['error'] != null &&
          responseData['error']['message'] == 'EMAIL_EXISTS') {
        throw Exception('This Club ID is already in use by another member. Please assign a different one.');
      }
      throw Exception(
          'Failed to create Auth account: ${responseData['error']?['message'] ?? 'Unknown Error'}');
    }

    final uid = responseData['localId'];

    if (uid == null) {
      throw Exception('Failed to retrieve user ID from Auth service.');
    }

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'clubId': cleanId,
      'name': name,
      'email': contactEmail,
      'photoUrl': 'https://api.dicebear.com/7.x/avataaars/png?seed=$name',
      'role': requestedRole,
      'batch': batch,
      'bio': 'Admitted via Access Request form.',
      'domainsFollowing': domainInterest,
      'githubId': githubId,
      'linkedinId': linkedinId,
      'instagramId': instagramId,
      'streak': {'count': 0, 'lastActiveDate': null},
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection('access_requests').doc(requestId).update({
      'status': 'approved',
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
    final cleanPassword = newPassword.trim();
    if (cleanPassword.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    // Retrieve user document
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw Exception('User account not found in database.');
    }

    final userData = userDoc.data() ?? {};
    final oldPassword = userData['password'] as String?;
    final clubId = userData['clubId'] as String?;
    final email = userData['email'] as String?;

    final loginEmail = (clubId != null && clubId.isNotEmpty)
        ? '${clubId.toLowerCase()}@kriva.app'
        : (email ?? '');

    final apiKey = Firebase.app().options.apiKey;

    // Try updating Firebase Auth password via REST API if old password is known
    if (loginEmail.isNotEmpty && oldPassword != null && oldPassword.isNotEmpty) {
      try {
        final signInUrl = Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
        final signInRes = await http.post(
          signInUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': loginEmail,
            'password': oldPassword,
            'returnSecureToken': true,
          }),
        );

        final signInData = jsonDecode(signInRes.body);
        final idToken = signInData['idToken'] as String?;

        if (signInRes.statusCode == 200 && idToken != null) {
          final updateUrl = Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey');
          await http.post(
            updateUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'password': cleanPassword,
              'returnSecureToken': false,
            }),
          );
        }
      } catch (_) {
        // Fallback to Firestore password update
      }
    }

    final cleanClubId = (clubId ?? '').toUpperCase();
    final cleanEmail = (email ?? '').trim();

    // SHA-256 hash the password before storing — plain text is NEVER saved
    final hashedPassword = sha256.convert(utf8.encode(cleanPassword)).toString();

    // ignore: avoid_print
    print('===> [ADMIN RESET DEBUG] Setting hashed password for uid=$uid, clubId="$cleanClubId"');

    // 1. Write to dedicated /user_passwords collection
    await _firestore.collection('user_passwords').doc(uid).set({
      'uid': uid,
      'clubId': cleanClubId,
      'email': cleanEmail,
      'password': hashedPassword,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Ensure /users profile document contains NO plain-text password field
    await _firestore.collection('users').doc(uid).update({
      'password': FieldValue.delete(),
      'passwordUpdatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    // ignore: avoid_print
    print('===> [ADMIN RESET DEBUG] Successfully saved password to Firestore for uid=$uid');
  }

  // ── Team Formation Requests ────────────────────────────────────────────────
  @override
  Stream<List<TeamRequestModel>> getTeamRequests() {
    return _firestore
        .collection('team_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> createTeamRequest(TeamRequestModel request) async {
    await _firestore
        .collection('team_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  @override
  Future<void> updateTeamRequestStatus(String requestId, String status) async {
    await _firestore
        .collection('team_requests')
        .doc(requestId)
        .update({'status': status});
  }

  @override
  Future<void> toggleTeamInterest(
    String uid,
    String requestId,
    bool isInterested,
  ) async {
    final docRef = _firestore.collection('team_requests').doc(requestId);
    if (isInterested) {
      await docRef.update({
        'interestedMemberIds': FieldValue.arrayUnion([uid])
      });
    } else {
      await docRef.update({
        'interestedMemberIds': FieldValue.arrayRemove([uid])
      });
    }
  }

  // ── Profile Update Requests (Admin Approval) ──────────────────────────────
  @override
  Stream<List<ProfileUpdateRequestModel>> getProfileUpdateRequests() {
    return _firestore
        .collection('profile_update_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProfileUpdateRequestModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> submitProfileUpdateRequest(
    ProfileUpdateRequestModel request,
  ) async {
    await _firestore
        .collection('profile_update_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  @override
  Future<void> approveProfileUpdateRequest(String requestId) async {
    final doc = await _firestore
        .collection('profile_update_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) throw Exception('Profile update request not found');

    final data = doc.data()!;
    final req = ProfileUpdateRequestModel.fromMap(data, doc.id);

    // Apply updates directly to user's document
    final updateData = <String, dynamic>{
      'name': req.requestedName,
      'batch': req.requestedBatch,
      'bio': req.requestedBio,
      'githubId': req.requestedGithubId,
      'linkedinId': req.requestedLinkedinId,
      'instagramId': req.requestedInstagramId,
    };

    if (req.requestedPhotoUrl.isNotEmpty) {
      updateData['photoUrl'] = req.requestedPhotoUrl;
    }

    await _firestore.collection('users').doc(req.uid).update(updateData);

    // Mark request approved
    await _firestore
        .collection('profile_update_requests')
        .doc(requestId)
        .update({'status': 'approved'});
  }

  @override
  Future<void> rejectProfileUpdateRequest(String requestId) async {
    await _firestore
        .collection('profile_update_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // ── Anonymous Complaints (Grievance Box) ───────────────────────────────────
  // Note: Stored under access_requests/_app_data to conform with active deployed security rules
  CollectionReference<Map<String, dynamic>> get _complaintsRef =>
      _firestore.collection('access_requests').doc('_app_data').collection('complaints');

  CollectionReference<Map<String, dynamic>> get _authoritiesRef =>
      _firestore.collection('access_requests').doc('_app_data').collection('authorities');

  CollectionReference<Map<String, dynamic>> get _authorityGroupsRef =>
      _firestore.collection('access_requests').doc('_app_data').collection('authority_groups');

  @override
  Stream<List<ComplaintModel>> getComplaints() {
    return _complaintsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<ComplaintModel>> getUserComplaints(String uid) {
    return _complaintsRef
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return ComplaintModel.fromMap(doc.data(), doc.id);
      }).toList();
      // Sort client-side to avoid requiring composite indexes
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<void> submitComplaint(ComplaintModel complaint) async {
    await _complaintsRef
        .doc(complaint.id)
        .set(complaint.toMap());
  }

  @override
  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? adminNotes,
    String? resolvedBy,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
    };
    if (adminNotes != null) {
      updates['adminNotes'] = adminNotes;
    }
    if (resolvedBy != null) {
      updates['resolvedBy'] = resolvedBy;
    }
    if (status == 'resolved' || status == 'dismissed') {
      updates['resolvedAt'] = Timestamp.now();
    }
    await _complaintsRef.doc(complaintId).update(updates);
  }

  @override
  Future<void> deleteComplaint(String complaintId) async {
    await _complaintsRef.doc(complaintId).delete();
  }

  // ── Authorities & Leadership ──────────────────────────────────────────────
  @override
  Stream<List<AuthorityModel>> getAuthorities() {
    return _authoritiesRef
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AuthorityModel.fromMap(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  @override
  Future<void> createAuthority(AuthorityModel authority) async {
    await _authoritiesRef
        .doc(authority.id)
        .set(authority.toMap());
  }

  @override
  Future<void> updateAuthority(AuthorityModel authority) async {
    final data = authority.toMap();
    data['updatedAt'] = Timestamp.now();
    await _authoritiesRef
        .doc(authority.id)
        .update(data);
  }

  @override
  Future<void> deleteAuthority(String authorityId) async {
    await _authoritiesRef.doc(authorityId).delete();
  }

  // ── Authority Groups & Cells (e.g. Women Cell) ────────────────────────────
  @override
  Stream<List<AuthorityGroupModel>> getAuthorityGroups() {
    return _authorityGroupsRef
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AuthorityGroupModel.fromMap(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) {
        final orderComp = a.order.compareTo(b.order);
        if (orderComp != 0) return orderComp;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  @override
  Future<void> createAuthorityGroup(AuthorityGroupModel group) async {
    await _authorityGroupsRef
        .doc(group.id)
        .set(group.toMap());
  }

  @override
  Future<void> updateAuthorityGroup(AuthorityGroupModel group) async {
    await _authorityGroupsRef
        .doc(group.id)
        .update(group.toMap());
  }

  @override
  Future<void> deleteAuthorityGroup(String groupId) async {
    await _authorityGroupsRef.doc(groupId).delete();
  }
}
