import 'package:cloud_firestore/cloud_firestore.dart';

class HackathonModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int teamSizeLimit;

  HackathonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.teamSizeLimit,
  });

  factory HackathonModel.fromMap(Map<String, dynamic> map, String id) {
    final start = map['startDate'];
    final end = map['endDate'];
    return HackathonModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: start is Timestamp
          ? start.toDate()
          : (start is String
                ? (DateTime.tryParse(start) ?? DateTime.now())
                : DateTime.now()),
      endDate: end is Timestamp
          ? end.toDate()
          : (end is String
                ? (DateTime.tryParse(end) ?? DateTime.now())
                : DateTime.now()),
      teamSizeLimit: map['teamSizeLimit'] ?? 4,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'teamSizeLimit': teamSizeLimit,
    };
  }
}

class TeamModel {
  final String id;
  final String name;
  final String leadUid;
  final List<String> memberUids;
  final List<String> requiredSkills;
  final List<String> pendingRequests; // UIDs of users wishing to join
  final String status; // "open" | "full"

  TeamModel({
    required this.id,
    required this.name,
    required this.leadUid,
    required this.memberUids,
    required this.requiredSkills,
    required this.pendingRequests,
    required this.status,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      leadUid: map['leadUid'] ?? '',
      memberUids: List<String>.from(map['memberUids'] ?? []),
      requiredSkills: List<String>.from(map['requiredSkills'] ?? []),
      pendingRequests: List<String>.from(map['pendingRequests'] ?? []),
      status: map['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'leadUid': leadUid,
      'memberUids': memberUids,
      'requiredSkills': requiredSkills,
      'pendingRequests': pendingRequests,
      'status': status,
    };
  }

  TeamModel copyWith({
    String? name,
    String? leadUid,
    List<String>? memberUids,
    List<String>? requiredSkills,
    List<String>? pendingRequests,
    String? status,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      leadUid: leadUid ?? this.leadUid,
      memberUids: memberUids ?? this.memberUids,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      status: status ?? this.status,
    );
  }
}
