import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';


class CompanyDocumentOverrideScreen extends StatefulWidget {
  const CompanyDocumentOverrideScreen({Key? key}) : super(key: key);

  @override
  State<CompanyDocumentOverrideScreen> createState() => _CompanyDocumentOverrideScreenState();
}

class _CompanyDocumentOverrideScreenState extends State<CompanyDocumentOverrideScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;
  String? _selectedCompanyId;

  List<CompanyModel> _companies = [];
  List<CategoryModel> _allCategories = [];
  List<DocumentTypeModel> _naDocumentTypes = []; // Only doc types with hasNotApplicableOption
  // documentTypeId -> isActive (null = not overridden = active by default)
  Map<String, bool> _activeState = {};

  @override
  void dispose() {
    // Switching document types on/off changes every company screen's totals.
    CategoryProvider.markOverridesStale();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load companies
      final companiesSnapshot = await _firestore.collection('companies').get();
      _companies = companiesSnapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();

      // Load all categories
      final categoriesSnapshot = await _firestore.collection('categories').get();
      _allCategories = categoriesSnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
      _allCategories.sort((a, b) => a.order.compareTo(b.order));

      // Load only document types that have the N/A option
      final docTypesSnapshot = await _firestore.collection('documentTypes').get();
      _naDocumentTypes = docTypesSnapshot.docs
          .map((doc) => DocumentTypeModel.fromMap(doc.data(), doc.id))
          .where((dt) => dt.hasNotApplicableOption)
          .toList();

    } catch (e) {
      _error = 'Error loading data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOverridesForCompany(String companyId) async {
    setState(() => _isLoading = true);

    try {
      final overridesSnapshot = await _firestore
          .collection('companyDocumentTypeSettings')
          .where('companyId', isEqualTo: companyId)
          .get();

      // Start with all NA doc types as active (true)
      final Map<String, bool> state = {};
      for (var docType in _naDocumentTypes) {
        state[docType.id] = true;
      }

      // Apply saved overrides
      for (var doc in overridesSnapshot.docs) {
        final data = doc.data();
        final documentTypeId = data['documentTypeId'] as String?;
        if (documentTypeId == null) continue;
        final overrides = data['overrides'] as Map<String, dynamic>? ?? {};
        if (overrides.containsKey('isActive')) {
          state[documentTypeId] = overrides['isActive'] as bool;
        }
      }

      setState(() {
        _activeState = state;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDocumentTypeActive(String documentTypeId, bool isActive) async {
    if (_selectedCompanyId == null) return;

    // Optimistically update UI
    setState(() {
      _activeState[documentTypeId] = isActive;
    });

    try {
      final docId = '${_selectedCompanyId}_$documentTypeId';

      // Get existing overrides for this document type to preserve them
      final existingDoc = await _firestore
          .collection('companyDocumentTypeSettings')
          .doc(docId)
          .get();

      Map<String, dynamic> existingOverrides = {};
      if (existingDoc.exists) {
        final data = existingDoc.data()!;
        existingOverrides = Map<String, dynamic>.from(data['overrides'] ?? {});
      }

      existingOverrides['isActive'] = isActive;

      await _firestore
          .collection('companyDocumentTypeSettings')
          .doc(docId)
          .set({
        'companyId': _selectedCompanyId,
        'documentTypeId': documentTypeId,
        'overrides': existingOverrides,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Document type activated' : 'Document type deactivated'),
            backgroundColor: isActive ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _activeState[documentTypeId] = !isActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Document Settings',
        child: const Center(child: Text('You do not have permission to access this page')),
      );
    }

    Widget content;
    if (_isLoading && _companies.isEmpty) {
      content = const LoadingIndicator(message: 'Loading...');
    } else if (_error != null) {
      content = ErrorDisplay(error: _error!, onRetry: _loadData);
    } else {
      content = _buildContent();
    }

    return AppScaffoldWrapper(
      title: 'Company Document Settings',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildContent() {
    final deactivatedCount = _activeState.values.where((v) => !v).length;
    final activeCount = _activeState.values.where((v) => v).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Type Activation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a company and activate or deactivate the document types '
                    'that have an N/A option. Deactivated document types will not '
                    'appear in the audit checklist and will not count towards the '
                    'compliance total for that company.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Company selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Company',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCompanyId,
                    items: _companies.map((company) {
                      return DropdownMenuItem<String>(
                        value: company.id,
                        child: Text(company.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompanyId = value;
                        _activeState = {};
                      });
                      if (value != null) {
                        _loadOverridesForCompany(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          if (_selectedCompanyId != null) ...[
            const SizedBox(height: 16),

            // Summary row
            if (_activeState.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _buildSummaryChip(
                      '$activeCount Active',
                      Colors.green,
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryChip(
                      '$deactivatedCount Deactivated',
                      Colors.orange,
                      Icons.block_outlined,
                    ),
                  ],
                ),
              ),

            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_naDocumentTypes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No document types with N/A option found.')),
                ),
              )
            else
              ..._buildGroupedDocumentTypes(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedDocumentTypes() {
    // Group NA doc types by category
    final Map<String, List<DocumentTypeModel>> byCategory = {};
    for (var docType in _naDocumentTypes) {
      byCategory.putIfAbsent(docType.categoryId, () => []).add(docType);
    }

    // Build cards grouped by category, in category order
    final widgets = <Widget>[];
    for (var category in _allCategories) {
      final docTypes = byCategory[category.id];
      if (docTypes == null || docTypes.isEmpty) continue;

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 18, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${docTypes.length} document${docTypes.length > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              // Document types
              ...docTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final docType = entry.value;
                final isActive = _activeState[docType.id] ?? true;

                return Column(
                  children: [
                    if (index > 0)
                      Divider(height: 1, indent: 16, endIndent: 16,
                          color: Colors.grey.shade200),
                    _buildDocumentTypeRow(docType, isActive),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    }

    // Handle doc types that don't match any known category
    final knownCategoryIds = _allCategories.map((c) => c.id).toSet();
    final uncategorized = _naDocumentTypes
        .where((dt) => !knownCategoryIds.contains(dt.categoryId))
        .toList();
    if (uncategorized.isNotEmpty) {
      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Uncategorized',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              ...uncategorized.asMap().entries.map((entry) {
                final isActive = _activeState[entry.value.id] ?? true;
                return Column(
                  children: [
                    if (entry.key > 0)
                      Divider(height: 1, indent: 16, endIndent: 16,
                          color: Colors.grey.shade200),
                    _buildDocumentTypeRow(entry.value, isActive),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDocumentTypeRow(DocumentTypeModel docType, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.green : Colors.orange,
            ),
          ),

          // Document type name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.black87 : Colors.grey.shade500,
                    decoration: isActive ? null : TextDecoration.none,
                  ),
                ),
                if (!isActive)
                  const Text(
                    'Deactivated — hidden from checklist',
                    style: TextStyle(fontSize: 11, color: Colors.orange),
                  ),
              ],
            ),
          ),

          // Active/inactive toggle
          Switch(
            value: isActive,
            activeColor: Colors.green,
            inactiveTrackColor: Colors.orange.shade200,
            onChanged: (value) => _setDocumentTypeActive(docType.id, value),
          ),
        ],
      ),
    );
  }
}
