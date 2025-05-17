import 'dart:io';
import 'package:cropcompliance/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  Future<DocumentModel?> updateDocumentFiles({
    required String documentId,
    required List<dynamic> files,
    required UserModel user, // Pass the user directly
    DateTime? expiryDate,
  }) async {
    _setLoading(true);

    try {
      // Get the existing document
      final document = await _firestoreService.getDocument(documentId);
      if (document == null) {
        _error = 'Document not found';
        return null;
      }

      // Upload new files
      List<String> fileUrls = [];
      for (var file in files) {
        String? fileUrl;

        if (kIsWeb) {
          // Handle web file upload
          if (file is Map<String, dynamic> && file.containsKey('bytes')) {
            fileUrl = await _storageService.uploadFile(
              file,
              user.companyId,
              documentId,
              file['name'] ?? 'file.pdf',
            );
          }
        } else {
          // Handle mobile/desktop file upload
          if (file is File) {
            final fileName = file.path.split('/').last;
            fileUrl = await _storageService.uploadFile(
              file,
              user.companyId,
              documentId,
              fileName,
            );
          }
        }

        if (fileUrl != null) {
          fileUrls.add(fileUrl);
        }
      }

      // Update the document
      final updatedDocument = document.copyWith(
        fileUrls: fileUrls,
        status: DocumentStatus.PENDING,
        updatedAt: DateTime.now(),
        expiryDate: expiryDate ?? document.expiryDate,
      );

      final success = await _firestoreService.updateDocument(updatedDocument);

      if (success) {
        // Add comment about resubmission
        await _documentService.addComment(
          documentId,
          "Document resubmitted with updated files.",
          user,
        );

        // Update local document list
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index >= 0) {
          _documents[index] = updatedDocument;
        }

        notifyListeners();
        return updatedDocument;
      } else {
        _error = 'Failed to update document';
        return null;
      }
    } catch (e) {
      _error = 'Error updating document: $e';
      return null;
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