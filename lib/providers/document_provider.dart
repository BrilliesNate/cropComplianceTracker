import 'dart:io';

import 'package:cropCompliance/core/services/document_service.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/core/services/storage_service.dart';
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

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

  // Context tracking for user selection
  String? _currentContextUserId;
  String? _currentContextCompanyId;

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

  // Context getters
  String? get currentContextUserId => _currentContextUserId;
  String? get currentContextCompanyId => _currentContextCompanyId;

  // ============================================
  // NEW: Package-aware filtering methods
  // ============================================

  /// Get categories filtered by company packages
  /// If packages is empty or null, returns all categories
  List<CategoryModel> getCategoriesForPackages(List<String>? packages) {
    if (packages == null || packages.isEmpty) {
      return _categories;
    }
    return _categories
        .where((category) => packages.contains(category.packageId))
        .toList();
  }

  /// Get category IDs for the given packages
  Set<String> getCategoryIdsForPackages(List<String>? packages) {
    return getCategoriesForPackages(packages).map((c) => c.id).toSet();
  }

  /// Get document types filtered by company packages
  /// This filters document types that belong to categories matching the packages
  List<DocumentTypeModel> getDocumentTypesForPackages(List<String>? packages) {
    if (packages == null || packages.isEmpty) {
      return _documentTypes;
    }

    final validCategoryIds = getCategoryIdsForPackages(packages);
    return _documentTypes
        .where((docType) => validCategoryIds.contains(docType.categoryId))
        .toList();
  }

  /// Get documents filtered by company packages
  /// This filters documents that belong to categories matching the packages
  List<DocumentModel> getDocumentsForPackages(List<String>? packages) {
    if (packages == null || packages.isEmpty) {
      return _documents;
    }

    final validCategoryIds = getCategoryIdsForPackages(packages);
    return _documents
        .where((doc) => validCategoryIds.contains(doc.categoryId))
        .toList();
  }

  /// Get pending documents filtered by packages
  List<DocumentModel> getPendingDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.status == DocumentStatus.PENDING)
        .toList();
  }

  /// Get approved documents filtered by packages
  List<DocumentModel> getApprovedDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.status == DocumentStatus.APPROVED)
        .toList();
  }

  /// Get rejected documents filtered by packages
  List<DocumentModel> getRejectedDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.isRejected)
        .toList();
  }

  /// Get expired documents filtered by packages
  List<DocumentModel> getExpiredDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.isExpired)
        .toList();
  }

  /// Calculate completion percentage based on company packages
  /// Returns: percentage of approved documents out of total document types for the packages
  double calculateCompletionPercentageForPackages(List<String>? packages) {
    final filteredDocTypes = getDocumentTypesForPackages(packages);
    final filteredApprovedDocs = getApprovedDocumentsForPackages(packages);

    if (filteredDocTypes.isEmpty) {
      return 0.0;
    }

    return (filteredApprovedDocs.length / filteredDocTypes.length) * 100;
  }

  /// Get compliance stats for a specific package
  /// Returns a map with all relevant metrics filtered by packages
  Map<String, dynamic> getComplianceStatsForPackages(List<String>? packages) {
    final filteredDocTypes = getDocumentTypesForPackages(packages);
    final filteredDocs = getDocumentsForPackages(packages);
    final filteredApprovedDocs = getApprovedDocumentsForPackages(packages);
    final filteredPendingDocs = getPendingDocumentsForPackages(packages);
    final filteredRejectedDocs = getRejectedDocumentsForPackages(packages);

    final totalDocTypes = filteredDocTypes.length;
    final uploadedDocs = filteredDocs.length;
    final approvedDocs = filteredApprovedDocs.length;
    final pendingDocs = filteredPendingDocs.length;
    final rejectedDocs = filteredRejectedDocs.length;

    final completionRate = totalDocTypes > 0
        ? (approvedDocs / totalDocTypes) * 100
        : 0.0;

    return {
      'totalDocTypes': totalDocTypes,
      'uploadedDocs': uploadedDocs,
      'approvedDocs': approvedDocs,
      'pendingDocs': pendingDocs,
      'rejectedDocs': rejectedDocs,
      'completionRate': completionRate,
      'completionPercentage': completionRate.toStringAsFixed(1),
    };
  }

  // ============================================
  // END: Package-aware filtering methods
  // ============================================

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

  // FIXED: Updated initialize method to work with user selection context
  Future<void> initializeWithContext(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      _error = 'No authenticated user';
      notifyListeners();
      return;
    }

    // Determine which user's documents to load
    UserModel targetUser;
    if (authProvider.hasSelectedUser && authProvider.selectedUser != null) {
      targetUser = authProvider.selectedUser!;
      print('DocumentProvider: Loading documents for SELECTED user: ${targetUser.name} (${targetUser.email})');
    } else {
      targetUser = authProvider.currentUser!;
      print('DocumentProvider: Loading documents for CURRENT user: ${targetUser.name} (${targetUser.email})');
    }

    final targetUserId = targetUser.id;
    final targetCompanyId = targetUser.companyId;

    print('DocumentProvider: Target user ID: $targetUserId, Company ID: $targetCompanyId');

    // IMPORTANT: Always reload if user context changes OR if we don't have the right context
    final needsReload = _currentContextUserId != targetUserId ||
        _currentContextCompanyId != targetCompanyId ||
        _documents.isEmpty;

    if (needsReload) {
      print('DocumentProvider: Context changed or no data, reloading...');
      print('DocumentProvider: Previous context - User: $_currentContextUserId, Company: $_currentContextCompanyId');
      print('DocumentProvider: New context - User: $targetUserId, Company: $targetCompanyId');

      // Clear previous data before loading new context
      _clearData();

      await initialize(targetCompanyId, userId: targetUserId);

      _currentContextUserId = targetUserId;
      _currentContextCompanyId = targetCompanyId;

      print('DocumentProvider: Context updated successfully. Loaded ${_documents.length} documents.');
    } else {
      print('DocumentProvider: Context unchanged, using existing data (${_documents.length} documents)');
    }
  }

  // Helper method to clear data when switching contexts
  void _clearData() {
    _documents = [];
    _documentsMap = {};
    // Keep categories and document types as they are global
  }

  // Enhanced initialize method with optional userId filter
  Future<void> initialize(String companyId, {String? userId}) async {
    _setLoading(true);

    try {
      print('DocumentProvider: Initializing with companyId: $companyId, userId: $userId');

      // Modified implementation to batch notifications
      await _batchFetchAllData(companyId, userId: userId);

      print('DocumentProvider: Initialization completed successfully');
    } catch (e) {
      _error = 'Failed to initialize data: $e';
      print('DocumentProvider initialize error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ENHANCED: Method to refresh data when user selection changes
  Future<void> refreshForUserContext(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    // COMPANY CONTEXT: If admin selected a company, load ALL documents for that company
    if (authProvider.isManagingCompany && authProvider.selectedCompany != null) {
      final targetCompanyId = authProvider.selectedCompany!.id;

      print('DocumentProvider: Loading ALL documents for company: ${authProvider.selectedCompany!.name}');

      // Check if we need to reload
      final needsReload = _currentContextUserId != null || // Was previously user-specific
          _currentContextCompanyId != targetCompanyId ||
          _documents.isEmpty;

      if (needsReload) {
        print('DocumentProvider: Company context changed, reloading...');

        // Clear previous data
        _clearData();

        // Load all company documents (no userId filter)
        await initialize(targetCompanyId); // No userId parameter = all company documents

        _currentContextUserId = null; // No specific user
        _currentContextCompanyId = targetCompanyId;

        print('DocumentProvider: Loaded ${_documents.length} documents for company ${authProvider.selectedCompany!.name}');
      } else {
        print('DocumentProvider: Company context unchanged, using existing data (${_documents.length} documents)');
      }
      return;
    }

    // USER CONTEXT: Load documents for specific user (existing behavior)
    UserModel targetUser;
    if (authProvider.hasSelectedUser && authProvider.selectedUser != null) {
      targetUser = authProvider.selectedUser!;
      print('DocumentProvider: Loading documents for SELECTED user: ${targetUser.name} (${targetUser.email})');
    } else {
      targetUser = authProvider.currentUser!;
      print('DocumentProvider: Loading documents for CURRENT user: ${targetUser.name} (${targetUser.email})');
    }

    final targetUserId = targetUser.id;
    final targetCompanyId = targetUser.companyId;

    print('DocumentProvider: Target user ID: $targetUserId, Company ID: $targetCompanyId');

    // Check if we need to reload
    final needsReload = _currentContextUserId != targetUserId ||
        _currentContextCompanyId != targetCompanyId ||
        _documents.isEmpty;

    if (needsReload) {
      print('DocumentProvider: User context changed, reloading...');

      // Clear previous data before loading new context
      _clearData();

      await initialize(targetCompanyId, userId: targetUserId);

      _currentContextUserId = targetUserId;
      _currentContextCompanyId = targetCompanyId;

      print('DocumentProvider: Context updated successfully. Loaded ${_documents.length} documents.');
    } else {
      print('DocumentProvider: User context unchanged, using existing data (${_documents.length} documents)');
    }
  }

  // Update document files (if this method exists in your DocumentProvider)
  Future<DocumentModel?> updateDocumentFiles({
    required String documentId,
    required List<dynamic> files,
    required UserModel user,
    DateTime? expiryDate,
    String? specification, // NEW PARAMETER
  }) async {
    _setLoading(true);

    try {
      final document = await _documentService.updateDocumentFiles(
        documentId: documentId,
        files: files,
        user: user,
        expiryDate: expiryDate,
        specification: specification, // NEW PARAMETER PASSED TO SERVICE
      );

      if (document != null) {
        // Update the document in our local list
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index >= 0) {
          _documents[index] = document;
        }
        _documentsMap[documentId] = document; // Update lookup map
        notifyListeners();
      }

      return document;
    } catch (e) {
      _error = 'Failed to update document files: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: New helper method for batch fetching with better user filtering
  // In your document_provider.dart, replace the _batchFetchAllData method with this:

  // Add this method to your DocumentProvider class in document_provider.dart

// Delete document
  Future<bool> deleteDocument({
    required String documentId,
    required UserModel user,
    String? reason,
  }) async {
    _setLoading(true);

    try {
      final result = await _documentService.deleteDocument(
        documentId: documentId,
        user: user,
        reason: reason,
      );

      if (result) {
        // Remove document from local lists
        _documents.removeWhere((doc) => doc.id == documentId);
        _documentsMap.remove(documentId);
        notifyListeners();

        print("DEBUG: Document removed from local cache");
      }

      return result;
    } catch (e) {
      _error = 'Failed to delete document: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _batchFetchAllData(String companyId, {String? userId}) async {
    try {
      print('DocumentProvider: Batch fetching data for companyId: $companyId, userId: $userId');

      // Fetch categories and all document types without multiple notifications
      await _batchFetchCategories();

      // FIXED: Always fetch ALL documents for the company, regardless of userId
      List<DocumentModel> documents;

      print('DocumentProvider: Fetching ALL documents for company: $companyId');
      // Always fetch documents for entire company - users should see all company documents
      documents = await _firestoreService.getDocuments(
        companyId: companyId, // Always use companyId, never filter by userId
      );

      _documents = documents;

      // Build lookup maps for faster access
      _buildLookupMaps();

      print('DocumentProvider: Loaded ${_documents.length} documents for company $companyId');
    } catch (e) {
      print('DocumentProvider: Error in _batchFetchAllData: $e');
      _error = 'Failed to fetch data: $e';
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

  // Enhanced method to get effective user for operations
  UserModel? _getEffectiveUser(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.effectiveUser;
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

  // Enhanced fetch documents with user context support
  Future<void> fetchDocuments({String? companyId, String? categoryId, String? userId}) async {
    _setLoading(true);

    try {
      final documents = await _firestoreService.getDocuments(
        companyId: companyId,
        categoryId: categoryId,
        userId: userId, // Add user filter support
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

  // Get document by ID - Always fetch fresh to ensure complete data
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      print('DEBUG DocumentProvider.getDocument: Fetching document $documentId');

      // Always fetch fresh from Firestore to ensure we have complete data including fileUrls
      final document = await _firestoreService.getDocument(documentId);

      if (document != null) {
        print('DEBUG DocumentProvider.getDocument: Document found');
        print('DEBUG DocumentProvider.getDocument: fileUrls count: ${document.fileUrls.length}');
        print('DEBUG DocumentProvider.getDocument: fileUrls: ${document.fileUrls}');

        // Update cache with fresh data
        _documentsMap[documentId] = document;

        // Also update in the documents list if present
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index >= 0) {
          _documents[index] = document;
        }
      } else {
        print('DEBUG DocumentProvider.getDocument: Document not found in Firestore');
      }

      return document;
    } catch (e) {
      print('DEBUG DocumentProvider.getDocument: Error - $e');
      _error = 'Failed to get document: $e';
      return null;
    }
  }

  // Create document
  Future<DocumentModel?> createDocument({
    required UserModel? user,
    required String categoryId,
    required String documentTypeId,
    required List<dynamic> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
    String? specification, // NEW FIELD
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
        specification: specification, // NEW FIELD
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

  // Enhanced create document with context
  Future<DocumentModel?> createDocumentWithContext({
    required BuildContext context,
    required String categoryId,
    required String documentTypeId,
    required List<dynamic> files,
    Map<String, dynamic>? formData,
    DateTime? expiryDate,
    bool isNotApplicable = false,
  }) async {
    final effectiveUser = _getEffectiveUser(context);

    if (effectiveUser == null) {
      _error = 'No effective user found';
      return null;
    }

    return await createDocument(
      user: effectiveUser,
      categoryId: categoryId,
      documentTypeId: documentTypeId,
      files: files,
      formData: formData,
      expiryDate: expiryDate,
      isNotApplicable: isNotApplicable,
    );
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

  // Clear context when needed (e.g., user logs out)
  void clearContext() {
    _currentContextUserId = null;
    _currentContextCompanyId = null;
    _documents = [];
    _documentsMap = {};
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