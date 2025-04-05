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