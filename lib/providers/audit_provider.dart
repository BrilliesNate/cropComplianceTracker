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