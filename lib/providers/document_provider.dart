import 'dart:async';
import 'dart:io';

import 'package:cropCompliance/core/offline/upload_outbox.dart';

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
import 'package:cropCompliance/providers/locale_provider.dart';

// Flip to `true` to see every DocumentProvider state change.
const bool _kDocProviderVerbose = false;
void _dplog(String msg) {
  if (_kDocProviderVerbose) debugPrint('DocumentProvider: $msg');
}

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

  // Per-company deactivated document type IDs (set from CategoryProvider after loading overrides)
  Set<String> _deactivatedDocumentTypeIds = {};

  bool _isLoading = false;
  String? _error;

  // Context tracking for user selection
  String? _currentContextUserId;

  // Auditor mode: only APPROVED documents are loaded (and no review comments).
  // Re-evaluated from the signed-in user on every context refresh so it can
  // never leak between users who share a browser session.
  bool _approvedOnly = false;
  String? _currentContextCompanyId;

  DocumentProvider() {
    _documentService = DocumentService(
      firestoreService: _firestoreService,
      storageService: _storageService,
    );
    // When a file saved offline finishes uploading, swap "waiting to upload"
    // for the real file in memory so open screens update straight away.
    _uploadSub = UploadOutbox.instance.uploaded.listen(_onFileUploaded);
  }

  StreamSubscription<UploadedFile>? _uploadSub;

  void _onFileUploaded(UploadedFile f) {
    final i = _documents.indexWhere((d) => d.id == f.documentId);
    if (i == -1) return;
    final d = _documents[i];
    final updated = d.copyWith(
      fileUrls: [...d.fileUrls, f.url],
      pendingFiles: d.pendingFiles.where((n) => n != f.fileName).toList(),
    );
    _documents[i] = updated;
    _documentsMap[updated.id] = updated;
    notifyListeners();
  }

  @override
  void dispose() {
    _uploadSub?.cancel();
    super.dispose();
  }

  // Getters - unchanged
  List<DocumentModel> get documents => _documents;
  List<CategoryModel> get categories => _categories;
  List<DocumentTypeModel> get documentTypes => _deactivatedDocumentTypeIds.isEmpty
      ? _documentTypes
      : _documentTypes.where((dt) => !_deactivatedDocumentTypeIds.contains(dt.id)).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Categories and document types are in memory (documents may still be loading).
  bool get hasLoadedReferenceData =>
      _categories.isNotEmpty && _documentTypes.isNotEmpty;

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

  /// Set deactivated document type IDs for the current company.
  /// Call this after CategoryProvider.loadCompanyOverrides().
  void setDeactivatedDocumentTypeIds(Set<String> ids) {
    _deactivatedDocumentTypeIds = ids;
    notifyListeners();
  }

  /// Get document types filtered by company packages, excluding deactivated ones
  List<DocumentTypeModel> getDocumentTypesForPackages(List<String>? packages) {
    List<DocumentTypeModel> types;
    if (packages == null || packages.isEmpty) {
      types = _documentTypes;
    } else {
      final validCategoryIds = getCategoryIdsForPackages(packages);
      types = _documentTypes
          .where((docType) => validCategoryIds.contains(docType.categoryId))
          .toList();
    }
    if (_deactivatedDocumentTypeIds.isEmpty) return types;
    return types.where((dt) => !_deactivatedDocumentTypeIds.contains(dt.id)).toList();
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

  /// Get pending documents filtered by packages (excludes superseded)
  List<DocumentModel> getPendingDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.status == DocumentStatus.PENDING && !doc.isSuperseded)
        .toList();
  }

  /// Get approved documents filtered by packages (excludes superseded)
  List<DocumentModel> getApprovedDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.status == DocumentStatus.APPROVED && !doc.isSuperseded)
        .toList();
  }

  /// Get rejected documents filtered by packages (excludes superseded)
  List<DocumentModel> getRejectedDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.isRejected && !doc.isSuperseded)
        .toList();
  }

  /// Get expired documents filtered by packages (excludes superseded)
  List<DocumentModel> getExpiredDocumentsForPackages(List<String>? packages) {
    return getDocumentsForPackages(packages)
        .where((doc) => doc.isExpired && !doc.isSuperseded)
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

    // Count unique doc types that have at least one approved, non-expired document
    final approvedDocTypeCount = filteredApprovedDocs
        .where((d) => !d.isExpired)
        .map((d) => d.documentTypeId)
        .toSet()
        .length;

    return (approvedDocTypeCount / filteredDocTypes.length) * 100;
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
    // Count unique doc types that have at least one document uploaded (any status)
    final uploadedDocs = filteredDocs
        .map((d) => d.documentTypeId)
        .toSet()
        .length;
    // Count unique doc types with at least one approved, non-expired document
    final approvedDocs = filteredApprovedDocs
        .where((d) => !d.isExpired)
        .map((d) => d.documentTypeId)
        .toSet()
        .length;
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

  // NOTE: these "active" getters exclude superseded (replaced) documents so they
  // don't keep showing up as action items / compliance gaps. The raw
  // getDocumentsByCategory / getDocumentsByType still include them so they stay
  // findable in the audit index.
  List<DocumentModel> get pendingDocuments {
    return _documents
        .where((doc) => doc.status == DocumentStatus.PENDING && !doc.isSuperseded)
        .toList();
  }

  List<DocumentModel> get approvedDocuments {
    return _documents
        .where((doc) => doc.status == DocumentStatus.APPROVED && !doc.isSuperseded)
        .toList();
  }

  List<DocumentModel> get rejectedDocuments {
    return _documents
        .where((doc) => doc.status == DocumentStatus.REJECTED && !doc.isSuperseded)
        .toList();
  }

  List<DocumentModel> get expiredDocuments {
    return _documents.where((doc) => doc.isExpired && !doc.isSuperseded).toList();
  }

  // FIXED: Updated initialize method to work with user selection context
  Future<void> initializeWithContext(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      _error = LocaleProvider.instance.l10n.errNoAuthUser;
      notifyListeners();
      return;
    }

    // Determine which user's documents to load
    UserModel targetUser;
    if (authProvider.hasSelectedUser && authProvider.selectedUser != null) {
      targetUser = authProvider.selectedUser!;
      _dplog(' Loading documents for SELECTED user: ${targetUser.name} (${targetUser.email})');
    } else {
      targetUser = authProvider.currentUser!;
      _dplog(' Loading documents for CURRENT user: ${targetUser.name} (${targetUser.email})');
    }

    final targetUserId = targetUser.id;
    final targetCompanyId = targetUser.companyId;

    _dplog(' Target user ID: $targetUserId, Company ID: $targetCompanyId');

    final modeChanged = _approvedOnly != authProvider.isAuditer;
    _approvedOnly = authProvider.isAuditer;

    // IMPORTANT: Always reload if user context changes OR if we don't have the right context
    final needsReload = modeChanged ||
        _currentContextUserId != targetUserId ||
        _currentContextCompanyId != targetCompanyId ||
        _documents.isEmpty;

    if (needsReload) {
      _dplog(' Context changed or no data, reloading...');
      _dplog(' Previous context - User: $_currentContextUserId, Company: $_currentContextCompanyId');
      _dplog(' New context - User: $targetUserId, Company: $targetCompanyId');

      // Clear previous data before loading new context
      _clearData();

      await initialize(targetCompanyId, userId: targetUserId);

      _currentContextUserId = targetUserId;
      _currentContextCompanyId = targetCompanyId;

      _dplog(' Context updated successfully. Loaded ${_documents.length} documents.');
    } else {
      _dplog(' Context unchanged, using existing data (${_documents.length} documents)');
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
      _dplog(' Initializing with companyId: $companyId, userId: $userId');

      // Modified implementation to batch notifications
      await _batchFetchAllData(companyId, userId: userId);

      _dplog(' Initialization completed successfully');
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errInitData('$e');
      _dplog('initialize error: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ENHANCED: Method to refresh data when user selection changes
  Future<void> refreshForUserContext(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    final modeChanged = _approvedOnly != authProvider.isAuditer;
    _approvedOnly = authProvider.isAuditer;

    // COMPANY CONTEXT: If admin selected a company, load ALL documents for that company
    if (authProvider.isManagingCompany && authProvider.selectedCompany != null) {
      final targetCompanyId = authProvider.selectedCompany!.id;

      _dplog(' Loading ALL documents for company: ${authProvider.selectedCompany!.name}');

      // Check if we need to reload
      final needsReload = modeChanged ||
          _currentContextUserId != null || // Was previously user-specific
          _currentContextCompanyId != targetCompanyId ||
          _documents.isEmpty;

      if (needsReload) {
        _dplog(' Company context changed, reloading...');

        // Clear previous data
        _clearData();

        // Load all company documents (no userId filter)
        await initialize(targetCompanyId); // No userId parameter = all company documents

        _currentContextUserId = null; // No specific user
        _currentContextCompanyId = targetCompanyId;

        _dplog(' Loaded ${_documents.length} documents for company ${authProvider.selectedCompany!.name}');
      } else {
        _dplog(' Company context unchanged, using existing data (${_documents.length} documents)');
      }
      return;
    }

    // USER CONTEXT: Load documents for specific user (existing behavior)
    UserModel targetUser;
    if (authProvider.hasSelectedUser && authProvider.selectedUser != null) {
      targetUser = authProvider.selectedUser!;
      _dplog(' Loading documents for SELECTED user: ${targetUser.name} (${targetUser.email})');
    } else {
      targetUser = authProvider.currentUser!;
      _dplog(' Loading documents for CURRENT user: ${targetUser.name} (${targetUser.email})');
    }

    final targetUserId = targetUser.id;
    final targetCompanyId = targetUser.companyId;

    _dplog(' Target user ID: $targetUserId, Company ID: $targetCompanyId');

    // Check if we need to reload
    final needsReload = modeChanged ||
        _currentContextUserId != targetUserId ||
        _currentContextCompanyId != targetCompanyId ||
        _documents.isEmpty;

    if (needsReload) {
      _dplog(' User context changed, reloading...');

      // Clear previous data before loading new context
      _clearData();

      await initialize(targetCompanyId, userId: targetUserId);

      _currentContextUserId = targetUserId;
      _currentContextCompanyId = targetCompanyId;

      _dplog(' Context updated successfully. Loaded ${_documents.length} documents.');
    } else {
      _dplog(' User context unchanged, using existing data (${_documents.length} documents)');
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
      _error = LocaleProvider.instance.l10n.errUpdateFiles('$e');
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
      _error = LocaleProvider.instance.l10n.errDeleteDoc('$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _batchFetchAllData(String companyId, {String? userId}) async {
    try {
      _dplog(' Batch fetching data for companyId: $companyId, userId: $userId');

      // Fetch categories and all document types without multiple notifications
      await _batchFetchCategories();

      // FIXED: Always fetch ALL documents for the company, regardless of userId
      List<DocumentModel> documents;

      _dplog(' Fetching ALL documents for company: $companyId');
      // Always fetch documents for entire company - users should see all company documents
      documents = await _firestoreService.getDocuments(
        companyId: companyId, // Always use companyId, never filter by userId
        approvedOnly: _approvedOnly, // auditors: approved documents only
        // Only these types can carry signatures, so skip looking up the rest.
        signatureTypeIds: _documentTypes
            .where((t) => t.requiresSignature || t.signatureCount > 0)
            .map((t) => t.id)
            .toSet(),
      );

      _documents = documents;

      // Build lookup maps for faster access
      _buildLookupMaps();

      _dplog(' Loaded ${_documents.length} documents for company $companyId');
    } catch (e) {
      _dplog(' Error in _batchFetchAllData: $e');
      _error = LocaleProvider.instance.l10n.errFetchData('$e');
    }
  }

  // Helper to batch fetch categories and document types.
  // OPTIMIZED:
  //   1) Skip entirely if we already have data in memory (cache).
  //   2) Use a single getAllDocumentTypes() call instead of N getDocumentTypes
  //      calls — 2 round-trips instead of (1 + N).
  Future<void> _batchFetchCategories() async {
    // FirestoreService caches these for the session, so calling this on every
    // refresh is instant and still picks up admin edits once they're invalidated.
    try {
      final results = await Future.wait([
        _firestoreService.getCategories(),
        _firestoreService.getAllDocumentTypes(),
      ]);

      _categories = results[0] as List<CategoryModel>;
      _documentTypes = results[1] as List<DocumentTypeModel>;
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errFetchCatsTypes('$e');
      rethrow; // Re-throw to be caught by the calling method
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
      _error = LocaleProvider.instance.l10n.errFetchCats('$e');
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
      _error = LocaleProvider.instance.l10n.errFetchTypes('$e');
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
        approvedOnly: _approvedOnly,
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
      _error = LocaleProvider.instance.l10n.errFetchDocs('$e');
    } finally {
      _setLoading(false);
    }
  }

  // Get document by ID - Always fetch fresh to ensure complete data
  Future<DocumentModel?> getDocument(String documentId) async {
    try {
      print('DEBUG DocumentProvider.getDocument: Fetching document $documentId');

      // Always fetch fresh from Firestore to ensure we have complete data including fileUrls
      final document = await _firestoreService.getDocument(documentId,
          approvedOnly: _approvedOnly);

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
      _error = LocaleProvider.instance.l10n.errGetDoc('$e');
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
    DateTime? reviewedDate,
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
        reviewedDate: reviewedDate,
      );

      if (document != null) {
        _documents.add(document);
        _documentsMap[document.id] = document; // Update lookup map
        notifyListeners();
      }

      return document;
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errCreateDoc('$e');
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
      _error = LocaleProvider.instance.l10n.errNoEffectiveUser;
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
      UserModel user, {
      String? specification,
      DateTime? expiryDate,
      bool clearExpiryDate = false,
      }) async {
    _setLoading(true);

    try {
      final result = await _documentService.updateDocumentStatus(
        documentId,
        status,
        comment,
        user,
        specification: specification,
        expiryDate: expiryDate,
        clearExpiryDate: clearExpiryDate,
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
      _error = LocaleProvider.instance.l10n.errUpdateStatus('$e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Marks a document as superseded by a newer version. It drops out of action
  /// items / compliance counts but remains in the audit index for history.
  Future<bool> supersedeDocument(String documentId,
      {String? newDocumentId}) async {
    try {
      final index = _documents.indexWhere((doc) => doc.id == documentId);
      if (index < 0) return false;
      final updated = _documents[index].copyWith(
        isSuperseded: true,
        supersededByDocumentId: newDocumentId,
        updatedAt: DateTime.now(),
      );
      final ok = await _firestoreService.updateDocument(updated);
      if (ok) {
        _documents[index] = updated;
        _documentsMap[documentId] = updated;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errSupersede('$e');
      return false;
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
      _error = LocaleProvider.instance.l10n.errAddSignature('$e');
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
      _error = LocaleProvider.instance.l10n.errAddComment('$e');
      return false;
    }
  }

  // Calculate compliance percentage
  Future<double> getCompliancePercentage(String companyId) async {
    try {
      return await _documentService.calculateCompliancePercentage(companyId);
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errCompliancePct('$e');
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
    _deactivatedDocumentTypeIds = {};
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