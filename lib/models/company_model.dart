import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;
  final List<String> packages;
  /// Farmable farm ID linked to this company. Null if not connected.
  final int? farmableLocationId;

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
    required this.packages,
    this.farmableLocationId,
  });

  bool get hasFarmable => farmableLocationId != null;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'packages': packages,
      if (farmableLocationId != null) 'farmableLocationId': farmableLocationId,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      packages: List<String>.from(map['packages'] ?? ['siza_wieta']),
      farmableLocationId: map['farmableLocationId'] as int?,
    );
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
    List<String>? packages,
    int? farmableLocationId,
    bool clearFarmable = false,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      packages: packages ?? this.packages,
      farmableLocationId: clearFarmable ? null : (farmableLocationId ?? this.farmableLocationId),
    );
  }

  // Helper methods for package checking
  bool hasPackage(String packageId) {
    return packages.contains(packageId);
  }

  bool get hasSizaWieta => packages.contains('siza_wieta');
  bool get hasGlobalGap => packages.contains('globalgap');
  bool get hasIpw => packages.contains('ipw');
  bool get hasFairtrade => packages.contains('fairtrade');
  bool get hasSizaEnvironmental => packages.contains('siza_environmental');
  bool get hasBothPackages => hasSizaWieta && hasGlobalGap;
}