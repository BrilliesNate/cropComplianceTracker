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
  bool _isLoading = false;
  String? _error;

  DocumentProvider() {
    _documentService = DocumentService(
      firestoreService: _firestoreService,
      storageService: _storageService,
    );
  }

  // Getters
  List<DocumentModel> get documents => _documents;
  List<CategoryModel> get categories => _categories;
  List<DocumentTypeModel> get documentTypes => _documentTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered document getters
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

  // Initialize data
  Future<void> initialize(String companyId) async {
    _setLoading(true);

    try {
      await fetchCategories();
      await fetchDocuments(companyId: companyId);
    } catch (e) {
      _error = 'Failed to initialize data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      final categories = await _firestoreService.getCategories();
      _categories = categories;
      notifyListeners();

      // Fetch document types for each category
      for (var category in _categories) {
        await fetchDocumentTypes(category.id);
      }
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
    }
  }

  // Fetch document types
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

      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch document types: $e';
    }
  }

  // Fetch documents
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

      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch documents: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get document by ID
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      return await _firestoreService.getDocument(documentId);
    } catch (e) {
      _error = 'Failed to get document: $e';
      return null;
    }
  }

  // Create document
  Future<DocumentModel?> createDocument({
    required UserModel? user,
    required String categoryId,
    required String documentTypeId,
    required List<File> files,
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
            notifyListeners();
          }
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
            notifyListeners();
          }
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
            notifyListeners();
          }
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
}