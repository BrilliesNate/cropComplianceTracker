import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/document_type_model.dart';
import '../core/services/firestore_service.dart';

class CategoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _categories = [];
  Map<String, List<DocumentTypeModel>> _documentTypesByCategory = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get document types for a category
  List<DocumentTypeModel> getDocumentTypes(String categoryId) {
    return _documentTypesByCategory[categoryId] ?? [];
  }

  // Initialize
  Future<void> initialize() async {
    _setLoading(true);

    try {
      await fetchCategories();
    } catch (e) {
      _error = 'Failed to initialize categories: $e';
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
      _documentTypesByCategory[categoryId] = documentTypes;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch document types: $e';
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