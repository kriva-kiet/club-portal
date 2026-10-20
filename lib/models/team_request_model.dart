import 'package:cloud_firestore/cloud_firestore.dart';

class TeamRequestModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String purpose;
  final List<String> techStack;
  final int membersNeeded;
  final List<String> interestedMemberIds;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;

  TeamRequestModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.purpose,
    required this.techStack,
    required this.membersNeeded,
    required this.interestedMemberIds,
    required this.status,
    required this.createdAt,
  });

  factory TeamRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeamRequestModel(
      id: documentId,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      title: map['title'] ?? '',
      purpose: map['purpose'] ?? '',
      techStack: List<String>.from(map['techStack'] ?? []),
      membersNeeded: map['membersNeeded']?.toInt() ?? 0,
      interestedMemberIds: List<String>.from(map['interestedMemberIds'] ?? []),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'purpose': purpose,
      'techStack': techStack,
      'membersNeeded': membersNeeded,
      'interestedMemberIds': interestedMemberIds,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
