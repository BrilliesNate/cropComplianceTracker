import 'package:cloud_firestore/cloud_firestore.dart';
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
    try {
      final snapshot = await _firestore
          .collection(AppConstants.categoriesCollection)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        return CategoryModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  // Document Types
  Future<List<DocumentTypeModel>> getDocumentTypes(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.documentTypesCollection)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      return snapshot.docs
          .map((doc) => DocumentTypeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting document types: $e');
      return [];
    }
  }

  Future<DocumentTypeModel?> getDocumentType(String documentTypeId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.documentTypesCollection)
          .doc(documentTypeId)
          .get();

      if (doc.exists) {
        return DocumentTypeModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting document type: $e');
      return null;
    }
  }

  // Documents
  Future<List<DocumentModel>> getDocuments({
    String? companyId,
    String? userId,
    String? categoryId,
    DocumentStatus? status,
  }) async {
    try {
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

      final snapshot = await query.get();

      List<DocumentModel> documents = [];
      for (var doc in snapshot.docs) {
        final signatures = await getSignatures(doc.id);
        final comments = await getComments(doc.id);

        documents.add(
            DocumentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id, signatures, comments)
        );
      }

      return documents;
    } catch (e) {
      print('Error getting documents: $e');
      return [];
    }
  }

  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.documentsCollection)
          .doc(documentId)
          .get();

      if (doc.exists) {
        final signatures = await getSignatures(documentId);
        final comments = await getComments(documentId);

        return DocumentModel.fromMap(
          doc.data()!,
          doc.id,
          signatures,
          comments,
        );
      }
      return null;
    } catch (e) {
      print('Error getting document: $e');
      return null;
    }
  }

  Future<String?> addDocument(DocumentModel document) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.documentsCollection)
          .add(document.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding document: $e');
      return null;
    }
  }

  Future<bool> updateDocument(DocumentModel document) async {
    try {
      await _firestore
          .collection(AppConstants.documentsCollection)
          .doc(document.id)
          .update(document.toMap());

      return true;
    } catch (e) {
      print('Error updating document: $e');
      return false;
    }
  }

  Future<bool> deleteDocument(String documentId) async {
    try {
      await _firestore
          .collection(AppConstants.documentsCollection)
          .doc(documentId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Signatures
  Future<List<SignatureModel>> getSignatures(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.signaturesCollection)
          .where('documentId', isEqualTo: documentId)
          .get();

      return snapshot.docs
          .map((doc) => SignatureModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting signatures: $e');
      return [];
    }
  }

  Future<String?> addSignature(SignatureModel signature) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.signaturesCollection)
          .add(signature.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding signature: $e');
      return null;
    }
  }

  // Comments
  Future<List<CommentModel>> getComments(String documentId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.commentsCollection)
          .where('documentId', isEqualTo: documentId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<String?> addComment(CommentModel comment) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.commentsCollection)
          .add(comment.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // Companies
  Future<List<CompanyModel>> getCompanies() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.companiesCollection)
          .get();

      return snapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting companies: $e');
      return [];
    }
  }

  Future<CompanyModel?> getCompany(String companyId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.companiesCollection)
          .doc(companyId)
          .get();

      if (doc.exists) {
        return CompanyModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting company: $e');
      return null;
    }
  }

  Future<String?> addCompany(CompanyModel company) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.companiesCollection)
          .add(company.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding company: $e');
      return null;
    }
  }

  // Users
  Future<List<UserModel>> getUsers({String? companyId}) async {
    try {
      Query query = _firestore.collection(AppConstants.usersCollection);

      if (companyId != null) {
        query = query.where('companyId', isEqualTo: companyId);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }
}