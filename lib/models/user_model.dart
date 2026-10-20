import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  member,
  lead,
  admin,
  developer;

  String get value => name;

  /// Developers share the Admin/Dev portal, while every other portal maps to
  /// exactly one role, EXCEPT the member portal which everyone can access.
  bool canAccessPortal(UserRole portalRole) {
    if (portalRole == UserRole.member) return true;
    if (portalRole == UserRole.admin) {
      return this == UserRole.admin || this == UserRole.developer;
    }
    return this == portalRole;
  }

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role.toLowerCase(),
      orElse: () => UserRole.member,
    );
  }
}

class UserStreak {
  final int count;
  final DateTime? lastActiveDate;
  /// ISO-date strings (yyyy-MM-dd) for each unique day user was active.
  /// Used by admin analytics for "Weekly Active Members" chart.
  final List<String> activityDays;

  UserStreak({required this.count, this.lastActiveDate, this.activityDays = const []});

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    final lastActive = map['lastActiveDate'];
    return UserStreak(
      count: map['count'] ?? 0,
      lastActiveDate: lastActive is Timestamp
          ? lastActive.toDate()
          : (lastActive is String ? DateTime.tryParse(lastActive) : null),
      activityDays: List<String>.from(map['activityDays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
      'activityDays': activityDays,
    };
  }

  UserStreak copyWith({int? count, DateTime? lastActiveDate, List<String>? activityDays}) {
    return UserStreak(
      count: count ?? this.count,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      activityDays: activityDays ?? this.activityDays,
    );
  }
}

class UserModel {
  final String uid;
  final String clubId;
  final String name;
  final String email;
  final String photoUrl;
  final UserRole role;
  final String batch;
  final String bio;
  final List<String> domainsFollowing;
  final UserStreak streak;
  final DateTime createdAt;
  final bool isActive;
  final String githubId;
  final String linkedinId;
  final String instagramId;
  final List<String> followingIds;
  final List<String> followerIds;

  UserModel({
    required this.uid,
    required this.clubId,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
    required this.batch,
    required this.bio,
    required this.domainsFollowing,
    required this.streak,
    required this.createdAt,
    this.isActive = true,
    this.githubId = '',
    this.linkedinId = '',
    this.instagramId = '',
    this.followingIds = const [],
    this.followerIds = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final created = map['createdAt'];
    return UserModel(
      uid: id,
      clubId: map['clubId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'member'),
      batch: map['batch'] ?? '',
      bio: map['bio'] ?? '',
      domainsFollowing: List<String>.from(map['domainsFollowing'] ?? []),
      streak: UserStreak.fromMap(
        map['streak'] is Map ? Map<String, dynamic>.from(map['streak']) : {},
      ),
      createdAt: created is Timestamp
          ? created.toDate()
          : (created is String
                ? (DateTime.tryParse(created) ?? DateTime.now())
                : DateTime.now()),
      isActive: map['isActive'] ?? true,
      githubId: map['githubId'] ?? '',
      linkedinId: map['linkedinId'] ?? '',
      instagramId: map['instagramId'] ?? '',
      followingIds: List<String>.from(map['followingIds'] ?? []),
      followerIds: List<String>.from(map['followerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.value,
      'batch': batch,
      'bio': bio,
      'domainsFollowing': domainsFollowing,
      'streak': streak.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'githubId': githubId,
      'linkedinId': linkedinId,
      'instagramId': instagramId,
      'followingIds': followingIds,
      'followerIds': followerIds,
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'clubId': clubId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.value,
      'batch': batch,
      'bio': bio,
      'domainsFollowing': domainsFollowing,
      'streak': {
        'count': streak.count,
        'lastActiveDate': streak.lastActiveDate?.toIso8601String(),
      },
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'githubId': githubId,
      'linkedinId': linkedinId,
      'instagramId': instagramId,
      'followingIds': followingIds,
      'followerIds': followerIds,
    };
  }

  UserModel copyWith({
    String? clubId,
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
    String? batch,
    String? bio,
    List<String>? domainsFollowing,
    UserStreak? streak,
    DateTime? createdAt,
    bool? isActive,
    String? githubId,
    String? linkedinId,
    String? instagramId,
    List<String>? followingIds,
    List<String>? followerIds,
  }) {
    return UserModel(
      uid: uid,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      batch: batch ?? this.batch,
      bio: bio ?? this.bio,
      domainsFollowing: domainsFollowing ?? this.domainsFollowing,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      githubId: githubId ?? this.githubId,
      linkedinId: linkedinId ?? this.linkedinId,
      instagramId: instagramId ?? this.instagramId,
      followingIds: followingIds ?? this.followingIds,
      followerIds: followerIds ?? this.followerIds,
    );
  }
}
