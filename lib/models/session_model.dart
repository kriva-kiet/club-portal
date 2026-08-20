import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String title;
  final String description;
  final String domainTag; // e.g. "web_dev", "ml", "dsa", "general"
  final DateTime dateTime;
  final String link; // meeting URL
  final String createdBy;
  final List<String> rsvps; // List of user UIDs who RSVP'd
  final List<String> attendees; // Checked-in members

  SessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.domainTag,
    required this.dateTime,
    required this.link,
    required this.createdBy,
    required this.rsvps,
    required this.attendees,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    final dt = map['dateTime'];
    return SessionModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domainTag: map['domainTag'] ?? 'general',
      dateTime: dt is Timestamp
          ? dt.toDate()
          : (dt is String
                ? (DateTime.tryParse(dt) ?? DateTime.now())
                : DateTime.now()),
      link: map['link'] ?? '',
      createdBy: map['createdBy'] ?? 'Admin',
      rsvps: List<String>.from(map['rsvps'] ?? []),
      attendees: List<String>.from(map['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'domainTag': domainTag,
      'dateTime': Timestamp.fromDate(dateTime),
      'link': link,
      'createdBy': createdBy,
      'rsvps': rsvps,
      'attendees': attendees,
    };
  }

  SessionModel copyWith({
    String? title,
    String? description,
    String? domainTag,
    DateTime? dateTime,
    String? link,
    String? createdBy,
    List<String>? rsvps,
    List<String>? attendees,
  }) {
    return SessionModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      domainTag: domainTag ?? this.domainTag,
      dateTime: dateTime ?? this.dateTime,
      link: link ?? this.link,
      createdBy: createdBy ?? this.createdBy,
      rsvps: rsvps ?? this.rsvps,
      attendees: attendees ?? this.attendees,
    );
  }
}
