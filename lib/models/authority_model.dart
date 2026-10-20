import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorityModel {
  final String id;
  final String userId; // Optional foreign key to UserModel.uid for live updates
  final String name; // e.g. 'Abhisht Singh'
  final String position; // e.g. 'President', 'Vice President', 'Women Cell Head'
  final String groupId; // Foreign key to AuthorityGroupModel.id
  final String groupName; // e.g. 'Executive Council', 'Women Cell'
  final String photoUrl; // URL or base64 data URL
  final String email;
  final String phone;
  final String linkedinUrl;
  final String githubUrl;
  final String instagramUrl;
  final String bio;
  final int order; // Sorting priority (1 for President, 2 for VP, etc.)
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AuthorityModel({
    required this.id,
    this.userId = '',
    required this.name,
    required this.position,
    required this.groupId,
    required this.groupName,
    this.photoUrl = '',
    this.email = '',
    this.phone = '',
    this.linkedinUrl = '',
    this.githubUrl = '',
    this.instagramUrl = '',
    this.bio = '',
    this.order = 0,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuthorityModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AuthorityModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      linkedinUrl: map['linkedinUrl'] ?? '',
      githubUrl: map['githubUrl'] ?? '',
      instagramUrl: map['instagramUrl'] ?? '',
      bio: map['bio'] ?? '',
      order: map['order'] is int ? map['order'] : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'position': position,
      'groupId': groupId,
      'groupName': groupName,
      'photoUrl': photoUrl,
      'email': email,
      'phone': phone,
      'linkedinUrl': linkedinUrl,
      'githubUrl': githubUrl,
      'instagramUrl': instagramUrl,
      'bio': bio,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  AuthorityModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? position,
    String? groupId,
    String? groupName,
    String? photoUrl,
    String? email,
    String? phone,
    String? linkedinUrl,
    String? githubUrl,
    String? instagramUrl,
    String? bio,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthorityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      position: position ?? this.position,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      bio: bio ?? this.bio,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
