import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/views/admin/widgets/company_category_settings.dart';
import 'package:cropCompliance/views/admin/widgets/docuement_type_form.dart';
import 'package:cropCompliance/views/admin/widgets/document_types_table.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  // Main loading states
  bool _isInitialLoading = false;
  bool _isSavingSettings = false;
  bool _isSavingDocType = false;
  bool _isDeletingDocType = false;
  String? _error;

  // Company and category settings
  String? _selectedCompanyId;
  List<Map<String, dynamic>> _companies = [];
  Map<String, bool> _enabledCategories = {};
  bool _isLoadingCategories = false;

  // Document type management
  List<DocumentTypeModel> _allDocumentTypes = [];
  List<DocumentTypeModel> _filteredDocumentTypes = [];
  String? _categoryFilterId;
  bool _isLoadingDocTypes = false;

  // Document type form
  final _docTypeFormKey = GlobalKey<FormState>();
  final _docTypeNameController = TextEditingController();
  String? _selectedCategoryId;
  bool _allowMultipleDocuments = false;
  bool _isUploadable = true;
  bool _hasExpiryDate = false;
  bool _hasNotApplicableOption = false;
  bool _requiresSignature = false;
  int _signatureCount = 0;
  DocumentTypeModel? _editingDocType;

  // Track individual operations
  final Set<String> _updatingDocTypes = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _docTypeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
    });

    try {
      // Load companies first
      await _loadCompanies();

      // Then load other data in parallel
      await Future.wait([
        _loadAllDocumentTypes(),
        if (_selectedCompanyId != null) _loadEnabledCategories(),
      ]);

      // Set initial category for form
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final categories = categoryProvider.categories;
      if (categories.isNotEmpty && _selectedCategoryId == null) {
        setState(() {
          _selectedCategoryId = categories[0].id;
        });
      }

    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList();

      setState(() {
        _companies = companies;
        if (companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = companies[0]['id'] as String;
        }
      });
    } catch (e) {
      throw Exception('Failed to load companies: $e');
    }
  }

  Future<void> _loadAllDocumentTypes() async {
    setState(() {
      _isLoadingDocTypes = true;
    });

    try {
      final docTypesSnapshot = await FirebaseFirestore.instance
          .collection('documentTypes')
          .get();

      final docTypes = docTypesSnapshot.docs.map((doc) {
        return DocumentTypeModel.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _allDocumentTypes = docTypes;
        _applyDocumentTypeFilter();
      });
    } catch (e) {
      print('Error loading document types: $e');
      _showSnackBar('Error loading document types: $e', Colors.red);
    } finally {
      setState(() {
        _isLoadingDocTypes = false;
      });
    }
  }

  void _applyDocumentTypeFilter() {
    if (_categoryFilterId == null) {
      _filteredDocumentTypes = List.from(_allDocumentTypes);
    } else {
      _filteredDocumentTypes = _allDocumentTypes
          .where((docType) => docType.categoryId == _categoryFilterId)
          .toList();
    }
  }

  Future<void> _loadEnabledCategories() async {
    if (_selectedCompanyId == null) return;

    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final configDoc = await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(_selectedCompanyId)
          .get();

      Map<String, bool> enabledCategories = {};

      if (configDoc.exists) {
        final data = configDoc.data() as Map<String, dynamic>;
        if (data.containsKey('enabledCategories')) {
          enabledCategories = Map<String, bool>.from(data['enabledCategories']);
        }
      }

      // Get all categories and set defaults
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final allCategories = categoryProvider.categories;

      for (var category in allCategories) {
        if (!enabledCategories.containsKey(category.id)) {
          enabledCategories[category.id] = true;
        }
      }

      setState(() {
        _enabledCategories = enabledCategories;
      });
    } catch (e) {
      _showSnackBar('Error loading category configuration: $e', Colors.red);
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedCompanyId == null) {
      _showSnackBar('Please select a company', Colors.red);
      return;
    }

    setState(() {
      _isSavingSettings = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(_selectedCompanyId)
          .set({
        'enabledCategories': _enabledCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSnackBar('Category settings saved successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving settings: $e', Colors.red);
    } finally {
      setState(() {
        _isSavingSettings = false;
      });
    }
  }

  Future<void> _saveDocumentType() async {
    if (!_docTypeFormKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnackBar('Please select a category', Colors.red);
      return;
    }

    if (_requiresSignature && _signatureCount <= 0) {
      _showSnackBar('Signature count must be greater than 0', Colors.red);
      return;
    }

    setState(() {
      _isSavingDocType = true;
    });

    try {
      final docTypeData = {
        'name': _docTypeNameController.text.trim(),
        'categoryId': _selectedCategoryId,
        'allowMultipleDocuments': _allowMultipleDocuments,
        'isUploadable': _isUploadable,
        'hasExpiryDate': _hasExpiryDate,
        'hasNotApplicableOption': _hasNotApplicableOption,
        'requiresSignature': _requiresSignature,
        'signatureCount': _requiresSignature ? _signatureCount : 0,
      };

      if (_editingDocType != null) {
        await FirebaseFirestore.instance
            .collection('documentTypes')
            .doc(_editingDocType!.id)
            .update(docTypeData);
        _showSnackBar('Document type updated successfully', Colors.green);
      } else {
        await FirebaseFirestore.instance
            .collection('documentTypes')
            .add(docTypeData);
        _showSnackBar('Document type added successfully', Colors.green);
      }

      _resetDocTypeForm();
      await _loadAllDocumentTypes();
    } catch (e) {
      _showSnackBar('Error saving document type: $e', Colors.red);
    } finally {
      setState(() {
        _isSavingDocType = false;
      });
    }
  }

  void _resetDocTypeForm() {
    setState(() {
      _editingDocType = null;
      _docTypeNameController.clear();
      _allowMultipleDocuments = false;
      _isUploadable = true;
      _hasExpiryDate = false;
      _hasNotApplicableOption = false;
      _requiresSignature = false;
      _signatureCount = 0;
    });
  }

  void _editDocumentType(DocumentTypeModel docType) {
    setState(() {
      _editingDocType = docType;
      _docTypeNameController.text = docType.name;
      _selectedCategoryId = docType.categoryId;
      _allowMultipleDocuments = docType.allowMultipleDocuments;
      _isUploadable = docType.isUploadable;
      _hasExpiryDate = docType.hasExpiryDate;
      _hasNotApplicableOption = docType.hasNotApplicableOption;
      _requiresSignature = docType.requiresSignature;
      _signatureCount = docType.signatureCount;
    });
  }

  Future<void> _deleteDocumentType(String docTypeId) async {
    final confirm = await _showConfirmDialog(
      'Delete Document Type',
      'Are you sure you want to delete this document type? This action cannot be undone.',
    );

    if (confirm != true) return;

    setState(() {
      _isDeletingDocType = true;
      _updatingDocTypes.add(docTypeId);
    });

    try {
      await FirebaseFirestore.instance
          .collection('documentTypes')
          .doc(docTypeId)
          .delete();

      if (_editingDocType?.id == docTypeId) {
        _resetDocTypeForm();
      }

      await _loadAllDocumentTypes();
      _showSnackBar('Document type deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error deleting document type: $e', Colors.red);
    } finally {
      setState(() {
        _isDeletingDocType = false;
        _updatingDocTypes.remove(docTypeId);
      });
    }
  }

  Future<void> _quickUpdateDocumentType(DocumentTypeModel docType, Map<String, dynamic> updates) async {
    setState(() {
      _updatingDocTypes.add(docType.id);
    });

    try {
      await FirebaseFirestore.instance
          .collection('documentTypes')
          .doc(docType.id)
          .update(updates);

      // Update local state immediately for better UX
      final index = _allDocumentTypes.indexWhere((dt) => dt.id == docType.id);
      if (index != -1) {
        // Create updated document type
        final updatedDocType = DocumentTypeModel(
          id: docType.id,
          categoryId: updates['categoryId'] ?? docType.categoryId,
          name: updates['name'] ?? docType.name,
          allowMultipleDocuments: updates['allowMultipleDocuments'] ?? docType.allowMultipleDocuments,
          isUploadable: updates['isUploadable'] ?? docType.isUploadable,
          hasExpiryDate: updates['hasExpiryDate'] ?? docType.hasExpiryDate,
          hasNotApplicableOption: updates['hasNotApplicableOption'] ?? docType.hasNotApplicableOption,
          requiresSignature: updates['requiresSignature'] ?? docType.requiresSignature,
          signatureCount: updates['signatureCount'] ?? docType.signatureCount,
        );

        setState(() {
          _allDocumentTypes[index] = updatedDocType;
          _applyDocumentTypeFilter();
        });
      }
    } catch (e) {
      _showSnackBar('Error updating document type: $e', Colors.red);
      // Refresh data on error
      await _loadAllDocumentTypes();
    } finally {
      setState(() {
        _updatingDocTypes.remove(docType.id);
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Category Management',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    // Show main loading screen for initial load
    if (_isInitialLoading || categoryProvider.isLoading) {
      return AppScaffoldWrapper(
        title: 'Category Management',
        backgroundColor: Colors.grey[100],
        child: const LoadingIndicator(message: 'Loading category management...'),
      );
    }

    // Show error screen
    if (categoryProvider.error != null || _error != null) {
      return AppScaffoldWrapper(
        title: 'Category Management',
        backgroundColor: Colors.grey[100],
        child: ErrorDisplay(
          error: categoryProvider.error ?? _error ?? 'Unknown error',
          onRetry: _loadData,
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'Category Management',
      backgroundColor: Colors.grey[100],
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Category Settings with loading overlay
                Stack(
                  children: [
                    CompanyCategorySettings(
                      companies: _companies,
                      selectedCompanyId: _selectedCompanyId,
                      enabledCategories: _enabledCategories,
                      categories: categoryProvider.categories,
                      onCompanyChanged: (companyId) {
                        setState(() {
                          _selectedCompanyId = companyId;
                        });
                        _loadEnabledCategories();
                      },
                      onCategoryToggle: (categoryId, enabled) {
                        setState(() {
                          _enabledCategories[categoryId] = enabled;
                        });
                      },
                      onSave: _saveConfiguration,
                      isLoading: _isSavingSettings,
                    ),
                    if (_isLoadingCategories)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Document Type Form with loading overlay
                Stack(
                  children: [
                    DocumentTypeForm(
                      formKey: _docTypeFormKey,
                      nameController: _docTypeNameController,
                      categories: categoryProvider.categories,
                      selectedCategoryId: _selectedCategoryId,
                      allowMultipleDocuments: _allowMultipleDocuments,
                      isUploadable: _isUploadable,
                      hasExpiryDate: _hasExpiryDate,
                      hasNotApplicableOption: _hasNotApplicableOption,
                      requiresSignature: _requiresSignature,
                      signatureCount: _signatureCount,
                      editingDocType: _editingDocType,
                      isLoading: _isSavingDocType,
                      onCategoryChanged: (categoryId) {
                        setState(() {
                          _selectedCategoryId = categoryId;
                        });
                      },
                      onAllowMultipleChanged: (value) {
                        setState(() {
                          _allowMultipleDocuments = value;
                        });
                      },
                      onUploadableChanged: (value) {
                        setState(() {
                          _isUploadable = value;
                        });
                      },
                      onExpiryDateChanged: (value) {
                        setState(() {
                          _hasExpiryDate = value;
                        });
                      },
                      onNotApplicableChanged: (value) {
                        setState(() {
                          _hasNotApplicableOption = value;
                        });
                      },
                      onSignatureRequiredChanged: (value) {
                        setState(() {
                          _requiresSignature = value;
                          if (!_requiresSignature) {
                            _signatureCount = 0;
                          } else if (_signatureCount == 0) {
                            _signatureCount = 1;
                          }
                        });
                      },
                      onSignatureCountChanged: (count) {
                        setState(() {
                          _signatureCount = count;
                        });
                      },
                      onSave: _saveDocumentType,
                      onReset: _resetDocTypeForm,
                    ),
                    if (_isSavingDocType)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Saving...',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Document Types Table with loading overlay
                Stack(
                  children: [
                    DocumentTypesTable(
                      documentTypes: _filteredDocumentTypes,
                      categories: categoryProvider.categories,
                      categoryFilter: _categoryFilterId,
                      onCategoryFilterChanged: (categoryId) {
                        setState(() {
                          _categoryFilterId = categoryId;
                          _applyDocumentTypeFilter();
                        });
                      },
                      onEdit: _editDocumentType,
                      onDelete: _deleteDocumentType,
                      onQuickUpdate: _quickUpdateDocumentType,
                    ),
                    if (_isLoadingDocTypes)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.7),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Loading document types...',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Global overlay for delete operation
          if (_isDeletingDocType)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Deleting document type...',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}