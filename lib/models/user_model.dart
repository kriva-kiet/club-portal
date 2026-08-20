import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  member,
  lead,
  admin,
  developer;

  String get value => name;

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

  UserStreak({required this.count, this.lastActiveDate});

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    final lastActive = map['lastActiveDate'];
    return UserStreak(
      count: map['count'] ?? 0,
      lastActiveDate: lastActive is Timestamp
          ? lastActive.toDate()
          : (lastActive is String ? DateTime.tryParse(lastActive) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'lastActiveDate': lastActiveDate != null
          ? Timestamp.fromDate(lastActiveDate!)
          : null,
    };
  }

  UserStreak copyWith({int? count, DateTime? lastActiveDate}) {
    return UserStreak(
      count: count ?? this.count,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
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
    );
  }
}
