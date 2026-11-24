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
  final String? specification; // NEW FIELD
  final String? rejectionReason; // latest rejection message (for notifications)
  final String? rejectedBy; // uid of who rejected (excluded from notifications)
  // True when a newer version has replaced this document. Superseded docs drop
  // out of action items / compliance counts but stay findable in the audit index.
  final bool isSuperseded;
  final String? supersededByDocumentId; // id of the replacement, if known
  // Display name of whoever uploaded this, captured at upload time so the
  // "Uploaded By" label never depends on a later user lookup ("Administrator"
  // for admin/auditor uploads).
  final String? uploadedByName;
  // When a policy was last reviewed (document types with hasReviewedDate).
  final DateTime? reviewedDate;
  // Files saved on the uploader's phone while offline that haven't reached
  // Storage yet (names). Empty once synced — see UploadOutbox.
  final List<String> pendingFiles;

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
    this.specification, // NEW FIELD
    this.rejectionReason,
    this.rejectedBy,
    this.isSuperseded = false,
    this.supersededByDocumentId,
    this.uploadedByName,
    this.reviewedDate,
    this.pendingFiles = const [],
  });

  /// True while files from the uploader's phone are still waiting to upload.
  bool get hasPendingFiles => pendingFiles.isNotEmpty;

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
      'specification': specification, // NEW FIELD
      'rejectionReason': rejectionReason,
      'rejectedBy': rejectedBy,
      'isSuperseded': isSuperseded,
      'supersededByDocumentId': supersededByDocumentId,
      'uploadedByName': uploadedByName,
      'reviewedDate':
          reviewedDate != null ? Timestamp.fromDate(reviewedDate!) : null,
      if (pendingFiles.isNotEmpty) 'pendingFiles': pendingFiles,
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
      specification: map['specification'], // NEW FIELD
      rejectionReason: map['rejectionReason'],
      rejectedBy: map['rejectedBy'],
      isSuperseded: map['isSuperseded'] ?? false,
      supersededByDocumentId: map['supersededByDocumentId'],
      uploadedByName: map['uploadedByName'],
      reviewedDate: (map['reviewedDate'] as Timestamp?)?.toDate(),
      pendingFiles: List<String>.from(map['pendingFiles'] ?? const []),
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
    String? specification, // NEW FIELD
    String? rejectionReason,
    String? rejectedBy,
    bool? isSuperseded,
    String? supersededByDocumentId,
    String? uploadedByName,
    DateTime? reviewedDate,
    List<String>? pendingFiles,
    // `expiryDate: null` means "keep the current one", so a separate flag is
    // needed to actually remove an expiry date.
    bool clearExpiryDate = false,
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
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      isNotApplicable: isNotApplicable ?? this.isNotApplicable,
      signatures: signatures ?? this.signatures,
      comments: comments ?? this.comments,
      specification: specification ?? this.specification, // NEW FIELD
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      isSuperseded: isSuperseded ?? this.isSuperseded,
      supersededByDocumentId:
          supersededByDocumentId ?? this.supersededByDocumentId,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      reviewedDate: reviewedDate ?? this.reviewedDate,
      pendingFiles: pendingFiles ?? this.pendingFiles,
    );
  }

  // ── Expiry ────────────────────────────────────────────────────────────────
  //
  // A document can only expire if its DOCUMENT TYPE uses expiry dates. Older
  // uploads were stamped "upload day + 1 year" even for types without expiry,
  // and a type can have expiry switched off after documents were uploaded —
  // either way a stray date must never make the document show as expired.
  // Every time a document type is read (DocumentTypeModel.fromMap) its
  // setting is noted here, so all screens apply the same rule.
  static final Map<String, bool> _typeUsesExpiry = {};

  /// Called whenever a document type is read.
  static void noteTypeExpiry(String typeId, bool usesExpiry) =>
      _typeUsesExpiry[typeId] = usesExpiry;

  /// The expiry date that counts for [typeId] — null when that type doesn't
  /// use expiry dates. (Unknown type: the date is kept.)
  static DateTime? effectiveExpiryFor(String? typeId, DateTime? expiry) =>
      typeId != null && _typeUsesExpiry[typeId] == false ? null : expiry;

  /// This document's expiry date, if its type uses expiry dates. Use this
  /// for status and display; [expiryDate] is the raw stored value (needed
  /// only when editing, so a stray date can be seen and cleared).
  DateTime? get effectiveExpiryDate =>
      effectiveExpiryFor(documentTypeId, expiryDate);

  /// Has a stored expiry date its type doesn't use (stray data).
  bool get hasStrayExpiryDate =>
      expiryDate != null && effectiveExpiryDate == null;

  // Helper methods
  bool get isExpired =>
      effectiveExpiryDate != null &&
      effectiveExpiryDate!.isBefore(DateTime.now());
  bool get isComplete => status == DocumentStatus.APPROVED;
  bool get isPending => status == DocumentStatus.PENDING;
  bool get isRejected => status == DocumentStatus.REJECTED;
}