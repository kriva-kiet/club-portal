import 'package:cloud_firestore/cloud_firestore.dart';

class ChatChannelModel {
  final String id;
  final String name; // e.g. "#dsa", "#web_dev", "John Doe"
  final String type; // "domain" | "direct"
  final String? domainId;

  ChatChannelModel({
    required this.id,
    required this.name,
    required this.type,
    this.domainId,
  });

  factory ChatChannelModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatChannelModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'direct',
      domainId: map['domainId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type, 'domainId': domainId};
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
