import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUpdateRequestModel {
  final String id;
  final String uid;
  final String clubId;
  final String currentName;
  final String currentBatch;
  final String currentBio;
  final String currentPhotoUrl;
  final String currentGithubId;
  final String currentLinkedinId;
  final String currentInstagramId;
  final String requestedName;
  final String requestedBatch;
  final String requestedBio;
  final String requestedPhotoUrl;
  final String requestedGithubId;
  final String requestedLinkedinId;
  final String requestedInstagramId;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  ProfileUpdateRequestModel({
    required this.id,
    required this.uid,
    required this.clubId,
    required this.currentName,
    this.currentBatch = '',
    this.currentBio = '',
    this.currentPhotoUrl = '',
    this.currentGithubId = '',
    this.currentLinkedinId = '',
    this.currentInstagramId = '',
    required this.requestedName,
    required this.requestedBatch,
    required this.requestedBio,
    required this.requestedPhotoUrl,
    this.requestedGithubId = '',
    this.requestedLinkedinId = '',
    this.requestedInstagramId = '',
    this.status = 'pending',
    required this.requestedAt,
  });

  factory ProfileUpdateRequestModel.fromMap(Map<String, dynamic> map, String id) {
    final requested = map['requestedAt'];
    return ProfileUpdateRequestModel(
      id: id,
      uid: map['uid'] ?? '',
      clubId: map['clubId'] ?? '',
      currentName: map['currentName'] ?? '',
      currentBatch: map['currentBatch'] ?? '',
      currentBio: map['currentBio'] ?? '',
      currentPhotoUrl: map['currentPhotoUrl'] ?? '',
      currentGithubId: map['currentGithubId'] ?? '',
      currentLinkedinId: map['currentLinkedinId'] ?? '',
      currentInstagramId: map['currentInstagramId'] ?? '',
      requestedName: map['requestedName'] ?? '',
      requestedBatch: map['requestedBatch'] ?? '',
      requestedBio: map['requestedBio'] ?? '',
      requestedPhotoUrl: map['requestedPhotoUrl'] ?? '',
      requestedGithubId: map['requestedGithubId'] ?? '',
      requestedLinkedinId: map['requestedLinkedinId'] ?? '',
      requestedInstagramId: map['requestedInstagramId'] ?? '',
      status: map['status'] ?? 'pending',
      requestedAt: requested is Timestamp
          ? requested.toDate()
          : (requested is String
              ? (DateTime.tryParse(requested) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'clubId': clubId,
      'currentName': currentName,
      'currentBatch': currentBatch,
      'currentBio': currentBio,
      'currentPhotoUrl': currentPhotoUrl,
      'currentGithubId': currentGithubId,
      'currentLinkedinId': currentLinkedinId,
      'currentInstagramId': currentInstagramId,
      'requestedName': requestedName,
      'requestedBatch': requestedBatch,
      'requestedBio': requestedBio,
      'requestedPhotoUrl': requestedPhotoUrl,
      'requestedGithubId': requestedGithubId,
      'requestedLinkedinId': requestedLinkedinId,
      'requestedInstagramId': requestedInstagramId,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }
}
