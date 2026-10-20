import 'package:cloud_firestore/cloud_firestore.dart';

class HackathonModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int teamSizeLimit;
  final String? participatingLink;
  final String status; // "pending" | "approved" | "rejected"
  final String requestedBy;
  final String type; // "hackathon" | "internship"
  final String? company;
  final String? location;
  final String? stipendOrPrize;

  HackathonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.teamSizeLimit,
    this.participatingLink,
    required this.status,
    required this.requestedBy,
    this.type = 'hackathon',
    this.company,
    this.location,
    this.stipendOrPrize,
  });

  factory HackathonModel.fromMap(Map<String, dynamic> map, String id) {
    final start = map['startDate'];
    final end = map['endDate'];

    // Auto-detect type if not set
    String resolvedType = map['type'] ?? '';
    if (resolvedType.isEmpty) {
      final combined = '${map['title'] ?? ''} ${map['description'] ?? ''}'.toLowerCase();
      if (combined.contains('intern') || combined.contains('hiring') || combined.contains('job')) {
        resolvedType = 'internship';
      } else {
        resolvedType = 'hackathon';
      }
    }

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
      participatingLink: map['participatingLink'],
      status: map['status'] ?? 'approved', // default to approved for backward compatibility
      requestedBy: map['requestedBy'] ?? 'Unknown',
      type: resolvedType,
      company: map['company'],
      location: map['location'],
      stipendOrPrize: map['stipendOrPrize'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'teamSizeLimit': teamSizeLimit,
      if (participatingLink != null) 'participatingLink': participatingLink,
      'status': status,
      'requestedBy': requestedBy,
      'type': type,
      if (company != null) 'company': company,
      if (location != null) 'location': location,
      if (stipendOrPrize != null) 'stipendOrPrize': stipendOrPrize,
    };
  }

  HackathonModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? teamSizeLimit,
    String? participatingLink,
    String? status,
    String? requestedBy,
    String? type,
    String? company,
    String? location,
    String? stipendOrPrize,
  }) {
    return HackathonModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      teamSizeLimit: teamSizeLimit ?? this.teamSizeLimit,
      participatingLink: participatingLink ?? this.participatingLink,
      status: status ?? this.status,
      requestedBy: requestedBy ?? this.requestedBy,
      type: type ?? this.type,
      company: company ?? this.company,
      location: location ?? this.location,
      stipendOrPrize: stipendOrPrize ?? this.stipendOrPrize,
    );
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
  final String participationStatus; // "applied" | "shortlisted" | "selected" | "hired"
  final String statusDescription; // Description or updates about current status

  TeamModel({
    required this.id,
    required this.name,
    required this.leadUid,
    required this.memberUids,
    required this.requiredSkills,
    required this.pendingRequests,
    required this.status,
    this.participationStatus = 'applied',
    this.statusDescription = '',
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
      participationStatus: map['participationStatus'] ?? map['eventStatus'] ?? 'applied',
      statusDescription: map['statusDescription'] ?? '',
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
      'participationStatus': participationStatus,
      'statusDescription': statusDescription,
    };
  }

  TeamModel copyWith({
    String? name,
    String? leadUid,
    List<String>? memberUids,
    List<String>? requiredSkills,
    List<String>? pendingRequests,
    String? status,
    String? participationStatus,
    String? statusDescription,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      leadUid: leadUid ?? this.leadUid,
      memberUids: memberUids ?? this.memberUids,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      status: status ?? this.status,
      participationStatus: participationStatus ?? this.participationStatus,
      statusDescription: statusDescription ?? this.statusDescription,
    );
  }
}
