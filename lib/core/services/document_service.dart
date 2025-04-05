import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  // In document_service.dart, update the createDocument method to handle web file uploads

  // Add these changes to your DocumentService.createDocument method:

  Future<DocumentModel?> createDocument({
    required UserModel user,
    required String categoryId,
    required String documentTypeId,
    required List<dynamic> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
  }) async {
    try {
      // Debug - Initial info
      print("DEBUG: createDocument called");
      print("DEBUG: categoryId: $categoryId");
      print("DEBUG: documentTypeId: $documentTypeId");
      print("DEBUG: files count: ${files.length}");
      print("DEBUG: isNotApplicable: $isNotApplicable");
      print("DEBUG: EXPIRY DATE RECEIVED: $expiryDate"); // Add this line

      // Platform check
      if (kIsWeb) {
        print("DEBUG: Running on web platform");
      } else {
        print("DEBUG: Running on non-web platform");
      }

      // Get document type
      final documentType = await _firestoreService.getDocumentType(documentTypeId);
      if (documentType == null) {
        print("DEBUG: Document type not found: $documentTypeId");
        return null;
      }

      print("DEBUG: Document type found: ${documentType.name}");
      print("DEBUG: isUploadable: ${documentType.isUploadable}");

      // Create initial document
      final docId = _uuid.v4();
      print("DEBUG: Generated document ID: $docId");

      // IMPORTANT: Make sure expiryDate is properly set
      if (expiryDate != null) {
        print("DEBUG: Using expiryDate: $expiryDate");
        print("DEBUG: Timestamp: ${expiryDate.millisecondsSinceEpoch}");
      } else {
        print("DEBUG: No expiryDate provided");
      }

      // Create the document object with explicit expiryDate
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
        expiryDate: expiryDate, // Ensure this is set correctly
        isNotApplicable: isNotApplicable,
        signatures: [],
        comments: [],
      );

      // Upload files if needed
      List<String> fileUrls = [];
      if (!isNotApplicable && documentType.isUploadable && files.isNotEmpty) {
        // File upload logic...
        // (Rest of your existing upload code)
      }

      // Update document with file URLs - CAREFUL HERE
      final updatedDocument = document.copyWith(fileUrls: fileUrls);
      print("DEBUG: Updated document with file URLs: ${fileUrls.length}");
      print("DEBUG: Document's fileUrls: ${updatedDocument.fileUrls}");

      // VERIFY expiryDate is still present after copyWith
      print("DEBUG: expiryDate after copyWith: ${updatedDocument.expiryDate}");

      // IMPORTANT: Manually prepare Firestore document map to ensure expiryDate is included
      Map<String, dynamic> firestoreData = {
        'userId': updatedDocument.userId,
        'companyId': updatedDocument.companyId,
        'categoryId': updatedDocument.categoryId,
        'documentTypeId': updatedDocument.documentTypeId,
        'status': updatedDocument.status.toString().split('.').last,
        'fileUrls': updatedDocument.fileUrls,
        'formData': updatedDocument.formData ?? {},
        'createdAt': Timestamp.fromDate(updatedDocument.createdAt),
        'updatedAt': Timestamp.fromDate(updatedDocument.updatedAt),
        'isNotApplicable': updatedDocument.isNotApplicable,
        // Explicitly add expiryDate field
        'expiryDate': updatedDocument.expiryDate != null
            ? Timestamp.fromDate(updatedDocument.expiryDate!)
            : null,
      };

      print("DEBUG: Final Firestore data: $firestoreData");

      // Save document to Firestore
      print("DEBUG: Saving document to Firestore...");
      final savedDocId = await _firestoreService.addDocument(updatedDocument, firestoreData);
      print("DEBUG: Document saved to Firestore. ID: $savedDocId");

      if (savedDocId != null) {
        print("DEBUG: Document creation successful");
        return updatedDocument;
      } else {
        print("DEBUG: Document creation failed - savedDocId is null");
        return null;
      }
    } catch (e) {
      print('ERROR creating document: $e');
      print('ERROR trace: ${e.toString()}');
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
      print("DEBUG: updateDocumentStatus called for document: $documentId");
      print("DEBUG: New status: ${status.toString()}");

      final document = await _firestoreService.getDocument(documentId);
      if (document == null) {
        print("DEBUG: Document not found: $documentId");
        return false;
      }

      print("DEBUG: Current document status: ${document.status}");
      print("DEBUG: Current fileUrls: ${document.fileUrls}");

      final updatedDocument = document.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      print("DEBUG: Updated document with new status");

      final result = await _firestoreService.updateDocument(updatedDocument);
      print("DEBUG: Document update result: $result");

      // Add comment if provided
      if (result && comment != null && comment.isNotEmpty) {
        print("DEBUG: Adding comment: $comment");
        final commentModel = CommentModel(
          id: _uuid.v4(),
          documentId: documentId,
          userId: user.id,
          userName: user.name,
          text: comment,
          createdAt: DateTime.now(),
        );

        await _firestoreService.addComment(commentModel);
        print("DEBUG: Comment added successfully");
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
      print("DEBUG: addSignature called for document: $documentId");

      // Upload signature image
      final signatureId = _uuid.v4();
      print("DEBUG: Generated signature ID: $signatureId");

      final imageUrl = await _storageService.uploadSignature(
        signatureFile,
        user.companyId,
        signatureId,
      );

      if (imageUrl == null) {
        print("DEBUG: Signature upload failed");
        return false;
      }

      print("DEBUG: Signature uploaded successfully. URL: $imageUrl");

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
      print("DEBUG: Saving signature to Firestore...");
      final savedId = await _firestoreService.addSignature(signature);
      print("DEBUG: Signature saved with ID: $savedId");

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
      print("DEBUG: addComment called for document: $documentId");
      print("DEBUG: Comment text: $commentText");

      final comment = CommentModel(
        id: _uuid.v4(),
        documentId: documentId,
        userId: user.id,
        userName: user.name,
        text: commentText,
        createdAt: DateTime.now(),
      );

      print("DEBUG: Saving comment to Firestore...");
      final savedId = await _firestoreService.addComment(comment);
      print("DEBUG: Comment saved with ID: $savedId");

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