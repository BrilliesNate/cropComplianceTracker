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
  })  : _firestoreService = firestoreService,
        _storageService = storageService;

  // Enhanced createDocument method with admin context support
  Future<DocumentModel?> createDocument({
    required UserModel user, // This is the target user (could be selected by admin)
    required String categoryId,
    required String documentTypeId,
    required List<dynamic> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
    UserModel? actingUser, // This is the admin who is performing the action (optional)
    String? specification, // NEW FIELD
  }) async {
    try {
      // Debug - Initial info with context
      print("DEBUG: createDocument called");
      print("DEBUG: Target user: ${user.name} (${user.email})");
      if (actingUser != null && actingUser.id != user.id) {
        print("DEBUG: Acting user (Admin): ${actingUser.name} (${actingUser.email})");
        print("DEBUG: Admin is creating document for another user");
      }
      print("DEBUG: categoryId: $categoryId");
      print("DEBUG: documentTypeId: $documentTypeId");
      print("DEBUG: files count: ${files.length}");
      print("DEBUG: isNotApplicable: $isNotApplicable");
      print("DEBUG: EXPIRY DATE RECEIVED: $expiryDate");
      print("DEBUG: SPECIFICATION RECEIVED: $specification"); // NEW DEBUG LINE

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

      // Create the document object with explicit expiryDate and specification
      // Document is created for the target user, not the acting user
      final document = DocumentModel(
        id: docId,
        userId: user.id, // Target user ID
        companyId: user.companyId, // Target user's company
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
        specification: specification, // NEW FIELD
      );

      // Upload files if needed
      List<String> fileUrls = [];
      if (!isNotApplicable && documentType.isUploadable && files.isNotEmpty) {
        print("DEBUG: Beginning file upload process for ${files.length} files");

        try {
          // Process each file
          for (int i = 0; i < files.length; i++) {
            final file = files[i];

            if (kIsWeb) {
              // For web platform
              if (file is Map<String, dynamic> && file.containsKey('bytes')) {
                final fileName = file['name'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';
                print("DEBUG: Uploading web file ${i + 1}/${files.length}: $fileName");

                final fileUrl = await _storageService.uploadFile(
                  file,
                  user.companyId, // Use target user's company for storage
                  docId,
                  fileName,
                );

                if (fileUrl != null) {
                  print("DEBUG: File uploaded successfully. URL: $fileUrl");
                  fileUrls.add(fileUrl);
                } else {
                  print("DEBUG: File upload failed for file $fileName");
                }
              } else {
                print("DEBUG: Invalid file format for web upload: ${file.runtimeType}");
              }
            } else {
              // For mobile/desktop platforms
              if (file is File) {
                final fileName = file.path.split('/').last;
                print("DEBUG: Uploading file ${i + 1}/${files.length}: $fileName");

                final fileUrl = await _storageService.uploadFile(
                  file,
                  user.companyId, // Use target user's company for storage
                  docId,
                  fileName,
                );

                if (fileUrl != null) {
                  print("DEBUG: File uploaded successfully. URL: $fileUrl");
                  fileUrls.add(fileUrl);
                } else {
                  print("DEBUG: File upload failed for file $fileName");
                }
              } else {
                print("DEBUG: Invalid file format for mobile/desktop upload: ${file.runtimeType}");
              }
            }
          }

          print("DEBUG: File upload process completed. Added ${fileUrls.length} URLs");
        } catch (e) {
          print("DEBUG: Error during file upload process: $e");
          print("DEBUG: Stack trace: ${StackTrace.current}");
        }
      }

      // Update document with file URLs
      final updatedDocument = document.copyWith(fileUrls: fileUrls);
      print("DEBUG: Updated document with file URLs: ${fileUrls.length}");
      print("DEBUG: Document's fileUrls: ${updatedDocument.fileUrls}");

      // VERIFY expiryDate and specification are still present after copyWith
      print("DEBUG: expiryDate after copyWith: ${updatedDocument.expiryDate}");
      print("DEBUG: specification after copyWith: ${updatedDocument.specification}"); // NEW DEBUG LINE

      // IMPORTANT: Manually prepare Firestore document map to ensure all fields are included
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
        'expiryDate': updatedDocument.expiryDate != null
            ? Timestamp.fromDate(updatedDocument.expiryDate!)
            : null,
        'specification': updatedDocument.specification, // NEW FIELD
      };

      print("DEBUG: Final Firestore data: $firestoreData");

      // Save document to Firestore
      print("DEBUG: Saving document to Firestore...");
      final savedDocId = await _firestoreService.addDocument(updatedDocument, firestoreData);
      print("DEBUG: Document saved to Firestore. ID: $savedDocId");

      if (savedDocId != null) {
        // Add a comment if admin created document for another user
        if (actingUser != null && actingUser.id != user.id) {
          final adminCommentModel = CommentModel(
            id: _uuid.v4(),
            documentId: docId,
            userId: actingUser.id,
            userName: actingUser.name,
            text: "Document created by admin ${actingUser.name} for user ${user.name}",
            createdAt: DateTime.now(),
          );

          await _firestoreService.addComment(adminCommentModel);
          print("DEBUG: Admin action comment added");
        }

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

  // Enhanced updateDocumentStatus with admin context support
  Future<bool> updateDocumentStatus(
      String documentId,
      DocumentStatus status,
      String? comment,
      UserModel user, // This could be admin or regular user
          {UserModel? onBehalfOfUser} // Optional: if admin is acting for another user
      ) async {
    try {
      print("DEBUG: updateDocumentStatus called for document: $documentId");
      print("DEBUG: Acting user: ${user.name} (${user.email})");
      print("DEBUG: New status: ${status.toString()}");

      if (onBehalfOfUser != null) {
        print("DEBUG: Admin is updating status on behalf of: ${onBehalfOfUser.name}");
      }

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

      // Add comment if provided or if admin action
      if (result) {
        String? finalComment = comment;

        // If admin is acting on behalf of another user, modify the comment
        if (onBehalfOfUser != null && user.id != onBehalfOfUser.id) {
          final adminNote = "Status updated by admin ${user.name}";
          finalComment = comment != null && comment.isNotEmpty
              ? "$comment\n\n[$adminNote]"
              : "[$adminNote]";
        }

        if (finalComment != null && finalComment.isNotEmpty) {
          print("DEBUG: Adding comment: $finalComment");
          final commentModel = CommentModel(
            id: _uuid.v4(),
            documentId: documentId,
            userId: user.id,
            userName: user.name,
            text: finalComment,
            createdAt: DateTime.now(),
          );

          await _firestoreService.addComment(commentModel);
          print("DEBUG: Comment added successfully");
        }
      }

      return result;
    } catch (e) {
      print('Error updating document status: $e');
      return false;
    }
  }

  // Enhanced addSignature with admin context support
  Future<bool> addSignature(
      String documentId,
      File signatureFile,
      UserModel user, // The user adding the signature
          {UserModel? onBehalfOfUser} // Optional: if admin is signing for another user
      ) async {
    try {
      print("DEBUG: addSignature called for document: $documentId");
      print("DEBUG: Signing user: ${user.name} (${user.email})");

      if (onBehalfOfUser != null) {
        print("DEBUG: Admin is signing on behalf of: ${onBehalfOfUser.name}");
      }

      // Upload signature image
      final signatureId = _uuid.v4();
      print("DEBUG: Generated signature ID: $signatureId");

      // Use the document owner's company for storage path
      final document = await _firestoreService.getDocument(documentId);
      if (document == null) {
        print("DEBUG: Document not found for signature upload");
        return false;
      }

      final imageUrl = await _storageService.uploadSignature(
        signatureFile,
        document.companyId, // Use document owner's company
        signatureId,
      );

      if (imageUrl == null) {
        print("DEBUG: Signature upload failed");
        return false;
      }

      print("DEBUG: Signature uploaded successfully. URL: $imageUrl");

      // Create signature model
      // If admin is signing on behalf of someone, show both names
      String signatureName = user.name;
      if (onBehalfOfUser != null && user.id != onBehalfOfUser.id) {
        signatureName = "${onBehalfOfUser.name} (via admin ${user.name})";
      }

      final signature = SignatureModel(
        id: signatureId,
        documentId: documentId,
        userId: user.id,
        userName: signatureName,
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

  // Enhanced addComment with admin context support
  Future<bool> addComment(
      String documentId,
      String commentText,
      UserModel user, // The user adding the comment
          {UserModel? onBehalfOfUser}// Optional: if admin is commenting for another user
      ) async {
    try {
      print("DEBUG: addComment called for document: $documentId");
      print("DEBUG: Commenting user: ${user.name} (${user.email})");
      print("DEBUG: Comment text: $commentText");

      if (onBehalfOfUser != null) {
        print("DEBUG: Admin is commenting on behalf of: ${onBehalfOfUser.name}");
      }

      // Modify comment text if admin is acting on behalf of another user
      String finalComment = commentText;
      String commenterName = user.name;

      if (onBehalfOfUser != null && user.id != onBehalfOfUser.id) {
        commenterName = "${onBehalfOfUser.name} (via admin ${user.name})";
      }

      final comment = CommentModel(
        id: _uuid.v4(),
        documentId: documentId,
        userId: user.id,
        userName: commenterName,
        text: finalComment,
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

  // Enhanced calculateCompliancePercentage with optional user filter
  Future<double> calculateCompliancePercentage(String companyId, {String? userId}) async {
    try {
      final documents = await _firestoreService.getDocuments(
        companyId: companyId,
        userId: userId, // Filter by specific user if provided
      );

      if (documents.isEmpty) {
        return 0.0;
      }

      int completedCount = 0;
      for (var doc in documents) {
        if (doc.isComplete || doc.isNotApplicable) {
          completedCount++;
        }
      }

      final percentage = (completedCount / documents.length) * 100;

      if (userId != null) {
        print("DEBUG: Compliance for user $userId: $percentage% ($completedCount/${documents.length})");
      }

      return percentage;
    } catch (e) {
      print('Error calculating compliance percentage: $e');
      return 0.0;
    }
  }

  // Enhanced updateDocumentFiles with admin context support and specification
  Future<DocumentModel?> updateDocumentFiles({
    required String documentId,
    required List<dynamic> files,
    required UserModel user, // The user performing the update (could be admin)
    DateTime? expiryDate,
    UserModel? onBehalfOfUser, // Optional: if admin is updating for another user
    String? specification, // NEW PARAMETER
  }) async {
    try {
      print("DEBUG: updateDocumentFiles called for document: $documentId");
      print("DEBUG: Updating user: ${user.name} (${user.email})");
      print("DEBUG: files count: ${files.length}");
      print("DEBUG: specification: $specification"); // NEW DEBUG LINE

      if (onBehalfOfUser != null) {
        print("DEBUG: Admin is updating files on behalf of: ${onBehalfOfUser.name}");
      }

      if (expiryDate != null) {
        print("DEBUG: Expiry date: $expiryDate");
      }

      // Get the existing document
      final document = await _firestoreService.getDocument(documentId);
      if (document == null) {
        print("DEBUG: Document not found: $documentId");
        return null;
      }

      // Get document type
      final documentType = await _firestoreService.getDocumentType(document.documentTypeId);
      if (documentType == null) {
        print("DEBUG: Document type not found: ${document.documentTypeId}");
        return null;
      }

      // Upload new files using the document owner's company
      List<String> fileUrls = [];
      if (documentType.isUploadable && files.isNotEmpty) {
        print("DEBUG: Beginning file upload process for ${files.length} files");

        try {
          // Process each file
          for (int i = 0; i < files.length; i++) {
            final file = files[i];

            if (kIsWeb) {
              // For web platform
              if (file is Map<String, dynamic> && file.containsKey('bytes')) {
                final fileName = file['name'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}.pdf';
                print("DEBUG: Uploading web file ${i+1}/${files.length}: $fileName");

                final fileUrl = await _storageService.uploadFile(
                  file,
                  document.companyId, // Use document owner's company
                  documentId,
                  fileName,
                );

                if (fileUrl != null) {
                  print("DEBUG: File uploaded successfully. URL: $fileUrl");
                  fileUrls.add(fileUrl);
                } else {
                  print("DEBUG: File upload failed for file $fileName");
                }
              } else {
                print("DEBUG: Invalid file format for web upload: ${file.runtimeType}");
              }
            } else {
              // For mobile/desktop platforms
              if (file is File) {
                final fileName = file.path.split('/').last;
                print("DEBUG: Uploading file ${i+1}/${files.length}: $fileName");

                final fileUrl = await _storageService.uploadFile(
                  file,
                  document.companyId, // Use document owner's company
                  documentId,
                  fileName,
                );

                if (fileUrl != null) {
                  print("DEBUG: File uploaded successfully. URL: $fileUrl");
                  fileUrls.add(fileUrl);
                } else {
                  print("DEBUG: File upload failed for file $fileName");
                }
              } else {
                print("DEBUG: Invalid file format for mobile/desktop upload: ${file.runtimeType}");
              }
            }
          }

          print("DEBUG: File upload process completed. Added ${fileUrls.length} URLs");
        } catch (e) {
          print("DEBUG: Error during file upload process: $e");
          print("DEBUG: Stack trace: ${StackTrace.current}");
          return null;
        }
      }

      // Update the document with new files, status, and specification
      final updatedDocument = document.copyWith(
        fileUrls: fileUrls,
        status: DocumentStatus.PENDING, // Set status back to pending
        updatedAt: DateTime.now(),
        expiryDate: expiryDate ?? document.expiryDate,
        specification: specification ?? document.specification, // NEW FIELD - update if provided, otherwise keep existing
      );

      print("DEBUG: Updating document with new file URLs: ${fileUrls.length}");
      print("DEBUG: Document's new fileUrls: ${updatedDocument.fileUrls}");
      print("DEBUG: Document's expiryDate: ${updatedDocument.expiryDate}");
      print("DEBUG: Document's specification: ${updatedDocument.specification}"); // NEW DEBUG LINE

      // Save updated document to Firestore
      final result = await _firestoreService.updateDocument(updatedDocument);
      print("DEBUG: Document update result: $result");

      if (result) {
        // Add a system comment about resubmission
        String commentText = "Document resubmitted with updated files.";
        String commenterName = user.name;

        if (onBehalfOfUser != null && user.id != onBehalfOfUser.id) {
          commentText = "Document resubmitted with updated files by admin ${user.name} for user ${onBehalfOfUser.name}.";
          commenterName = "${onBehalfOfUser.name} (via admin ${user.name})";
        }

        final commentModel = CommentModel(
          id: _uuid.v4(),
          documentId: documentId,
          userId: user.id,
          userName: commenterName,
          text: commentText,
          createdAt: DateTime.now(),
        );

        await _firestoreService.addComment(commentModel);
        print("DEBUG: Resubmission comment added");

        return updatedDocument;
      } else {
        print("DEBUG: Document update failed");
        return null;
      }
    } catch (e) {
      print('ERROR updating document files: $e');
      print('ERROR trace: ${e.toString()}');
      return null;
    }
  }
}