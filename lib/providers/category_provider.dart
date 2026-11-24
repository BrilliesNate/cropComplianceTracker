import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/document_type_model.dart';
import '../core/services/firestore_service.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class CategoryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CategoryModel> _allCategories = []; // Stores ALL categories from database
  List<String> _companyPackages = []; // Package filter (empty = show all)
  Map<String, List<DocumentTypeModel>> _documentTypesByCategory = {};
  Map<String, DocumentTypeModel> _documentTypesMap = {};
  // Per-company overrides: documentTypeId -> isActive (false = deactivated for this company)
  Map<String, bool> _documentTypeActiveState = {};
  bool _isLoading = false;
  String? _error;

  // Which company the overrides above belong to (null = not loaded / stale).
  String? _overridesCompanyId;

  // Getters
  bool get isLoading => _isLoading;

  /// True when categories are in memory and the overrides held are for [companyId],
  /// i.e. a screen can render straight away without showing a loader.
  bool isWarmFor(String companyId) =>
      _allCategories.isNotEmpty &&
      (companyId.isEmpty ||
          (_overridesCompanyId == companyId && !_overridesStale));

  // Set by the admin screens that edit document types / overrides, so the next
  // screen reloads them instead of trusting what is in memory.
  static bool _overridesStale = false;
  static void markOverridesStale() => _overridesStale = true;
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

  // Get document types for a category, filtered by company active state
  List<DocumentTypeModel> getDocumentTypes(String categoryId) {
    final types = _documentTypesByCategory[categoryId] ?? [];
    if (_documentTypeActiveState.isEmpty) return types;
    return types.where((dt) => _documentTypeActiveState[dt.id] ?? true).toList();
  }

  // Get all document types for filtered categories only, respecting active state
  List<DocumentTypeModel> get documentTypes {
    final filteredCategoryIds = categories.map((c) => c.id).toSet();
    List<DocumentTypeModel> result = [];
    for (var entry in _documentTypesByCategory.entries) {
      if (filteredCategoryIds.contains(entry.key)) {
        result.addAll(entry.value);
      }
    }
    if (_documentTypeActiveState.isEmpty) return result;
    return result.where((dt) => _documentTypeActiveState[dt.id] ?? true).toList();
  }

  // Get all document types (unfiltered, ignores active state - for admin use)
  List<DocumentTypeModel> get allDocumentTypes {
    List<DocumentTypeModel> result = [];
    for (var docTypes in _documentTypesByCategory.values) {
      result.addAll(docTypes);
    }
    return result;
  }

  // IDs of document types deactivated for the current company
  Set<String> get deactivatedDocumentTypeIds {
    return _documentTypeActiveState.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toSet();
  }

  // Load per-company document type overrides (isActive field)
  Future<void> loadCompanyOverrides(String companyId) async {
    try {
      final overridesSnapshot = await FirebaseFirestore.instance
          .collection('companyDocumentTypeSettings')
          .where('companyId', isEqualTo: companyId)
          .get();

      _documentTypeActiveState = {};
      _overridesCompanyId = companyId;
      _overridesStale = false;
      for (var doc in overridesSnapshot.docs) {
        final data = doc.data();
        final documentTypeId = data['documentTypeId'] as String?;
        if (documentTypeId == null) continue;
        final overrides = data['overrides'] as Map<String, dynamic>? ?? {};
        if (overrides.containsKey('isActive')) {
          _documentTypeActiveState[documentTypeId] = overrides['isActive'] as bool;
        }
      }
      notifyListeners();
    } catch (e) {
      print('CategoryProvider: Error loading company overrides: $e');
    }
  }

  // Clear company overrides (call when switching companies or logging out)
  void clearCompanyOverrides() {
    _documentTypeActiveState = {};
    _overridesCompanyId = null;
    notifyListeners();
  }

  // Initialize - unchanged method signature (backward compatible)
  Future<void> initialize() async {
    // Already have categories? Refresh quietly (the service cache makes this
    // instant) instead of flipping every listening screen into a loading state.
    final quiet = _allCategories.isNotEmpty;
    if (!quiet) _setLoading(true);

    try {
      await _batchFetchAllData();
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errInitCats('$e');
    } finally {
      if (!quiet) _setLoading(false);
    }
  }

  // Helper method for batch fetching.
  // OPTIMIZED: 2 Firestore round-trips instead of (1 + N categories).
  Future<void> _batchFetchAllData() async {
    try {
      // Fetch categories AND all document types in parallel — two queries
      // total, regardless of how many categories exist.
      final results = await Future.wait([
        _firestoreService.getCategories(),
        _firestoreService.getAllDocumentTypes(),
      ]);

      _allCategories = results[0] as List<CategoryModel>;
      final allTypes = results[1] as List<DocumentTypeModel>;

      // Group document types by categoryId in memory — much faster than
      // hitting Firestore once per category.
      _documentTypesByCategory = {};
      for (final type in allTypes) {
        (_documentTypesByCategory[type.categoryId] ??= []).add(type);
      }

      // Build lookup map for faster access
      _buildDocumentTypesMap();

      // Only notify once after all data is loaded
      notifyListeners();
    } catch (e) {
      _error = LocaleProvider.instance.l10n.errFetchCatsTypes('$e');
      notifyListeners();
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
      _error = LocaleProvider.instance.l10n.errFetchCats('$e');
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
      _error = LocaleProvider.instance.l10n.errFetchTypes('$e');
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