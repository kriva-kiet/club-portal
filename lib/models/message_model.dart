import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChannelModel {
  final String id;
  final String name; // e.g. "#dsa", "#web_dev", "John Doe"
  final String type; // "domain" | "direct"
  final String? domainId;
  final List<String> participants; // UID of participants
  final String? lastMessage;
  final DateTime? updatedAt;

  ChatChannelModel({
    required this.id,
    required this.name,
    required this.type,
    this.domainId,
    this.participants = const [],
    this.lastMessage,
    this.updatedAt,
  });

  factory ChatChannelModel.fromMap(Map<String, dynamic> map, String id) {
    final ua = map['updatedAt'];
    return ChatChannelModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'direct',
      domainId: map['domainId'],
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      updatedAt: ua is Timestamp
          ? ua.toDate()
          : (ua is String ? DateTime.tryParse(ua) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'domainId': domainId,
      'participants': participants,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class MessageModel {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderPhoto;
  final String text;
  final DateTime sentAt;

  MessageModel({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderPhoto,
    required this.text,
    required this.sentAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    final sa = map['sentAt'];
    return MessageModel(
      id: id,
      senderUid: map['senderUid'] ?? '',
      senderName: map['senderName'] ?? 'Anonymous',
      senderPhoto: map['senderPhoto'] ?? '',
      text: map['text'] ?? '',
      sentAt: sa is Timestamp
          ? sa.toDate()
          : (sa is String
                ? (DateTime.tryParse(sa) ?? DateTime.now())
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
