import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final int order;
  final String packageId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.packageId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'order': order,
      'packageId': packageId,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
      packageId: map['packageId'] ?? 'siza_wieta',
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    String? packageId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      packageId: packageId ?? this.packageId,
    );
  }
}