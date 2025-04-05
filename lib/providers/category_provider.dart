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