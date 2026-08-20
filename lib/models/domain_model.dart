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

  TopicModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.order,
    required this.resources,
  });

  factory TopicModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String moduleId,
  ) {
    final resourcesList = map['resources'] as List? ?? [];
    return TopicModel(
      id: id,
      moduleId: moduleId,
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      resources: resourcesList
          .map((r) => ResourceModel.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'resources': resources.map((r) => r.toMap()).toList(),
    };
  }

  TopicModel copyWith({
    String? title,
    int? order,
    List<ResourceModel>? resources,
  }) {
    return TopicModel(
      id: id,
      moduleId: moduleId,
      title: title ?? this.title,
      order: order ?? this.order,
      resources: resources ?? this.resources,
    );
  }
}

class ModuleModel {
  final String id;
  final String domainId;
  final String title;
  final int order;
  final List<TopicModel> topics;

  ModuleModel({
    required this.id,
    required this.domainId,
    required this.title,
    required this.order,
    required this.topics,
  });

  factory ModuleModel.fromMap(
    Map<String, dynamic> map,
    String id,
    String domainId, {
    List<TopicModel>? topics,
  }) {
    return ModuleModel(
      id: id,
      domainId: domainId,
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      topics: topics ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'order': order};
  }

  ModuleModel copyWith({String? title, int? order, List<TopicModel>? topics}) {
    return ModuleModel(
      id: id,
      domainId: domainId,
      title: title ?? this.title,
      order: order ?? this.order,
      topics: topics ?? this.topics,
    );
  }
}

class DomainModel {
  final String id;
  final String name;
  final String description;
  final String leadUserId;
  final String password;
  final List<ModuleModel> modules;

  DomainModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leadUserId,
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
      leadUserId: map['leadUserId'] ?? '',
      password: map['password'] ?? '',
      modules: modules ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'leadUserId': leadUserId,
      'password': password,
    };
  }

  DomainModel copyWith({
    String? name,
    String? description,
    String? leadUserId,
    String? password,
    List<ModuleModel>? modules,
  }) {
    return DomainModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      leadUserId: leadUserId ?? this.leadUserId,
      password: password ?? this.password,
      modules: modules ?? this.modules,
    );
  }
}
