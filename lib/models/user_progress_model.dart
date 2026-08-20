import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgressModel {
  final String uid;
  final String domainId;
  final Map<String, DateTime>
  topicsCompleted; // Key: topicId, Value: completedAt
  final double percentComplete;

  UserProgressModel({
    required this.uid,
    required this.domainId,
    required this.topicsCompleted,
    required this.percentComplete,
  });

  factory UserProgressModel.fromMap(Map<String, dynamic> map, String docId) {
    // docId format: {uid}_{domainId}
    final split = docId.split('_');
    final uid = split.isNotEmpty ? split[0] : '';
    final domainId = split.length > 1 ? split[1] : '';

    final rawTopics = map['topicsCompleted'] as Map? ?? {};
    final topicsCompleted = <String, DateTime>{};

    rawTopics.forEach((key, val) {
      if (val is Map && val['completedAt'] != null) {
        final completedAt = val['completedAt'];
        if (completedAt is Timestamp) {
          topicsCompleted[key.toString()] = completedAt.toDate();
        } else if (completedAt is String) {
          topicsCompleted[key.toString()] =
              DateTime.tryParse(completedAt) ?? DateTime.now();
        }
      }
    });

    return UserProgressModel(
      uid: uid,
      domainId: domainId,
      topicsCompleted: topicsCompleted,
      percentComplete: (map['percentComplete'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    final rawTopics = <String, Map<String, dynamic>>{};
    topicsCompleted.forEach((key, val) {
      rawTopics[key] = {
        'status': 'completed',
        'completedAt': Timestamp.fromDate(val),
      };
    });

    return {
      'uid': uid,
      'domainId': domainId,
      'topicsCompleted': rawTopics,
      'percentComplete': percentComplete,
    };
  }

  UserProgressModel copyWith({
    Map<String, DateTime>? topicsCompleted,
    double? percentComplete,
  }) {
    return UserProgressModel(
      uid: uid,
      domainId: domainId,
      topicsCompleted: topicsCompleted ?? this.topicsCompleted,
      percentComplete: percentComplete ?? this.percentComplete,
    );
  }
}
