import 'dart:async';
import '../../models/domain_model.dart';
import '../../models/user_progress_model.dart';
import '../../models/broadcast_model.dart';
import '../../models/user_model.dart';
import '../../models/session_model.dart';
import '../../models/hackathon_model.dart';
import '../../models/post_model.dart';
import '../../models/message_model.dart';
import '../../models/access_request_model.dart';
import '../auth/mock_auth_repository.dart';
import 'database_repository.dart';

class MockDatabaseRepository implements DatabaseRepository {
  // Streams controllers
  final _domainController = StreamController<List<DomainModel>>.broadcast();
  final _broadcastController =
      StreamController<List<BroadcastModel>>.broadcast();
  final _membersController = StreamController<List<UserModel>>.broadcast();
  final _accessRequestsController =
      StreamController<List<AccessRequestModel>>.broadcast();

  // Phase 2/3 stream controllers
  final _sessionsController = StreamController<List<SessionModel>>.broadcast();
  final _hackathonsController =
      StreamController<List<HackathonModel>>.broadcast();
  final _teamsControllers = <String, StreamController<List<TeamModel>>>{};
  final _postsController = StreamController<List<PostModel>>.broadcast();
  final _commentsControllers = <String, StreamController<List<CommentModel>>>{};
  final _channelsController =
      StreamController<List<ChatChannelModel>>.broadcast();
  final _messagesControllers = <String, StreamController<List<MessageModel>>>{};

  // Specific topic and progress streams
  final _progressControllers = <String, StreamController<UserProgressModel?>>{};
  final _modulesControllers = <String, StreamController<List<ModuleModel>>>{};
  final _topicsControllers = <String, StreamController<List<TopicModel>>>{};

  // Memory Storage
  late List<DomainModel> _domains;
  late List<ModuleModel> _modules;
  late List<TopicModel> _topics;
  final List<BroadcastModel> _broadcasts = [];
  final List<UserModel> _members = [];
  final List<AccessRequestModel> _accessRequests = [];
  final Map<String, UserProgressModel> _progressStore = {};

  // Phase 2/3 Storage
  final List<SessionModel> _sessions = [];
  final List<HackathonModel> _hackathons = [];
  final Map<String, List<TeamModel>> _teamsStore = {};
  final List<PostModel> _posts = [];
  final Map<String, List<CommentModel>> _commentsStore = {};
  final List<ChatChannelModel> _channels = [];
  final Map<String, List<MessageModel>> _messagesStore = {};

  MockDatabaseRepository() {
    _initMockData();
  }

  void _initMockData() {
    // 1. Initial Domains
    _domains = [
      DomainModel(
        id: 'dsa',
        name: 'Data Structures & Algorithms',
        description:
            'Master core computational problem solving. Graphs, Dynamic Programming, Trees, and analysis.',
        leadUserId: 'user_led001',
        password: '',
        modules: [],
      ),
      DomainModel(
        id: 'web_dev',
        name: 'Web Development (Full Stack)',
        description:
            'Build modern responsive websites and APIs using React, Node.js, Express, and Database design.',
        leadUserId: 'user_adm001',
        password: '',
        modules: [],
      ),
      DomainModel(
        id: 'ml',
        name: 'Machine Learning & AI',
        description:
            'Deep dive into statistics, linear regression, neural networks, computer vision, and NLP.',
        leadUserId: 'user_adm001',
        password: '',
        modules: [],
      ),
    ];

    // 2. Initial Modules
    _modules = [
      // DSA Modules
      ModuleModel(
        id: 'dsa_mod1',
        domainId: 'dsa',
        title: 'Arrays & Hashing',
        order: 1,
        topics: [],
      ),
      ModuleModel(
        id: 'dsa_mod2',
        domainId: 'dsa',
        title: 'Two Pointers & Slid Window',
        order: 2,
        topics: [],
      ),
      ModuleModel(
        id: 'dsa_mod3',
        domainId: 'dsa',
        title: 'Trees & Recursion',
        order: 3,
        topics: [],
      ),

      // Web Dev Modules
      ModuleModel(
        id: 'web_mod1',
        domainId: 'web_dev',
        title: 'HTML, CSS & Modern layouts',
        order: 1,
        topics: [],
      ),
      ModuleModel(
        id: 'web_mod2',
        domainId: 'web_dev',
        title: 'JS Core & Asynchronous flows',
        order: 2,
        topics: [],
      ),
      ModuleModel(
        id: 'web_mod3',
        domainId: 'web_dev',
        title: 'State Management & Flutter Web',
        order: 3,
        topics: [],
      ),
    ];

    // 3. Initial Topics
    _topics = [
      // DSA mod1
      TopicModel(
        id: 'dsa_top1',
        moduleId: 'dsa_mod1',
        title: 'Contains Duplicate (Easy)',
        order: 1,
        resources: [
          ResourceModel(
            title: 'LeetCode Problem #217',
            url: 'https://leetcode.com/problems/contains-duplicate/',
            type: 'link',
          ),
          ResourceModel(
            title: 'NeetCode Video Solution',
            url: 'https://www.youtube.com/watch?v=3OamzN90kDg',
            type: 'video',
          ),
        ],
      ),
      TopicModel(
        id: 'dsa_top2',
        moduleId: 'dsa_mod1',
        title: 'Two Sum (Easy)',
        order: 2,
        resources: [
          ResourceModel(
            title: 'LeetCode Problem #1',
            url: 'https://leetcode.com/problems/two-sum/',
            type: 'link',
          ),
          ResourceModel(
            title: 'Video walkthrough',
            url: 'https://www.youtube.com/watch?v=KLlXCFG5Tk0',
            type: 'video',
          ),
        ],
      ),
      TopicModel(
        id: 'dsa_top3',
        moduleId: 'dsa_mod1',
        title: 'Group Anagrams (Medium)',
        order: 3,
        resources: [
          ResourceModel(
            title: 'LeetCode Problem #49',
            url: 'https://leetcode.com/problems/group-anagrams/',
            type: 'link',
          ),
          ResourceModel(
            title: 'Optimal Approach Article',
            url: 'https://neetcode.io/solutions/group-anagrams',
            type: 'doc',
          ),
        ],
      ),

      // DSA mod2
      TopicModel(
        id: 'dsa_top4',
        moduleId: 'dsa_mod2',
        title: 'Valid Palindrome',
        order: 1,
        resources: [
          ResourceModel(
            title: 'LeetCode #125',
            url: 'https://leetcode.com/problems/valid-palindrome/',
            type: 'link',
          ),
        ],
      ),
      TopicModel(
        id: 'dsa_top5',
        moduleId: 'dsa_mod2',
        title: 'Two Sum II - Sorted Input',
        order: 2,
        resources: [
          ResourceModel(
            title: 'LeetCode #167',
            url:
                'https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/',
            type: 'link',
          ),
        ],
      ),

      // DSA mod3
      TopicModel(
        id: 'dsa_top6',
        moduleId: 'dsa_mod3',
        title: 'Invert Binary Tree',
        order: 1,
        resources: [
          ResourceModel(
            title: 'LeetCode #226',
            url: 'https://leetcode.com/problems/invert-binary-tree/',
            type: 'link',
          ),
        ],
      ),

      // Web Dev mod1
      TopicModel(
        id: 'web_top1',
        moduleId: 'web_mod1',
        title: 'Semantic Tags & Structures',
        order: 1,
        resources: [
          ResourceModel(
            title: 'MDN Semantic Elements Guide',
            url: 'https://developer.mozilla.org/en-US/docs/Glossary/Semantics',
            type: 'doc',
          ),
        ],
      ),
      TopicModel(
        id: 'web_top2',
        moduleId: 'web_mod1',
        title: 'CSS Grid & Flexbox Mastery',
        order: 2,
        resources: [
          ResourceModel(
            title: 'CSS Tricks Flexbox Complete Guide',
            url: 'https://css-tricks.com/snippets/css/a-guide-to-flexbox/',
            type: 'doc',
          ),
          ResourceModel(
            title: 'Grid Garden Practice game',
            url: 'https://cssgridgarden.com/',
            type: 'practice',
          ),
        ],
      ),

      // Web Dev mod2
      TopicModel(
        id: 'web_top3',
        moduleId: 'web_mod2',
        title: 'Promises & Async Await',
        order: 1,
        resources: [
          ResourceModel(
            title: 'JavaScript.info Async chapter',
            url: 'https://javascript.info/async',
            type: 'doc',
          ),
        ],
      ),
    ];

    // 4. Initial Broadcasts
    _broadcasts.addAll([
      BroadcastModel(
        id: 'bc1',
        title: '🚀 Welcome to KRIVA App!',
        body:
            'Kriva is officially launched for our community. Start tracking your roadmap, follow domains, and prepare for upcoming hackathons!',
        audienceType: 'all',
        audienceValue: '',
        sentBy: 'Club President',
        sentAt: DateTime.now().subtract(const Duration(days: 3)),
        readBy: ['user_mem001'],
      ),
      BroadcastModel(
        id: 'bc2',
        title: '📅 DSA Mentorship Session Today',
        body:
            'Join us today at 6:00 PM in Seminar Hall 1 for an interactive Q&A session on trees and graphs. Don\'t forget to mark your roadmaps!',
        audienceType: 'domain',
        audienceValue: 'dsa',
        sentBy: 'Elena Rostova (DSA Lead)',
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
        readBy: [],
      ),
      BroadcastModel(
        id: 'bc3',
        title: '📢 Batch of 2026 Feedback Needed',
        body:
            'We are planning our web dev workshop slots. Please complete the interest form pinned in the group.',
        audienceType: 'batch',
        audienceValue: 'Batch of 2026',
        sentBy: 'Club President',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
        readBy: [],
      ),
    ]);

    // 5. Initial Members
    _members.addAll([
      UserModel(
        uid: 'user_mem001',
        clubId: 'MEM001',
        name: 'Abhisht Singh',
        email: 'mem001@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Abhisht',
        role: UserRole.member,
        batch: 'Batch of 2026',
        bio:
            'Flutter enthusiast & competitive programmer. Building cool stuff!',
        domainsFollowing: ['dsa', 'web_dev'],
        streak: UserStreak(
          count: 7,
          lastActiveDate: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      UserModel(
        uid: 'user_led001',
        clubId: 'LED001',
        name: 'Elena Rostova',
        email: 'led001@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Elena',
        role: UserRole.lead,
        batch: 'Batch of 2025',
        bio:
            'Domain Lead for Data Structures & Algorithms. Ask me anything about graphs!',
        domainsFollowing: ['dsa'],
        streak: UserStreak(count: 24, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      UserModel(
        uid: 'user_mem002',
        clubId: 'MEM002',
        name: 'Jane Doe',
        email: 'mem002@kriva.app',
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Jane',
        role: UserRole.member,
        batch: 'Batch of 2026',
        bio: 'Aspiring Web Developer & UI Designer.',
        domainsFollowing: ['web_dev'],
        streak: UserStreak(count: 3, lastActiveDate: DateTime.now()),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);

    // 6. Prepopulate Progress
    _progressStore['user_mem001_dsa'] = UserProgressModel(
      uid: 'user_mem001',
      domainId: 'dsa',
      topicsCompleted: {
        'dsa_top1': DateTime.now().subtract(const Duration(days: 5)),
        'dsa_top2': DateTime.now().subtract(const Duration(days: 2)),
      },
      percentComplete: 0.33,
    );

    // 7. Initial Sessions (Phase 2)
    _sessions.addAll([
      SessionModel(
        id: 'sess1',
        title: 'React & Next.js Advanced Architecture',
        description:
            'Deep dive into App Router, Server Actions, caching mechanisms, and optimizing web applications for scale.',
        domainTag: 'web_dev',
        dateTime: DateTime.now().add(
          const Duration(hours: 2),
        ), // Today in 2 hours
        link: 'https://meet.google.com/abc-defg-hij',
        createdBy: 'Elena Rostova',
        rsvps: ['user_mem001'],
        attendees: [],
      ),
      SessionModel(
        id: 'sess2',
        title: 'Introduction to Neural Networks',
        description:
            'Understand the math behind perceptrons, activation functions, backpropagation, and build a simple neural net from scratch.',
        domainTag: 'ml',
        dateTime: DateTime.now().add(
          const Duration(days: 1, hours: 3),
        ), // Tomorrow
        link: 'https://zoom.us/j/123456789',
        createdBy: 'Club President',
        rsvps: [],
        attendees: [],
      ),
      SessionModel(
        id: 'sess3',
        title: 'Binary Trees & Graph Traversals',
        description:
            'Weekly algorithm code review. We will solve DFS, BFS, and Dijkstra optimization patterns on LeetCode.',
        domainTag: 'dsa',
        dateTime: DateTime.now().subtract(
          const Duration(days: 2),
        ), // 2 days ago
        link: 'https://meet.google.com/xyz-pdqr-wuv',
        createdBy: 'Elena Rostova',
        rsvps: ['user_mem001', 'user_mem002'],
        attendees: ['user_mem001'],
      ),
    ]);

    // 8. Initial Hackathons & Teams (Phase 2)
    _hackathons.add(
      HackathonModel(
        id: 'hack1',
        title: 'KRIVA Winter Hackathon 2026',
        description:
            'The annual flagship dev challenge. Team up to build open-source community solutions for educational and utility needs. Win exciting prizes!',
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        teamSizeLimit: 4,
      ),
    );

    _teamsStore['hack1'] = [
      TeamModel(
        id: 'team1',
        name: 'Algorithm Avengers',
        leadUid: 'user_led001',
        memberUids: ['user_led001', 'user_mem002'],
        requiredSkills: ['Backend', 'Python', 'ML Engine'],
        pendingRequests: ['user_mem001'],
        status: 'open',
      ),
      TeamModel(
        id: 'team2',
        name: 'Web Wizards',
        leadUid: 'user_mem001',
        memberUids: ['user_mem001'],
        requiredSkills: ['UI/UX', 'React', 'TailwindCSS'],
        pendingRequests: [],
        status: 'open',
      ),
    ];

    // 9. Initial Posts & Comments (Phase 3)
    _posts.addAll([
      PostModel(
        id: 'post1',
        authorUid: 'user_led001',
        authorName: 'Elena Rostova',
        authorPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Elena',
        text:
            'Just finished structuring the Arrays & Hashing topics for the DSA track! Check it out and let me know if you want any specific resources added.',
        tag: 'dsa',
        likes: ['user_mem001', 'user_mem002'],
        commentCount: 2,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      PostModel(
        id: 'post2',
        authorUid: 'user_mem001',
        authorName: 'Abhisht Singh',
        authorPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Abhisht',
        text:
            'Anyone planning to build a Flutter application for the Winter Hackathon? Looking for a UI/UX designer to join our team "Web Wizards"!',
        tag: 'hackathon',
        likes: [],
        commentCount: 0,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ]);

    _commentsStore['post1'] = [
      CommentModel(
        id: 'c1',
        authorUid: 'user_mem001',
        authorName: 'Abhisht Singh',
        authorPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Abhisht',
        text:
            'This is super helpful Elena! The NeetCode video links are awesome.',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      CommentModel(
        id: 'c2',
        authorUid: 'user_mem002',
        authorName: 'Jane Doe',
        authorPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Jane',
        text: 'Thanks Elena, starting topic 1 today!',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];

    // 10. Initial Channels & Messages (Phase 3)
    _channels.addAll([
      ChatChannelModel(
        id: 'chan_global',
        name: '#announcements',
        type: 'direct',
      ),
      ChatChannelModel(
        id: 'chan_dsa',
        name: '#dsa_discussion',
        type: 'domain',
        domainId: 'dsa',
      ),
      ChatChannelModel(
        id: 'chan_web',
        name: '#web_dev_discussion',
        type: 'domain',
        domainId: 'web_dev',
      ),
    ]);

    _messagesStore['chan_global'] = [
      MessageModel(
        id: 'msg1',
        senderUid: 'user_led001',
        senderName: 'Elena Rostova',
        senderPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Elena',
        text:
            'Welcome to the global announcements channel! Please keep discussions to domain-specific channels.',
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    _messagesStore['chan_dsa'] = [
      MessageModel(
        id: 'msg2',
        senderUid: 'user_mem001',
        senderName: 'Abhisht Singh',
        senderPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Abhisht',
        text:
            'Stuck on Group Anagrams optimization. Should I use sorting or frequency counts?',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      MessageModel(
        id: 'msg3',
        senderUid: 'user_led001',
        senderName: 'Elena Rostova',
        senderPhoto: 'https://api.dicebear.com/7.x/avataaars/png?seed=Elena',
        text:
            'Frequency counts will give you O(N * K) time. Sorting takes O(N * K log K). Try mapping characters!',
        sentAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
      ),
    ];
  }

  // Domain Stream
  @override
  Stream<List<DomainModel>> getDomains() {
    // Yield current values and update future subscribers
    Timer.run(() => _domainController.add(_domains));
    return _domainController.stream;
  }

  @override
  Future<DomainModel> getDomainById(String domainId) async {
    return _domains.firstWhere((element) => element.id == domainId);
  }

  // Modules Stream
  @override
  Stream<List<ModuleModel>> getModules(String domainId) {
    final key = domainId;
    if (!_modulesControllers.containsKey(key)) {
      _modulesControllers[key] =
          StreamController<List<ModuleModel>>.broadcast();
    }

    // Push updates
    final domainMods = _modules.where((m) => m.domainId == domainId).toList();
    domainMods.sort((a, b) => a.order.compareTo(b.order));
    Timer.run(() => _modulesControllers[key]!.add(domainMods));

    return _modulesControllers[key]!.stream;
  }

  // Topics Stream
  @override
  Stream<List<TopicModel>> getTopics(String domainId, String moduleId) {
    final key = moduleId;
    if (!_topicsControllers.containsKey(key)) {
      _topicsControllers[key] = StreamController<List<TopicModel>>.broadcast();
    }

    final modTopics = _topics.where((t) => t.moduleId == moduleId).toList();
    modTopics.sort((a, b) => a.order.compareTo(b.order));
    Timer.run(() => _topicsControllers[key]!.add(modTopics));

    return _topicsControllers[key]!.stream;
  }

  // User Progress Stream
  @override
  Stream<UserProgressModel?> getUserProgress(String uid, String domainId) {
    final key = '${uid}_$domainId';
    if (!_progressControllers.containsKey(key)) {
      _progressControllers[key] =
          StreamController<UserProgressModel?>.broadcast();
    }

    final progress =
        _progressStore[key] ??
        UserProgressModel(
          uid: uid,
          domainId: domainId,
          topicsCompleted: {},
          percentComplete: 0.0,
        );

    Timer.run(() => _progressControllers[key]!.add(progress));
    return _progressControllers[key]!.stream;
  }

  // Toggle Completion
  @override
  Future<void> toggleTopicCompletion(
    String uid,
    String domainId,
    String topicId,
    bool isCompleted,
    int totalTopicsInDomain,
  ) async {
    final progressKey = '${uid}_$domainId';
    final existing =
        _progressStore[progressKey] ??
        UserProgressModel(
          uid: uid,
          domainId: domainId,
          topicsCompleted: {},
          percentComplete: 0.0,
        );

    final updatedMap = Map<String, DateTime>.from(existing.topicsCompleted);
    if (isCompleted) {
      updatedMap[topicId] = DateTime.now();
    } else {
      updatedMap.remove(topicId);
    }

    final double computedPercent = totalTopicsInDomain > 0
        ? (updatedMap.length / totalTopicsInDomain)
        : 0.0;

    final updatedProgress = existing.copyWith(
      topicsCompleted: updatedMap,
      percentComplete: double.parse(computedPercent.toStringAsFixed(2)),
    );

    _progressStore[progressKey] = updatedProgress;

    // Trigger update on stream
    if (_progressControllers.containsKey(progressKey)) {
      _progressControllers[progressKey]!.add(updatedProgress);
    }
  }

  // Broadcasts Stream
  @override
  Stream<List<BroadcastModel>> getBroadcasts(UserModel user) {
    // Sort broadcasts, newest first
    _sortBroadcasts();

    // Trigger immediate emission
    Timer.run(() => _broadcastController.add(_filterBroadcastsForUser(user)));
    return _broadcastController.stream;
  }

  void _sortBroadcasts() {
    _broadcasts.sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  List<BroadcastModel> _filterBroadcastsForUser(UserModel user) {
    return _broadcasts.where((bc) {
      if (bc.audienceType == 'all') return true;
      if (bc.audienceType == 'batch' && bc.audienceValue == user.batch)
        return true;
      if (bc.audienceType == 'domain' &&
          user.domainsFollowing.contains(bc.audienceValue))
        return true;
      return false;
    }).toList();
  }

  @override
  Future<void> markBroadcastAsRead(String uid, String broadcastId) async {
    final idx = _broadcasts.indexWhere((element) => element.id == broadcastId);
    if (idx != -1) {
      final bc = _broadcasts[idx];
      if (!bc.readBy.contains(uid)) {
        final updatedRead = List<String>.from(bc.readBy)..add(uid);
        _broadcasts[idx] = bc.copyWith(readBy: updatedRead);
        _broadcastController.add(_broadcasts); // updates listeners
      }
    }
  }

  @override
  Future<void> createBroadcast(BroadcastModel broadcast) async {
    _broadcasts.add(broadcast);
    _sortBroadcasts();
    _broadcastController.add(_broadcasts);
  }

  // Sessions (Phase 2)
  @override
  Stream<List<SessionModel>> getSessions() {
    Timer.run(() => _sessionsController.add(_sessions));
    return _sessionsController.stream;
  }

  @override
  Future<void> createSession(SessionModel session) async {
    _sessions.add(session);
    _sessionsController.add(_sessions);
  }

  @override
  Future<void> toggleRSVP(String uid, String sessionId, bool rsvp) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _sessions[index];
      final updatedRsvps = List<String>.from(session.rsvps);
      if (rsvp) {
        if (!updatedRsvps.contains(uid)) updatedRsvps.add(uid);
      } else {
        updatedRsvps.remove(uid);
      }
      _sessions[index] = session.copyWith(rsvps: updatedRsvps);
      _sessionsController.add(_sessions);
    }
  }

  // Hackathons & Teams (Phase 2)
  @override
  Stream<List<HackathonModel>> getHackathons() {
    Timer.run(() => _hackathonsController.add(_hackathons));
    return _hackathonsController.stream;
  }

  @override
  Future<void> createHackathon(HackathonModel hackathon) async {
    _hackathons.add(hackathon);
    _hackathonsController.add(_hackathons);
  }

  @override
  Stream<List<TeamModel>> getTeams(String hackathonId) {
    if (!_teamsControllers.containsKey(hackathonId)) {
      _teamsControllers[hackathonId] =
          StreamController<List<TeamModel>>.broadcast();
    }
    final teams = _teamsStore[hackathonId] ?? [];
    Timer.run(() => _teamsControllers[hackathonId]!.add(teams));
    return _teamsControllers[hackathonId]!.stream;
  }

  @override
  Future<void> createTeam(String hackathonId, TeamModel team) async {
    final teams = _teamsStore[hackathonId] ?? [];
    teams.add(team);
    _teamsStore[hackathonId] = teams;
    if (_teamsControllers.containsKey(hackathonId)) {
      _teamsControllers[hackathonId]!.add(teams);
    }
  }

  @override
  Future<void> requestToJoinTeam(
    String hackathonId,
    String teamId,
    String uid,
  ) async {
    final teams = _teamsStore[hackathonId] ?? [];
    final idx = teams.indexWhere((t) => t.id == teamId);
    if (idx != -1) {
      final team = teams[idx];
      if (!team.pendingRequests.contains(uid) &&
          !team.memberUids.contains(uid)) {
        final pending = List<String>.from(team.pendingRequests)..add(uid);
        teams[idx] = team.copyWith(pendingRequests: pending);
        _teamsStore[hackathonId] = teams;
        if (_teamsControllers.containsKey(hackathonId)) {
          _teamsControllers[hackathonId]!.add(teams);
        }
      }
    }
  }

  @override
  Future<void> manageJoinRequest(
    String hackathonId,
    String teamId,
    String uid,
    bool approve,
  ) async {
    final teams = _teamsStore[hackathonId] ?? [];
    final idx = teams.indexWhere((t) => t.id == teamId);
    if (idx != -1) {
      final team = teams[idx];
      final pending = List<String>.from(team.pendingRequests)..remove(uid);
      List<String> members = List<String>.from(team.memberUids);
      if (approve) {
        if (!members.contains(uid)) members.add(uid);
      }
      final newStatus = members.length >= 4
          ? 'full'
          : 'open'; // limit mock to 4
      teams[idx] = team.copyWith(
        pendingRequests: pending,
        memberUids: members,
        status: newStatus,
      );
      _teamsStore[hackathonId] = teams;
      if (_teamsControllers.containsKey(hackathonId)) {
        _teamsControllers[hackathonId]!.add(teams);
      }
    }
  }

  // Community Feed & Comments (Phase 3)
  @override
  Stream<List<PostModel>> getPosts(String? tagFilter) {
    Timer.run(() {
      if (tagFilter == null || tagFilter == 'all') {
        _postsController.add(_posts);
      } else {
        _postsController.add(_posts.where((p) => p.tag == tagFilter).toList());
      }
    });
    return _postsController.stream;
  }

  @override
  Future<void> createPost(PostModel post) async {
    _posts.insert(0, post); // Newest first
    _postsController.add(_posts);
  }

  @override
  Future<void> toggleLikePost(String uid, String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      final post = _posts[idx];
      final likes = List<String>.from(post.likes);
      if (likes.contains(uid)) {
        likes.remove(uid);
      } else {
        likes.add(uid);
      }
      _posts[idx] = post.copyWith(likes: likes);
      _postsController.add(_posts);
    }
  }

  @override
  Stream<List<CommentModel>> getComments(String postId) {
    if (!_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId] =
          StreamController<List<CommentModel>>.broadcast();
    }
    final comments = _commentsStore[postId] ?? [];
    Timer.run(() => _commentsControllers[postId]!.add(comments));
    return _commentsControllers[postId]!.stream;
  }

  @override
  Future<void> addComment(String postId, CommentModel comment) async {
    final comments = _commentsStore[postId] ?? [];
    comments.add(comment);
    _commentsStore[postId] = comments;
    if (_commentsControllers.containsKey(postId)) {
      _commentsControllers[postId]!.add(comments);
    }

    // Update comment count on post
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx != -1) {
      _posts[postIdx] = _posts[postIdx].copyWith(
        commentCount: _posts[postIdx].commentCount + 1,
      );
      _postsController.add(_posts);
    }
  }

  // Chats & Messaging (Phase 3)
  @override
  Stream<List<ChatChannelModel>> getChannels(UserModel user) {
    Timer.run(() => _channelsController.add(_channels));
    return _channelsController.stream;
  }

  @override
  Stream<List<MessageModel>> getMessages(String channelId) {
    if (!_messagesControllers.containsKey(channelId)) {
      _messagesControllers[channelId] =
          StreamController<List<MessageModel>>.broadcast();
    }
    final messages = _messagesStore[channelId] ?? [];
    Timer.run(() => _messagesControllers[channelId]!.add(messages));
    return _messagesControllers[channelId]!.stream;
  }

  @override
  Future<void> sendMessage(String channelId, MessageModel message) async {
    final messages = _messagesStore[channelId] ?? [];
    messages.add(message);
    _messagesStore[channelId] = messages;
    if (_messagesControllers.containsKey(channelId)) {
      _messagesControllers[channelId]!.add(messages);
    }
  }

  // Admin Roadmaps setup
  @override
  Future<void> createDomain(DomainModel domain) async {
    _domains.add(domain);
    _domainController.add(_domains);
  }

  @override
  Future<void> createModule(String domainId, ModuleModel module) async {
    _modules.add(module);
    if (_modulesControllers.containsKey(domainId)) {
      final domainMods = _modules.where((m) => m.domainId == domainId).toList();
      domainMods.sort((a, b) => a.order.compareTo(b.order));
      _modulesControllers[domainId]!.add(domainMods);
    }
  }

  @override
  Future<void> createTopic(
    String domainId,
    String moduleId,
    TopicModel topic,
  ) async {
    _topics.add(topic);
    if (_topicsControllers.containsKey(moduleId)) {
      final modTopics = _topics.where((t) => t.moduleId == moduleId).toList();
      modTopics.sort((a, b) => a.order.compareTo(b.order));
      _topicsControllers[moduleId]!.add(modTopics);
    }
  }

  // Members Stream
  @override
  Stream<List<UserModel>> getMembers() {
    Timer.run(() => _membersController.add(_members));
    return _membersController.stream;
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    final index = _members.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      _members[index] = _members[index].copyWith(role: role);
      _membersController.add(_members);
    }
  }

  @override
  Future<void> updateFollowedDomains(String uid, List<String> domains) async {
    final index = _members.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      _members[index] = _members[index].copyWith(domainsFollowing: domains);
      _membersController.add(_members);
    }
  }

  // Admissions & Password resets (Phase 4 completion)
  @override
  Stream<List<AccessRequestModel>> getAccessRequests() {
    // Add default mock pending request if list is empty, for preview
    if (_accessRequests.isEmpty) {
      _accessRequests.add(
        AccessRequestModel(
          id: 'req_101',
          name: 'Harsh Vardhan',
          fatherName: 'Rajesh Vardhan',
          phoneNumber: '9876543210',
          personalEmail: 'harsh@gmail.com',
          kietEmail: 'harsh.22bcs1010@kiet.edu',
          aadharNumber: '1234 5678 9012',
          requestedRole: 'member',
          domainInterest: ['dsa', 'web_dev'],
          status: 'pending',
          requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      );
    }
    Timer.run(() => _accessRequestsController.add(_accessRequests));
    return _accessRequestsController.stream;
  }

  @override
  Future<void> submitAccessRequest(AccessRequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _accessRequests.add(request);
    _accessRequestsController.add(_accessRequests);
  }

  @override
  Future<void> approveAccessRequest(
    String requestId,
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final reqIndex = _accessRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex != -1) {
      final req = _accessRequests[reqIndex];
      // Update status
      _accessRequests[reqIndex] = AccessRequestModel(
        id: req.id,
        name: req.name,
        fatherName: req.fatherName,
        phoneNumber: req.phoneNumber,
        personalEmail: req.personalEmail,
        kietEmail: req.kietEmail,
        aadharNumber: req.aadharNumber,
        requestedRole: req.requestedRole,
        domainInterest: req.domainInterest,
        status: 'approved',
        requestedAt: req.requestedAt,
      );
      _accessRequestsController.add(_accessRequests);

      // Admit User
      final cleanId = email.split('@')[0].toUpperCase();
      final uid = 'user_${cleanId.toLowerCase()}';
      final isLead = req.requestedRole == 'lead';

      final newUser = UserModel(
        uid: uid,
        clubId: cleanId,
        name: req.name,
        email: email,
        photoUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=${req.name}',
        role: isLead ? UserRole.lead : UserRole.member,
        batch: 'Batch of 2027',
        bio: 'Admitted via Access Request form.',
        domainsFollowing: req.domainInterest,
        streak: UserStreak(count: 0, lastActiveDate: null),
        createdAt: DateTime.now(),
      );

      _members.add(newUser);
      _membersController.add(_members);

      // Register in mock auth credentials
      MockAuthRepository.mockUsers[cleanId] = newUser;
      MockAuthRepository.mockPasswords[cleanId] = password;
    }
  }

  @override
  Future<void> rejectAccessRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final reqIndex = _accessRequests.indexWhere((r) => r.id == requestId);
    if (reqIndex != -1) {
      final req = _accessRequests[reqIndex];
      _accessRequests[reqIndex] = AccessRequestModel(
        id: req.id,
        name: req.name,
        fatherName: req.fatherName,
        phoneNumber: req.phoneNumber,
        personalEmail: req.personalEmail,
        kietEmail: req.kietEmail,
        aadharNumber: req.aadharNumber,
        requestedRole: req.requestedRole,
        domainInterest: req.domainInterest,
        status: 'rejected',
        requestedAt: req.requestedAt,
      );
      _accessRequestsController.add(_accessRequests);
    }
  }

  @override
  Future<void> changeUserPassword(String uid, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _members.indexWhere((element) => element.uid == uid);
    if (index != -1) {
      final clubId = _members[index].clubId.toUpperCase();
      MockAuthRepository.mockPasswords[clubId] = newPassword;
    }
  }
}
