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

  AuditProvider() {
    _documentService = DocumentService(
      firestoreService: _firestoreService,
      storageService: _storageService,
    );
  }

  // Getters
  String? get currentCompanyId => _currentCompanyId;
  Map<String, double> get categoryComplianceMap => _categoryComplianceMap;
  double get overallCompliance => _overallCompliance;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set current company
  void setCurrentCompany(String companyId) {
    _currentCompanyId = companyId;
    calculateComplianceStats();
  }

  // Calculate compliance statistics
  Future<void> calculateComplianceStats() async {
    if (_currentCompanyId == null) return;

    _setLoading(true);
    try {
      // Get overall compliance
      _overallCompliance = await _documentService.calculateCompliancePercentage(_currentCompanyId!);

      // Get categories
      final categories = await _firestoreService.getCategories();

      // Calculate compliance for each category
      _categoryComplianceMap = {};
      for (var category in categories) {
        final docs = await _firestoreService.getDocuments(
          companyId: _currentCompanyId,
          categoryId: category.id,
        );

        if (docs.isEmpty) {
          _categoryComplianceMap[category.id] = 0.0;
        } else {
          int completedCount = 0;
          for (var doc in docs) {
            if (doc.isComplete || doc.isNotApplicable) {
              completedCount++;
            }
          }

          final compliancePercentage = (completedCount / docs.length) * 100;
          _categoryComplianceMap[category.id] = compliancePercentage;
        }
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to calculate compliance statistics: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Get documents for audit
  Future<List<DocumentModel>> getDocumentsForAudit({
    String? categoryId,
    bool includeNotApplicable = true,
  }) async {
    if (_currentCompanyId == null) return [];

    try {
      final docs = await _firestoreService.getDocuments(
        companyId: _currentCompanyId,
        categoryId: categoryId,
      );

      if (!includeNotApplicable) {
        return docs.where((doc) => !doc.isNotApplicable).toList();
      }

      return docs;
    } catch (e) {
      _error = 'Failed to get documents for audit: $e';
      return [];
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