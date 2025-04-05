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
  String get name {
    switch (this) {
      case UserRole.ADMIN:
        return 'Admin';
      case UserRole.AUDITER:
        return 'Auditer';
      case UserRole.USER:
        return 'User';
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
  String get name {
    switch (this) {
      case DocumentStatus.PENDING:
        return 'Pending';
      case DocumentStatus.APPROVED:
        return 'Approved';
      case DocumentStatus.REJECTED:
        return 'Rejected';
      // case DocumentStatus.UPCOMING:
      //   return 'Upcoming'; // need to create enum to say upcoming dates. dates hase to be generic change
    // case DocumentStatus.NEWREQUIRMENTS:
      //   return 'New Requirments';
    }
  }

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.toString().split('.').last == value,
      orElse: () => DocumentStatus.PENDING,
    );
  }
}
