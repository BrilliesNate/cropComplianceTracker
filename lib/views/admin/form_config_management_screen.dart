import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/document_type_model.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';

class FormConfigManagementScreen extends StatefulWidget {
  const FormConfigManagementScreen({Key? key}) : super(key: key);

  @override
  State<FormConfigManagementScreen> createState() => _FormConfigManagementScreenState();
}

class _FormConfigManagementScreenState extends State<FormConfigManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _error;
  List<DocumentTypeModel> _nonUploadableDocTypes = [];
  List<String> _availableJsonConfigs = [];
  DocumentTypeModel? _selectedDocType;
  String? _selectedConfigFile;
  bool _isCollectionCreated = false;
  Set<String> _configuredDocTypes = {};

  @override
  void initState() {
    super.initState();
    _checkCollection();
  }

  Future<void> _checkCollection() async {
    setState(() => _isLoading = true);

    try {
      // Check if collection exists
      final snapshot = await _firestore.collection('formConfig').limit(1).get();
      setState(() => _isCollectionCreated = snapshot.size > 0);

      // If collection exists, get configured document types
      if (_isCollectionCreated) {
        final configsSnapshot = await _firestore.collection('formConfig').get();
        Set<String> configuredIds = {};
        for (var doc in configsSnapshot.docs) {
          if (doc.id != 'init_document') {
            configuredIds.add(doc.id);
          }
        }
        setState(() => _configuredDocTypes = configuredIds);
      }

      await _loadAll();
    } catch (e) {
      print('Error checking collection: $e');
      setState(() => _error = 'Error checking collection: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _createCollection() async {
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('formConfig').doc('init_document').set({
        'created': FieldValue.serverTimestamp(),
        'note': 'Initialization document'
      });

      setState(() => _isCollectionCreated = true);
      await _loadAll();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collection created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating collection: $e');
      setState(() => _error = 'Error creating collection: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadDocumentTypes(),
      _loadJsonFiles()
    ]);
  }

  Future<void> _loadDocumentTypes() async {
    try {
      final List<DocumentTypeModel> docTypes = [];

      // Get categories
      final categorySnapshot = await _firestore.collection('categories').get();

      // For each category, get non-uploadable document types
      for (var category in categorySnapshot.docs) {
        final docTypesSnapshot = await _firestore
            .collection('documentTypes')
            .where('categoryId', isEqualTo: category.id)
            .where('isUploadable', isEqualTo: false)
            .get();

        for (var doc in docTypesSnapshot.docs) {
          // Skip if already configured
          if (_configuredDocTypes.contains(doc.id)) continue;

          final data = doc.data();
          docTypes.add(DocumentTypeModel.fromMap(data, doc.id));
        }
      }

      setState(() => _nonUploadableDocTypes = docTypes);
    } catch (e) {
      print('Error loading document types: $e');
    }
  }

  Future<void> _loadJsonFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final jsonPaths = manifestMap.keys
          .where((key) => key.startsWith('assets/formConfig/') && key.endsWith('.json'))
          .toList();

      setState(() {
        _availableJsonConfigs = jsonPaths.map((path) => path.split('/').last).toList();
      });
    } catch (e) {
      print('Error loading JSON files: $e');
    }
  }

  Future<void> _uploadConfig() async {
    if (_selectedDocType == null || _selectedConfigFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a document type and config file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store the document type name before the upload
    // This prevents null reference issues after clearing the selection
    final String docTypeName = _selectedDocType!.name;
    final String docTypeId = _selectedDocType!.id;

    setState(() => _isLoading = true);

    try {
      final jsonPath = 'assets/formConfig/$_selectedConfigFile';
      final jsonString = await rootBundle.loadString(jsonPath);
      final configJson = json.decode(jsonString);

      await _firestore.collection('formConfig').doc(docTypeId).set({
        'documentTypeId': docTypeId,
        'configJson': configJson,
      });

      // Add to configured list and reload
      _configuredDocTypes.add(docTypeId);

      // Clear selections BEFORE reloading (to avoid null reference)
      setState(() {
        _selectedDocType = null;
        _selectedConfigFile = null;
      });

      // Now reload the document types
      await _loadDocumentTypes();

      // Show success message with the stored name
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration for $docTypeName uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error uploading config: $e');
      setState(() => _error = 'Error uploading config: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading config: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Form Configuration',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading...')
          : _error != null
          ? ErrorDisplay(
        error: _error!,
        onRetry: _checkCollection,
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _isCollectionCreated
                              ? Icons.check_circle
                              : Icons.error,
                          color: _isCollectionCreated
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCollectionCreated
                              ? 'Collection exists'
                              : 'Collection does not exist',
                        ),
                        const Spacer(),
                        if (!_isCollectionCreated)
                          ElevatedButton(
                            onPressed: _createCollection,
                            child: const Text('Create Collection'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_isCollectionCreated) ...[
              const SizedBox(height: 16),

              // Document Type selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Document Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _nonUploadableDocTypes.isEmpty
                          ? const Text('No non-uploadable document types found')
                          : DropdownButtonFormField<DocumentTypeModel>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        hint: const Text('Select a document type'),
                        value: _selectedDocType,
                        items: _nonUploadableDocTypes.map((docType) {
                          return DropdownMenuItem<DocumentTypeModel>(
                            value: docType,
                            child: Text(docType.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDocType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // JSON file selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Config File',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _availableJsonConfigs.isEmpty
                          ? const Text('No JSON files found in assets/formConfig/')
                          : DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        hint: const Text('Select a config file'),
                        value: _selectedConfigFile,
                        items: _availableJsonConfigs.map((file) {
                          return DropdownMenuItem<String>(
                            value: file,
                            child: Text(file),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedConfigFile = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedDocType != null && _selectedConfigFile != null
                      ? _uploadConfig
                      : null,
                  child: const Text('Upload Configuration'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}