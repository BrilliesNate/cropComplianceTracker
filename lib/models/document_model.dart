import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';
import 'signature_model.dart';
import 'comment_model.dart';

class DocumentModel {
  final String id;
  final String userId;
  final String companyId;
  final String categoryId;
  final String documentTypeId;
  final DocumentStatus status;
  final List<String> fileUrls;
  final Map<String, dynamic> formData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiryDate;
  final bool isNotApplicable;
  final List<SignatureModel> signatures;
  final List<CommentModel> comments;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.categoryId,
    required this.documentTypeId,
    required this.status,
    required this.fileUrls,
    required this.formData,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    required this.isNotApplicable,
    required this.signatures,
    required this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyId': companyId,
      'categoryId': categoryId,
      'documentTypeId': documentTypeId,
      'status': status.toString().split('.').last,
      'fileUrls': fileUrls,
      'formData': formData,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'isNotApplicable': isNotApplicable,
    };
  }

  factory DocumentModel.fromMap(
      Map<String, dynamic> map,
      String id,
      List<SignatureModel> signatures,
      List<CommentModel> comments,
      ) {
    return DocumentModel(
      id: id,
      userId: map['userId'] ?? '',
      companyId: map['companyId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      documentTypeId: map['documentTypeId'] ?? '',
      status: DocumentStatusExtension.fromString(map['status'] ?? 'PENDING'),
      fileUrls: List<String>.from(map['fileUrls'] ?? []),
      formData: Map<String, dynamic>.from(map['formData'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      isNotApplicable: map['isNotApplicable'] ?? false,
      signatures: signatures,
      comments: comments,
    );
  }

  DocumentModel copyWith({
    String? id,
    String? userId,
    String? companyId,
    String? categoryId,
    String? documentTypeId,
    DocumentStatus? status,
    List<String>? fileUrls,
    Map<String, dynamic>? formData,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiryDate,
    bool? isNotApplicable,
    List<SignatureModel>? signatures,
    List<CommentModel>? comments,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId ?? this.companyId,
      categoryId: categoryId ?? this.categoryId,
      documentTypeId: documentTypeId ?? this.documentTypeId,
      status: status ?? this.status,
      fileUrls: fileUrls ?? this.fileUrls,
      formData: formData ?? this.formData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiryDate: expiryDate,
      isNotApplicable: isNotApplicable ?? this.isNotApplicable,
      signatures: signatures ?? this.signatures,
      comments: comments ?? this.comments,
    );
  }

  // Helper methods
  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isComplete => status == DocumentStatus.APPROVED;
  bool get isPending => status == DocumentStatus.PENDING;
  bool get isRejected => status == DocumentStatus.REJECTED;
}