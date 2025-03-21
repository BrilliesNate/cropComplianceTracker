
class DocumentTypeModel {
  final String id;
  final String categoryId;
  final String name;
  final bool allowMultipleDocuments;
  final bool isUploadable;
  final bool hasExpiryDate;
  final bool hasNotApplicableOption;
  final bool requiresSignature;
  final int signatureCount;

  DocumentTypeModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.allowMultipleDocuments,
    required this.isUploadable,
    required this.hasExpiryDate,
    required this.hasNotApplicableOption,
    required this.requiresSignature,
    required this.signatureCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'allowMultipleDocuments': allowMultipleDocuments,
      'isUploadable': isUploadable,
      'hasExpiryDate': hasExpiryDate,
      'hasNotApplicableOption': hasNotApplicableOption,
      'requiresSignature': requiresSignature,
      'signatureCount': signatureCount,
    };
  }

  factory DocumentTypeModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentTypeModel(
      id: id,
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      allowMultipleDocuments: map['allowMultipleDocuments'] ?? false,
      isUploadable: map['isUploadable'] ?? true,
      hasExpiryDate: map['hasExpiryDate'] ?? false,
      hasNotApplicableOption: map['hasNotApplicableOption'] ?? false,
      requiresSignature: map['requiresSignature'] ?? false,
      signatureCount: map['signatureCount'] ?? 0,
    );
  }

  DocumentTypeModel copyWith({
    String? id,
    String? categoryId,
    String? name,
    bool? allowMultipleDocuments,
    bool? isUploadable,
    bool? hasExpiryDate,
    bool? hasNotApplicableOption,
    bool? requiresSignature,
    int? signatureCount,
  }) {
    return DocumentTypeModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      allowMultipleDocuments: allowMultipleDocuments ?? this.allowMultipleDocuments,
      isUploadable: isUploadable ?? this.isUploadable,
      hasExpiryDate: hasExpiryDate ?? this.hasExpiryDate,
      hasNotApplicableOption: hasNotApplicableOption ?? this.hasNotApplicableOption,
      requiresSignature: requiresSignature ?? this.requiresSignature,
      signatureCount: signatureCount ?? this.signatureCount,
    );
  }
}