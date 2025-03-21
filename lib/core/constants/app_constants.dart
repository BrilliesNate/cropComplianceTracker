class AppConstants {
  static const String appName = 'Agricultural Compliance';
  static const String appVersion = '1.0.0';

  // Firebase collection names
  static const String usersCollection = 'users';
  static const String companiesCollection = 'companies';
  static const String categoriesCollection = 'categories';
  static const String documentTypesCollection = 'documentTypes';
  static const String documentsCollection = 'documents';
  static const String signaturesCollection = 'signatures';
  static const String commentsCollection = 'comments';

  // Storage paths
  static const String documentsStoragePath = 'companies/{companyId}/documents/{documentId}';
  static const String signaturesStoragePath = 'companies/{companyId}/signatures/{signatureId}';
}