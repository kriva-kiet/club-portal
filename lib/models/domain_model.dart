import 'standalone_quiz_model.dart';

class ResourceModel {
  final String title;
  final String url;
  final String type; // 'video' | 'link' | 'doc' | 'practice'

  ResourceModel({required this.title, required this.url, required this.type});

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? 'link',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'url': url, 'type': type};
  }
}

class TopicModel {
  final String id;
  final String moduleId;
  final String title;
  final int order;
  final List<ResourceModel> resources;
  final List<QuizQuestionModel> quizQuestions;

  TopicModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.order,
    required this.resources,
    this.quizQuestions = const [],
  });

  factory TopicModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String moduleId,
  ) {
    final resourcesList = map['resources'] as List? ?? [];
    final quizList = map['quizQuestions'] as List? ?? [];
    return TopicModel(
      id: id,
      moduleId: moduleId,
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      resources: resourcesList
          .map((r) => ResourceModel.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
      quizQuestions: quizList
          .map((q) => QuizQuestionModel.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'resources': resources.map((r) => r.toMap()).toList(),
      'quizQuestions': quizQuestions.map((q) => q.toMap()).toList(),
    };
  }

  TopicModel copyWith({
    String? title,
    int? order,
    List<ResourceModel>? resources,
    List<QuizQuestionModel>? quizQuestions,
  }) {
    return TopicModel(
      id: id,
      moduleId: moduleId,
      title: title ?? this.title,
      order: order ?? this.order,
      resources: resources ?? this.resources,
      quizQuestions: quizQuestions ?? this.quizQuestions,
    );
  }
}

class ModuleModel {
  final String id;
  final String domainId;
  final String title;
  final int order;
  final List<TopicModel> topics;
  final List<ResourceModel> resources;

  ModuleModel({
    required this.id,
    required this.domainId,
    required this.title,
    required this.order,
    required this.topics,
    this.resources = const [],
  });

  factory ModuleModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String domainId, {
    List<TopicModel>? topics,
  }) {
    final resourcesList = map['resources'] as List? ?? [];
    return ModuleModel(
      id: id,
      domainId: domainId,
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      topics: topics ?? [],
      resources: resourcesList
          .map((r) => ResourceModel.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'resources': resources.map((resource) => resource.toMap()).toList(),
    };
  }

  ModuleModel copyWith({
    String? title,
    int? order,
    List<TopicModel>? topics,
    List<ResourceModel>? resources,
  }) {
    return ModuleModel(
      id: id,
      domainId: domainId,
      title: title ?? this.title,
      order: order ?? this.order,
      topics: topics ?? this.topics,
      resources: resources ?? this.resources,
    );
  }
}

class DomainModel {
  final String id;
  final String name;
  final String description;
  final List<String> leadUserIds;
  final String password;
  final List<ModuleModel> modules;

  DomainModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leadUserIds,
    required this.password,
    required this.modules,
  });

  factory DomainModel.fromMap(
    Map<String, dynamic> map,
    String id, {
    List<ModuleModel>? modules,
  }) {
    return DomainModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leadUserIds: map['leadUserIds'] != null 
          ? List<String>.from(map['leadUserIds']) 
          : (map['leadUserId'] != null && map['leadUserId'].toString().isNotEmpty 
              ? [map['leadUserId'].toString()] 
              : []),
      password: map['password'] ?? '',
      modules: modules ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'leadUserIds': leadUserIds,
      'password': password,
    };
  }

  DomainModel copyWith({
    String? name,
    String? description,
    List<String>? leadUserIds,
    String? password,
    List<ModuleModel>? modules,
  }) {
    return DomainModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      leadUserIds: leadUserIds ?? this.leadUserIds,
      password: password ?? this.password,
      modules: modules ?? this.modules,
    );
  }
}
