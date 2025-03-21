import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}