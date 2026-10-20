import 'package:cloud_firestore/cloud_firestore.dart';

class AccessRequestModel {
  final String id;
  final String name;
  final String fatherName;
  final String phoneNumber;
  final String personalEmail;
  final String kietEmail;
  final String aadharNumber;
  final String githubId;
  final String linkedinId;
  final String instagramId;
  final String requestedRole; // 'member', 'lead'
  final String batch; // e.g. 'Batch of 2028'
  final List<String> domainInterest; // ['dsa', 'web_dev', 'ml']
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;

  AccessRequestModel({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.phoneNumber,
    required this.personalEmail,
    required this.kietEmail,
    required this.aadharNumber,
    this.githubId = '',
    this.linkedinId = '',
    this.instagramId = '',
    required this.requestedRole,
    this.batch = 'Batch of 2028',
    required this.domainInterest,
    required this.status,
    required this.requestedAt,
  });

  factory AccessRequestModel.fromMap(Map<String, dynamic> map, String id) {
    final requested = map['requestedAt'];
    final domains = map['domainInterest'];
    return AccessRequestModel(
      id: id,
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      personalEmail: map['personalEmail'] ?? '',
      kietEmail: map['kietEmail'] ?? '',
      aadharNumber: map['aadharNumber'] ?? '',
      githubId: map['githubId'] ?? '',
      linkedinId: map['linkedinId'] ?? '',
      instagramId: map['instagramId'] ?? '',
      requestedRole: map['requestedRole'] ?? 'member',
      batch: map['batch'] ?? 'Batch of 2028',
      domainInterest: domains is List ? List<String>.from(domains) : [],
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
      'name': name,
      'fatherName': fatherName,
      'phoneNumber': phoneNumber,
      'personalEmail': personalEmail,
      'kietEmail': kietEmail,
      'aadharNumber': aadharNumber,
      'githubId': githubId,
      'linkedinId': linkedinId,
      'instagramId': instagramId,
      'requestedRole': requestedRole,
      'batch': batch,
      'domainInterest': domainInterest,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
    };
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'name': name,
      'fatherName': fatherName,
      'phoneNumber': phoneNumber,
      'personalEmail': personalEmail,
      'kietEmail': kietEmail,
      'aadharNumber': aadharNumber,
      'githubId': githubId,
      'linkedinId': linkedinId,
      'instagramId': instagramId,
      'requestedRole': requestedRole,
      'batch': batch,
      'domainInterest': domainInterest,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }
}
