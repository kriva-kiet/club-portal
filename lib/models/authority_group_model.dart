import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorityGroupModel {
  final String id;
  final String name; // e.g. 'Executive Council', 'Women Cell', 'Technical Wing'
  final String description; // e.g. 'Oversees community administration and strategic directions'
  final int order; // Ordering in tabs / section
  final String? iconName; // e.g. 'security', 'female', 'code'
  final String? colorHex; // e.g. '#EC4899'
  final DateTime createdAt;

  AuthorityGroupModel({
    required this.id,
    required this.name,
    required this.description,
    this.order = 0,
    this.iconName,
    this.colorHex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuthorityGroupModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AuthorityGroupModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] is int ? map['order'] : int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      iconName: map['iconName'],
      colorHex: map['colorHex'],
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'order': order,
      'iconName': iconName,
      'colorHex': colorHex,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AuthorityGroupModel copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    String? iconName,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return AuthorityGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
