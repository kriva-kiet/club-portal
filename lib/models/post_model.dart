import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorPhoto;
  final String text;
  final String? imageUrl;
  final String tag; // "general" | "dsa" | "web_dev" | "hackathon"
  final List<String> likes; // UIDs of users who liked
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    this.imageUrl,
    required this.tag,
    required this.likes,
    required this.commentCount,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String id) {
    final ca = map['createdAt'];
    return PostModel(
      id: id,
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous',
      authorPhoto: map['authorPhoto'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      tag: map['tag'] ?? 'general',
      likes: List<String>.from(map['likes'] ?? []),
      commentCount: map['commentCount'] ?? 0,
      createdAt: ca is Timestamp
          ? ca.toDate()
          : (ca is String
                ? (DateTime.tryParse(ca) ?? DateTime.now())
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'imageUrl': imageUrl,
      'tag': tag,
      'likes': likes,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PostModel copyWith({
    String? authorName,
    String? authorPhoto,
    String? text,
    String? imageUrl,
    String? tag,
    List<String>? likes,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id,
      authorUid: authorUid,
      authorName: authorName ?? this.authorName,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CommentModel {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorPhoto;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhoto,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    final ca = map['createdAt'];
    return CommentModel(
      id: id,
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'] ?? 'Anonymous',
      authorPhoto: map['authorPhoto'] ?? '',
      text: map['text'] ?? '',
      createdAt: ca is Timestamp
          ? ca.toDate()
          : (ca is String
                ? (DateTime.tryParse(ca) ?? DateTime.now())
                : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
