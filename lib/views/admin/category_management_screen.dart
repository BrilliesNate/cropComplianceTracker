// views/admin/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  bool _isLoading = false;
  String? _error;
  String? _selectedCompanyId;
  List<Map<String, dynamic>> _companies = [];
  Map<String, bool> _enabledCategories = {};

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
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Category Management',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Category Management',
        showBackButton: true,
      ),
      body: categoryProvider.isLoading || _isLoading
          ? const LoadingIndicator(message: 'Loading categories...')
          : categoryProvider.error != null || _error != null
          ? ErrorDisplay(
        error: categoryProvider.error ?? _error ?? 'Unknown error',
        onRetry: _loadData,
      )
          : SingleChildScrollView(
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
                      'Manage Categories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable or disable categories for specific companies.',
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
                          return SwitchListTile(
                            title: Text(category.name),
                            subtitle: Text(category.description),
                            value: _enabledCategories[category.id] ?? true,
                            onChanged: (value) {
                              setState(() {
                                _enabledCategories[category.id] = value;
                              });
                            },
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
      ),
    );
  }
}