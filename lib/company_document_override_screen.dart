import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
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
  List<DocumentTypeModel> _allDocumentTypes = [];
  Map<String, Map<String, dynamic>> _currentOverrides = {};

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

      // Load ALL document types from all categories
      final docTypesSnapshot = await _firestore.collection('documentTypes').get();
      _allDocumentTypes = docTypesSnapshot.docs
          .map((doc) => DocumentTypeModel.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      _error = 'Error loading data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOverridesForCompany() async {
    if (_selectedCompanyId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load existing overrides for this company
      final overridesSnapshot = await _firestore
          .collection('companyDocumentTypeSettings')
          .where('companyId', isEqualTo: _selectedCompanyId)
          .get();

      _currentOverrides = {};
      for (var doc in overridesSnapshot.docs) {
        final data = doc.data();
        final documentTypeId = data['documentTypeId'] as String;
        final overrides = data['overrides'] as Map<String, dynamic>;
        _currentOverrides[documentTypeId] = overrides;
      }

      print('Loaded ${_currentOverrides.length} overrides for company $_selectedCompanyId');

    } catch (e) {
      _error = 'Error loading overrides: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveOverride(String documentTypeId, String field, dynamic value) async {
    if (_selectedCompanyId == null) return;

    try {
      final docId = '${_selectedCompanyId}_$documentTypeId';

      // Get existing overrides for this document type
      Map<String, dynamic> existingOverrides =
      Map<String, dynamic>.from(_currentOverrides[documentTypeId] ?? {});

      // Update the specific field
      existingOverrides[field] = value;

      // Save to Firestore
      await _firestore
          .collection('companyDocumentTypeSettings')
          .doc(docId)
          .set({
        'companyId': _selectedCompanyId,
        'documentTypeId': documentTypeId,
        'overrides': existingOverrides,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local state
      setState(() {
        _currentOverrides[documentTypeId] = existingOverrides;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Override saved: $field = $value'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving override: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeOverride(String documentTypeId, String field) async {
    if (_selectedCompanyId == null) return;

    try {
      final docId = '${_selectedCompanyId}_$documentTypeId';

      // Get existing overrides
      Map<String, dynamic> existingOverrides =
      Map<String, dynamic>.from(_currentOverrides[documentTypeId] ?? {});

      // Remove the field
      existingOverrides.remove(field);

      if (existingOverrides.isEmpty) {
        // Delete the entire document if no overrides left
        await _firestore
            .collection('companyDocumentTypeSettings')
            .doc(docId)
            .delete();

        setState(() {
          _currentOverrides.remove(documentTypeId);
        });
      } else {
        // Update with remaining overrides
        await _firestore
            .collection('companyDocumentTypeSettings')
            .doc(docId)
            .update({
          'overrides': existingOverrides,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _currentOverrides[documentTypeId] = existingOverrides;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Override removed: $field'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing override: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Document Overrides',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    Widget content;
    if (_isLoading) {
      content = const LoadingIndicator(message: 'Loading...');
    } else if (_error != null) {
      content = ErrorDisplay(
        error: _error!,
        onRetry: _loadData,
      );
    } else {
      content = _buildContent();
    }

    return AppScaffoldWrapper(
      title: 'Company Document Overrides',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Document Type Overrides',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Customize document type settings for specific companies. '
                        'This creates the companyDocumentTypeSettings collection in Firebase. '
                        'Only changed settings are stored - defaults are used for everything else.',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Company Selection
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
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Company',
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
                        _currentOverrides = {};
                      });
                      if (value != null) {
                        _loadOverridesForCompany();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Document Types List
          if (_selectedCompanyId != null && _allDocumentTypes.isNotEmpty) ...[
            Text(
              'All Document Types (${_allDocumentTypes.length} total)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            ...(_allDocumentTypes.map((docType) => _buildDocumentTypeCard(docType)).toList()),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTypeCard(DocumentTypeModel docType) {
    final hasOverrides = _currentOverrides.containsKey(docType.id);
    final overrides = _currentOverrides[docType.id] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: hasOverrides ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    docType.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (hasOverrides)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${overrides.length} OVERRIDE${overrides.length > 1 ? 'S' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Override Toggles
            _buildOverrideToggle(
              docType,
              'Has Not Applicable Option',
              'hasNotApplicableOption',
              docType.hasNotApplicableOption,
              overrides['hasNotApplicableOption'],
            ),

            _buildOverrideToggle(
              docType,
              'Requires Signature',
              'requiresSignature',
              docType.requiresSignature,
              overrides['requiresSignature'],
            ),

            _buildOverrideToggle(
              docType,
              'Has Expiry Date',
              'hasExpiryDate',
              docType.hasExpiryDate,
              overrides['hasExpiryDate'],
            ),

            _buildOverrideToggle(
              docType,
              'Is Uploadable',
              'isUploadable',
              docType.isUploadable,
              overrides['isUploadable'],
            ),

            _buildOverrideToggle(
              docType,
              'Allow Multiple Documents',
              'allowMultipleDocuments',
              docType.allowMultipleDocuments,
              overrides['allowMultipleDocuments'],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverrideToggle(
      DocumentTypeModel docType,
      String label,
      String fieldName,
      bool defaultValue,
      dynamic overrideValue,
      ) {
    final bool currentValue = overrideValue ?? defaultValue;
    final bool hasOverride = overrideValue != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: hasOverride ? Colors.blue.shade700 : null,
                fontWeight: hasOverride ? FontWeight.bold : null,
              ),
            ),
          ),

          // Current value indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasOverride
                  ? Colors.blue.shade100
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hasOverride
                  ? 'Override: ${currentValue ? 'Yes' : 'No'}'
                  : 'Default: ${defaultValue ? 'Yes' : 'No'}',
              style: TextStyle(
                fontSize: 12,
                color: hasOverride ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Toggle buttons
          if (!hasOverride) ...[
            ElevatedButton(
              onPressed: () => _saveOverride(docType.id, fieldName, !defaultValue),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                'Set ${!defaultValue ? 'Yes' : 'No'}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ] else ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _saveOverride(docType.id, fieldName, !currentValue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: Text(
                    !currentValue ? 'Yes' : 'No',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => _removeOverride(docType.id, fieldName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}