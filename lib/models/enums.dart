import 'package:cropCompliance/l10n/generated/app_localizations.dart';
enum UserRole {
  ADMIN,
  AUDITER,
  USER,
}

enum DocumentStatus {
  PENDING,
  APPROVED,
  REJECTED,
  // UPCOMING,
  // NEWREQUIRMENTS
}

extension UserRoleExtension on UserRole {
  /// The role in the app language.
  String label(AppLocalizations l10n) {
    switch (this) {
      case UserRole.ADMIN:
        return l10n.roleAdmin;
      case UserRole.AUDITER:
        return l10n.roleAuditor;
      case UserRole.USER:
        return l10n.roleUser;
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.toString().split('.').last == value,
      orElse: () => UserRole.USER,
    );
  }
}

extension DocumentStatusExtension on DocumentStatus {
  /// The status in the app language.
  String label(AppLocalizations l10n) {
    switch (this) {
      case DocumentStatus.PENDING:
        return l10n.statusPending;
      case DocumentStatus.APPROVED:
        return l10n.statusApproved;
      case DocumentStatus.REJECTED:
        return l10n.statusRejected;
    }
  }

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => DocumentStatus.PENDING,
    );
  }
}
