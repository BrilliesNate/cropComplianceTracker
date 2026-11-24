import 'document_model.dart';

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
  final bool hasFormTemplate;

  /// The uploader must describe what the document covers (site, period,
  /// worker group…) — the Specification box becomes required.
  final bool requiresSpecification;

  /// Policies without an expiry still need a "last reviewed" date; when true
  /// the uploader enters it and it's shown with the document.
  final bool hasReviewedDate;

  DocumentTypeModel({
    required this.id,
    required this.categoryId,
    this.hasFormTemplate = false,
    required this.name,
    required this.allowMultipleDocuments,
    required this.isUploadable,
    required this.hasExpiryDate,
    required this.hasNotApplicableOption,
    required this.requiresSignature,
    required this.signatureCount,
    this.requiresSpecification = false,
    this.hasReviewedDate = false,
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
      'hasFormTemplate': hasFormTemplate,
      'requiresSpecification': requiresSpecification,
      'hasReviewedDate': hasReviewedDate,
    };
  }

  factory DocumentTypeModel.fromMap(Map<String, dynamic> map, String id) {
    // A document of this type only expires if the type uses expiry dates.
    DocumentModel.noteTypeExpiry(id, map['hasExpiryDate'] == true);
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
      hasFormTemplate: map['hasFormTemplate'] ?? false,
      requiresSpecification: map['requiresSpecification'] ?? false,
      hasReviewedDate: map['hasReviewedDate'] ?? false,
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
    bool? hasFormTemplate,
    bool? requiresSpecification,
    bool? hasReviewedDate,
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
      hasFormTemplate: hasFormTemplate ?? this.hasFormTemplate,
      requiresSpecification:
          requiresSpecification ?? this.requiresSpecification,
      hasReviewedDate: hasReviewedDate ?? this.hasReviewedDate,
    );
  }
}