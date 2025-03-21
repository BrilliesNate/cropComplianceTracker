import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String companyId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.companyId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'USER'),
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? companyId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}