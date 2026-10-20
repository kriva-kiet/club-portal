import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }
}

class StandaloneQuizModel {
  final String id;
  final String domainId;
  final String title;
  final String type; // 'simple' or 'timed'
  final int? timeLimitMinutes; // Total quiz time
  final int? questionTimeLimitSeconds; // Time limit per question
  final List<QuizQuestionModel> questions;
  final String createdBy;
  final DateTime createdAt;

  StandaloneQuizModel({
    required this.id,
    required this.domainId,
    required this.title,
    required this.type,
    this.timeLimitMinutes,
    this.questionTimeLimitSeconds,
    required this.questions,
    required this.createdBy,
    required this.createdAt,
  });

  factory StandaloneQuizModel.fromMap(Map<String, dynamic> map, String id) {
    final ca = map['createdAt'];
    return StandaloneQuizModel(
      id: id,
      domainId: map['domainId'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? 'simple',
      timeLimitMinutes: map['timeLimitMinutes'],
      questionTimeLimitSeconds: map['questionTimeLimitSeconds'],
      questions: (map['questions'] as List?)
              ?.map((q) => QuizQuestionModel.fromMap(Map<String, dynamic>.from(q)))
              .toList() ??
          [],
      createdBy: map['createdBy'] ?? '',
      createdAt: ca is Timestamp
          ? ca.toDate()
          : (ca is String
              ? (DateTime.tryParse(ca) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'domainId': domainId,
      'title': title,
      'type': type,
      'timeLimitMinutes': timeLimitMinutes,
      'questionTimeLimitSeconds': questionTimeLimitSeconds,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

