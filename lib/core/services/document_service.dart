import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../models/document_model.dart';
import '../../models/document_type_model.dart';
import '../../models/signature_model.dart';
import '../../models/comment_model.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class DocumentService {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final Uuid _uuid = Uuid();

  DocumentService({
    required FirestoreService firestoreService,
    required StorageService storageService,
  }) : _firestoreService = firestoreService,
        _storageService = storageService;

  Future<DocumentModel?> createDocument({
    required UserModel user,
    required String categoryId,
    required String documentTypeId,
    required List<File> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
  }) async {
    try {
      // Get document type
      final documentType = await _firestoreService.getDocumentType(documentTypeId);
      if (documentType == null) {
        return null;
      }

      // Create initial document
      final docId = _uuid.v4();
      final document = DocumentModel(
        id: docId,
        userId: user.id,
        companyId: user.companyId,
        categoryId: categoryId,
        documentTypeId: documentTypeId,
        status: DocumentStatus.PENDING,
        fileUrls: [],
        formData: formData ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiryDate: expiryDate,
        isNotApplicable: isNotApplicable,
        signatures: [],
        comments: [],
      );

      // Upload files if needed
      List<String> fileUrls = [];
      if (!isNotApplicable && documentType.isUploadable && files.isNotEmpty) {
        for (var file in files) {
          final fileName = file.path.split('/').last;
          final fileUrl = await _storageService.uploadFile(
            file,
            user.companyId,
            docId,
            fileName,
          );

          if (fileUrl != null) {
            fileUrls.add(fileUrl);
          }
        }
      }

      // Update document with file URLs
      final updatedDocument = document.copyWith(fileUrls: fileUrls);

      // Save document to Firestore
      final savedDocId = await _firestoreService.addDocument(updatedDocument);
      if (savedDocId != null) {
        return updatedDocument;
      }
      return null;
    } catch (e) {
      print('Error creating document: $e');
      return null;
    }
  }

  Future<bool> updateDocumentStatus(
      String documentId,
      DocumentStatus status,
      String? comment,
      UserModel user,
      ) async {
    try {
      final document = await _firestoreService.getDocument(documentId);
      if (document == null) {
        return false;
      }

      final updatedDocument = document.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      final result = await _firestoreService.updateDocument(updatedDocument);

      // Add comment if provided
      if (result && comment != null && comment.isNotEmpty) {
        final commentModel = CommentModel(
          id: _uuid.v4(),
          documentId: documentId,
          userId: user.id,
          userName: user.name,
          text: comment,
          createdAt: DateTime.now(),
        );

        await _firestoreService.addComment(commentModel);
      }

      return result;
    } catch (e) {
      print('Error updating document status: $e');
      return false;
    }
  }

  Future<bool> addSignature(
      String documentId,
      File signatureFile,
      UserModel user,
      ) async {
    try {
      // Upload signature image
      final signatureId = _uuid.v4();
      final imageUrl = await _storageService.uploadSignature(
        signatureFile,
        user.companyId,
        signatureId,
      );

      if (imageUrl == null) {
        return false;
      }

      // Create signature model
      final signature = SignatureModel(
        id: signatureId,
        documentId: documentId,
        userId: user.id,
        userName: user.name,
        imageUrl: imageUrl,
        signedAt: DateTime.now(),
      );

      // Save signature to Firestore
      final savedId = await _firestoreService.addSignature(signature);

      return savedId != null;
    } catch (e) {
      print('Error adding signature: $e');
      return false;
    }
  }

  Future<bool> addComment(
      String documentId,
      String commentText,
      UserModel user,
      ) async {
    try {
      final comment = CommentModel(
        id: _uuid.v4(),
        documentId: documentId,
        userId: user.id,
        userName: user.name,
        text: commentText,
        createdAt: DateTime.now(),
      );

      final savedId = await _firestoreService.addComment(comment);

      return savedId != null;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  Future<double> calculateCompliancePercentage(String companyId) async {
    try {
      final documents = await _firestoreService.getDocuments(companyId: companyId);

      if (documents.isEmpty) {
        return 0.0;
      }

      int completedCount = 0;
      for (var doc in documents) {
        if (doc.isComplete || doc.isNotApplicable) {
          completedCount++;
        }
      }

      return (completedCount / documents.length) * 100;
    } catch (e) {
      print('Error calculating compliance percentage: $e');
      return 0.0;
    }
  }
}