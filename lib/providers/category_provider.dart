import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/document_type_model.dart';
import '../core/services/firestore_service.dart';

class CategoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _allCategories = []; // Stores ALL categories from database
  List<String> _companyPackages = []; // Package filter (empty = show all)
  Map<String, List<DocumentTypeModel>> _documentTypesByCategory = {};
  Map<String, DocumentTypeModel> _documentTypesMap = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Returns filtered categories based on company packages
  // If no packages set, returns all categories (backward compatible)
  List<CategoryModel> get categories {
    if (_companyPackages.isEmpty) {
      return _allCategories;
    }
    return _allCategories
        .where((category) => _companyPackages.contains(category.packageId))
        .toList();
  }

  // Get all categories (unfiltered) - useful for admin screens
  List<CategoryModel> get allCategories => _allCategories;

  // Get current package filter
  List<String> get companyPackages => _companyPackages;

  // Set the package filter for a company
  // Call this after initialize() to filter categories
  void setPackageFilter(List<String> packages) {
    _companyPackages = packages;
    notifyListeners();
  }

  // Clear the package filter (show all categories)
  void clearPackageFilter() {
    _companyPackages = [];
    notifyListeners();
  }

  // Get document types for a category - unchanged
  List<DocumentTypeModel> getDocumentTypes(String categoryId) {
    return _documentTypesByCategory[categoryId] ?? [];
  }

  // Get all document types for filtered categories only
  List<DocumentTypeModel> get documentTypes {
    final filteredCategoryIds = categories.map((c) => c.id).toSet();
    List<DocumentTypeModel> result = [];
    for (var entry in _documentTypesByCategory.entries) {
      if (filteredCategoryIds.contains(entry.key)) {
        result.addAll(entry.value);
      }
    }
    return result;
  }

  // Get all document types (unfiltered)
  List<DocumentTypeModel> get allDocumentTypes {
    List<DocumentTypeModel> result = [];
    for (var docTypes in _documentTypesByCategory.values) {
      result.addAll(docTypes);
    }
    return result;
  }

  // Initialize - unchanged method signature (backward compatible)
  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _batchFetchAllData();
    } catch (e) {
      _error = 'Failed to initialize categories: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Helper method for batch fetching - unchanged logic
  Future<void> _batchFetchAllData() async {
    try {
      // Fetch all categories
      final categories = await _firestoreService.getCategories();
      _allCategories = categories;

      // Create a list of document type fetching futures for parallel execution
      final futures = <Future>[];
      for (var category in _allCategories) {
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

  // Helper method to fetch document types for a category - unchanged
  Future<void> _fetchDocTypesForCategory(String categoryId) async {
    try {
      final documentTypes = await _firestoreService.getDocumentTypes(categoryId);
      _documentTypesByCategory[categoryId] = documentTypes;
    } catch (e) {
      print('Error fetching document types for category $categoryId: $e');
    }
  }

  // Build lookup map for faster access - unchanged
  void _buildDocumentTypesMap() {
    _documentTypesMap = {};
    for (var entry in _documentTypesByCategory.entries) {
      for (var docType in entry.value) {
        _documentTypesMap[docType.id] = docType;
      }
    }
  }

  // Fetch categories - kept for backward compatibility
  Future<void> fetchCategories() async {
    try {
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

  // Direct document type lookup - unchanged
  DocumentTypeModel? getDocumentTypeById(String id) {
    return _documentTypesMap[id];
  }
}