class AppConstants {
  static const String appName = 'Agricultural Compliance'; // l10n-ignore: unused id
  static const String appVersion = '1.0.0';

  // ── Farmable Partner API ───────────────────────────────────────────────────
  static const String farmableApiKey = 'ed1aca4e1b2846148dda29617b570884';
  static const String farmableBaseUrl = 'https://api.farmable.tech';

  // Firebase collection names
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String categoriesCollection = 'categories';
  static const String documentTypesCollection = 'documentTypes';
  static const String documentsCollection = 'documents';
  static const String signaturesCollection = 'signatures';
  static const String commentsCollection = 'comments';
  static const String formTemplatesCollection = 'formConfig';

  // Storage paths
  static const String documentsStoragePath =
      'companies/{companyId}/documents/{documentId}';
  static const String signaturesStoragePath =
      'companies/{companyId}/signatures/{signatureId}';

  // ── Audit packages ─────────────────────────────────────────────────────────
  // Single source of truth for every audit package the system supports.
  // Add a new package here and it flows to the company switches, the
  // audit-tracker / audit-index toggles, and the dashboard badges.
  static const List<AuditPackage> auditPackages = [
    AuditPackage(id: 'siza_wieta', label: 'SIZA/WIETA', shortLabel: 'SIZA'),
    AuditPackage(id: 'globalgap', label: 'GlobalG.A.P.', shortLabel: 'GGAP'),
    AuditPackage(id: 'ipw', label: 'IPW', shortLabel: 'IPW'),
    AuditPackage(id: 'fairtrade', label: 'Fairtrade', shortLabel: 'FT'), // l10n-ignore: brand name
    AuditPackage(
        id: 'siza_environmental',
        label: 'SIZA Environmental', // l10n-ignore: brand name
        shortLabel: 'SIZA-E'),
  ];

  static const String defaultPackageId = 'siza_wieta';
}

/// A selectable audit package (e.g. SIZA/WIETA, GlobalG.A.P., IPW).
class AuditPackage {
  final String id;
  final String label;
  final String shortLabel;
  const AuditPackage({
    required this.id,
    required this.label,
    required this.shortLabel,
  });
}
