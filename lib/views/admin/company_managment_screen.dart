

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/company_model.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  bool _isLoading = false;
  String? _error;
  List<CompanyModel> _companies = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .orderBy('name')
          .get();

      final companies = companiesSnapshot.docs.map((doc) =>
          CompanyModel.fromMap(doc.data(), doc.id)
      ).toList();

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading companies: $e';
        _isLoading = false;
      });
    }
  }

  Future<int> _getCompanyUserCount(String companyId) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companyId', isEqualTo: companyId)
          .get();

      return usersSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getCompanyDocumentCount(String companyId) async {
    try {
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('companyId', isEqualTo: companyId)
          .get();

      return documentsSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  List<CompanyModel> get _filteredCompanies {
    if (_searchQuery.isEmpty) return _companies;

    return _companies.where((company) =>
    company.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        company.address.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _navigateToCompanyDashboard(CompanyModel company) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch to Company View'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are about to switch to managing:'),
            const SizedBox(height: 8),
            Text(
              company.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will have full access to view, approve, reject, and upload documents for this company.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Find a user from this company to use as context
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('companyId', isEqualTo: company.id)
            .limit(1)
            .get();

        if (usersSnapshot.docs.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No users found for ${company.name}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Get the first user from this company
        final userData = usersSnapshot.docs.first.data();
        final companyUser = UserModel.fromMap(userData, usersSnapshot.docs.first.id);

        // Set this user as selected for the admin
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.selectUser(companyUser);
        authProvider.setSelectedCompany(company);

        // Navigate to dashboard (existing route)
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteConstants.dashboard,
              (route) => false, // Clear the stack
        );

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading company data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return AppScaffoldWrapper(
        title: 'Company Management',
        child: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    Widget content;
    if (_isLoading) {
      content = const LoadingIndicator(message: 'Loading companies...');
    } else if (_error != null) {
      content = ErrorDisplay(
        error: _error!,
        onRetry: _loadCompanies,
      );
    } else {
      content = _buildCompanyList();
    }

    return AppScaffoldWrapper(
      title: 'Company Management',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildCompanyList() {
    final filteredCompanies = _filteredCompanies;

    return Column(
      children: [
        // Search and header section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage Companies',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a company to manage their documents and users.',
              ),
              const SizedBox(height: 16),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search companies...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),

        // Companies list
        Expanded(
          child: filteredCompanies.isEmpty
              ? const Center(
            child: Text('No companies found'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCompanies.length,
            itemBuilder: (context, index) {
              final company = filteredCompanies[index];
              return _buildCompanyCard(company);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToCompanyDashboard(company),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Company icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Company details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          company.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Company stats
              FutureBuilder<List<int>>(
                future: Future.wait([
                  _getCompanyUserCount(company.id),
                  _getCompanyDocumentCount(company.id),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userCount = snapshot.data![0];
                    final documentCount = snapshot.data![1];

                    return Row(
                      children: [
                        _buildStatChip(
                          Icons.people,
                          '$userCount Users',
                          Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          Icons.description,
                          '$documentCount Documents',
                          Colors.green,
                        ),
                        const Spacer(),
                        Text(
                          'Created ${_formatDate(company.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      _buildStatChip(Icons.people, '-- Users', Colors.grey),
                      const SizedBox(width: 12),
                      _buildStatChip(Icons.description, '-- Documents', Colors.grey),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}