import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  /// The user's primary ("home") company. While a multi-farm user has switched
  /// farms, [AuthProvider] hands out a copy of the user with this field set to
  /// the farm currently in view — the stored record is never rewritten.
  final String companyId;

  /// Extra farms (companies) an admin has granted this user access to, on top of
  /// [companyId]. Empty for most users.
  final List<String> additionalCompanyIds;

  /// False once an admin has deactivated the account. A missing field means
  /// active, so every existing user keeps working without a data migration.
  final bool isActive;

  final DateTime createdAt;

  /// App language the user chose: 'en' or 'af'. Null = not chosen yet (the
  /// app then uses the device's last choice, or English).
  final String? language;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.companyId,
    required this.createdAt,
    this.additionalCompanyIds = const [],
    this.isActive = true,
    this.language,
  });

  /// Every company this user may work in: primary first, then the extras
  /// (de-duplicated, blanks removed).
  List<String> get accessibleCompanyIds {
    final ids = <String>[];
    for (final id in [companyId, ...additionalCompanyIds]) {
      if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
    }
    return ids;
  }

  bool get hasMultipleCompanies => accessibleCompanyIds.length > 1;

  bool canAccessCompany(String id) => accessibleCompanyIds.contains(id);

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'companyId': companyId,
      'additionalCompanyIds': additionalCompanyIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (language != null) 'language': language,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'USER'),
      companyId: map['companyId'] ?? '',
      additionalCompanyIds: List<String>.from(
          (map['additionalCompanyIds'] as List?) ?? const []),
      // Only an explicit `false` deactivates; missing/null means active.
      isActive: map['isActive'] != false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      language: map['language'] as String?,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? companyId,
    List<String>? additionalCompanyIds,
    bool? isActive,
    DateTime? createdAt,
    String? language,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      additionalCompanyIds: additionalCompanyIds ?? this.additionalCompanyIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
    );
  }
}
