# lib\core\constants\app_constants.dart

```dart
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
```

# lib\core\constants\route_constants.dart

```dart
class RouteConstants {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main routes
  static const String dashboard = '/dashboard';
  static const String auditTracker = '/audit-tracker';
  static const String complianceReport = '/compliance-report';
  static const String auditIndex = '/audit-index';

  // Document routes
  static const String documentDetail = '/document-detail';
  static const String documentUpload = '/document-upload';
  static const String documentForm = '/document-form';
  static const String categoryDocuments = '/category-documents';

  // Admin routes
  static const String userManagement = '/user-management';
  static const String categoryManagement = '/category-management';
}
```

# lib\core\services\auth_service.dart

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    required String companyId,
    UserRole role = UserRole.USER,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          email: email,
          name: name,
          role: role,
          companyId: companyId,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.id)
            .set(user.toMap());

        return user;
      }
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  Future<UserModel?> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'role': role.toString().split('.').last});

      return await getUserData(userId);
    } catch (e) {
      print('Error updating user role: $e');
      return null;
    }
  }
}
```

# lib\core\services\document_service.dart

```dart
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
```

# lib\core\services\firestore_service.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../models/document_model.dart';
import '../../models/comment_model.dart';
import '../../models/signature_model.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../models/enums.dart';
import '../constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Categories
  Future<List<CategoryModel>> getCategories() async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getCategories');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('order')
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getCategories completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${categories.length} categories');

      return categories;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting categories: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getCategory: $categoryId');

    try {
      final doc = await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .get();

      stopwatch.stop();
      developer.log('FirestoreService - getCategory completed: ${stopwatch.elapsedMilliseconds}ms - Found: ${doc.exists}');

      if (doc.exists) {
        return CategoryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting category: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  // Document Types
  Future<List<DocumentTypeModel>> getDocumentTypes(String categoryId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getDocumentTypes for category: $categoryId');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.documentTypesCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      final docTypes = snapshot.docs
          .map((doc) => DocumentTypeModel.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getDocumentTypes completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${docTypes.length} document types for category: $categoryId');

      return docTypes;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting document types: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  Future<DocumentTypeModel?> getDocumentType(String documentTypeId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getDocumentType: $documentTypeId');

    try {
      final doc = await _firestore
          .collection(AppConstants.documentTypesCollection)
          .doc(documentTypeId)
          .get();

      stopwatch.stop();
      developer.log('FirestoreService - getDocumentType completed: ${stopwatch.elapsedMilliseconds}ms - Found: ${doc.exists}');

      if (doc.exists) {
        return DocumentTypeModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting document type: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  // Documents - OPTIMIZED
  Future<List<DocumentModel>> getDocuments({
    String? companyId,
    String? userId,
    String? categoryId,
    DocumentStatus? status,
  }) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getDocuments - companyId: $companyId, categoryId: $categoryId, status: $status');

    try {
      // 1. Build the base query
      Query query = _firestore.collection(AppConstants.documentsCollection);

      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      if (status != null) {
        query = query.where(
            'status',
            isEqualTo: status.toString().split('.').last
        );
      }

      // 2. Execute the main query
      developer.log('FirestoreService - Executing main documents query');
      final queryStopwatch = Stopwatch()..start();

      final snapshot = await query.get();

      queryStopwatch.stop();
      developer.log('FirestoreService - Main documents query completed: ${queryStopwatch.elapsedMilliseconds}ms - Retrieved ${snapshot.docs.length} documents');

      if (snapshot.docs.isEmpty) {
        stopwatch.stop();
        developer.log('FirestoreService - getDocuments completed: ${stopwatch.elapsedMilliseconds}ms - No documents found');
        return [];
      }

      // 3. Extract document IDs
      final documentIds = snapshot.docs.map((doc) => doc.id).toList();

      // 4. Batch fetch all signatures and comments
      developer.log('FirestoreService - Batch fetching signatures and comments');

      // Firestore whereIn has a limit of 10 items, so we need to chunk the documents
      final chunks = _chunkList(documentIds, 10);
      final signaturesQueryStopwatch = Stopwatch()..start();
      final commentsQueryStopwatch = Stopwatch()..start();

      // Lists to hold all signatures and comments
      List<SignatureModel> allSignatures = [];
      List<CommentModel> allComments = [];

      // Create parallel queries for each chunk
      final signaturesFutures = chunks.map((chunk) =>
          _firestore
              .collection(AppConstants.signaturesCollection)
              .where('documentId', whereIn: chunk)
              .get()
      ).toList();

      final commentsFutures = chunks.map((chunk) =>
          _firestore
              .collection(AppConstants.commentsCollection)
              .where('documentId', whereIn: chunk)
              .orderBy('createdAt', descending: true)
              .get()
      ).toList();

      // Execute all queries in parallel
      final signaturesResults = await Future.wait(signaturesFutures);
      signaturesQueryStopwatch.stop();

      final commentsResults = await Future.wait(commentsFutures);
      commentsQueryStopwatch.stop();

      // Process signatures results
      for (var snapshot in signaturesResults) {
        for (var doc in snapshot.docs) {
          allSignatures.add(SignatureModel.fromMap(doc.data(), doc.id));
        }
      }

      // Process comments results
      for (var snapshot in commentsResults) {
        for (var doc in snapshot.docs) {
          allComments.add(CommentModel.fromMap(doc.data(), doc.id));
        }
      }

      developer.log('FirestoreService - Signatures fetched: ${signaturesQueryStopwatch.elapsedMilliseconds}ms - ${allSignatures.length} total');
      developer.log('FirestoreService - Comments fetched: ${commentsQueryStopwatch.elapsedMilliseconds}ms - ${allComments.length} total');

      // 5. Group signatures and comments by document ID for easy access
      final signaturesMap = <String, List<SignatureModel>>{};
      final commentsMap = <String, List<CommentModel>>{};

      for (var signature in allSignatures) {
        if (!signaturesMap.containsKey(signature.documentId)) {
          signaturesMap[signature.documentId] = [];
        }
        signaturesMap[signature.documentId]!.add(signature);
      }

      for (var comment in allComments) {
        if (!commentsMap.containsKey(comment.documentId)) {
          commentsMap[comment.documentId] = [];
        }
        commentsMap[comment.documentId]!.add(comment);
      }

      // 6. Create the final document models
      final documents = snapshot.docs.map((doc) {
        final docId = doc.id;
        return DocumentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          docId,
          signaturesMap[docId] ?? [],
          commentsMap[docId] ?? [],
        );
      }).toList();

      stopwatch.stop();
      developer.log('FirestoreService - getDocuments completed: ${stopwatch.elapsedMilliseconds}ms - Total documents processed: ${documents.length}');

      return documents;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting documents: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  // Helper to chunk a list for batch processing
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  // Get a single document - OPTIMIZED
  Future<DocumentModel?> getDocument(String documentId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getDocument: $documentId');

    try {
      // Fetch document, signatures, and comments in parallel
      final docFuture = _firestore
          .collection(AppConstants.documentsCollection)
          .doc(documentId)
          .get();

      final signaturesFuture = _firestore
          .collection(AppConstants.signaturesCollection)
          .where('documentId', isEqualTo: documentId)
          .get();

      final commentsFuture = _firestore
          .collection(AppConstants.commentsCollection)
          .where('documentId', isEqualTo: documentId)
          .orderBy('createdAt', descending: true)
          .get();

      // Wait for all futures to complete in parallel
      final results = await Future.wait([docFuture, signaturesFuture, commentsFuture]);

      final docSnapshot = results[0] as DocumentSnapshot;
      final signaturesSnapshot = results[1] as QuerySnapshot;
      final commentsSnapshot = results[2] as QuerySnapshot;

      if (!docSnapshot.exists) {
        stopwatch.stop();
        developer.log('FirestoreService - Document not found: ${stopwatch.elapsedMilliseconds}ms');
        return null;
      }

      // Convert signatures and comments
      final signatures = signaturesSnapshot.docs
          .map((doc) => SignatureModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      final comments = commentsSnapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Create the document model
      final document = DocumentModel.fromMap(
        docSnapshot.data() as Map<String, dynamic>,
        docSnapshot.id,
        signatures,
        comments,
      );

      stopwatch.stop();
      developer.log('FirestoreService - getDocument completed: ${stopwatch.elapsedMilliseconds}ms - Signatures: ${signatures.length}, Comments: ${comments.length}');

      return document;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting document: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  Future<String?> addDocument(DocumentModel document, [Map<String, dynamic>? explicitData]) async {
    try {
      // Use explicit data if provided, otherwise use document.toMap()
      final data = explicitData ?? document.toMap();

      // Debug - verify data
      print("DEBUG FirestoreService: Adding document with ID: ${document.id}");
      print("DEBUG FirestoreService: Document data: $data");

      // Explicitly check if expiryDate is in the data
      if (document.expiryDate != null) {
        print("DEBUG FirestoreService: Document has expiryDate: ${document.expiryDate}");
        if (data['expiryDate'] == null) {
          print("DEBUG FirestoreService: WARNING - expiryDate is missing from data!");
          // Force add it if missing
          data['expiryDate'] = Timestamp.fromDate(document.expiryDate!);
          print("DEBUG FirestoreService: Added missing expiryDate to data");
        }
      }

      // Add to Firestore
      await _firestore.collection('documents').doc(document.id).set(data);

      return document.id;
    } catch (e) {
      print('Error adding document: $e');
      return null;
    }
  }

  Future<bool> updateDocument(DocumentModel document) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting updateDocument: ${document.id}');

    try {
      await _firestore
          .collection(AppConstants.documentsCollection)
          .doc(document.id)
          .update(document.toMap());

      stopwatch.stop();
      developer.log('FirestoreService - updateDocument completed: ${stopwatch.elapsedMilliseconds}ms');

      return true;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error updating document: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting deleteDocument: $documentId');

    try {
      await _firestore
          .collection(AppConstants.documentsCollection)
          .doc(documentId)
          .delete();

      stopwatch.stop();
      developer.log('FirestoreService - deleteDocument completed: ${stopwatch.elapsedMilliseconds}ms');

      return true;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error deleting document: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return false;
    }
  }

  // Signatures
  Future<List<SignatureModel>> getSignatures(String documentId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getSignatures for document: $documentId');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.signaturesCollection)
          .where('documentId', isEqualTo: documentId)
          .get();

      final signatures = snapshot.docs
          .map((doc) => SignatureModel.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getSignatures completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${signatures.length} signatures');

      return signatures;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting signatures: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  Future<String?> addSignature(SignatureModel signature) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting addSignature');

    try {
      final docRef = await _firestore
          .collection(AppConstants.signaturesCollection)
          .add(signature.toMap());

      stopwatch.stop();
      developer.log('FirestoreService - addSignature completed: ${stopwatch.elapsedMilliseconds}ms - New ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error adding signature: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  // Comments
  Future<List<CommentModel>> getComments(String documentId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getComments for document: $documentId');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.commentsCollection)
          .where('documentId', isEqualTo: documentId)
          .orderBy('createdAt', descending: true)
          .get();

      final comments = snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getComments completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${comments.length} comments');

      return comments;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting comments: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  Future<String?> addComment(CommentModel comment) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting addComment');

    try {
      final docRef = await _firestore
          .collection(AppConstants.commentsCollection)
          .add(comment.toMap());

      stopwatch.stop();
      developer.log('FirestoreService - addComment completed: ${stopwatch.elapsedMilliseconds}ms - New ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error adding comment: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  // Companies
  Future<List<CompanyModel>> getCompanies() async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getCompanies');

    try {
      final snapshot = await _firestore
          .collection(AppConstants.companiesCollection)
          .get();

      final companies = snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getCompanies completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${companies.length} companies');

      return companies;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting companies: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }

  Future<CompanyModel?> getCompany(String companyId) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getCompany: $companyId');

    try {
      final doc = await _firestore
          .collection(AppConstants.companiesCollection)
          .doc(companyId)
          .get();

      stopwatch.stop();
      developer.log('FirestoreService - getCompany completed: ${stopwatch.elapsedMilliseconds}ms - Found: ${doc.exists}');

      if (doc.exists) {
        return CompanyModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting company: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  Future<String?> addCompany(CompanyModel company) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting addCompany');

    try {
      final docRef = await _firestore
          .collection(AppConstants.companiesCollection)
          .add(company.toMap());

      stopwatch.stop();
      developer.log('FirestoreService - addCompany completed: ${stopwatch.elapsedMilliseconds}ms - New ID: ${docRef.id}');

      return docRef.id;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error adding company: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return null;
    }
  }

  // Users
  Future<List<UserModel>> getUsers({String? companyId}) async {
    final stopwatch = Stopwatch()..start();
    developer.log('FirestoreService - Starting getUsers - companyId: $companyId');

    try {
      Query query = _firestore.collection(AppConstants.usersCollection);

      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }

      final snapshot = await query.get();

      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      stopwatch.stop();
      developer.log('FirestoreService - getUsers completed: ${stopwatch.elapsedMilliseconds}ms - Retrieved ${users.length} users');

      return users;
    } catch (e) {
      stopwatch.stop();
      developer.log('FirestoreService - Error getting users: $e - Elapsed: ${stopwatch.elapsedMilliseconds}ms');
      return [];
    }
  }
}
```

# lib\core\services\storage_service.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String?> uploadFile(dynamic file, String companyId, String documentId, String fileName) async {
    try {
      print("DEBUG Storage: Starting file upload");
      print("DEBUG Storage: Company ID: $companyId");
      print("DEBUG Storage: Document ID: $documentId");
      print("DEBUG Storage: Filename: $fileName");

      final storagePath = AppConstants.documentsStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{documentId}', documentId);
      print("DEBUG Storage: Storage path: $storagePath");

      final uniqueFileName = '${_uuid.v4()}_$fileName';
      print("DEBUG Storage: Unique filename: $uniqueFileName");

      final ref = _storage.ref().child('$storagePath/$uniqueFileName');
      print("DEBUG Storage: Storage reference created");

      UploadTask uploadTask;

      if (kIsWeb) {
        print("DEBUG Storage: Using web upload method");

        // Web environment - handle different possible input types
        if (file is Uint8List) {
          // Direct bytes input
          print("DEBUG Storage: Using provided Uint8List data, size: ${file.length} bytes");
          uploadTask = ref.putData(file, SettableMetadata(
            contentType: _getContentType(fileName),
            customMetadata: {'picked-file-path': fileName},
          ));
        }
        else if (file is Map<String, dynamic>) {
          // Map with bytes key
          if (file.containsKey('bytes') && file['bytes'] is Uint8List) {
            Uint8List bytes = file['bytes'] as Uint8List;
            print("DEBUG Storage: Using bytes from map, size: ${bytes.length} bytes");
            uploadTask = ref.putData(bytes, SettableMetadata(
              contentType: _getContentType(fileName),
              customMetadata: {'picked-file-path': fileName},
            ));
          } else {
            print("DEBUG Storage: Map does not contain valid bytes data");
            return null;
          }
        }
        else {
          // Fallback for empty upload (for debugging - remove in production)
          print("DEBUG Storage: WARNING - Using empty bytes for upload. File type: ${file.runtimeType}");
          uploadTask = ref.putData(Uint8List(0), SettableMetadata(
            contentType: _getContentType(fileName),
            customMetadata: {'picked-file-path': fileName},
          ));
        }
        print("DEBUG Storage: Web upload task started");
      } else {
        // Mobile/Desktop environment
        print("DEBUG Storage: Using file upload method");
        if (file is File) {
          uploadTask = ref.putFile(file);
        } else {
          print("DEBUG Storage: Error - Non-web environment requires File objects, got: ${file.runtimeType}");
          return null;
        }
      }

      final snapshot = await uploadTask;
      print("DEBUG Storage: Upload completed");

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("DEBUG Storage: Download URL obtained: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print('ERROR uploading file: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      return null;
    }
  }

  String _getContentType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.doc')) return 'application/msword';
    if (fileName.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }

  Future<String?> uploadSignature(dynamic signatureFile, String companyId, String signatureId) async {
    try {
      print("DEBUG Storage: Starting signature upload");

      final storagePath = AppConstants.signaturesStoragePath
          .replaceAll('{companyId}', companyId)
          .replaceAll('{signatureId}', signatureId);
      print("DEBUG Storage: Signature path: $storagePath");

      final ref = _storage.ref().child('$storagePath.png');
      print("DEBUG Storage: Signature reference created");

      UploadTask uploadTask;

      if (kIsWeb) {
        print("DEBUG Storage: Using web upload for signature");

        if (signatureFile is Uint8List) {
          // Direct bytes input
          print("DEBUG Storage: Using Uint8List for signature, size: ${signatureFile.length} bytes");
          uploadTask = ref.putData(signatureFile, SettableMetadata(contentType: 'image/png'));
        }
        else if (signatureFile is Map<String, dynamic> && signatureFile.containsKey('bytes')) {
          // Map with bytes key
          Uint8List bytes = signatureFile['bytes'] as Uint8List;
          print("DEBUG Storage: Using bytes from map for signature, size: ${bytes.length} bytes");
          uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
        }
        else {
          print("DEBUG Storage: Error - Web signature upload requires Uint8List data");
          return null;
        }
      } else {
        if (signatureFile is File) {
          uploadTask = ref.putFile(signatureFile);
        } else {
          print("DEBUG Storage: Error - Non-web signature upload requires File objects");
          return null;
        }
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("DEBUG Storage: Signature URL: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      print('ERROR uploading signature: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}
```

# lib\firebase_options.dart

```dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// \`\`\`dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// \`\`\`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA7NWG0s-9Z8M5WeQgJq1mRuVY-6W8mVUw',
    appId: '1:854876175061:web:fce454e395448d9503805c',
    messagingSenderId: '854876175061',
    projectId: 'cropcompliance',
    authDomain: 'cropcompliance.firebaseapp.com',
    storageBucket: 'cropcompliance.firebasestorage.app',
    measurementId: 'G-WYCB8SGGQ8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKWlUuRI_a1DXx-j9GZ2106kGmWGrg87Q',
    appId: '1:854876175061:android:a826d41714b6b6ab03805c',
    messagingSenderId: '854876175061',
    projectId: 'cropcompliance',
    storageBucket: 'cropcompliance.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDEeZ71oGmCiTmjaDIeplsFxr0oNDU41WY',
    appId: '1:854876175061:ios:17ce1bf0e0cdea1a03805c',
    messagingSenderId: '854876175061',
    projectId: 'cropcompliance',
    storageBucket: 'cropcompliance.firebasestorage.app',
    iosBundleId: 'com.example.cropcompliance',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDEeZ71oGmCiTmjaDIeplsFxr0oNDU41WY',
    appId: '1:854876175061:ios:17ce1bf0e0cdea1a03805c',
    messagingSenderId: '854876175061',
    projectId: 'cropcompliance',
    storageBucket: 'cropcompliance.firebasestorage.app',
    iosBundleId: 'com.example.cropcompliance',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA7NWG0s-9Z8M5WeQgJq1mRuVY-6W8mVUw',
    appId: '1:854876175061:web:80af2ffbf87036c903805c',
    messagingSenderId: '854876175061',
    projectId: 'cropcompliance',
    authDomain: 'cropcompliance.firebaseapp.com',
    storageBucket: 'cropcompliance.firebasestorage.app',
    measurementId: 'G-SKJ8N05RNV',
  );

}
```

# lib\initialize_data.dart

```dart
// Setup initial data method with all 12 categories
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> _setupInitialData() async {
  final firestore = FirebaseFirestore.instance;

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Setting up document categories...'),
        ],
      ),
    ),
  );

  try {
    // 1. Business Information and Compliance
    final businessCatRef = await firestore.collection('categories').add({
      'name': 'Business Information and Compliance',
      'description': 'Registration, tax, and compliance documentation',
      'order': 1,
    });

    // Business Information document types
    final businessDocTypes = [
      {
        'name': 'Company Registration Documents',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Tax Compliance Certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Workmans Compensation Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'BEE Certification Documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Company Organisational Chart',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Site Maps/Layouts',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Business Licences and Permits',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'WIETA/SIZA Membership Documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in businessDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': businessCatRef.id,
      });
    }

    // 2. Management Systems
    final managementCatRef = await firestore.collection('categories').add({
      'name': 'Management Systems',
      'description': 'Policies, procedures, and risk assessments',
      'order': 2,
    });

    // Management Systems document types
    final managementDocTypes = [
      {
        'name': 'Ethical Code of Conduct',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Document Control Procedure',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Company Policies',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Appointments (Ethical & Health and Safety)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Risk Assessments',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Internal Audits Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Social Compliance Improvement Plans',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Previous WIETA/SIZA Audit Reports',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Evidence of Closed Non-Conformances',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Continuous Improvement Plans',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in managementDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': managementCatRef.id,
      });
    }

    // 3. Employment Documentation
    final employmentCatRef = await firestore.collection('categories').add({
      'name': 'Employment Documentation',
      'description': 'Contracts, agreements, and employee records',
      'order': 3,
    });

    final employmentDocTypes = [
      {
        'name': 'Employment Contracts',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Housing Agreements/Contracts',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'List of Employees',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Employee Contact Details Form',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Medical Screening Form',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Labour Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Disciplinary Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Proof of Identity and Right to Work Documents',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Migrant Workers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'EEA1 Forms',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Employment Equity Documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in employmentDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': employmentCatRef.id,
      });
    }

    // 4. Child Labor and Young Workers
    final childLaborCatRef = await firestore.collection('categories').add({
      'name': 'Child Labor and Young Workers',
      'description': 'Age verification and young worker protections',
      'order': 4,
    });

    final childLaborDocTypes = [
      {
        'name': 'Age Verification Procedure',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Young Workers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Young Worker Risk Assessments',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Records of Working Hours for Young Workers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Education Support Programs',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Child Labor Remediation Plan',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in childLaborDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': childLaborCatRef.id,
      });
    }

    // 5. Forced Labor Prevention
    final forcedLaborCatRef = await firestore.collection('categories').add({
      'name': 'Forced Labor Prevention',
      'description': 'Procedures and records to prevent forced labor',
      'order': 5,
    });

    final forcedLaborDocTypes = [
      {
        'name': 'Loan and Advance Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Loan Payments and Tracking',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Procedures for Voluntary Overtime',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Contracts with Labor Providers/Recruiters',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in forcedLaborDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': forcedLaborCatRef.id,
      });
    }

    // 6. Wages and Working Hours
    final wagesCatRef = await firestore.collection('categories').add({
      'name': 'Wages and Working Hours',
      'description': 'Wage documentation and working hour records',
      'order': 6,
    });

    final wagesDocTypes = [
      {
        'name': 'SARS Registration',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'UIF Records and Payments',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Wage Slips',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Time Recording System Documentation',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Working Hours',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Overtime Authorization Forms/Exemptions',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Night Allowance',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Production Targets and Piece Rate Calculations',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Bonuses or Incentives',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Deduction Agreements',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Loan Agreements',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Minimum Wage Calculations and Compliance Evidence',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Leave Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Public Holiday Work and Pay Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in wagesDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': wagesCatRef.id,
      });
    }

    // 7. Freedom of Association
    final associationCatRef = await firestore.collection('categories').add({
      'name': 'Freedom of Association',
      'description': 'Worker representation and collective bargaining',
      'order': 7,
    });

    final associationDocTypes = [
      {
        'name': 'Records of Worker Representative Elections',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Worker Committee Meeting Minutes',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Management Review Meeting Minutes',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Records of Collective Bargaining Agreements',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Trade Union Recognition Agreements',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in associationDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': associationCatRef.id,
      });
    }

    // 8. Training and Development
    final trainingCatRef = await firestore.collection('categories').add({
      'name': 'Training and Development',
      'description': 'Training materials and records',
      'order': 8,
    });

    final trainingDocTypes = [
      {
        'name': 'Induction Training Materials',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Induction Training Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Skills Training Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Health and Safety Training Materials',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Social Compliance Training Materials',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Training Schedule',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in trainingDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': trainingCatRef.id,
      });
    }

    // 9. Health and Safety
    final healthSafetyCatRef = await firestore.collection('categories').add({
      'name': 'Health and Safety',
      'description': 'Procedures, records, and safety documentation',
      'order': 9,
    });

    final healthSafetyDocTypes = [
      {
        'name': 'Emergency & Safety Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Health and Safety Committee Meeting Minutes',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Workplace Safety Inspections',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Accident and Incident Reports',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Training Certificates',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Fire Drills and Evacuations',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Fire Permit Fire Association',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Fire Extinguishers Service Certificate',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Forklift Load Test',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Pressure Test Compressor',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Machine and Vehicle Safety Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Asbestos Register',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Procedure Asbestos Maintenance',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Removal and Management Plan',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Asbestos Survey',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'PDPs/Licenses',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'COCs',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Analysis Potable Water',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Septic Tank Pump Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Personal Protective Equipment (PPE) Distribution Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Medical Surveillance Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Hygiene Inspection Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Stacking Permit',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in healthSafetyDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': healthSafetyCatRef.id,
      });
    }

    // 10. Chemical and Pesticide Management
    final chemicalCatRef = await firestore.collection('categories').add({
      'name': 'Chemical and Pesticide Management',
      'description': 'Chemical handling, storage, and safety records',
      'order': 10,
    });

    final chemicalDocTypes = [
      {
        'name': 'Chemical Inventory List',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Safety Data Sheets (SDS)',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Chemical Handling Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Chemical Storage Facility Specifications',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'PPE Specific for Chemical Handling',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'Re-entry Interval Procedure',
        'allowMultipleDocuments': false,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Medical Check-up Records for Chemical Handlers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Pesticide Containers Disposal Certificate',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in chemicalDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': chemicalCatRef.id,
      });
    }

    // 11. Labour and Service Providers
    final serviceProvidersCatRef = await firestore.collection('categories').add({
      'name': 'Labour and Service Providers',
      'description': 'Contractor agreements and compliance records',
      'order': 11,
    });

    final serviceProvidersDocTypes = [
      {
        'name': 'Service Providers/Contractor Code of Conduct',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': true,
        'signatureCount': 1,
      },
      {
        'name': 'List of Contractors and Service Providers',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Section 37(2) Agreements',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Contractor Compliance Evaluation Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in serviceProvidersDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': serviceProvidersCatRef.id,
      });
    }

    // 12. Environmental and Community Impact
    final environmentalCatRef = await firestore.collection('categories').add({
      'name': 'Environmental and Community Impact',
      'description': 'Environmental procedures and community engagement',
      'order': 12,
    });

    final environmentalDocTypes = [
      {
        'name': 'Waste Management Procedures',
        'allowMultipleDocuments': true,
        'isUploadable': false,
        'hasExpiryDate': false,
        'hasNotApplicableOption': false,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Waste Removal Records',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Community Engagement Activities',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Records of Environmental Permits',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
      {
        'name': 'Environmental Impact Assessments',
        'allowMultipleDocuments': true,
        'isUploadable': true,
        'hasExpiryDate': true,
        'hasNotApplicableOption': true,
        'requiresSignature': false,
        'signatureCount': 0,
      },
    ];

    for (var docType in environmentalDocTypes) {
      await firestore.collection('documentTypes').add({
        ...docType,
        'categoryId': environmentalCatRef.id,
      });
    }

    // Success message
    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      // Refresh providers
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.initialize();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All categories and document types created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting up data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

# lib\main.dart

```dart
import 'package:cropcompliance/providers/audit_provider.dart';
import 'package:cropcompliance/providers/category_provider.dart';
import 'package:cropcompliance/providers/route_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'routes/router.dart';
import 'providers/auth_provider.dart';
import 'providers/document_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ChangeNotifierProvider(create: (_) => AuditProvider()),
      ChangeNotifierProvider(create: (_) => RouteProvider()),
    ],
    child: const AgriComplianceApp(),
  ));
}

class AgriComplianceApp extends StatelessWidget {
  const AgriComplianceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Agricultural Compliance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRouter.initialRoute,
    );
  }
}
```

# lib\models\category_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String description;
  final int order;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'order': order,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
    );
  }
}
```

# lib\models\comment_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String documentId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    return CommentModel(
      id: id,
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

# lib\models\company_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String address;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

# lib\models\document_model.dart

```dart
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
      expiryDate: expiryDate ?? this.expiryDate,  // Fixed this line to preserve existing expiryDate
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
```

# lib\models\document_type_model.dart

```dart

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
```

# lib\models\enums.dart

```dart
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

```

# lib\models\signature_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SignatureModel {
  final String id;
  final String documentId;
  final String userId;
  final String userName;
  final String imageUrl;
  final DateTime signedAt;

  SignatureModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    required this.signedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'signedAt': Timestamp.fromDate(signedAt),
    };
  }

  factory SignatureModel.fromMap(Map<String, dynamic> map, String id) {
    return SignatureModel(
      id: id,
      documentId: map['documentId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      signedAt: (map['signedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
```

# lib\models\user_model.dart

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String companyId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.companyId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'USER'),
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? companyId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

# lib\providers\audit_provider.dart

```dart
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../core/services/firestore_service.dart';
import '../core/services/document_service.dart';
import '../core/services/storage_service.dart';

class AuditProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  late final DocumentService _documentService;

  String? _currentCompanyId;
  Map<String, double> _categoryComplianceMap = {};
  double _overallCompliance = 0.0;
  bool _isLoading = false;
  String? _error;

  // Cache for documents to avoid frequent refetching
  Map<String, List<DocumentModel>> _documentsCache = {};

  AuditProvider() {
    _documentService = DocumentService(
      firestoreService: _firestoreService,
      storageService: _storageService,
    );
  }

  // Getters - unchanged
  String? get currentCompanyId => _currentCompanyId;
  Map<String, double> get categoryComplianceMap => _categoryComplianceMap;
  double get overallCompliance => _overallCompliance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set current company - unchanged
  void setCurrentCompany(String companyId) {
    _currentCompanyId = companyId;
    calculateComplianceStats();
  }

  // Calculate compliance statistics - optimized to reduce notifications
  Future<void> calculateComplianceStats() async {
    if (_currentCompanyId == null) return;

    _setLoading(true);

    try {
      // Get overall compliance
      final complianceFuture = _documentService.calculateCompliancePercentage(_currentCompanyId!);

      // Get categories
      final categoriesFuture = _firestoreService.getCategories();

      // Wait for both operations to complete
      final results = await Future.wait([complianceFuture, categoriesFuture]);

      _overallCompliance = results[0] as double;
      final categories = results[1] as List<CategoryModel>;

      // Prepare for batch calculation
      final tempComplianceMap = <String, double>{};
      final futures = <Future>[];

      // Create futures for all category calculations
      for (var category in categories) {
        futures.add(_calculateCategoryCompliance(category, tempComplianceMap));
      }

      // Wait for all calculations to complete
      await Future.wait(futures);

      // Update final map and notify once
      _categoryComplianceMap = tempComplianceMap;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to calculate compliance statistics: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to calculate category compliance
  Future<void> _calculateCategoryCompliance(CategoryModel category, Map<String, double> resultMap) async {
    try {
      // Use cache if available
      final cacheKey = '${_currentCompanyId}_${category.id}';
      List<DocumentModel> docs;

      if (_documentsCache.containsKey(cacheKey)) {
        docs = _documentsCache[cacheKey]!;
      } else {
        docs = await _firestoreService.getDocuments(
          companyId: _currentCompanyId,
          categoryId: category.id,
        );
        _documentsCache[cacheKey] = docs; // Cache for future use
      }

      if (docs.isEmpty) {
        resultMap[category.id] = 0.0;
      } else {
        int completedCount = 0;
        for (var doc in docs) {
          if (doc.isComplete || doc.isNotApplicable) {
            completedCount++;
          }
        }

        final compliancePercentage = (completedCount / docs.length) * 100;
        resultMap[category.id] = compliancePercentage;
      }
    } catch (e) {
      print('Error calculating compliance for category ${category.id}: $e');
      resultMap[category.id] = 0.0;
    }
  }

  // Get documents for audit - optimized with caching
  Future<List<DocumentModel>> getDocumentsForAudit({
    String? categoryId,
    bool includeNotApplicable = true,
  }) async {
    if (_currentCompanyId == null) return [];

    try {
      // Create cache key
      final cacheKey = categoryId != null
          ? '${_currentCompanyId}_$categoryId'
          : '${_currentCompanyId}_all';

      // Check if data is in cache
      if (_documentsCache.containsKey(cacheKey)) {
        final cachedDocs = _documentsCache[cacheKey]!;

        if (!includeNotApplicable) {
          return cachedDocs.where((doc) => !doc.isNotApplicable).toList();
        }

        return cachedDocs;
      }

      // Fetch from service if not in cache
      final docs = await _firestoreService.getDocuments(
        companyId: _currentCompanyId,
        categoryId: categoryId,
      );

      // Store in cache
      _documentsCache[cacheKey] = docs;

      if (!includeNotApplicable) {
        return docs.where((doc) => !doc.isNotApplicable).toList();
      }

      return docs;
    } catch (e) {
      _error = 'Failed to get documents for audit: $e';
      return [];
    }
  }

  // Clear cache - useful after document updates
  void clearCache() {
    _documentsCache.clear();
  }

  // Helper - unchanged
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error - unchanged
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

# lib\providers\auth_provider.dart

```dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser => _currentUser!;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  // Role-based getters
  bool get isAdmin => _currentUser?.role == UserRole.ADMIN;
  bool get isAuditer => _currentUser?.role == UserRole.AUDITER;
  bool get isUser => _currentUser?.role == UserRole.USER;

  // Initialize
  Future<void> initializeUser() async {
    _setLoading(true);
    _error = null;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
      }
    } catch (e) {
      _error = 'Failed to initialize user: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        return true;
      } else {
        _error = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String companyId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authService.registerUser(
        email: email,
        password: password,
        name: name,
        companyId: companyId,
      );

      if (user != null) {
        _currentUser = user;
        return true;
      } else {
        _error = 'Registration failed';
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logoutUser();
      _currentUser = null;
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await _authService.resetPassword(email);
      return result;
    } catch (e) {
      _error = 'Password reset failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

# lib\providers\category_provider.dart

```dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/document_type_model.dart';
import '../core/services/firestore_service.dart';

class CategoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _categories = [];
  Map<String, List<DocumentTypeModel>> _documentTypesByCategory = {};
  Map<String, DocumentTypeModel> _documentTypesMap = {}; // New lookup map
  bool _isLoading = false;
  String? _error;

  // Getters - unchanged
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get document types for a category - unchanged
  List<DocumentTypeModel> getDocumentTypes(String categoryId) {
    return _documentTypesByCategory[categoryId] ?? [];
  }

  // Initialize - unchanged method signature
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Modified implementation to reduce notifications
      await _batchFetchAllData();
    } catch (e) {
      _error = 'Failed to initialize categories: $e';
    } finally {
      _setLoading(false);
    }
  }

  // New helper method for batch fetching
  Future<void> _batchFetchAllData() async {
    try {
      // Fetch categories first
      final categories = await _firestoreService.getCategories();
      _categories = categories;

      // Create a list of document type fetching futures for parallel execution
      final futures = <Future>[];
      for (var category in _categories) {
        futures.add(_fetchDocTypesForCategory(category.id));
      }

      // Wait for all document types to be fetched
      await Future.wait(futures);

      // Build lookup map for faster access
      _buildDocumentTypesMap();

      // Only notify once after all data is loaded
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch categories and document types: $e';
      notifyListeners();
    }
  }

  // Helper method to fetch document types for a category
  Future<void> _fetchDocTypesForCategory(String categoryId) async {
    try {
      final documentTypes = await _firestoreService.getDocumentTypes(categoryId);
      _documentTypesByCategory[categoryId] = documentTypes;
    } catch (e) {
      print('Error fetching document types for category $categoryId: $e');
    }
  }

  // Build lookup map for faster access
  void _buildDocumentTypesMap() {
    _documentTypesMap = {};
    for (var entry in _documentTypesByCategory.entries) {
      for (var docType in entry.value) {
        _documentTypesMap[docType.id] = docType;
      }
    }
  }

  // These methods remain unchanged but are optimized to use a single notification

  // Fetch categories - kept for backward compatibility
  Future<void> fetchCategories() async {
    try {
      // Using batch fetch instead of multiple notifications
      await _batchFetchAllData();
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
      notifyListeners();
    }
  }

  // Fetch document types - kept for backward compatibility
  Future<void> fetchDocumentTypes(String categoryId) async {
    try {
      final documentTypes = await _firestoreService.getDocumentTypes(categoryId);
      _documentTypesByCategory[categoryId] = documentTypes;

      // Update the lookup map with new document types
      for (var docType in documentTypes) {
        _documentTypesMap[docType.id] = docType;
      }

      // Single notification after all updates
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch document types: $e';
      notifyListeners();
    }
  }

  // Helper - unchanged
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error - unchanged
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // New method for direct document type lookup
  DocumentTypeModel? getDocumentTypeById(String id) {
    return _documentTypesMap[id];
  }
}
```

# lib\providers\document_provider.dart

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/document_type_model.dart';
import '../models/category_model.dart';
import '../models/user_model.dart';
import '../models/enums.dart';
import '../core/services/firestore_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/document_service.dart';

class DocumentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  late final DocumentService _documentService;

  List<DocumentModel> _documents = [];
  List<CategoryModel> _categories = [];
  List<DocumentTypeModel> _documentTypes = [];

  // New lookup maps for faster access
  Map<String, DocumentTypeModel> _documentTypesMap = {};
  Map<String, CategoryModel> _categoriesMap = {};
  Map<String, DocumentModel> _documentsMap = {};

  bool _isLoading = false;
  String? _error;

  DocumentProvider() {
    _documentService = DocumentService(
      firestoreService: _firestoreService,
      storageService: _storageService,
    );
  }

  // Getters - unchanged
  List<DocumentModel> get documents => _documents;
  List<CategoryModel> get categories => _categories;
  List<DocumentTypeModel> get documentTypes => _documentTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered document getters - unchanged
  List<DocumentModel> getDocumentsByCategory(String categoryId) {
    return _documents.where((doc) => doc.categoryId == categoryId).toList();
  }

  List<DocumentModel> getDocumentsByType(String documentTypeId) {
    return _documents.where((doc) => doc.documentTypeId == documentTypeId).toList();
  }

  List<DocumentModel> get pendingDocuments {
    return _documents.where((doc) => doc.status == DocumentStatus.PENDING).toList();
  }

  List<DocumentModel> get approvedDocuments {
    return _documents.where((doc) => doc.status == DocumentStatus.APPROVED).toList();
  }

  List<DocumentModel> get rejectedDocuments {
    return _documents.where((doc) => doc.status == DocumentStatus.REJECTED).toList();
  }

  List<DocumentModel> get expiredDocuments {
    return _documents.where((doc) => doc.isExpired).toList();
  }

  // Initialize data - same method signature
  Future<void> initialize(String companyId) async {
    _setLoading(true);

    try {
      // Modified implementation to batch notifications
      await _batchFetchAllData(companyId);
    } catch (e) {
      _error = 'Failed to initialize data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // New helper method for batch fetching
  Future<void> _batchFetchAllData(String companyId) async {
    try {
      // Fetch categories and all document types without multiple notifications
      await _batchFetchCategories();

      // Fetch documents (this will reset _documents)
      final documents = await _firestoreService.getDocuments(
        companyId: companyId,
      );
      _documents = documents;

      // Build lookup maps for faster access
      _buildLookupMaps();

      // Only notify once after all data is loaded
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch data: $e';
      notifyListeners();
    }
  }

  // Helper to batch fetch categories and document types
  Future<void> _batchFetchCategories() async {
    try {
      // Fetch categories
      final categories = await _firestoreService.getCategories();
      _categories = categories;

      // Prepare list of futures for parallel fetching
      final futures = <Future>[];
      for (var category in _categories) {
        futures.add(_fetchDocTypesForCategory(category.id));
      }

      // Wait for all document types to be fetched
      await Future.wait(futures);
    } catch (e) {
      _error = 'Failed to fetch categories and document types: $e';
      throw e; // Re-throw to be caught by the calling method
    }
  }

  // Helper to fetch document types for a category
  Future<void> _fetchDocTypesForCategory(String categoryId) async {
    try {
      final documentTypes = await _firestoreService.getDocumentTypes(categoryId);

      // Add new document types and update existing ones
      for (var docType in documentTypes) {
        final index = _documentTypes.indexWhere((dt) => dt.id == docType.id);
        if (index >= 0) {
          _documentTypes[index] = docType;
        } else {
          _documentTypes.add(docType);
        }
      }
    } catch (e) {
      print('Error fetching document types for category $categoryId: $e');
    }
  }

  // Build lookup maps for faster access
  void _buildLookupMaps() {
    _categoriesMap = {for (var c in _categories) c.id: c};
    _documentTypesMap = {for (var dt in _documentTypes) dt.id: dt};
    _documentsMap = {for (var doc in _documents) doc.id: doc};
  }

  // Original methods kept for backward compatibility but optimized

  // Fetch categories - kept but optimized
  Future<void> fetchCategories() async {
    try {
      // Using batch fetch to avoid multiple notifications
      await _batchFetchCategories();
      notifyListeners(); // Only notify once at the end
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
      notifyListeners();
    }
  }

  // Fetch document types - kept but optimized
  Future<void> fetchDocumentTypes(String categoryId) async {
    try {
      final documentTypes = await _firestoreService.getDocumentTypes(categoryId);

      // Add new document types and update existing ones
      for (var docType in documentTypes) {
        final index = _documentTypes.indexWhere((dt) => dt.id == docType.id);
        if (index >= 0) {
          _documentTypes[index] = docType;
        } else {
          _documentTypes.add(docType);
        }
      }

      // Update document types map
      for (var docType in documentTypes) {
        _documentTypesMap[docType.id] = docType;
      }

      notifyListeners(); // Single notification
    } catch (e) {
      _error = 'Failed to fetch document types: $e';
      notifyListeners();
    }
  }

  // Fetch documents - unchanged signature but optimized
  Future<void> fetchDocuments({String? companyId, String? categoryId}) async {
    _setLoading(true);

    try {
      final documents = await _firestoreService.getDocuments(
        companyId: companyId,
        categoryId: categoryId,
      );

      if (categoryId != null) {
        // Update only documents for the specified category
        _documents.removeWhere((doc) => doc.categoryId == categoryId);
        _documents.addAll(documents);
      } else {
        // Replace all documents
        _documents = documents;
      }

      // Update documents map
      for (var doc in documents) {
        _documentsMap[doc.id] = doc;
      }

      notifyListeners(); // Single notification
    } catch (e) {
      _error = 'Failed to fetch documents: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get document by ID - unchanged but optimized with lookup map
  Future<DocumentModel?> getDocument(String documentId) async {
    // Check cache first
    if (_documentsMap.containsKey(documentId)) {
      return _documentsMap[documentId];
    }

    try {
      final document = await _firestoreService.getDocument(documentId);
      if (document != null) {
        _documentsMap[documentId] = document; // Update cache
      }
      return document;
    } catch (e) {
      _error = 'Failed to get document: $e';
      return null;
    }
  }

  // Rest of the methods are unchanged

  // Create document
  Future<DocumentModel?> createDocument({
    required UserModel? user,
    required String categoryId,
    required String documentTypeId,
    required List<dynamic> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
  }) async {
    _setLoading(true);

    try {
      final document = await _documentService.createDocument(
        user: user!,
        categoryId: categoryId,
        documentTypeId: documentTypeId,
        files: files,
        formData: formData,
        expiryDate: expiryDate,
        isNotApplicable: isNotApplicable,
      );

      if (document != null) {
        _documents.add(document);
        _documentsMap[document.id] = document; // Update lookup map
        notifyListeners();
      }

      return document;
    } catch (e) {
      _error = 'Failed to create document: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update document status
  Future<bool> updateDocumentStatus(
      String documentId,
      DocumentStatus status,
      String? comment,
      UserModel user,
      ) async {
    _setLoading(true);

    try {
      final result = await _documentService.updateDocumentStatus(
        documentId,
        status,
        comment,
        user,
      );

      if (result) {
        // Refresh the document
        final updatedDoc = await _firestoreService.getDocument(documentId);
        if (updatedDoc != null) {
          final index = _documents.indexWhere((doc) => doc.id == documentId);
          if (index >= 0) {
            _documents[index] = updatedDoc;
          }
          _documentsMap[documentId] = updatedDoc; // Update lookup map
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _error = 'Failed to update document status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add signature
  Future<bool> addSignature(
      String documentId,
      File signatureFile,
      UserModel user,
      ) async {
    _setLoading(true);

    try {
      final result = await _documentService.addSignature(
        documentId,
        signatureFile,
        user,
      );

      if (result) {
        // Refresh the document
        final updatedDoc = await _firestoreService.getDocument(documentId);
        if (updatedDoc != null) {
          final index = _documents.indexWhere((doc) => doc.id == documentId);
          if (index >= 0) {
            _documents[index] = updatedDoc;
          }
          _documentsMap[documentId] = updatedDoc; // Update lookup map
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _error = 'Failed to add signature: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add comment
  Future<bool> addComment(
      String documentId,
      String commentText,
      UserModel user,
      ) async {
    try {
      final result = await _documentService.addComment(
        documentId,
        commentText,
        user,
      );

      if (result) {
        // Refresh the document
        final updatedDoc = await _firestoreService.getDocument(documentId);
        if (updatedDoc != null) {
          final index = _documents.indexWhere((doc) => doc.id == documentId);
          if (index >= 0) {
            _documents[index] = updatedDoc;
          }
          _documentsMap[documentId] = updatedDoc; // Update lookup map
          notifyListeners();
        }
      }

      return result;
    } catch (e) {
      _error = 'Failed to add comment: $e';
      return false;
    }
  }

  // Calculate compliance percentage
  Future<double> getCompliancePercentage(String companyId) async {
    try {
      return await _documentService.calculateCompliancePercentage(companyId);
    } catch (e) {
      _error = 'Failed to calculate compliance percentage: $e';
      return 0.0;
    }
  }

  // Helper
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // New helper methods for direct lookups
  DocumentTypeModel? getDocumentTypeById(String id) {
    return _documentTypesMap[id];
  }

  CategoryModel? getCategoryById(String id) {
    return _categoriesMap[id];
  }
}
```

# lib\providers\route_provider.dart

```dart
import 'package:flutter/material.dart';

class RouteProvider extends ChangeNotifier {
  String _activeRoute = '/dashboard'; // Default to dashboard

  String get activeRoute => _activeRoute;

  void setActiveRoute(String route) {
    if (_activeRoute != route) {
      _activeRoute = route;
      notifyListeners();
    }
  }
}
```

# lib\providers\theme_provider.dart

```dart
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
```

# lib\routes\router.dart

```dart
import 'package:cropcompliance/views/admin/category_management_screen.dart';
import 'package:cropcompliance/views/admin/user_management_screen.dart';
import 'package:cropcompliance/views/audit_index/category_documents_screen.dart';
import 'package:flutter/material.dart';
import '../core/constants/route_constants.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/dashboard/dashboard_screen.dart';
import '../views/audit_tracker/audit_tracker_screen.dart';
import '../views/compliance_report/compliance_report_screen.dart';
import '../views/audit_index/audit_index_screen.dart';
import '../views/document_management/document_detail_screen.dart';
import '../views/document_management/document_upload_screen.dart';
import '../views/document_management/document_form_screen.dart';

class AppRouter {
  static String get initialRoute => RouteConstants.login;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.register:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteConstants.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case RouteConstants.auditTracker:
        return MaterialPageRoute(builder: (_) => const AuditTrackerScreen());
      case RouteConstants.complianceReport:
        return MaterialPageRoute(builder: (_) => const ComplianceReportScreen());
      case RouteConstants.auditIndex:
        return MaterialPageRoute(builder: (_) => const AuditIndexScreen());
      case RouteConstants.userManagement:
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case RouteConstants.categoryManagement:
        return MaterialPageRoute(builder: (_) => const CategoryManagementScreen());
      case RouteConstants.categoryDocuments:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => CategoryDocumentsScreen(
            categoryId: args['categoryId'],
            categoryName: args['categoryName'],
          ),
        );
      case RouteConstants.documentDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DocumentDetailScreen(documentId: args['documentId']),
        );
      case RouteConstants.documentUpload:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DocumentUploadScreen(
            categoryId: args['categoryId'],
            documentTypeId: args['documentTypeId'],
          ),
        );
      case RouteConstants.documentForm:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DocumentFormScreen(
            categoryId: args['categoryId'],
            documentTypeId: args['documentTypeId'],
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
```

# lib\theme\app_theme.dart

```dart
import 'package:flutter/material.dart';
import 'theme_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: ThemeConstants.primaryColor,
      colorScheme: ColorScheme.light(
        primary: ThemeConstants.primaryColor,
        secondary: ThemeConstants.accentColor,
        background: ThemeConstants.lightBackgroundColor,
      ),
      scaffoldBackgroundColor: ThemeConstants.lightBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeConstants.primaryColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: ThemeConstants.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: ThemeConstants.primaryColor,
        secondary: ThemeConstants.accentColor,
        background: ThemeConstants.darkBackgroundColor,
      ),
      scaffoldBackgroundColor: ThemeConstants.darkBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeConstants.darkAppBarColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

# lib\theme\theme_constants.dart

```dart
import 'package:flutter/material.dart';

class ThemeConstants {
  // Brand colors
  static const Color primaryColor = Color(0xFF43A047); // Refined modern green
  static const Color accentColor = Color(0xFFFDC060);  // Amber for highlights

  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFF0F2F5); // Soft neutral background
  static const Color lightCardColor = Colors.white;

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF1A1A1A); // Softer dark
  static const Color darkCardColor = Color(0xFF2C2C2C);       // Subtle elevation
  static const Color darkAppBarColor = Color(0xFF2C2C2C);

  // Status colors (muted for clean dashboard)
  static const Color pendingColor = Color(0xFFFFD54F);   // Soft amber
  static const Color approvedColor = Color(0xFF81C784);  // Pastel green
  static const Color rejectedColor = Color(0xFFE57373);  // Soft red
  static const Color expiredColor = Color(0xFFFF8A65);   // Salmon

  // Text colors
  static const Color primaryTextColor = Color(0xFF1E1E1E);     // Nearly black for strong contrast
  static const Color secondaryTextColor = Color(0xFF616161);   // Soft neutral gray
  static const Color lightTextColor = Colors.white;

  // Accent / border / subtle elements
  static const Color neutralAccent = Color(0xFF90A4AE); // Blue-grey for subtle elements

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double borderRadius = 12.0;
  static const double buttonRadius = 8.0;
}

```

# lib\views\admin\category_management_screen.dart

```dart
// views/admin/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _isLoading = false;
  String? _error;
  String? _selectedCompanyId;
  List<Map<String, dynamic>> _companies = [];
  Map<String, bool> _enabledCategories = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load companies
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList();

      // Set initial state
      setState(() {
        _companies = companies;
        if (companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = companies[0]['id'] as String;
        }
        _isLoading = false;
      });

      // Load enabled categories if company is selected
      if (_selectedCompanyId != null) {
        _loadEnabledCategories();
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEnabledCategories() async {
    if (_selectedCompanyId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if configuration exists
      final configDoc = await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(_selectedCompanyId)
          .get();

      Map<String, bool> enabledCategories = {};

      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        if (data.containsKey('enabledCategories')) {
          enabledCategories = Map<String, bool>.from(data['enabledCategories']);
        }
      }

      // Get all categories
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final allCategories = categoryProvider.categories;

      // Initialize missing categories as enabled by default
      for (var category in allCategories) {
        if (!enabledCategories.containsKey(category.id)) {
          enabledCategories[category.id] = true; // Enable by default
        }
      }

      setState(() {
        _enabledCategories = enabledCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading category configuration: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(_selectedCompanyId)
          .set({
        'enabledCategories': _enabledCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Category Management',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    Widget content;
    if (categoryProvider.isLoading || _isLoading) {
      content = const LoadingIndicator(message: 'Loading categories...');
    } else if (categoryProvider.error != null || _error != null) {
      content = ErrorDisplay(
        error: categoryProvider.error ?? _error ?? 'Unknown error',
        onRetry: _loadData,
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Categories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable or disable categories for specific companies.',
                    ),
                    const SizedBox(height: 16),

                    // Company selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Company',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCompanyId,
                      items: _companies.map((company) {
                        return DropdownMenuItem<String>(
                          value: company['id'] as String,
                          child: Text(company['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCompanyId = value;
                        });
                        _loadEnabledCategories();
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedCompanyId != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          ElevatedButton(
                            onPressed: _saveConfiguration,
                            child: const Text('Save Settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categoryProvider.categories.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final category = categoryProvider.categories[index];
                          return SwitchListTile(
                            title: Text(category.name),
                            subtitle: Text(category.description),
                            value: _enabledCategories[category.id] ?? true,
                            onChanged: (value) {
                              setState(() {
                                _enabledCategories[category.id] = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveConfiguration,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Save Category Settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'Category Management',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }
}
```

# lib\views\admin\user_management_screen.dart

```dart
import 'package:cropcompliance/providers/auth_provider.dart' as autPro;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/enums.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedCompanyId;
  UserRole _selectedRole = UserRole.USER;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _companies = [];
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load companies
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList();

      // Load users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final users = usersSnapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _companies = companies;
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCompanyId == null) {
      setState(() {
        _error = 'Please select a company';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Create user with Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': _selectedRole.toString().split('.').last,
          'companyId': _selectedCompanyId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Clear form and reload data
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _selectedRole = UserRole.USER;
        _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error creating user: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<autPro.AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'User Management',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    Widget content;
    if (_isLoading) {
      content = const LoadingIndicator(message: 'Loading user data...');
    } else if (_error != null) {
      content = ErrorDisplay(
        error: _error!,
        onRetry: _loadData,
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New User',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCompanyId,
                        items: _companies.map((company) {
                          return DropdownMenuItem<String>(
                            value: company['id'] as String,
                            child: Text(company['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCompanyId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<UserRole>(
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRole,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(role.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createUser,
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Create User'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Existing Users',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Chip(
                      label: Text(user.role.name),
                      backgroundColor: _getRoleColor(user.role),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'User Management',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return Colors.purple.shade100;
      case UserRole.AUDITER:
        return Colors.blue.shade100;
      case UserRole.USER:
        return Colors.green.shade100;
    }
  }
}
```

# lib\views\audit_index\audit_index_screen.dart

```dart
// views/audit_index/audit_index_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

class AuditIndexScreen extends StatefulWidget {
  const AuditIndexScreen({Key? key}) : super(key: key);

  @override
  State<AuditIndexScreen> createState() => _AuditIndexScreenState();
}

class _AuditIndexScreenState extends State<AuditIndexScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = categoryProvider.isLoading;
    final hasError = categoryProvider.error != null;
    final error = categoryProvider.error ?? '';

    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading categories...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      content = _buildCategoryList(categoryProvider);
    }

    return AppScaffoldWrapper(
      title: 'Audit Index',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildCategoryList(CategoryProvider categoryProvider) {
    // Filter out duplicates by creating a unique list of category IDs
    final categories = categoryProvider.categories;
    final uniqueIds = <String>{};
    final uniqueCategories = categories.where((category) =>
        uniqueIds.add(category.id)
    ).toList();

    if (uniqueCategories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uniqueCategories.length,
      itemBuilder: (context, index) {
        final category = uniqueCategories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getCategoryIcon(category.name),
              color: Theme.of(context).primaryColor,
            ),
            title: Text(category.name),
            subtitle: Text(
              category.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteConstants.categoryDocuments,
                arguments: {'categoryId': category.id, 'categoryName': category.name},
              );
            },
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('business') || name.contains('compliance')) {
      return Icons.business;
    } else if (name.contains('management')) {
      return Icons.settings;
    } else if (name.contains('employment')) {
      return Icons.people;
    } else if (name.contains('child') || name.contains('young')) {
      return Icons.child_care;
    } else if (name.contains('forced') || name.contains('labor prevention')) {
      return Icons.security;
    } else if (name.contains('wages') || name.contains('working')) {
      return Icons.payments;
    } else if (name.contains('association')) {
      return Icons.groups;
    } else if (name.contains('training')) {
      return Icons.school;
    } else if (name.contains('health') || name.contains('safety')) {
      return Icons.health_and_safety;
    } else if (name.contains('chemical') || name.contains('pesticide')) {
      return Icons.science;
    } else if (name.contains('service') || name.contains('provider')) {
      return Icons.handyman;
    } else if (name.contains('environmental') || name.contains('community')) {
      return Icons.eco;
    }

    return Icons.folder;
  }
}
```

# lib\views\audit_index\category_documents_screen.dart

```dart
// views/audit_index/category_documents_screen.dart
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_model.dart';
import '../../models/enums.dart';
import '../../core/constants/route_constants.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';

class CategoryDocumentsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDocumentsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryDocumentsScreen> createState() => _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  String? _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await documentProvider.initialize(authProvider.currentUser!.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading;
    final hasError = documentProvider.error != null;
    final error = documentProvider.error ?? '';

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.categoryName,
        showBackButton: true,
      ),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading documents...')
          : hasError
          ? ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      )
          : Column(
        children: [
          _buildFilterControls(context),
          Expanded(
            child: _buildDocumentTable(documentProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status dropdown
          Container(
            height: 42,
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _statusFilter,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('All Statuses'),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                borderRadius: BorderRadius.circular(8),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Statuses'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'APPROVED',
                    child: Text('Approved'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'PENDING',
                    child: Text('Pending'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'REJECTED',
                    child: Text('Rejected'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'EXPIRED',
                    child: Text('Expired'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'NOT_APPLICABLE',
                    child: Text('Not Applicable'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
              ),
            ),
          ),

          // Search field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTable(DocumentProvider documentProvider) {
    // Get documents for this category
    var documents = documentProvider.getDocumentsByCategory(widget.categoryId);

    // Filter by status if selected
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      if (_statusFilter == 'APPROVED') {
        documents = documents.where((doc) => doc.isComplete).toList();
      } else if (_statusFilter == 'PENDING') {
        documents = documents.where((doc) => doc.isPending).toList();
      } else if (_statusFilter == 'REJECTED') {
        documents = documents.where((doc) => doc.isRejected).toList();
      } else if (_statusFilter == 'EXPIRED') {
        documents = documents.where((doc) => doc.isExpired).toList();
      } else if (_statusFilter == 'NOT_APPLICABLE') {
        documents = documents.where((doc) => doc.isNotApplicable).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final documentTypes = documentProvider.documentTypes;

      documents = documents.where((doc) {
        DocumentTypeModel? documentType;
        try {
          documentType = documentTypes.firstWhere((dt) => dt.id == doc.documentTypeId) as DocumentTypeModel?;
        } catch (_) {
          documentType = null;
        }

        if (documentType != null) {
          return documentType.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }

        return false;
      }).toList();
    }

    if (documents.isEmpty) {
      return const Center(
        child: Text('No documents found for this category'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Document Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Uploaded Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Width for actions column
              ],
            ),
          ),
          const Divider(height: 0),

          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final document = documents[index];
                DocumentTypeModel? documentType;
                try {
                  documentType = documentProvider.documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
                } catch (_) {
                  documentType = null;
                }

                final documentName = documentType?.name ?? 'Unknown Document Type';

                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Document Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            documentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Expiry Date
                        Expanded(
                          flex: 2,
                          child: Text(
                            document.expiryDate != null
                                ? DateFormat('MMM d, y').format(document.expiryDate!)
                                : 'No Expiry',
                            style: TextStyle(
                              color: document.isExpired
                                  ? Colors.red
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                        // Status
                        Expanded(
                          flex: 2,
                          child: document.isNotApplicable
                              ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Not Applicable',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          )
                              : StatusBadge(
                            status: document.status,
                            isExpired: document.isExpired,
                          ),
                        ),
                        // Uploaded Date
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat('MMM d, y').format(document.createdAt),
                          ),
                        ),
                        // Action button
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Document',
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.documentDetail,
                                arguments: {'documentId': document.id},
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

# lib\views\audit_index\widgets\document_filter.dart

```dart
import 'package:flutter/material.dart';
import '../../../models/category_model.dart';

class DocumentFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String? statusFilter;
  final String searchQuery;
  final Function(String?) onCategoryChanged;
  final Function(String?) onStatusChanged;
  final Function(String) onSearchChanged;
  final bool isDesktop;

  const DocumentFilter({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.statusFilter,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCategoryDropdown(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusDropdown(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSearchField(context),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildCategoryDropdown(context),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(context),
                  const SizedBox(height: 16),
                  _buildSearchField(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      value: selectedCategoryId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...categories.map((category) {
          return DropdownMenuItem<String?>(
            value: category.id,
            child: Text(category.name),
          );
        }).toList(),
      ],
      onChanged: onCategoryChanged,
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      value: statusFilter,
      items: const [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('All Statuses'),
        ),
        DropdownMenuItem<String?>(
          value: 'APPROVED',
          child: Text('Approved'),
        ),
        DropdownMenuItem<String?>(
          value: 'PENDING',
          child: Text('Pending'),
        ),
        DropdownMenuItem<String?>(
          value: 'REJECTED',
          child: Text('Rejected'),
        ),
        DropdownMenuItem<String?>(
          value: 'EXPIRED',
          child: Text('Expired'),
        ),
        DropdownMenuItem<String?>(
          value: 'NOT_APPLICABLE',
          child: Text('Not Applicable'),
        ),
      ],
      onChanged: onStatusChanged,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Search',
        hintText: 'Search by document type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      controller: TextEditingController(text: searchQuery),
      onChanged: onSearchChanged,
    );
  }
}
```

# lib\views\audit_index\widgets\document_list_item.dart

```dart
import 'package:cropcompliance/models/category_model.dart';
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/document_model.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../shared/status_badge.dart';

class DocumentListItem extends StatelessWidget {
  final DocumentModel document;
  final DocumentProvider documentProvider;
  final CategoryProvider categoryProvider;

  const DocumentListItem({
    Key? key,
    required this.document,
    required this.documentProvider,
    required this.categoryProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get category and document type names
    final categories = categoryProvider.categories;
    CategoryModel? category;
    try {
      category = categories.firstWhere((c) => c.id == document.categoryId) as CategoryModel?;
    } catch (_) {
      category = null;
    }

    final documentTypes = documentProvider.documentTypes;
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    final categoryName = category?.name ?? 'Unknown Category';
    final documentTypeName = documentType?.name ?? 'Unknown Document Type';

    return Card(
        margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
    ),
    child: InkWell(
    onTap: () {
    Navigator.of(context).pushNamed(
    RouteConstants.documentDetail,
    arguments: {'documentId': document.id},
    );
    },
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        documentTypeName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        'Category: $categoryName',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
    ),
    ),
      StatusBadge(
        status: document.status,
        isExpired: document.isExpired,
      ),
    ],
    ),
      const Divider(height: 24),
      Row(
        children: [
          _buildInfoItem(
            context,
            'Last Updated',
            DateFormat('MMM d, y').format(document.updatedAt),
            Icons.update,
          ),
          const SizedBox(width: 16),
          if (document.expiryDate != null)
            _buildInfoItem(
              context,
              'Expires',
              DateFormat('MMM d, y').format(document.expiryDate!),
              Icons.event,
              isExpired: document.isExpired,
            ),
          const Spacer(),
          if (document.fileUrls.isNotEmpty)
            _buildInfoItem(
              context,
              'Files',
              document.fileUrls.length.toString(),
              Icons.attach_file,
            ),
          if (document.fileUrls.isNotEmpty && document.signatures.isNotEmpty)
            const SizedBox(width: 16),
          if (document.signatures.isNotEmpty)
            _buildInfoItem(
              context,
              'Signatures',
              document.signatures.length.toString(),
              Icons.draw,
            ),
          if ((document.fileUrls.isNotEmpty || document.signatures.isNotEmpty) && document.comments.isNotEmpty)
            const SizedBox(width: 16),
          if (document.comments.isNotEmpty)
            _buildInfoItem(
              context,
              'Comments',
              document.comments.length.toString(),
              Icons.comment,
            ),
        ],
      ),
      if (document.comments.isNotEmpty && document.isRejected) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejection Comment:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                document.comments.first.text,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
    ),
    ),
    ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context,
      String label,
      String value,
      IconData icon, {
        bool isExpired = false,
      }) {
    final textColor = isExpired ? Colors.red : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: textColor ?? Colors.grey,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

# lib\views\audit_tracker\audit_tracker_screen.dart

```dart
import 'package:cropcompliance/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../models/document_model.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'dart:developer' as developer;

class AuditTrackerScreen extends StatefulWidget {
  const AuditTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AuditTrackerScreen> createState() => _AuditTrackerScreenState();
}

class _AuditTrackerScreenState extends State<AuditTrackerScreen> {
  bool _showDocuments = true; // Toggle between Documents and Audit List views
  Map<String, bool> _expandedCategories = {};
  Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    developer.log('AuditTrackerScreen - initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('AuditTrackerScreen - post frame callback triggered');
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _initializeData started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - authProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - documentProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - categoryProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    if (authProvider.currentUser != null) {
      developer.log('AuditTrackerScreen - User is logged in, initializing data');

      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - Starting category initialization');
      await categoryProvider.initialize();
      developer.log('AuditTrackerScreen - Category initialization completed: ${_stopwatch.elapsedMilliseconds}ms');

      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - Starting document initialization with companyId: ${authProvider.currentUser!.companyId}');
      await documentProvider.initialize(authProvider.currentUser!.companyId);
      developer.log('AuditTrackerScreen - Document initialization completed: ${_stopwatch.elapsedMilliseconds}ms');
      developer.log('AuditTrackerScreen - Document count: ${documentProvider.documents.length}');
      developer.log('AuditTrackerScreen - Document types count: ${documentProvider.documentTypes.length}');
    } else {
      developer.log('AuditTrackerScreen - No user logged in, skipping data initialization');
    }

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _initializeData completed: ${_stopwatch.elapsedMilliseconds}ms');
  }

  @override
  Widget build(BuildContext context) {
    developer.log('AuditTrackerScreen - build method called');
    _stopwatch.reset();
    _stopwatch.start();

    final authProvider = Provider.of<AuthProvider>(context);
    developer.log('AuditTrackerScreen - build: authProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final documentProvider = Provider.of<DocumentProvider>(context);
    developer.log('AuditTrackerScreen - build: documentProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final categoryProvider = Provider.of<CategoryProvider>(context);
    developer.log('AuditTrackerScreen - build: categoryProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    if (authProvider.currentUser == null) {
      developer.log('AuditTrackerScreen - build: No user logged in, showing login prompt');
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    developer.log('AuditTrackerScreen - build: isLoading=$isLoading, hasError=$hasError');

    Widget content;
    if (isLoading) {
      developer.log('AuditTrackerScreen - build: Showing loading indicator');
      content = const LoadingIndicator(message: 'Loading audit data...');
    } else if (hasError) {
      developer.log('AuditTrackerScreen - build: Showing error: $error');
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - build: Starting to build content sections');

      developer.log('AuditTrackerScreen - build: Building KPI section');
      final kpiSection = _buildKPISection(documentProvider);
      developer.log('AuditTrackerScreen - build: KPI section built: ${_stopwatch.elapsedMilliseconds}ms');

      developer.log('AuditTrackerScreen - build: Building toggle buttons');
      final toggleButtons = _buildViewToggleButtons();
      developer.log('AuditTrackerScreen - build: Toggle buttons built: ${_stopwatch.elapsedMilliseconds}ms');

      developer.log('AuditTrackerScreen - build: Preparing main content view (documents or audit list)');
      final mainContent = _showDocuments
          ? _buildDocumentsView(documentProvider, categoryProvider)
          : _buildAuditListView(documentProvider, categoryProvider);
      developer.log('AuditTrackerScreen - build: Main content built: ${_stopwatch.elapsedMilliseconds}ms');

      content = Column(
        children: [
          kpiSection,
          toggleButtons,
          Expanded(child: mainContent),
        ],
      );
      developer.log('AuditTrackerScreen - build: Content column assembled: ${_stopwatch.elapsedMilliseconds}ms');
    }

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - build method completed: ${_stopwatch.elapsedMilliseconds}ms');

    return AppScaffoldWrapper(
      title: 'Compliance Tracker',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildKPISection(DocumentProvider documentProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildKPISection started');

    final totalDocuments = documentProvider.documentTypes.length;
    final uploadedDocuments = documentProvider.documents.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final rejectedDocuments = documentProvider.rejectedDocuments.length;

    developer.log('AuditTrackerScreen - KPI counts - '
        'total: $totalDocuments, '
        'uploaded: $uploadedDocuments, '
        'approved: $approvedDocuments, '
        'pending: $pendingDocuments, '
        'rejected: $rejectedDocuments');

    // Calculate completion percentage
    double completionPercentage = 0;
    if (totalDocuments > 0) {
      completionPercentage = (uploadedDocuments / totalDocuments) * 100;
    }

    // Calculate approval rate percentage
    double approvalRate = 0;
    if (uploadedDocuments > 0) {
      approvalRate = (approvedDocuments / uploadedDocuments) * 100;
    }

    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final result = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit Compliance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          isSmallScreen
              ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Completion',
                      '$uploadedDocuments/$totalDocuments',
                      '${completionPercentage.toStringAsFixed(1)}%',
                      Colors.blue,
                      Icons.insert_chart,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKPICard(
                      'Approval',
                      '$approvedDocuments/$uploadedDocuments',
                      '${approvalRate.toStringAsFixed(1)}%',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Pending',
                      '$pendingDocuments',
                      pendingDocuments > 0
                          ? "Action needed"
                          : "All clear",
                      Colors.orange,
                      Icons.hourglass_empty,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKPICard(
                      'Rejected',
                      '$rejectedDocuments',
                      rejectedDocuments > 0
                          ? "Fix required"
                          : "All clear",
                      Colors.red,
                      Icons.error_outline,
                    ),
                  ),
                ],
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Completion Rate',
                  '$uploadedDocuments/$totalDocuments',
                  '${completionPercentage.toStringAsFixed(1)}%',
                  Colors.blue,
                  Icons.insert_chart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Approval Rate',
                  '$approvedDocuments/$uploadedDocuments',
                  '${approvalRate.toStringAsFixed(1)}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Pending Review',
                  '$pendingDocuments',
                  pendingDocuments > 0 ? "Action needed" : "All clear",
                  Colors.orange,
                  Icons.hourglass_empty,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Rejected Items',
                  '$rejectedDocuments',
                  rejectedDocuments > 0 ? "Needs attention" : "All clear",
                  Colors.red,
                  Icons.error_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildKPISection completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  // KPI Card Widget
  Widget _buildKPICard(
      String title, String value, String subtitle, Color color, IconData icon) {
    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: isSmallScreen
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      )
          : Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor: _showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Action Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !_showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor:
                !_showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Audit Checklist',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // State variable for showing approved documents
  bool _showApprovedDocuments = false;

  // Documents View (Action Items)
  Widget _buildDocumentsView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildDocumentsView started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role;
    final isAdmin = currentUserRole == UserRole.ADMIN;

    // Filter documents based on the _showApprovedDocuments toggle
    final documents = _showApprovedDocuments
        ? documentProvider.documents
        .where((doc) => doc.status == DocumentStatus.APPROVED)
        .toList()
        : documentProvider.documents
        .where((doc) => doc.status != DocumentStatus.APPROVED)
        .toList();

    developer.log('AuditTrackerScreen - Filtered ${documents.length} documents to display');

    if (documents.isEmpty) {
      developer.log('AuditTrackerScreen - No documents to display in this filter');
      return Center(
        child: Text(_showApprovedDocuments
            ? 'No approved documents'
            : 'No pending or rejected documents'),
      );
    }

    // Add a filter option at the top
    final result = Column(
      children: [
        // Filter toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Filter: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Action Items'),
                selected: !_showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = false;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Approved Documents'),
                selected: _showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = true;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];

              // Find document type and category details
              DocumentTypeModel? documentType;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                documentType = documentProvider.documentTypes
                    .firstWhere((dt) => dt.id == document.documentTypeId)
                as DocumentTypeModel?;
                developer.log('AuditTrackerScreen - Found document type for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (_) {
                developer.log('AuditTrackerScreen - Document type not found for document ${index+1}/${documents.length}');
                documentType = null;
              }

              // Find category details
              CategoryModel? category;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                category = categoryProvider.categories
                    .firstWhere((c) => c.id == document.categoryId);
                developer.log('AuditTrackerScreen - Found category for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (e) {
                developer.log('AuditTrackerScreen - Category not found for document ${index+1}/${documents.length}: ${e.toString()}');
                // Category not found, create a placeholder
                category = CategoryModel(
                  id: document.categoryId,
                  name: 'Unknown Category',
                  description: '',
                  order: 0,
                );
              }

              final documentName =
                  documentType?.name ?? 'Unknown Document Type';
              final categoryName = category.name;

              // Check if we're on a small screen
              final isSmallScreen = MediaQuery.of(context).size.width < 600;

              _stopwatch.reset();
              _stopwatch.start();
              final card = Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: isSmallScreen
                    ? _buildMobileDocumentCard(
                    document, documentName, categoryName, isAdmin)
                    : _buildDesktopDocumentCard(
                    document, documentName, categoryName, isAdmin),
              );
              developer.log('AuditTrackerScreen - Built card for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');

              return card;
            },
          ),
        ),
      ],
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildDocumentsView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  // Mobile document card with comments
  Widget _buildMobileDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category info
          Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expiry date
          if (document.expiryDate != null)
            Text(
              'Expires: ${DateFormat('MMM d, y').format(document.expiryDate!)}',
              style: TextStyle(
                fontSize: 13,
                color: document.isExpired ? Colors.red : Colors.grey.shade700,
              ),
            ),

          // Comments section
          if (document.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Comments:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            ...document.comments.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y').format(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 12),

          // Add resubmit button for rejected documents
          if (document.status == DocumentStatus.REJECTED) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text('Resubmit'),
                onPressed: () {
                  // Navigate to document upload/form screen with existing document ID
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentUpload,
                    arguments: {
                      'categoryId': document.categoryId,
                      'documentTypeId': document.documentTypeId,
                      'documentId': document.id,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Update button for admin
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Desktop document card with comments
  Widget _buildDesktopDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {
    return Column(
      children: [
        // Card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  document.expiryDate != null
                      ? 'Expires: ${DateFormat('MMM d, y').format(document.expiryDate!)}'
                      : 'No Expiry Date',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    document.isExpired ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Not Applicable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
              ),
            ],
          ),
        ),

        // Description row with category and buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              // Add resubmit button for rejected documents
              if (document.status == DocumentStatus.REJECTED)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 16),
                    label: const Text('Resubmit'),
                    onPressed: () {
                      // Navigate to document upload/form screen with existing document ID
                      Navigator.of(context).pushNamed(
                        RouteConstants.documentUpload,
                        arguments: {
                          'categoryId': document.categoryId,
                          'documentTypeId': document.documentTypeId,
                          'documentId': document.id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),

              if (isAdmin)
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),

        // Add comments section
        if (document.comments.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...document.comments.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y')
                                        .format(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAuditListView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildAuditListView started');

    final categories = categoryProvider.categories;
    developer.log('AuditTrackerScreen - Categories count: ${categories.length}');

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final result = ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        developer.log('AuditTrackerScreen - Building category item ${index+1}/${categories.length}');

        final category = categories[index];

        // Initialize expandedCategories map entry if needed
        if (!_expandedCategories.containsKey(category.id)) {
          _expandedCategories[category.id] = false;
        }

        final card = Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              // Category header
              ListTile(
                leading: Icon(
                  _getCategoryIcon(category.name),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    _expandedCategories[category.id]!
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedCategories[category.id] =
                      !_expandedCategories[category.id]!;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _expandedCategories[category.id] =
                    !_expandedCategories[category.id]!;
                  });
                },
              ),

              // Document types list (expandable)
              if (_expandedCategories[category.id]!) ...[
                const Divider(height: 1),
                _buildDocumentTypesList(
                    category.id, documentProvider, isSmallScreen),
              ],
            ],
          ),
        );

        developer.log('AuditTrackerScreen - Built category item ${index+1}/${categories.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return card;
      },
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildAuditListView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  Widget _buildDocumentTypesList(String categoryId,
      DocumentProvider documentProvider, bool isSmallScreen) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildDocumentTypesList started for category: $categoryId');

    final documentTypes = documentProvider.documentTypes
        .where((dt) => dt.categoryId == categoryId)
        .toList();

    developer.log('AuditTrackerScreen - Document types for category $categoryId: ${documentTypes.length}');

    if (documentTypes.isEmpty) {
      developer.log('AuditTrackerScreen - No document types found for category: $categoryId');
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No document types found for this category'),
      );
    }

    final result = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentTypes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        developer.log('AuditTrackerScreen - Building document type ${index+1}/${documentTypes.length} for category: $categoryId');

        final documentType = documentTypes[index];

        // Check if this document type has been uploaded
        final existingDocuments = documentProvider.documents
            .where((doc) => doc.documentTypeId == documentType.id)
            .toList();

        developer.log('AuditTrackerScreen - Found ${existingDocuments.length} existing documents for type: ${documentType.id}');

        final hasDocument = existingDocuments.isNotEmpty;
        final documentStatus = hasDocument
            ? existingDocuments.first.isNotApplicable
            ? 'Not Applicable'
            : existingDocuments.first.status.name
            : 'Not Uploaded';

        final listItem = isSmallScreen
            ? _buildMobileDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments)
            : _buildDesktopDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments);

        developer.log('AuditTrackerScreen - Built document type ${index+1}/${documentTypes.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return listItem;
      },
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildDocumentTypesList completed for category $categoryId: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  Widget _buildMobileDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentType.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            _getDocumentTypeDescription(documentType),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusChip(documentStatus),
              const Spacer(),
              if (!hasDocument ||
                  (hasDocument && existingDocuments.first.isRejected))
                OutlinedButton(
                  onPressed: () =>
                      _navigateToDocumentUpload(context, documentType),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Upload'),
                ),
              if (hasDocument) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'View Document',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': existingDocuments.first.id},
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(documentType.name),
      subtitle: Text(
        _getDocumentTypeDescription(documentType),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(documentStatus),
          const SizedBox(width: 8),
          if (!hasDocument ||
              (hasDocument && existingDocuments.first.isRejected))
            OutlinedButton(
              onPressed: () => _navigateToDocumentUpload(context, documentType),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Upload'),
            ),
          if (hasDocument)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'View Document',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RouteConstants.documentDetail,
                  arguments: {'documentId': existingDocuments.first.id},
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'APPROVED':
      case 'Approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'PENDING':
      case 'Pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'REJECTED':
      case 'Rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'Not Applicable':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      case 'Not Uploaded':
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getDocumentTypeDescription(DocumentTypeModel documentType) {
    List<String> properties = [];

    if (documentType.allowMultipleDocuments) {
      properties.add('Multiple documents allowed');
    }

    if (documentType.hasExpiryDate) {
      properties.add('Requires expiry date');
    }

    if (documentType.requiresSignature) {
      properties.add('Requires signature');
    }

    if (documentType.hasNotApplicableOption) {
      properties.add('Can be marked N/A');
    }

    return properties.join(' • ');
  }

  void _navigateToDocumentUpload(
      BuildContext context, DocumentTypeModel documentType) {
    developer.log('AuditTrackerScreen - Navigating to document upload/form: ${documentType.id}');

    if (documentType.isUploadable) {
      Navigator.of(context).pushNamed(
        RouteConstants.documentUpload,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    } else {
      Navigator.of(context).pushNamed(
        RouteConstants.documentForm,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('business') || name.contains('compliance')) {
      return Icons.business;
    } else if (name.contains('management')) {
      return Icons.settings;
    } else if (name.contains('employment')) {
      return Icons.people;
    } else if (name.contains('child') || name.contains('young')) {
      return Icons.child_care;
    } else if (name.contains('forced') || name.contains('labor prevention')) {
      return Icons.security;
    } else if (name.contains('wages') || name.contains('working')) {
      return Icons.payments;
    } else if (name.contains('association')) {
      return Icons.groups;
    } else if (name.contains('training')) {
      return Icons.school;
    } else if (name.contains('health') || name.contains('safety')) {
      return Icons.health_and_safety;
    } else if (name.contains('chemical') || name.contains('pesticide')) {
      return Icons.science;
    } else if (name.contains('service') || name.contains('provider')) {
      return Icons.handyman;
    } else if (name.contains('environmental') || name.contains('community')) {
      return Icons.eco;
    }

    return Icons.folder;
  }
}
```

# lib\views\audit_tracker\widgets\category_progress_bar.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../models/document_model.dart';

class CategoryProgressBar extends StatelessWidget {
  final String categoryId;

  const CategoryProgressBar({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final documents = documentProvider.getDocumentsByCategory(categoryId);

    // Calculate progress
    if (documents.isEmpty) {
      return _buildProgressBar(context, 0, 'No documents available');
    }

    int completedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;

    for (var doc in documents) {
      if (doc.isComplete || doc.isNotApplicable) {
        completedCount++;
      } else if (doc.isPending) {
        pendingCount++;
      } else if (doc.isRejected) {
        rejectedCount++;
      }
    }

    final percentage = (completedCount / documents.length) * 100;
    final statusText = 'Completed: $completedCount / ${documents.length} (${percentage.toStringAsFixed(0)}%)';

    return Column(
      children: [
        _buildProgressBar(context, percentage / 100, statusText),
        const SizedBox(height: 8),
        _buildLegend(context, documents.length, completedCount, pendingCount, rejectedCount),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double value, String statusText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 16,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForPercentage(value),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLegend(
      BuildContext context,
      int total,
      int completed,
      int pending,
      int rejected,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, 'Completed', Colors.green, completed, total),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Pending', Colors.orange, pending, total),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Rejected', Colors.red, rejected, total),
      ],
    );
  }

  Widget _buildLegendItem(
      BuildContext context,
      String label,
      Color color,
      int count,
      int total,
      ) {
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count, ${percentage.toStringAsFixed(0)}%)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}
```

# lib\views\audit_tracker\widgets\document_status_list.dart

```dart
import 'package:cropcompliance/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/document_model.dart';
import '../../../models/document_type_model.dart';
import '../../../models/enums.dart';
import '../../shared/status_badge.dart';

class DocumentStatusList extends StatelessWidget {
  final String categoryId;

  const DocumentStatusList({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final documentTypes = categoryProvider.getDocumentTypes(categoryId);

    if (documentTypes.isEmpty) {
      return const Center(
        child: Text('No document types found for this category'),
      );
    }

    return ListView.builder(
      itemCount: documentTypes.length,
      itemBuilder: (context, index) {
        final documentType = documentTypes[index];
        final documents = documentProvider.getDocumentsByType(documentType.id);

        return _buildDocumentTypeCard(
          context,
          documentType,
          documents,
        );
      },
    );
  }

  Widget _buildDocumentTypeCard(
      BuildContext context,
      DocumentTypeModel documentType,
      List<DocumentModel> documents,
      ) {
    final hasDocuments = documents.isNotEmpty;
    final isNotApplicable = hasDocuments && documents.first.isNotApplicable;
    final status = hasDocuments ? documents.first.status : DocumentStatus.PENDING;
    final isExpired = hasDocuments && documents.first.isExpired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentType.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDocumentTypeDescription(documentType),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (hasDocuments && !isNotApplicable)
                  StatusBadge(
                    status: status,
                    isExpired: isExpired,
                  )
                else if (isNotApplicable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Not Applicable',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (documentType.isUploadable)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentUpload,
                          arguments: {
                            'categoryId': categoryId,
                            'documentTypeId': documentType.id,
                          },
                        );
                      },
                    ),
                  ),
                if (documentType.isUploadable && !documentType.isUploadable)
                  const SizedBox(width: 8),
                if (!documentType.isUploadable)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_document),
                      label: const Text('Fill Form'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentForm,
                          arguments: {
                            'categoryId': categoryId,
                            'documentTypeId': documentType.id,
                          },
                        );
                      },
                    ),
                  ),
                if (hasDocuments)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentDetail,
                          arguments: {'documentId': documents.first.id},
                        );
                      },
                      tooltip: 'View Document',
                    ),
                  ),
                if (documentType.hasNotApplicableOption)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.not_interested,
                        color: isNotApplicable ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        _showNotApplicableDialog(context, documentType);
                      },
                      tooltip: 'Mark as Not Applicable',
                    ),
                  ),
              ],
            ),
            if (hasDocuments && documents.first.isRejected && documents.first.comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documents.first.comments.first.text,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDocumentTypeDescription(DocumentTypeModel documentType) {
    List<String> descriptions = [];

    if (documentType.allowMultipleDocuments) {
      descriptions.add('Multiple documents allowed');
    }

    if (documentType.hasExpiryDate) {
      descriptions.add('Requires expiry date');
    }

    if (documentType.requiresSignature) {
      final count = documentType.signatureCount;
      descriptions.add('Requires $count signature${count > 1 ? 's' : ''}');
    }

    return descriptions.join(' • ');
  }

  void _showNotApplicableDialog(
      BuildContext context,
      DocumentTypeModel documentType,
      ) {

    print("Need to fix this as the authProvider.currentUser is apperintly flucking null");

    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Mark as Not Applicable'),
    //     content: Text(
    //       'Are you sure you want to mark "${documentType.name}" as not applicable to your business?',
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () {
    //           Navigator.of(context).pop();
    //         },
    //         child: const Text('Cancel'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () {
    //           final documentProvider = Provider.of<DocumentProvider>(
    //             context,
    //             listen: false,
    //           );
    //           final authProvider = Provider.of<AuthProvider>(
    //             context,
    //             listen: false,
    //           );
    //
    //           if (authProvider.currentUser != null) {
    //            var user = authProvider.currentUser;
    //             documentProvider.createDocument(
    //               user: user!,
    //               categoryId: categoryId,
    //               documentTypeId: documentType.id,
    //               files: [],
    //               isNotApplicable: true,
    //             );
    //           }
    //
    //           Navigator.of(context).pop();
    //         },
    //         child: const Text('Mark as Not Applicable'),
    //       ),
    //     ],
    //   ),
    // );
  }
}
```

# lib\views\audit_tracker\widgets\document_upload_card.dart

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/document_type_model.dart';

class DocumentUploadCard extends StatefulWidget {
  final String categoryId;
  final DocumentTypeModel documentType;

  const DocumentUploadCard({
    Key? key,
    required this.categoryId,
    required this.documentType,
  }) : super(key: key);

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  // Changed to store information about each file
  List<FileUploadItem> _uploadItems = [];
  bool _isUploading = false;

  // Helper method to show toasts/snackbars
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: widget.documentType.allowMultipleDocuments,
        withData: kIsWeb, // Important: Get file bytes for web
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          // For web, we need a custom approach
          final newItems = result.files
              .where((file) => file.bytes != null && file.name != null)
              .map((file) {
            // Create a file-like object with the path as the filename
            final tempFile = File(file.name!);
            // Create a new upload item with file and bytes
            return FileUploadItem(
              file: tempFile,
              bytes: file.bytes!, // Store bytes for web uploads
              expiryDate: widget.documentType.hasExpiryDate ? null : DateTime.now().add(const Duration(days: 365)), // Default expiry date if needed
            );
          }).toList();

          setState(() {
            _uploadItems.addAll(newItems);
          });

          print("DEBUG: Web files selected: ${newItems.length}");
          for (var item in newItems) {
            print("DEBUG: Web file: ${item.file.path} with ${item.bytes!.length} bytes");
          }
        } else {
          // For mobile/desktop
          final newItems = result.files
              .where((file) => file.path != null)
              .map((file) => FileUploadItem(
            file: File(file.path!),
            bytes: null, // No bytes needed for mobile/desktop
            expiryDate: widget.documentType.hasExpiryDate ? null : DateTime.now().add(const Duration(days: 365)), // Default expiry date if needed
          ))
              .toList();

          setState(() {
            _uploadItems.addAll(newItems);
          });

          print("DEBUG: Mobile/desktop files selected: ${newItems.length}");
        }
      }
    } catch (e) {
      print('Error picking files: $e');
      _showToast('Error selecting files: $e', isError: true);
    }
  }

  Future<void> _selectExpiryDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _uploadItems[index].expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _uploadItems[index] = _uploadItems[index].copyWith(expiryDate: date);
      });

      // DEBUG: Print the selected date
      print("DEBUG: Selected expiry date for item $index: ${_uploadItems[index].expiryDate}");
      // Convert to Timestamp format for verification
      print("DEBUG: As milliseconds since epoch: ${_uploadItems[index].expiryDate?.millisecondsSinceEpoch}");
    }
  }

  String _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📎';
    }
  }

  Color _getFileColor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red.shade100;
      case 'doc':
      case 'docx':
        return Colors.blue.shade100;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _uploadDocuments() async {
    if (_uploadItems.isEmpty) {
      _showToast('Please select files to upload', isError: true);
      return;
    }

    // Check if any document with expiry date required is missing the date
    if (widget.documentType.hasExpiryDate) {
      final missingExpiryDates = _uploadItems.where((item) => item.expiryDate == null).isNotEmpty;
      if (missingExpiryDates) {
        _showToast('Please select an expiry date for all documents', isError: true);
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      if (authProvider.currentUser != null) {
        int successCount = 0;
        int failCount = 0;
        List<String> failedFiles = [];

        // Upload each document individually with its own expiry date
        for (var item in _uploadItems) {
          try {
            final filename = item.file.path.split('/').last;

            if (kIsWeb) {
              // For web
              final webFile = {
                'name': item.file.path,
                'bytes': item.bytes,
              };

              print("DEBUG: Uploading web file: ${item.file.path} with expiry date: ${item.expiryDate}");

              final document = await documentProvider.createDocument(
                user: authProvider.currentUser!,
                categoryId: widget.categoryId,
                documentTypeId: widget.documentType.id,
                files: [webFile], // Single file with its own expiry date
                expiryDate: item.expiryDate, // Individual expiry date for this file
              );

              if (document != null) {
                print("DEBUG: Document created with ID: ${document.id}");
                print("DEBUG: Document expiryDate: ${document.expiryDate}");
                successCount++;

                // Show individual success toast
                if (mounted) {
                  _showToast("Successfully uploaded: $filename", isError: false);
                }

                // Handle signature requirement for the last document
                if (mounted && item == _uploadItems.last && widget.documentType.requiresSignature) {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                }
              } else {
                // Document is null (upload failed)
                failCount++;
                failedFiles.add(filename);
                if (mounted) {
                  _showToast("Failed to upload: $filename", isError: true);
                }
              }
            } else {
              // For mobile/desktop
              print("DEBUG: Uploading file: ${item.file.path} with expiry date: ${item.expiryDate}");

              final document = await documentProvider.createDocument(
                user: authProvider.currentUser!,
                categoryId: widget.categoryId,
                documentTypeId: widget.documentType.id,
                files: [item.file], // Single file with its own expiry date
                expiryDate: item.expiryDate, // Individual expiry date for this file
              );

              if (document != null) {
                print("DEBUG: Document created with ID: ${document.id}");
                print("DEBUG: Document expiryDate: ${document.expiryDate}");
                successCount++;

                // Show individual success toast
                if (mounted) {
                  _showToast("Successfully uploaded: $filename", isError: false);
                }

                // Handle signature requirement for the last document
                if (mounted && item == _uploadItems.last && widget.documentType.requiresSignature) {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                }
              } else {
                // Document is null (upload failed)
                failCount++;
                failedFiles.add(filename);
                if (mounted) {
                  _showToast("Failed to upload: $filename", isError: true);
                }
              }
            }
          } catch (e) {
            // Handle individual file upload error
            final filename = item.file.path.split('/').last;
            print("ERROR uploading $filename: $e");
            failCount++;
            failedFiles.add(filename);
            if (mounted) {
              _showToast("Error uploading: $filename", isError: true);
            }
          }
        }

        // After all uploads complete, show summary toast and possibly pop the screen
        if (mounted) {
          if (successCount > 0 && failCount == 0) {
            _showToast("All documents uploaded successfully!", isError: false);
            // Only pop if all uploads were successful
            Navigator.of(context).pop();
          } else if (successCount > 0 && failCount > 0) {
            _showToast("$successCount uploaded, $failCount failed", isError: true);
            // If mixed results and all successful ones don't need signatures, pop
            if (!widget.documentType.requiresSignature) {
              Navigator.of(context).pop();
            }
          } else if (successCount == 0 && failCount > 0) {
            _showToast("All uploads failed", isError: true);
            // Don't pop on complete failure
          }
        }
      }
    } catch (e) {
      print("ERROR during document upload: $e");
      print("ERROR stack trace: ${StackTrace.current}");
      _showToast('Error uploading documents: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.documentType.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              widget.documentType.hasExpiryDate
                  ? 'Upload documents and set expiry dates for each'
                  : 'Upload documents for this category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),

            const Divider(height: 24),

            // Upload section
            if (_uploadItems.isEmpty) ... [
              GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload,
                          size: 42,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to select files',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: PDF, JPG, JPEG, PNG, DOC, DOCX',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ... [
              // Document list section
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Documents (${_uploadItems.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add More'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Document cards in a wrap layout (responsive to screen width)
              // Document cards in a wrap layout (responsive to screen width)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uploadItems.map((item) {
                  final filename = item.file.path.split('/').last;
                  final extension = filename.split('.').last.toUpperCase();

                  return Container(
                    width: 140, // Fixed width for consistency
                    // Remove fixed height to let content determine size
                    child: Card(
                      elevation: 1,
                      clipBehavior: Clip.antiAlias, // Ensures clean edges
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: item.expiryDate == null && widget.documentType.hasExpiryDate
                            ? const BorderSide(color: Colors.red, width: 1)
                            : BorderSide.none,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Important: Use minimum space needed
                        children: [
                          // File header with icon and remove button
                          Container(
                            decoration: BoxDecoration(
                              color: _getFileColor(filename),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getFileIcon(filename),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      extension,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _uploadItems.remove(item);
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                          ),

                          // File name
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                            child: Text(
                              filename,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          // File size for web
                          if (kIsWeb && item.bytes != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: Text(
                                "${(item.bytes!.length / 1024).toStringAsFixed(1)} KB",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // Remove the Spacer widget that was forcing expansion

                          // Expiry date section
                          if (widget.documentType.hasExpiryDate)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: GestureDetector(
                                onTap: () => _selectExpiryDate(_uploadItems.indexOf(item)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: item.expiryDate != null
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: item.expiryDate != null
                                          ? Colors.green.shade300
                                          : Colors.red.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Expires',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          item.expiryDate != null
                                              ? Text(
                                            '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          )
                                              : const Text(
                                            'Set date',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_uploadItems.length > 1
                        ? "Uploading Documents..."
                        : "Uploading Document..."),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_upload),
                    const SizedBox(width: 8),
                    Text(
                      _uploadItems.isNotEmpty
                          ? (_uploadItems.length > 1
                          ? "Upload ${_uploadItems.length} Documents"
                          : "Upload Document")
                          : "Select and Upload Documents",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Class to store file information with its expiry date
class FileUploadItem {
  final File file;
  final Uint8List? bytes; // Only used for web
  final DateTime? expiryDate;

  FileUploadItem({
    required this.file,
    this.bytes,
    this.expiryDate,
  });

  // Helper method to create a copy with updated fields
  FileUploadItem copyWith({
    File? file,
    Uint8List? bytes,
    DateTime? expiryDate,
  }) {
    return FileUploadItem(
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
```

# lib\views\auth\login_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:animate_do/animate_do.dart'; // Add this package to pubspec.yaml
import '../../providers/auth_provider.dart';
import '../../core/constants/route_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: "alissaTest1@gmail.com");
  final _passwordController = TextEditingController(text: "804080");
  // final _emailController = TextEditingController(text: "nathanTest1@gmail.com");
  // final _passwordController = TextEditingController(text: "123456");
  // final _emailController = "nathanTest2@gmail.com";
  // final _passwordController = "123456";
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient and designs
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              height: size.height * 0.5,
              width: size.width * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1), // Primary green with opacity
                shape: BoxShape.circle,
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              height: size.height * 0.5,
              width: size.width * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withOpacity(0.1), // Amber with opacity
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Card(
                      elevation: 10,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            children: [
                              // Left side with branding and imagery (only on desktop)
                              if (isDesktop)
                                Expanded(
                                  flex: 6,
                                  child: Container(
                                    height: 600,
                                    color: const Color(0xFF2E7D32),
                                    child: Stack(
                                      children: [
                                        // Decorative pattern
                                        Positioned.fill(
                                          child: Opacity(
                                            opacity: 0.1,
                                            child: GridPattern(
                                              size: 20,
                                              lineWidth: 1,
                                              lineColor: Colors.white,
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(40),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Logo and app name
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: SvgPicture.asset(
                                                      'assets/svg/logoIcon.svg',
                                                      width: 32,
                                                      height: 32,

                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  const Text(
                                                    'Crop Compliance',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 60),

                                              // Taglines
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 300),
                                                child: const Text(
                                                  'Simplified Compliance,',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 600),
                                                child: const Text(
                                                  'Guaranteed Success',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 24),

                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 900),
                                                child: Container(
                                                  width: 100,
                                                  height: 4,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFA000),
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 32),

                                              // Bullet points
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1200),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  'Streamlined document management',
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1400),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  'Real-time compliance tracking',
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1600),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  'Effortless audit preparation',
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 1800),
                                                child: _buildFeatureItem(
                                                  Icons.check_circle,
                                                  'Comprehensive compliance reports',
                                                ),
                                              ),

                                              const Spacer(),

                                              FadeInLeft(
                                                delay: const Duration(milliseconds: 2000),
                                                child: const Text(
                                                  '© 2025 Crop Compliance. All rights reserved.',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Right side with login form
                              Expanded(
                                flex: isDesktop ? 4 : 10,
                                child: Container(
                                  padding: EdgeInsets.all(isDesktop ? 40 : 24),
                                  color: Colors.white,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!isDesktop) ...[
                                        // Mobile logo and branding
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: SvgPicture.asset(
                                              'assets/svg/logoIcon.svg',
                                              width: 40,
                                              height: 40,

                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Center(
                                          child: Text(
                                            'Crop Compliance',
                                            style: TextStyle(
                                              color: Color(0xFF2E7D32),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                      ],

                                      // Welcome text
                                      FadeInUp(
                                        delay: const Duration(milliseconds: 300),
                                        child: Text(
                                          isDesktop ? 'Welcome back!' : 'Welcome back!',
                                          style: TextStyle(
                                            fontSize: isDesktop ? 32 : 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isDesktop ? 16 : 8),

                                      FadeInUp(
                                        delay: const Duration(milliseconds: 400),
                                        child: Text(
                                          'Enter your credentials to access your account',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isDesktop ? 40 : 24),

                                      // Login form
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Email field
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 500),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Email',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _emailController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Enter your email',
                                                      prefixIcon: Icon(
                                                        Icons.email_outlined,
                                                        color: Colors.grey[400],
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.grey[100],
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.emailAddress,
                                                    textInputAction: TextInputAction.next,
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter your email';
                                                      }
                                                      if (!value.contains('@')) {
                                                        return 'Please enter a valid email';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 24 : 16),

                                            // Password field
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 600),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Password',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  TextFormField(
                                                    controller: _passwordController,
                                                    decoration: InputDecoration(
                                                      hintText: 'Enter your password',
                                                      prefixIcon: Icon(
                                                        Icons.lock_outline,
                                                        color: Colors.grey[400],
                                                      ),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                          _obscurePassword
                                                              ? Icons.visibility_outlined
                                                              : Icons.visibility_off_outlined,
                                                          color: Colors.grey[400],
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _obscurePassword = !_obscurePassword;
                                                          });
                                                        },
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.grey[100],
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        vertical: 16,
                                                        horizontal: 16,
                                                      ),
                                                    ),
                                                    obscureText: _obscurePassword,
                                                    textInputAction: TextInputAction.done,
                                                    validator: (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter your password';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 16 : 12),

                                            // Remember me and forgot password
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 700),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Checkbox(
                                                          value: _rememberMe,
                                                          onChanged: (value) {
                                                            setState(() {
                                                              _rememberMe = value ?? false;
                                                            });
                                                          },
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          activeColor: const Color(0xFF2E7D32),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Remember me',
                                                        style: TextStyle(
                                                          color: Colors.grey[700],
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      // Handle forgot password
                                                    },
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: const Color(0xFF2E7D32),
                                                      padding: EdgeInsets.zero,
                                                      minimumSize: const Size(0, 0),
                                                    ),
                                                    child: const Text(
                                                      'Forgot Password?',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            SizedBox(height: isDesktop ? 32 : 24),

                                            // Login button
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 800),
                                              child: SizedBox(
                                                height: 56,
                                                child: ElevatedButton(
                                                  onPressed: authProvider.isLoading ? null : _login,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF2E7D32),
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    elevation: 2,
                                                  ),
                                                  child: authProvider.isLoading
                                                      ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                                  )
                                                      : const Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Error message
                                            if (authProvider.error != null) ...[
                                              const SizedBox(height: 16),
                                              FadeIn(
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.red.shade200,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red.shade700,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          authProvider.error!,
                                                          style: TextStyle(
                                                            color: Colors.red.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],

                                            SizedBox(height: isDesktop ? 48 : 32),

                                            // Sign up option
                                            FadeInUp(
                                              delay: const Duration(milliseconds: 900),
                                              child: Center(
                                                child: RichText(
                                                  text: TextSpan(
                                                    text: 'Don\'t have an account? ',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 14,
                                                    ),
                                                    children: [
                                                      TextSpan(
                                                        text: 'Contact Support',
                                                        style: TextStyle(
                                                          color: const Color(0xFF2E7D32),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFFA000),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// Grid pattern for the decorative background
class GridPattern extends StatelessWidget {
  final double size;
  final double lineWidth;
  final Color lineColor;

  const GridPattern({
    Key? key,
    required this.size,
    required this.lineWidth,
    required this.lineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(
        size: size,
        lineWidth: lineWidth,
        lineColor: lineColor,
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double size;
  final double lineWidth;
  final Color lineColor;

  GridPainter({
    required this.size,
    required this.lineWidth,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    for (double i = 0; i < canvasSize.width; i += size) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, canvasSize.height),
        paint,
      );
    }

    for (double i = 0; i < canvasSize.height; i += size) {
      canvas.drawLine(
        Offset(0, i),
        Offset(canvasSize.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

# lib\views\auth\register_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../core/services/firestore_service.dart';
import '../../models/company_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _createNewCompany = true;
  String? _selectedCompanyId;

  final FirestoreService _firestoreService = FirestoreService();
  List<CompanyModel> _companies = [];
  bool _isLoadingCompanies = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoadingCompanies = true;
    });

    final companies = await _firestoreService.getCompanies();

    setState(() {
      _companies = companies;
      _isLoadingCompanies = false;
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      String companyId = _selectedCompanyId ?? '';

      // Create new company if needed
      if (_createNewCompany) {
        final company = CompanyModel(
          id: '',
          name: _companyNameController.text.trim(),
          address: _addressController.text.trim(),
          createdAt: DateTime.now(),
        );

        companyId = await _firestoreService.addCompany(company) ?? '';
      }

      if (companyId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create company. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyId: companyId,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.agriculture,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Create an Account',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Company Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Switch(
                            value: _createNewCompany,
                            onChanged: (value) {
                              setState(() {
                                _createNewCompany = value;
                              });
                            },
                          ),
                          Text(_createNewCompany
                              ? 'New Company'
                              : 'Existing Company'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_createNewCompany) ...[
                        TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            prefixIcon: Icon(Icons.business),
                          ),
                          validator: (value) {
                            if (_createNewCompany &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Company Address',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (_createNewCompany &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter company address';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        _isLoadingCompanies
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Select Company',
                                  prefixIcon: Icon(Icons.business),
                                ),
                                value: _selectedCompanyId,
                                items: _companies.map((company) {
                                  return DropdownMenuItem<String>(
                                    value: company.id,
                                    child: Text(company.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCompanyId = value;
                                  });
                                },
                                validator: (value) {
                                  if (!_createNewCompany &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please select a company';
                                  }
                                  return null;
                                },
                              ),
                      ],
                      const SizedBox(height: 24),
                      if (authProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authProvider.error!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _register,
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Register'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed(RouteConstants.login);
                            },
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

```

# lib\views\compliance_report\compliance_report_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'widgets/report_summary.dart';
import 'widgets/document_status_table.dart';

class ComplianceReportScreen extends StatefulWidget {
  const ComplianceReportScreen({Key? key}) : super(key: key);

  @override
  State<ComplianceReportScreen> createState() => _ComplianceReportScreenState();
}

class _ComplianceReportScreenState extends State<ComplianceReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
      await documentProvider.initialize(authProvider.currentUser!.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading compliance data...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      // Determine the appropriate view based on screen size
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth >= 1200) {
        content = _buildDesktopView(context);
      } else if (screenWidth >= 600) {
        content = _buildTabletView(context);
      } else {
        content = _buildMobileView(context);
      }
    }

    return AppScaffoldWrapper(
      title: 'Compliance Report',
      backgroundColor: Colors.grey[100],
      child: content,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Generate and export report
          _exportReport();
        },
        tooltip: 'Export Report',
        child: const Icon(Icons.file_download),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 24),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 24),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 32),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  void _exportReport() {
    // In a real app, this would generate a PDF or Excel report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export functionality will be implemented in a future update'),
      ),
    );
  }
}
```

# lib\views\compliance_report\widgets\document_status_table.dart

```dart
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../models/category_model.dart';
import '../../../models/document_model.dart';
import '../../../models/enums.dart';
import '../../shared/status_badge.dart';

class DocumentStatusTable extends StatelessWidget {
  const DocumentStatusTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in categories) ...[
              _buildCategorySection(context, category, documentProvider),
              if (category != categories.last)
                const Divider(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context,
      CategoryModel category,
      DocumentProvider documentProvider,
      ) {
    final documents = documentProvider.getDocumentsByCategory(category.id);
    final totalDocuments = documents.length;

    // Calculate counts
    int approvedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;
    int expiredCount = 0;
    int notApplicableCount = 0;

    for (var doc in documents) {
      if (doc.isNotApplicable) {
        notApplicableCount++;
      } else if (doc.isExpired) {
        expiredCount++;
      } else if (doc.status == DocumentStatus.APPROVED) {
        approvedCount++;
      } else if (doc.status == DocumentStatus.PENDING) {
        pendingCount++;
      } else if (doc.status == DocumentStatus.REJECTED) {
        rejectedCount++;
      }
    }

    // Calculate compliance percentage
    double compliancePercentage = 0;
    if (totalDocuments > 0) {
      compliancePercentage = ((approvedCount + notApplicableCount) / totalDocuments) * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          category.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: compliancePercentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForPercentage(compliancePercentage / 100),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                '${compliancePercentage.toStringAsFixed(0)}% Compliant',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(label: Text('Document Type')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Last Updated')),
              DataColumn(label: Text('Expiry Date')),
              DataColumn(label: Text('Signatures')),
              DataColumn(label: Text('Comments')),
            ],
            rows: documents.map((document) {
              return _buildDocumentRow(context, document, documentProvider);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatusCount('Approved', approvedCount, Colors.green),
            _buildStatusCount('Pending', pendingCount, Colors.orange),
            _buildStatusCount('Rejected', rejectedCount, Colors.red),
            _buildStatusCount('Expired', expiredCount, Colors.red.shade700),
            _buildStatusCount('Not Applicable', notApplicableCount, Colors.grey),
          ],
        ),
      ],
    );
  }

  DataRow _buildDocumentRow(
      BuildContext context,
      DocumentModel document,
      DocumentProvider documentProvider,
      ) {
    // Get document type name
    final documentTypes = documentProvider.documentTypes;
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    final documentTypeName = documentType?.name ?? 'Unknown Document Type';

    return DataRow(
      cells: [
        DataCell(Text(documentTypeName)),
        DataCell(
          document.isNotApplicable
              ? const Text('Not Applicable')
              : StatusBadge(
            status: document.status,
            isExpired: document.isExpired,
          ),
        ),
        DataCell(Text(
          _formatDate(document.updatedAt),
        )),
        DataCell(Text(
          document.expiryDate != null
              ? _formatDate(document.expiryDate!)
              : 'N/A',
        )),
        DataCell(Text(
          '${document.signatures.length}/${documentType?.signatureCount ?? 0}',
        )),
        DataCell(Text(
          '${document.comments.length}',
        )),
      ],
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}
```

# lib\views\compliance_report\widgets\report_summary.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';

class ReportSummary extends StatelessWidget {
  const ReportSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';

    final totalDocuments = documentProvider.documents.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final rejectedDocuments = documentProvider.rejectedDocuments.length;
    final expiredDocuments = documentProvider.expiredDocuments.length;

    // Calculate compliance percentage
    double compliancePercentage = 0;
    if (totalDocuments > 0) {
      compliancePercentage = (approvedDocuments / totalDocuments) * 100;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compliance Summary Report',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generated on ${DateFormat('MMMM d, y').format(DateTime.now())}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prepared for: $userName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildComplianceGauge(context, compliancePercentage),
                ),
              ],
            ),
            const Divider(height: 40),
            Text(
              'Summary Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Documents',
                    totalDocuments,
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Approved',
                    approvedDocuments,
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pending',
                    pendingDocuments,
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Rejected',
                    rejectedDocuments,
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expiredDocuments > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Warning: Expired Documents',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have $expiredDocuments expired document${expiredDocuments > 1 ? 's' : ''}. Please update these documents as soon as possible.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceGauge(BuildContext context, double percentage) {
    final color = _getColorForPercentage(percentage / 100);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text('Compliant'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getComplianceStatusText(percentage),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      int value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getComplianceStatusText(double percentage) {
    if (percentage < 30) return 'High Risk';
    if (percentage < 70) return 'Moderate Risk';
    if (percentage < 90) return 'Good Standing';
    return 'Excellent';
  }
}
```

# lib\views\dashboard\dashboard_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
      await documentProvider.initialize(authProvider.currentUser!.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    // Figure out what content to show
    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading dashboard data...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      // Calculate key metrics
      final totalDocTypes = documentProvider.documentTypes.length;
      final uploadedDocs = documentProvider.documents.length;
      final pendingDocs = documentProvider.pendingDocuments.length;
      final approvedDocs = documentProvider.approvedDocuments.length;
      final rejectedDocs = documentProvider.documents
          .where((doc) => doc.isRejected)
          .length;
      final expiredDocs = documentProvider.documents
          .where((doc) => doc.isExpired)
          .length;

      // Calculate completion percentage
      // Adjust how we calculate completion percentage
      final completionRate = totalDocTypes > 0
          ? uploadedDocs / totalDocTypes
          : 0.0;
      final completionPercentage = (completionRate * 100).toStringAsFixed(1);

      content = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(authProvider),
            const SizedBox(height: 16),
            _buildComplianceOverview(
                completionPercentage,
                uploadedDocs,
                totalDocTypes,
                approvedDocs,
                pendingDocs,
                rejectedDocs,
                expiredDocs
            ),
            const SizedBox(height: 16),
            _buildQuickLinks(context),
            const SizedBox(height: 16),
            _buildRecentActivitySection(documentProvider),

            // Admin section if user is admin
            if (authProvider.isAdmin) ...[
              const SizedBox(height: 16),
              _buildAdminSection(context, categoryProvider),
            ],
          ],
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'Dashboard',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider) {
    final userName = authProvider.currentUser?.name ?? "User";
    final firstName = userName.split(' ').first;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              radius: 24,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $firstName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your compliance documents',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceOverview(
      String completionPercentage,
      int uploadedDocs,
      int totalDocs,
      int approvedDocs,
      int pendingDocs,
      int rejectedDocs,
      int expiredDocs,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Compliance Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Overall completion indicator
                Row(
                  children: [
                    CircularProgressIndicator(
                      value: double.parse(completionPercentage) / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        double.parse(completionPercentage) > 80
                            ? Colors.green
                            : double.parse(completionPercentage) > 40
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completionPercentage% Complete',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$uploadedDocs of $totalDocs documents uploaded',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Document status summary
                Row(
                  children: [
                    _buildStatusItem(approvedDocs, 'Approved', Colors.green),
                    _buildStatusItem(pendingDocs, 'Pending', Colors.orange),
                    _buildStatusItem(rejectedDocs, 'Rejected', Colors.red),
                    _buildStatusItem(expiredDocs, 'Expired', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(int count, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            _buildActionTile(
              context,
              'Tracker',
              Icons.assignment_outlined,
              Colors.blue,
              RouteConstants.auditTracker,
              'Upload and track documents',
            ),
            const SizedBox(width: 8),
            _buildActionTile(
              context,
              'Audit Index',
              Icons.folder_outlined,
              Colors.amber,
              RouteConstants.auditIndex,
              'View document categories',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildActionTile(
              context,
              'Reports',
              Icons.analytics_outlined,
              Colors.green,
              RouteConstants.complianceReport,
              'View compliance reports',
            ),
            const SizedBox(width: 8),
            _buildActionTile(
              context,
              'Upload',
              Icons.upload_file_outlined,
              Colors.purple,
              RouteConstants.auditTracker,
              'Upload new document',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String route,
      String subtitle,
      ) {
    return Expanded(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(route),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(DocumentProvider documentProvider) {
    // Get the 5 most recent documents
    final recentDocuments = documentProvider.documents
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final displayDocuments = recentDocuments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RouteConstants.auditTracker);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        displayDocuments.isEmpty
            ? const Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('No recent activity'),
            ),
          ),
        )
            : Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: displayDocuments.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final document = displayDocuments[index];

              // Find document type for this document
              String documentTypeName = 'Unknown Document';
              try {
                final docType = documentProvider.documentTypes
                    .firstWhere((dt) => dt.id == document.documentTypeId);
                documentTypeName = docType.name;
              } catch (_) {
                // Keep default name if document type not found
              }

              return ListTile(
                dense: true,
                title: Text(
                  documentTypeName,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _getRelativeTime(document.updatedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: _getStatusIcon(document.status.toString()),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context, CategoryProvider categoryProvider) {
    // Get category stats
    final categoryCount = categoryProvider.categories.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Administration',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                title: const Text('User Management', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Manage system users', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                dense: true,
                onTap: () => Navigator.of(context).pushNamed(RouteConstants.userManagement),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.category_outlined,
                    color: Colors.teal,
                    size: 20,
                  ),
                ),
                title: const Text('Category Management', style: TextStyle(fontSize: 13)),
                subtitle: Text('$categoryCount categories', style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20),
                dense: true,
                onTap: () => Navigator.of(context).pushNamed(RouteConstants.categoryManagement),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;

    if (status == 'DocumentStatus.APPROVED') {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (status == 'DocumentStatus.PENDING') {
      icon = Icons.hourglass_empty;
      color = Colors.orange;
    } else if (status == 'DocumentStatus.REJECTED') {
      icon = Icons.cancel;
      color = Colors.red;
    } else {
      icon = Icons.info_outline;
      color = Colors.grey;
    }

    return Icon(icon, color: color, size: 16);
  }
}
```

# lib\views\dashboard\widgets\compliance_progress_chart.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/document_provider.dart';

class ComplianceProgressChart extends StatelessWidget {
  const ComplianceProgressChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    // Calculate compliance percentage by category
    final categories = categoryProvider.categories;
    final categoryComplianceMap = <String, double>{};

    for (var category in categories) {
      final docs = documentProvider.getDocumentsByCategory(category.id);
      if (docs.isEmpty) {
        categoryComplianceMap[category.id] = 0;
      } else {
        final completedDocs = docs.where((doc) => doc.isComplete || doc.isNotApplicable).length;
        categoryComplianceMap[category.id] = (completedDocs / docs.length) * 100;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Progress by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ...categories.map((category) {
              final compliance = categoryComplianceMap[category.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          '${compliance.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: compliance / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForPercentage(compliance / 100),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}
```

# lib\views\dashboard\widgets\dashboard_summary_card.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';

    final totalDocuments = documentProvider.documents.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final expiredDocuments = documentProvider.expiredDocuments.length;

    // Calculate compliance percentage
    double compliancePercentage = 0;
    if (totalDocuments > 0) {
      compliancePercentage = (approvedDocuments / totalDocuments) * 100;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $userName',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your compliance dashboard summary',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${compliancePercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Documents',
                    totalDocuments.toString(),
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pending',
                    pendingDocuments.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Approved',
                    approvedDocuments.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Expired',
                    expiredDocuments.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

# lib\views\dashboard\widgets\recent_activity_list.dart

```dart
import 'package:cropcompliance/core/constants/route_constants.dart';
import 'package:cropcompliance/models/document_model.dart';
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:cropcompliance/models/enums.dart';
import 'package:cropcompliance/providers/document_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class RecentActivityList extends StatelessWidget {
  const RecentActivityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);

    // Get recent documents (sorted by update date)
    final recentDocuments = List<DocumentModel>.from(documentProvider.documents)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Take only the first 10 documents
    final documents = recentDocuments.take(10).toList();

    if (documents.isEmpty) {
      return const Center(
        child: Text('No recent activity'),
      );
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, __) => const Divider(),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(document).withOpacity(0.1),
            child: Icon(
              _getStatusIcon(document),
              color: _getStatusColor(document),
            ),
          ),
          title: Text(
            _getDocumentTitle(document, documentProvider),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _getActivityDescription(document),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            DateFormat('MMM d, y').format(document.updatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            Navigator.of(context).pushNamed(
              RouteConstants.documentDetail,
              arguments: {'documentId': document.id},
            );
          },
        );
      },
    );
  }

  String _getDocumentTitle(DocumentModel document, DocumentProvider provider) {
    final documentTypes = provider.documentTypes;
    final documentType = documentTypes.firstWhere(
          (dt) => dt.id == document.documentTypeId,
      orElse: () => DocumentTypeModel(
        id: '',
        categoryId: '',
        name: 'Unknown Document Type',
        allowMultipleDocuments: false,
        isUploadable: false,
        hasExpiryDate: false,
        hasNotApplicableOption: false,
        requiresSignature: false,
        signatureCount: 0,
      ),
    );

    return documentType.name;
  }

  String _getActivityDescription(DocumentModel document) {
    if (document.isNotApplicable) {
      return 'Marked as Not Applicable';
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return 'Pending review';
      case DocumentStatus.APPROVED:
        return 'Approved on ${DateFormat('MMM d, y').format(document.updatedAt)}';
      case DocumentStatus.REJECTED:
        return 'Rejected - Requires attention';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(DocumentModel document) {
    if (document.isExpired) {
      return Icons.warning;
    }

    if (document.isNotApplicable) {
      return Icons.not_interested;
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return Icons.hourglass_empty;
      case DocumentStatus.APPROVED:
        return Icons.check_circle;
      case DocumentStatus.REJECTED:
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(DocumentModel document) {
    if (document.isExpired) {
      return Colors.red;
    }

    if (document.isNotApplicable) {
      return Colors.grey;
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return Colors.orange;
      case DocumentStatus.APPROVED:
        return Colors.green;
      case DocumentStatus.REJECTED:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
```

# lib\views\document_management\document_detail_screen.dart

```dart
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_model.dart';
import '../../models/enums.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';
import 'widgets/document_viewer.dart';
import 'widgets/signature_pad.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Future<DocumentModel?>? _documentFuture;
  TextEditingController _commentController = TextEditingController();
  DocumentTypeModel? _documentType;
  bool _hasLoggedDocumentInfo = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadDocument() {
    // Only set the future if it hasn't been set already
    if (_documentFuture == null) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      _documentFuture = documentProvider.getDocument(widget.documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Document Details',
        showBackButton: true,
      ),
      body: FutureBuilder<DocumentModel?>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading document...');
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              error: 'Error loading document: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _documentFuture = null;
                  _loadDocument();
                });
              },
            );
          }

          final document = snapshot.data;
          if (document == null) {
            return const Center(
              child: Text('Document not found'),
            );
          }

          // Print debug info only once when document is first loaded
          if (!_hasLoggedDocumentInfo) {
            print("Document ID: ${document.id}");
            print("File URLs: ${document.fileUrls}");
            print("File URLs count: ${document.fileUrls.length}");
            _hasLoggedDocumentInfo = true;
          }

          // Get document type information - avoid repeated fetches
          if (_documentType == null) {
            categoryProvider.fetchDocumentTypes(document.categoryId);
            final documentTypes = categoryProvider.getDocumentTypes(document.categoryId);
            try {
              _documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
            } catch (_) {
              _documentType = null;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _documentType?.name ?? 'Document',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            StatusBadge(
                              status: document.status,
                              isExpired: document.isExpired,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Created on',
                          DateFormat('MMM d, y').format(document.createdAt),
                        ),
                        if (document.expiryDate != null)
                          _buildInfoRow(
                            'Expires on',
                            DateFormat('MMM d, y').format(document.expiryDate!),
                            isError: document.isExpired,
                          ),
                        _buildInfoRow(
                          'Status',
                          document.status.name,
                        ),
                        if (document.isNotApplicable)
                          _buildInfoRow(
                            'Applicability',
                            'Marked as Not Applicable',
                          ),
                      ],
                    ),
                  ),
                ),

                // Document content
                if (!document.isNotApplicable) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Document Files',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (document.fileUrls.isNotEmpty)
                    DocumentViewer(document: document)
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No document files available (${document.fileUrls.length} files)',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This document does not have any uploaded files. You can add files by updating the document.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // Signature section
                if (_documentType?.requiresSignature == true &&
                    !document.isNotApplicable &&
                    document.status != DocumentStatus.REJECTED) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Signatures',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required signatures: ${_documentType?.signatureCount}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          if (document.signatures.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: document.signatures.length,
                              itemBuilder: (context, index) {
                                final signature = document.signatures[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(signature.userName),
                                  subtitle: Text(
                                    'Signed on ${DateFormat('MMM d, y').format(signature.signedAt)}',
                                  ),
                                  trailing: Image.network(
                                    signature.imageUrl,
                                    height: 40,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                                  ),
                                );
                              },
                            ),

                          if (document.signatures.length < (_documentType?.signatureCount ?? 0)) ...[
                            if (document.signatures.isNotEmpty)
                              const Divider(height: 32),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.draw),
                              label: const Text('Add Signature'),
                              onPressed: () {
                                _showSignatureDialog(context, document);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ] else
                            const Text(
                              'All required signatures have been collected',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Comment section with actions
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: document.comments.isNotEmpty
                        ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: document.comments.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final comment = document.comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.person),
                          ),
                          title: Row(
                            children: [
                              Text(comment.userName),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, y').format(comment.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(comment.text),
                          ),
                          isThreeLine: true,
                        );
                      },
                    )
                        : const Center(
                      child: Text('No comments yet'),
                    ),
                  ),
                ),

                // Combined comment input and action section
                if (!document.isNotApplicable) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Comment',
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          // Admin-specific action buttons
                          if (authProvider.isAdmin || authProvider.isAuditer) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Approve'),
                                    onPressed: document.status == DocumentStatus.APPROVED
                                        ? null
                                        : () => _updateDocumentStatus(
                                      document,
                                      DocumentStatus.APPROVED,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Reject'),
                                    onPressed: document.status == DocumentStatus.REJECTED
                                        ? null
                                        : () => _updateDocumentStatus(
                                      document,
                                      DocumentStatus.REJECTED,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignatureDialog(BuildContext context, DocumentModel document) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Your Signature',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please sign below:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SignaturePad(
                onSave: (file) async {
                  Navigator.of(context).pop();

                  final documentProvider = Provider.of<DocumentProvider>(
                    context,
                    listen: false,
                  );
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  if (authProvider.currentUser != null) {
                    final success = await documentProvider.addSignature(
                      document.id,
                      file,
                      authProvider.currentUser!,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signature added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      setState(() {
                        _documentFuture = null;
                        _loadDocument();
                      });
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add signature'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDocumentStatus(
      DocumentModel document,
      DocumentStatus status,
      ) async {
    if (_commentController.text.isEmpty && status == DocumentStatus.REJECTED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final success = await documentProvider.updateDocumentStatus(
        document.id,
        status,
        _commentController.text.isNotEmpty ? _commentController.text : null,
        authProvider.currentUser!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${status == DocumentStatus.APPROVED ? 'approved' : 'rejected'} successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _commentController.clear();
        setState(() {
          _documentFuture = null;
          _loadDocument();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update document status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addComment(DocumentModel document) async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final success = await documentProvider.addComment(
        document.id,
        _commentController.text,
        authProvider.currentUser!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _commentController.clear();
        setState(() {
          _documentFuture = null;
          _loadDocument();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

# lib\views\document_management\document_form_screen.dart

```dart
import 'package:cropcompliance/core/constants/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import 'widgets/document_form_builder.dart';

class DocumentFormScreen extends StatefulWidget {
  final String categoryId;
  final String documentTypeId;

  const DocumentFormScreen({
    Key? key,
    required this.categoryId,
    required this.documentTypeId,
  }) : super(key: key);

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final Map<String, dynamic> _formData = {};
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.initialize();
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _submitForm() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    // Get document type to check if expiry date is required
    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == widget.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    if (documentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document type not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (documentType.hasExpiryDate && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (authProvider.currentUser != null) {
        final document = await documentProvider.createDocument(
          user: authProvider.currentUser!,
          categoryId: widget.categoryId,
          documentTypeId: widget.documentTypeId,
          files: [],
          formData: _formData,
          expiryDate: _expiryDate,
        );

        if (document != null && mounted) {
          Navigator.of(context).pop();

          if (documentType.requiresSignature) {
            Navigator.of(context).pushNamed(
              RouteConstants.documentDetail,
              arguments: {'documentId': document.id},
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: const LoadingIndicator(message: 'Loading document type...'),
      );
    }

    if (categoryProvider.error != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: ErrorDisplay(
          error: categoryProvider.error!,
          onRetry: _initializeData,
        ),
      );
    }

    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == widget.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    if (documentType == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Fill Document Form',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Document type not found'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Fill ${documentType.name}',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentType.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Use form builder based on document type
                DocumentFormBuilder(
                  documentType: documentType,
                  onFormDataChanged: (key, value) {
                    setState(() {
                      _formData[key] = value;
                    });
                  },
                ),

                if (documentType.hasExpiryDate) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: _expiryDate != null
                        ? Text(
                      '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                    )
                        : const Text('Select expiry date'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectExpiryDate,
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Submit Form'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

# lib\views\document_management\document_upload_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../audit_tracker/widgets/document_upload_card.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String categoryId;
  final String documentTypeId;

  const DocumentUploadScreen({
    Key? key,
    required this.categoryId,
    required this.documentTypeId,
  }) : super(key: key);

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    await categoryProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (categoryProvider.isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: const LoadingIndicator(message: 'Loading document type...'),
      );
    }

    if (categoryProvider.error != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: ErrorDisplay(
          error: categoryProvider.error!,
          onRetry: _initializeData,
        ),
      );
    }

    final documentTypes = categoryProvider.getDocumentTypes(widget.categoryId);
    final documentType = documentTypes.firstWhere(
          (dt) => dt.id == widget.documentTypeId,
      orElse: () => DocumentTypeModel(
        id: '',
        categoryId: '',
        name: 'Unknown Document Type',
        allowMultipleDocuments: false,
        isUploadable: true,
        hasExpiryDate: false,
        hasNotApplicableOption: false,
        requiresSignature: false,
        signatureCount: 0,
      ),
    );

    if (documentType.id.isEmpty) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Upload Document',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Document type not found'),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Upload ${documentType.name}',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: DocumentUploadCard(
          categoryId: widget.categoryId,
          documentType: documentType,
        ),
      ),
    );
  }
}
```

# lib\views\document_management\widgets\document_form_builder.dart

```dart
import 'package:flutter/material.dart';
import '../../../models/document_type_model.dart';

class DocumentFormBuilder extends StatefulWidget {
  final DocumentTypeModel documentType;
  final Function(String, dynamic) onFormDataChanged;

  const DocumentFormBuilder({
    Key? key,
    required this.documentType,
    required this.onFormDataChanged,
  }) : super(key: key);

  @override
  State<DocumentFormBuilder> createState() => _DocumentFormBuilderState();
}

class _DocumentFormBuilderState extends State<DocumentFormBuilder> {
  // This is where form field definitions would be stored for different document types
  // In a real app, these would likely come from Firestore or another data source

  @override
  Widget build(BuildContext context) {
    // Based on the document type ID, generate appropriate form fields
    return _buildFormForDocumentType(widget.documentType.id);
  }

  Widget _buildFormForDocumentType(String documentTypeId) {
    // This is a simplified implementation just for demonstration
    // In a real app, you would have more sophisticated form generation logic

    // Generate different forms based on document type ID patterns
    // These examples are just placeholders
    if (documentTypeId.contains('contract')) {
      return _buildContractForm();
    } else if (documentTypeId.contains('certification')) {
      return _buildCertificationForm();
    } else if (documentTypeId.contains('inspection')) {
      return _buildInspectionForm();
    } else if (documentTypeId.contains('risk')) {
      return _buildRiskAssessmentForm();
    } else {
      return _buildGenericForm();
    }
  }

  Widget _buildContractForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'contractName',
          'Contract Name',
          'Enter the name of the contract',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'contractNumber',
          'Contract Number',
          'Enter the contract reference number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'counterparty',
          'Counterparty',
          'Enter the name of the other party',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'effectiveDate',
          'Effective Date',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'status',
          'Contract Status',
          ['Active', 'Pending', 'Terminated', 'Expired'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'description',
          'Description',
          'Enter a description of the contract',
        ),
      ],
    );
  }

  Widget _buildCertificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'certificationName',
          'Certification Name',
          'Enter the name of the certification',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'certificationNumber',
          'Certification Number',
          'Enter the certification reference number',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'issuingAuthority',
          'Issuing Authority',
          'Enter the name of the issuing authority',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'issueDate',
          'Issue Date',
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'hasRestrictions',
          'Has Restrictions',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          'Notes',
          'Enter any additional notes',
        ),
      ],
    );
  }

  Widget _buildInspectionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'inspectionLocation',
          'Inspection Location',
          'Enter the location that was inspected',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'inspectionDate',
          'Inspection Date',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'inspector',
          'Inspector',
          'Enter the name of the inspector',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'result',
          'Inspection Result',
          ['Pass', 'Pass with Conditions', 'Fail', 'Incomplete'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'findings',
          'Findings',
          'Enter inspection findings',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'recommendations',
          'Recommendations',
          'Enter recommendations',
        ),
      ],
    );
  }

  Widget _buildRiskAssessmentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'assessmentTitle',
          'Assessment Title',
          'Enter the title of this risk assessment',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'assessmentDate',
          'Assessment Date',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'assessor',
          'Assessor',
          'Enter the name of the assessor',
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          'riskLevel',
          'Overall Risk Level',
          ['Low', 'Medium', 'High', 'Critical'],
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'hazards',
          'Identified Hazards',
          'List the identified hazards',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'controls',
          'Control Measures',
          'List the control measures',
        ),
        const SizedBox(height: 16),
        _buildCheckboxField(
          'requiresFollowUp',
          'Requires Follow-up',
        ),
      ],
    );
  }

  Widget _buildGenericForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'title',
          'Title',
          'Enter a title',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          'reference',
          'Reference',
          'Enter a reference number',
        ),
        const SizedBox(height: 16),
        _buildDateField(
          'documentDate',
          'Document Date',
        ),
        const SizedBox(height: 16),
        _buildMultilineTextField(
          'notes',
          'Notes',
          'Enter any additional notes',
        ),
      ],
    );
  }

  Widget _buildTextField(
      String fieldKey,
      String label,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            widget.onFormDataChanged(fieldKey, value);
          },
        ),
      ],
    );
  }

  Widget _buildMultilineTextField(
      String fieldKey,
      String label,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) {
            widget.onFormDataChanged(fieldKey, value);
          },
        ),
      ],
    );
  }

  Widget _buildDateField(
      String fieldKey,
      String label,
      ) {
    DateTime? selectedDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (date != null) {
              setState(() {
                selectedDate = date;
              });
              widget.onFormDataChanged(fieldKey, date.toIso8601String());
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate != null
                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                        : 'Select a date',
                  ),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String fieldKey,
      String label,
      List<String> options,
      ) {
    String? selectedValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          value: selectedValue,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedValue = value;
            });
            if (value != null) {
              widget.onFormDataChanged(fieldKey, value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxField(
      String fieldKey,
      String label,
      ) {
    bool isChecked = false;

    return Row(
      children: [
        Checkbox(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              isChecked = value ?? false;
            });
            widget.onFormDataChanged(fieldKey, isChecked);
          },
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

# lib\views\document_management\widgets\document_viewer.dart

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/document_model.dart';

class DocumentViewer extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewer({
    Key? key,
    required this.document,
  }) : super(key: key);

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    // Cache document fileUrls to avoid repeated access
    final fileUrls = widget.document.fileUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Document Files',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
        ),

        // Files grid in a card with minimal padding
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(fileUrls.length, (index) {
              final fileUrl = fileUrls[index];
              final fileName = _getFileNameFromUrl(fileUrl);
              final fileExtension = _getFileExtension(fileName);

              return InkWell(
                onTap: () => _viewFile(context, fileUrl, fileName),
                child: SizedBox(
                  width: 70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getFileIconWindows(fileExtension),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        fileExtension.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),

        // Show loading indicator
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),

        // Show error message if any
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: const Icon(Icons.close, size: 16),
                ),
              ],
            ),
          ),

        // Show image preview if available
        if (_selectedImageUrl != null) _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageUrl == null) return const SizedBox.shrink();

    // Only try to display image types
    final String fileExtension = _getFileExtension(_selectedImageUrl!).toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
      // For non-image files, open in browser immediately
      Future.delayed(Duration.zero, () {
        _openInBrowser(_selectedImageUrl!);
        setState(() {
          _selectedImageUrl = null;
        });
      });

      return const SizedBox.shrink();
    }

    // Handle problematic file paths
    String displayUrl = _selectedImageUrl!;
    if (_selectedImageUrl!.contains("407a4209-262d-49d5-8303-07fb6ae300da")) {
      displayUrl = "https://firebasestorage.googleapis.com/v0/b/cropcompliance.firebasestorage.app/o/companies%2FehDGrBMipUKg3i6jIUvc%2Fdocuments%2F238fe53d-b89a-4858-833f-3929cb77b233%2F407a4209-262d-49d5-8303-07fb6ae300da_WhatsApp%20Image%202025-03-05%20at%2022.47.22.jpeg?alt=media&token=7a97be74-f5a5-4282-b92a-fc518139052f";
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Image Preview',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedImageUrl = null;
                  });
                },
                child: const Icon(Icons.close, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: displayUrl,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) {
                // Automatically open in browser when image fails to load
                Future.delayed(Duration.zero, () {
                  print("Image failed to load: $error");
                  _openInBrowser(displayUrl);

                  // Clear the selected image URL to remove the preview
                  if (mounted) {
                    setState(() {
                      _selectedImageUrl = null;
                    });
                  }
                });

                return const Center(
                  child: Text('Opening in browser...',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                );
              },
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      // Extract the filename from the URL
      if (url.contains('WhatsApp') && (url.contains('.jpeg') || url.contains('.jpg'))) {
        return 'WhatsApp_Image.jpg';
      }

      // Basic filename extraction
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.contains('.')) {
          return lastSegment.split('?').first;
        }
      }

      return 'document.jpg';
    } catch (e) {
      print("Error getting filename: $e");
      return 'document.jpg';
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  // Modern file icons for grid view
  Widget _getFileIconWindows(String extension) {
    Color color;
    IconData iconData;

    switch (extension.toLowerCase()) {
      case 'pdf':
        color = Colors.red;
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        color = Colors.blue;
        iconData = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        color = Colors.green;
        iconData = Icons.table_chart;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        color = Colors.green.shade700;
        iconData = Icons.image;
        break;
      default:
        color = Colors.grey;
        iconData = Icons.insert_drive_file;
    }

    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          // Icon centered in the container
          Center(
            child: Icon(
              iconData,
              color: Colors.white,
              size: 25,
            ),
          ),

          // "Folded corner" effect at top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewFile(BuildContext context, String fileUrl, String fileName) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedImageUrl = null;
    });

    try {
      print("Viewing file URL: $fileUrl");

      // For image files, we'll try to display them in the app
      final fileExtension = _getFileExtension(fileName).toLowerCase();
      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        setState(() {
          _selectedImageUrl = fileUrl;
          _isLoading = false;
        });
        // The error handling in _buildImagePreview will auto-open in browser if image loading fails
      } else {
        // For non-image files, open in browser immediately
        _openInBrowser(fileUrl);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in _viewFile: $e");

      // If any error occurs, open in browser as fallback
      _openInBrowser(fileUrl);

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error viewing file: $e';
      });
    }
  }

  Future<void> _openInBrowser(String? url) async {
    if (url == null) return;

    // Use hardcoded URL for the problematic file
    String displayUrl = url;
    if (url.contains("407a4209-262d-49d5-8303-07fb6ae300da")) {
      displayUrl = "https://firebasestorage.googleapis.com/v0/b/cropcompliance.firebasestorage.app/o/companies%2FehDGrBMipUKg3i6jIUvc%2Fdocuments%2F238fe53d-b89a-4858-833f-3929cb77b233%2F407a4209-262d-49d5-8303-07fb6ae300da_WhatsApp%20Image%202025-03-05%20at%2022.47.22.jpeg?alt=media&token=7a97be74-f5a5-4282-b92a-fc518139052f";
    }

    try {
      print("Opening URL in browser: $displayUrl");
      final Uri uri = Uri.parse(displayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $displayUrl');
      }
    } catch (e) {
      print("Error opening URL: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

# lib\views\document_management\widgets\signature_pad.dart

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class SignaturePad extends StatefulWidget {
  final Function(File) onSave;

  const SignaturePad({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  final GlobalKey _signatureKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _points.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: RepaintBoundary(
              key: _signatureKey,
              child: CustomPaint(
                painter: _SignaturePainter(points: _points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.clear),
              label: const Text('Clear'),
              onPressed: _clear,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: _isSaving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text('Save'),
              onPressed: _isSaving || _points.isEmpty ? null : _save,
            ),
          ],
        ),
      ],
    );
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _save() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final boundary = _signatureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // also need to fix getTemporaryDirectory

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/signature_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      widget.onSave(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

# lib\views\shared\app_drawer.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../models/enums.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 30,
                  child: Icon(
                    Icons.account_circle,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  authProvider.currentUser?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                Text(
                  authProvider.currentUser?.role.name ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == RouteConstants.dashboard,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.dashboard);
            },
          ),
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Audit Tracker'),
            selected: currentRoute == RouteConstants.auditTracker,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.auditTracker);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Compliance Report'),
            selected: currentRoute == RouteConstants.complianceReport,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.complianceReport);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Audit Index'),
            selected: currentRoute == RouteConstants.auditIndex,
            onTap: () {
              Navigator.of(context).pushReplacementNamed(RouteConstants.auditIndex);
            },
          ),
          const Divider(),
          if (authProvider.isAdmin) ...[
            const ListTile(
              title: Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('User Management'),
              selected: currentRoute == RouteConstants.userManagement,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(RouteConstants.userManagement);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category Management'),
              selected: currentRoute == RouteConstants.categoryManagement,
              onTap: () {
                Navigator.of(context).pushReplacementNamed(RouteConstants.categoryManagement);
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              authProvider.logout();
              Navigator.of(context).pushReplacementNamed(RouteConstants.login);
            },
          ),
        ],
      ),
    );
  }
}
```

# lib\views\shared\app_scaffold_wrapper.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart'; // Add this import
import '../../core/constants/route_constants.dart';

class AppScaffoldWrapper extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? actions;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final FloatingActionButton? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AppScaffoldWrapper({
    Key? key,
    required this.child,
    required this.title,
    this.actions,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.floatingActionButton,
    this.appBar,
  }) : super(key: key);

  @override
  State<AppScaffoldWrapper> createState() => _AppScaffoldWrapperState();
}

class _AppScaffoldWrapperState extends State<AppScaffoldWrapper> {
  bool _isSidebarCollapsed = false;
  final double _sidebarWidth = 210;
  final double _collapsedSidebarWidth = 70;

  @override
  void initState() {
    super.initState();
    // Initialize the route provider with the current route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != null) {
        Provider.of<RouteProvider>(context, listen: false).setActiveRoute(currentRoute);
      }
    });
  }

  // Menu items
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Dashboard',
      'icon': Icons.grid_view,
      'route': RouteConstants.dashboard,
      'adminOnly': false,
    },
    {
      'title': 'Compliance Tracker',
      'icon': Icons.track_changes,
      'route': RouteConstants.auditTracker,
      'adminOnly': false,
    },
    {
      'title': 'Compliance Report',
      'icon': Icons.bar_chart,
      'route': RouteConstants.complianceReport,
      'adminOnly': false,
    },
    {
      'title': 'Audit Index',
      'icon': Icons.folder_outlined,
      'route': RouteConstants.auditIndex,
      'adminOnly': false,
    },
  ];

  // Admin menu items
  final List<Map<String, dynamic>> _adminMenuItems = [
    {
      'title': 'User Management',
      'icon': Icons.people_outline,
      'route': RouteConstants.userManagement,
    },
    {
      'title': 'Category Management',
      'icon': Icons.category_outlined,
      'route': RouteConstants.categoryManagement,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context); // Get the route provider

    final isLargeScreen = MediaQuery.of(context).size.width > 1100;
    final isMediumScreen = MediaQuery.of(context).size.width > 800 && MediaQuery.of(context).size.width <= 1100;
    final primaryColor = Theme.of(context).primaryColor;

    // Determine the effective sidebar width
    double effectiveSidebarWidth = 0;
    if (isLargeScreen) {
      effectiveSidebarWidth = _isSidebarCollapsed ? _collapsedSidebarWidth : _sidebarWidth;
    } else if (isMediumScreen) {
      effectiveSidebarWidth = _collapsedSidebarWidth;
    }

    // Create AppBar with back button style
    final appBar = widget.appBar ?? AppBar(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_open, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),
          const SizedBox(width: 8),
          Text(widget.title),
        ],
      ),
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      actions: widget.actions,
    );

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? Colors.grey[100],
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      appBar: appBar,
      drawer: (!isLargeScreen && !isMediumScreen)
          ? _buildDrawer(context, authProvider, routeProvider)
          : null,
      body: Row(
        children: [
          // Persistent sidebar for large and medium screens
          if (isLargeScreen || isMediumScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: effectiveSidebarWidth,
              color: Colors.white,
              child: Column(
                children: [
                  // Banner image
                  ClipRRect(
                    child: Image.asset(
                      'assets/images/menuImage.png',
                      width: effectiveSidebarWidth,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: effectiveSidebarWidth,
                        height: 120,
                        color: primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.image,
                          color: primaryColor.withOpacity(0.3),
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  // User profile
                  _buildUserProfile(context, authProvider, _isSidebarCollapsed),

                  // Divider
                  const Divider(height: 1),

                  // Menu header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "MENU",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu items
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ..._menuItems.map((item) {
                            // Check if this item is selected based on the active route
                            final bool isSelected = routeProvider.activeRoute == item['route'];

                            return _buildMenuItem(
                              context,
                              item['icon'],
                              item['title'],
                              item['route'],
                              isSelected,
                              _isSidebarCollapsed,
                              onTap: () {
                                // Update the route provider when navigating
                                routeProvider.setActiveRoute(item['route']);
                                Navigator.of(context).pushReplacementNamed(item['route']);
                              },
                            );
                          }).toList(),

                          if (authProvider.isAdmin) ...[
                            // Admin header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              child: Row(
                                children: [
                                  Text(
                                    "ADMIN",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Admin menu items
                            ..._adminMenuItems.map((item) {
                              // Check if this item is selected
                              final bool isSelected = routeProvider.activeRoute == item['route'];

                              return _buildMenuItem(
                                context,
                                item['icon'],
                                item['title'],
                                item['route'],
                                isSelected,
                                _isSidebarCollapsed,
                                onTap: () {
                                  // Update the route provider when navigating
                                  routeProvider.setActiveRoute(item['route']);
                                  Navigator.of(context).pushReplacementNamed(item['route']);
                                },
                              );
                            }).toList(),
                          ],

                          // Divider before logout
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          // Logout
                          _buildMenuItem(
                            context,
                            Icons.logout,
                            'Logout',
                            '',
                            false,
                            _isSidebarCollapsed,
                            onTap: () {
                              authProvider.logout();
                              routeProvider.setActiveRoute(RouteConstants.login);
                              Navigator.of(context).pushReplacementNamed(RouteConstants.login);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Collapse button at the bottom
                  if (!_isSidebarCollapsed)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isSidebarCollapsed = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chevron_left,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Collapse',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Main content
          Expanded(
            child: widget.child,
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider, RouteProvider routeProvider) {
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      child: Column(
        children: [
          // Logo and banner
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.eco,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Crop Compliance',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Banner image
                ClipRRect(
                  child: Image.asset(
                    'assets/images/banner.png',
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 120,
                      color: primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        color: primaryColor.withOpacity(0.3),
                        size: 48,
                      ),
                    ),
                  ),
                ),

                // User profile
                _buildUserProfile(context, authProvider, false),

                // Divider
                const Divider(height: 1),
              ],
            ),
          ),

          // Menu header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  "MENU",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._menuItems.map((item) {
                  // Check if this item is selected
                  final bool isSelected = routeProvider.activeRoute == item['route'];

                  return _buildMenuItem(
                    context,
                    item['icon'],
                    item['title'],
                    item['route'],
                    isSelected,
                    false,
                    onTap: () {
                      // Update the route provider when navigating
                      routeProvider.setActiveRoute(item['route']);
                      Navigator.of(context).pushReplacementNamed(item['route']);
                    },
                  );
                }).toList(),

                if (authProvider.isAdmin) ...[
                  // Admin header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          "ADMIN",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin menu items
                  ..._adminMenuItems.map((item) {
                    // Check if this item is selected
                    final bool isSelected = routeProvider.activeRoute == item['route'];

                    return _buildMenuItem(
                      context,
                      item['icon'],
                      item['title'],
                      item['route'],
                      isSelected,
                      false,
                      onTap: () {
                        // Update the route provider when navigating
                        routeProvider.setActiveRoute(item['route']);
                        Navigator.of(context).pushReplacementNamed(item['route']);
                      },
                    );
                  }).toList(),
                ],

                // Divider before logout
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Logout
                _buildMenuItem(
                  context,
                  Icons.logout,
                  'Logout',
                  '',
                  false,
                  false,
                  onTap: () {
                    authProvider.logout();
                    routeProvider.setActiveRoute(RouteConstants.login);
                    Navigator.of(context).pushReplacementNamed(RouteConstants.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context, AuthProvider authProvider, bool isCollapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar with user initial
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 20,
            child: Text(
              authProvider.currentUser?.name.isNotEmpty ?? false
                  ? authProvider.currentUser!.name.substring(0, 1).toUpperCase()
                  : 'N',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          // User name and role (only show if not collapsed)
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.currentUser?.name ?? 'Nathan Test',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    authProvider.currentUser?.role.name ?? 'ADMIN',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context,
      IconData icon,
      String title,
      String route,
      bool isSelected,
      bool isCollapsed, {
        VoidCallback? onTap,
      }) {
    final primaryColor = Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? primaryColor : Colors.grey[600],
      ),
      title: !isCollapsed
          ? Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          color: isSelected ? primaryColor : Colors.grey[800],
        ),
      )
          : null,
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      selected: isSelected,
      selectedTileColor: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
      selectedColor: primaryColor,
      onTap: onTap,
    );
  }
}
```

# lib\views\shared\custom_app_bar.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/enums.dart';
import '../../core/constants/route_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBackButton,
      actions: [
        if (actions != null) ...actions!,
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
        ),
        if (authProvider.isAuthenticated)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed(RouteConstants.login);
              } else if (value == 'profile') {
                // Navigate to profile
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
```

# lib\views\shared\error_display.dart

```dart
import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

# lib\views\shared\loading_indicator.dart

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(

            child:  Container(
                width: 300,
                height: 300,
                child: Lottie.asset('assets/lottie/loader.json')),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
```

# lib\views\shared\responsive_layout.dart

```dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget tabletView;
  final Widget desktopView;

  const ResponsiveLayout({
    Key? key,
    required this.mobileView,
    required this.tabletView,
    required this.desktopView,
  }) : super(key: key);

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
          MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktopView;
        } else if (constraints.maxWidth >= 650) {
          return tabletView;
        } else {
          return mobileView;
        }
      },
    );
  }
}
```

# lib\views\shared\status_badge.dart

```dart
import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../theme/theme_constants.dart';

class StatusBadge extends StatelessWidget {
  final DocumentStatus status;
  final bool isExpired;

  const StatusBadge({
    Key? key,
    required this.status,
    this.isExpired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (isExpired) {
      color = ThemeConstants.expiredColor;
      label = 'Expired';
      icon = Icons.warning;
    } else {
      switch (status) {
        case DocumentStatus.PENDING:
          color = ThemeConstants.pendingColor;
          label = 'Pending';
          icon = Icons.hourglass_empty;
          break;
        case DocumentStatus.APPROVED:
          color = ThemeConstants.approvedColor;
          label = 'Approved';
          icon = Icons.check_circle;
          break;
        case DocumentStatus.REJECTED:
          color = ThemeConstants.rejectedColor;
          label = 'Rejected';
          icon = Icons.cancel;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

