import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  String? _selectedCompanyId;
  List<Map<String, dynamic>> _companies = [];
  Map<String, bool> _enabledCategories = {};
  List<DocumentTypeModel> _allDocumentTypes = [];
  List<DocumentTypeModel> _filteredDocumentTypes = [];
  String? _categoryFilterId;

  // For adding new category
  final _newCategoryFormKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  final _categoryDescriptionController = TextEditingController();
  int _categoryOrder = 0;
  bool _isCreatingNewCategory = false;

  // For adding/editing document type
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

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryNameController.dispose();
    _categoryDescriptionController.dispose();
    _docTypeNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load companies
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      final companies = companiesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc.data()['name'] ?? 'Unnamed Company',
      }).toList();

      // Set initial state
      setState(() {
        _companies = companies;
        if (companies.isNotEmpty && _selectedCompanyId == null) {
          _selectedCompanyId = companies[0]['id'] as String;
        }
        _isLoading = false;
      });

      // Load enabled categories if company is selected
      if (_selectedCompanyId != null) {
        _loadEnabledCategories();
      }

      // Load all document types
      await _loadAllDocumentTypes();

      // For the add new document type section, set the initial selected category
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
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllDocumentTypes() async {
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
      _isLoading = true;
    });

    try {
      // Check if configuration exists
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

      // Get all categories
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final allCategories = categoryProvider.categories;

      // Initialize missing categories as enabled by default
      for (var category in allCategories) {
        if (!enabledCategories.containsKey(category.id)) {
          enabledCategories[category.id] = true; // Enable by default
        }
      }

      setState(() {
        _enabledCategories = enabledCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading category configuration: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (_selectedCompanyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('companySettings')
          .doc(_selectedCompanyId)
          .set({
        'enabledCategories': _enabledCategories,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _addNewCategory() async {
    if (!_newCategoryFormKey.currentState!.validate()) {
      return null;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the new category in Firestore
      final newCategory = {
        'name': _categoryNameController.text.trim(),
        'description': _categoryDescriptionController.text.trim(),
        'order': _categoryOrder,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('categories')
          .add(newCategory);

      final categoryId = docRef.id;

      // Refresh categories
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.initialize();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _categoryNameController.clear();
      _categoryDescriptionController.clear();
      _categoryOrder = 0;
      setState(() {
        _isCreatingNewCategory = false;
      });

      return categoryId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding category: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDocumentType() async {
    if (!_docTypeFormKey.currentState!.validate()) {
      return;
    }

    // Handle new category creation if needed
    if (_isCreatingNewCategory) {
      final newCategoryId = await _addNewCategory();
      if (newCategoryId != null) {
        setState(() {
          _selectedCategoryId = newCategoryId;
        });
      } else {
        // Category creation failed
        return;
      }
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate signature count if signatures are required
    if (_requiresSignature && _signatureCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signature count must be greater than 0 if signatures are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create/update document type data
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
        // Update existing document type
        await FirebaseFirestore.instance
            .collection('documentTypes')
            .doc(_editingDocType!.id)
            .update(docTypeData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document type updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new document type
        await FirebaseFirestore.instance
            .collection('documentTypes')
            .add(docTypeData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document type added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reset form
      _resetDocTypeForm();

      // Refresh document types
      await _loadAllDocumentTypes();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving document type: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
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

      // Scroll to form
      // In a real app, you might want to use a ScrollController to scroll to the form
    });
  }

  Future<void> _deleteDocumentType(String docTypeId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this document type? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('documentTypes')
          .doc(docTypeId)
          .delete();

      // Reset form if currently editing this document type
      if (_editingDocType?.id == docTypeId) {
        _resetDocTypeForm();
      }

      // Refresh document types
      await _loadAllDocumentTypes();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document type deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting document type: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    // Check if category has document types
    final docTypes = _allDocumentTypes.where((dt) => dt.categoryId == categoryId).toList();

    if (docTypes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete category with existing document types. Delete the document types first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this category? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .delete();

      // Update category provider
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.initialize();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

    Widget content;
    if (categoryProvider.isLoading || _isLoading) {
      content = const LoadingIndicator(message: 'Loading categories...');
    } else if (categoryProvider.error != null || _error != null) {
      content = ErrorDisplay(
        error: categoryProvider.error ?? _error ?? 'Unknown error',
        onRetry: _loadData,
      );
    } else {
      content = Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Manage Categories'),
                Tab(text: 'Document Types'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // First Tab - Manage Categories
                _buildManageCategoriesTab(categoryProvider),

                // Second Tab - Document Types
                _buildDocumentTypesTab(categoryProvider),
              ],
            ),
          ),
        ],
      );
    }

    return AppScaffoldWrapper(
      title: 'Category Management',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildManageCategoriesTab(CategoryProvider categoryProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable/Disable Categories by Company',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Control which categories are enabled for specific companies.',
                  ),
                  const SizedBox(height: 16),

                  // Company selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Company',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCompanyId,
                    items: _companies.map((company) {
                      return DropdownMenuItem<String>(
                        value: company['id'] as String,
                        child: Text(company['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompanyId = value;
                      });
                      _loadEnabledCategories();
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedCompanyId != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton(
                          onPressed: _saveConfiguration,
                          child: const Text('Save Settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoryProvider.categories.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final category = categoryProvider.categories[index];
                        return Row(
                          children: [
                            Expanded(
                              child: SwitchListTile(
                                title: Text(category.name),
                                subtitle: Text(category.description),
                                value: _enabledCategories[category.id] ?? true,
                                onChanged: (value) {
                                  setState(() {
                                    _enabledCategories[category.id] = value;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(category.id),
                              tooltip: 'Delete Category',
                            ),
                            const SizedBox(width: 8),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Save Category Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTypesTab(CategoryProvider categoryProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add/Edit Document Type Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _docTypeFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingDocType != null
                          ? 'Edit Document Type'
                          : 'Add New Document Type',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    // Category selection with option to create new
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _isCreatingNewCategory
                              ? Form(
                            key: _newCategoryFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _categoryNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'New Category Name',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Health and Safety',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a category name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _categoryDescriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., Documents related to workplace health and safety',
                                  ),
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a description';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _categoryOrder.toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Display Order',
                                    border: OutlineInputBorder(),
                                    hintText: 'e.g., 1',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an order number';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _categoryOrder = int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                              ],
                            ),
                          )
                              : DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCategoryId,
                            items: categoryProvider.categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            },
                            validator: (value) {
                              if (!_isCreatingNewCategory && (value == null || value.isEmpty)) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCreatingNewCategory = !_isCreatingNewCategory;
                            });
                          },
                          icon: Icon(_isCreatingNewCategory ? Icons.list : Icons.add),
                          label: Text(_isCreatingNewCategory ? 'Select Existing' : 'Create New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Document type name
                    TextFormField(
                      controller: _docTypeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Type Name',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Fire Safety Certificate',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a document type name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Properties checkboxes in a grid
                    Text(
                      'Document Type Properties',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 16,
                      runSpacing: 0,
                      children: [
                        SizedBox(
                          width: 250,
                          child: CheckboxListTile(
                            title: const Text('Allow Multiple Documents'),
                            value: _allowMultipleDocuments,
                            onChanged: (value) {
                              setState(() {
                                _allowMultipleDocuments = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: CheckboxListTile(
                            title: const Text('Is Uploadable'),
                            value: _isUploadable,
                            onChanged: (value) {
                              setState(() {
                                _isUploadable = value ?? true;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: CheckboxListTile(
                            title: const Text('Has Expiry Date'),
                            value: _hasExpiryDate,
                            onChanged: (value) {
                              setState(() {
                                _hasExpiryDate = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: CheckboxListTile(
                            title: const Text('Not Applicable Option'),
                            value: _hasNotApplicableOption,
                            onChanged: (value) {
                              setState(() {
                                _hasNotApplicableOption = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: CheckboxListTile(
                            title: const Text('Requires Signature'),
                            value: _requiresSignature,
                            onChanged: (value) {
                              setState(() {
                                _requiresSignature = value ?? false;
                                if (!_requiresSignature) {
                                  _signatureCount = 0;
                                } else if (_signatureCount == 0) {
                                  _signatureCount = 1;
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ),
                      ],
                    ),

                    // Signature count if required
                    if (_requiresSignature) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _signatureCount.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Signature Count',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 1',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter signature count';
                          }
                          final count = int.tryParse(value);
                          if (count == null || count <= 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _signatureCount = int.tryParse(value) ?? 1;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_editingDocType != null)
                          OutlinedButton(
                            onPressed: _resetDocTypeForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Cancel Editing'),
                          ),
                        const Spacer(),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveDocumentType,
                            child: _isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : Text(_editingDocType != null ? 'Update Document Type' : 'Add Document Type'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Existing Document Types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Document Types',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Category filter dropdown
                  DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                    ),
                    value: _categoryFilterId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...categoryProvider.categories.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoryFilterId = value;
                        _applyDocumentTypeFilter();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Document types table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Multiple')),
                        DataColumn(label: Text('Uploadable')),
                        DataColumn(label: Text('Expiry')),
                        DataColumn(label: Text('N/A Option')),
                        DataColumn(label: Text('Signatures')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _filteredDocumentTypes.map((docType) {
                        // Find category name
                        String categoryName = 'Unknown';
                        try {
                          final category = categoryProvider.categories
                              .firstWhere((c) => c.id == docType.categoryId);
                          categoryName = category.name;
                        } catch (_) {}

                        return DataRow(
                          cells: [
                            DataCell(Text(docType.name)),
                            DataCell(Text(categoryName)),
                            // Multiple documents
                            DataCell(
                              Switch(
                                value: docType.allowMultipleDocuments,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('documentTypes')
                                      .doc(docType.id)
                                      .update({'allowMultipleDocuments': value});
                                  _loadAllDocumentTypes();
                                },
                              ),
                            ),
                            // Uploadable
                            DataCell(
                              Switch(
                                value: docType.isUploadable,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('documentTypes')
                                      .doc(docType.id)
                                      .update({'isUploadable': value});
                                  _loadAllDocumentTypes();
                                },
                              ),
                            ),
                            // Has expiry date
                            DataCell(
                              Switch(
                                value: docType.hasExpiryDate,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('documentTypes')
                                      .doc(docType.id)
                                      .update({'hasExpiryDate': value});
                                  _loadAllDocumentTypes();
                                },
                              ),
                            ),
                            // Not applicable option
                            DataCell(
                              Switch(
                                value: docType.hasNotApplicableOption,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('documentTypes')
                                      .doc(docType.id)
                                      .update({'hasNotApplicableOption': value});
                                  _loadAllDocumentTypes();
                                },
                              ),
                            ),
                            // Signature info
                            DataCell(
                              docType.requiresSignature
                                  ? Row(
                                children: [
                                  Text('${docType.signatureCount}'),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () {
                                      // Show dialog to edit signature count
                                      _showSignatureCountDialog(docType);
                                    },
                                  ),
                                ],
                              )
                                  : Switch(
                                value: docType.requiresSignature,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('documentTypes')
                                      .doc(docType.id)
                                      .update({
                                    'requiresSignature': value,
                                    'signatureCount': value ? 1 : 0,
                                  });
                                  _loadAllDocumentTypes();
                                },
                              ),
                            ),
                            // Actions
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editDocumentType(docType),
                                    tooltip: 'Edit Document Type',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteDocumentType(docType.id),
                                    tooltip: 'Delete Document Type',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show signature count editing dialog
  Future<void> _showSignatureCountDialog(DocumentTypeModel docType) async {
    int count = docType.signatureCount;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Signature Count'),
        content: TextFormField(
          initialValue: count.toString(),
          decoration: const InputDecoration(
            labelText: 'Number of Signatures Required',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            count = int.tryParse(value) ?? 1;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (count > 0) {
                await FirebaseFirestore.instance
                    .collection('documentTypes')
                    .doc(docType.id)
                    .update({
                  'signatureCount': count,
                });
                _loadAllDocumentTypes();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signature count must be greater than 0'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}