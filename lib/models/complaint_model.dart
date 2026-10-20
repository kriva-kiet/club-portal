import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userClubId;
  final String userRole; // member, lead
  final String userBatch;
  final String title;
  final String category; // e.g. 'Club Culture', 'Domain & Roadmaps', 'Mentorship / Leads', 'Disciplinary & Conduct', 'Women Cell / Safety', 'Events / Facilities', 'Other'
  final String description;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'under_review', 'resolved', 'dismissed'
  final bool isAnonymousToPeers;
  final String? adminNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userClubId,
    required this.userRole,
    required this.userBatch,
    required this.title,
    required this.category,
    required this.description,
    this.priority = 'medium',
    this.status = 'pending',
    this.isAnonymousToPeers = true,
    this.adminNotes,
    this.resolvedBy,
    this.resolvedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
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

    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Unknown Member',
      userEmail: map['userEmail'] ?? '',
      userClubId: map['userClubId'] ?? '',
      userRole: map['userRole'] ?? 'member',
      userBatch: map['userBatch'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      isAnonymousToPeers: map['isAnonymousToPeers'] ?? true,
      adminNotes: map['adminNotes'],
      resolvedBy: map['resolvedBy'],
      resolvedAt: parseNullableDate(map['resolvedAt']),
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userClubId': userClubId,
      'userRole': userRole,
      'userBatch': userBatch,
      'title': title,
      'category': category,
      'description': description,
      'priority': priority,
      'status': status,
      'isAnonymousToPeers': isAnonymousToPeers,
      'adminNotes': adminNotes,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ComplaintModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userClubId,
    String? userRole,
    String? userBatch,
    String? title,
    String? category,
    String? description,
    String? priority,
    String? status,
    bool? isAnonymousToPeers,
    String? adminNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userClubId: userClubId ?? this.userClubId,
      userRole: userRole ?? this.userRole,
      userBatch: userBatch ?? this.userBatch,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isAnonymousToPeers: isAnonymousToPeers ?? this.isAnonymousToPeers,
      adminNotes: adminNotes ?? this.adminNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
