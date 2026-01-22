import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;
  final List<String> packages;

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.packages,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'packages': packages,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      packages: List<String>.from(map['packages'] ?? ['siza_wieta']),
    );
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    List<String>? packages,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      packages: packages ?? this.packages,
    );
  }

  // Helper methods for package checking
  bool hasPackage(String packageId) {
    return packages.contains(packageId);
  }

  bool get hasSizaWieta => packages.contains('siza_wieta');
  bool get hasGlobalGap => packages.contains('globalgap');
  bool get hasBothPackages => hasSizaWieta && hasGlobalGap;
}