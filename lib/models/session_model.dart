import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String title;
  final String description;
  final String domainTag; // Primary/legacy domain tag e.g. "web_dev", "ml", "dsa", "general"
  final List<String> domainTags; // Target multiple domains e.g. ["dsa", "web_dev"]
  final DateTime dateTime;
  final String link; // meeting URL
  final String venue; // offline venue location
  final bool isOnline; // true for online, false for offline
  final String createdBy;
  final List<String> rsvps; // List of user UIDs who RSVP'd
  final List<String> attendees; // Checked-in members

  final String targetRole; // "both", "member", "lead"

  SessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.domainTag,
    this.domainTags = const [],
    this.targetRole = 'both',
    required this.dateTime,
    required this.link,
    this.venue = '',
    this.isOnline = true,
    required this.createdBy,
    required this.rsvps,
    required this.attendees,
  });

  List<String> get allDomainTags {
    if (domainTags.isNotEmpty) return domainTags;
    if (domainTag.isNotEmpty) return [domainTag];
    return ['general'];
  }

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    final dt = map['dateTime'];
    final primaryTag = map['domainTag'] ?? 'general';
    final List<String> tags = map['domainTags'] != null
        ? List<String>.from(map['domainTags'])
        : <String>[primaryTag];

    return SessionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domainTag: primaryTag,
      domainTags: tags,
      targetRole: map['targetRole'] ?? 'both',
      dateTime: dt is Timestamp
          ? dt.toDate()
          : (dt is String
                ? (DateTime.tryParse(dt) ?? DateTime.now())
                : DateTime.now()),
      link: map['link'] ?? '',
      venue: map['venue'] ?? '',
      isOnline: map['isOnline'] ?? true,
      createdBy: map['createdBy'] ?? 'Admin',
      rsvps: List<String>.from(map['rsvps'] ?? []),
      attendees: List<String>.from(map['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final effectiveTags = domainTags.isNotEmpty ? domainTags : [domainTag];
    return {
      'title': title,
      'description': description,
      'domainTag': effectiveTags.isNotEmpty ? effectiveTags.first : domainTag,
      'domainTags': effectiveTags,
      'targetRole': targetRole,
      'dateTime': Timestamp.fromDate(dateTime),
      'link': link,
      'venue': venue,
      'isOnline': isOnline,
      'createdBy': createdBy,
      'rsvps': rsvps,
      'attendees': attendees,
    };
  }

  SessionModel copyWith({
    String? title,
    String? description,
    String? domainTag,
    List<String>? domainTags,
    String? targetRole,
    DateTime? dateTime,
    String? link,
    String? venue,
    bool? isOnline,
    String? createdBy,
    List<String>? rsvps,
    List<String>? attendees,
  }) {
    return SessionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      domainTag: domainTag ?? this.domainTag,
      domainTags: domainTags ?? this.domainTags,
      targetRole: targetRole ?? this.targetRole,
      dateTime: dateTime ?? this.dateTime,
      link: link ?? this.link,
      venue: venue ?? this.venue,
      isOnline: isOnline ?? this.isOnline,
      createdBy: createdBy ?? this.createdBy,
      rsvps: rsvps ?? this.rsvps,
      attendees: attendees ?? this.attendees,
    );
  }
}
