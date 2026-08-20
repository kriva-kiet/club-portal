import 'package:cloud_firestore/cloud_firestore.dart';

class BroadcastModel {
  final String id;
  final String title;
  final String body;
  final String audienceType; // 'all' | 'domain' | 'batch'
  final String audienceValue;
  final String sentBy;
  final DateTime sentAt;
  final List<String> readBy;

  BroadcastModel({
    required this.id,
    required this.title,
    required this.body,
    required this.audienceType,
    required this.audienceValue,
    required this.sentBy,
    required this.sentAt,
    required this.readBy,
  });

  factory BroadcastModel.fromMap(Map<String, dynamic> map, String id) {
    final sent = map['sentAt'];
    final audience = map['audience'] is Map
        ? Map<String, dynamic>.from(map['audience'])
        : {};

    return BroadcastModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      audienceType: audience['type'] ?? 'all',
      audienceValue: audience['value'] ?? '',
      sentBy: map['sentBy'] ?? '',
      sentAt: sent is Timestamp
          ? sent.toDate()
          : (sent is String
                ? (DateTime.tryParse(sent) ?? DateTime.now())
                : DateTime.now()),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'audience': {'type': audienceType, 'value': audienceValue},
      'sentBy': sentBy,
      'sentAt': Timestamp.fromDate(sentAt),
      'readBy': readBy,
    };
  }

  BroadcastModel copyWith({
    String? title,
    String? body,
    String? audienceType,
    String? audienceValue,
    String? sentBy,
    DateTime? sentAt,
    List<String>? readBy,
  }) {
    return BroadcastModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      audienceType: audienceType ?? this.audienceType,
      audienceValue: audienceValue ?? this.audienceValue,
      sentBy: sentBy ?? this.sentBy,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
    );
  }
}
