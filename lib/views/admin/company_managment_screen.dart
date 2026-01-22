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

  // NEW: Get pending document count for a company
  Future<int> _getCompanyPendingDocumentCount(String companyId) async {
    try {
      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'PENDING')
          .get();

      return documentsSnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // NEW: Update company packages in Firestore
  Future<void> _updateCompanyPackages(CompanyModel company, List<String> newPackages) async {
    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(company.id)
          .update({'packages': newPackages});

      // Update local state
      setState(() {
        final index = _companies.indexWhere((c) => c.id == company.id);
        if (index >= 0) {
          _companies[index] = company.copyWith(packages: newPackages);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Packages updated for ${company.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update packages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

              // NEW: Package switches
              _buildPackageSwitches(company),

              const SizedBox(height: 12),

              // Company stats
              FutureBuilder<List<int>>(
                future: Future.wait([
                  _getCompanyUserCount(company.id),
                  _getCompanyDocumentCount(company.id),
                  _getCompanyPendingDocumentCount(company.id),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userCount = snapshot.data![0];
                    final documentCount = snapshot.data![1];
                    final pendingCount = snapshot.data![2];

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          Icons.people,
                          '$userCount Users',
                          Colors.blue,
                        ),
                        _buildStatChip(
                          Icons.description,
                          '$documentCount Documents',
                          Colors.green,
                        ),
                        // Only show pending if > 0
                        if (pendingCount > 0)
                          _buildStatChip(
                            Icons.pending_actions,
                            '$pendingCount Pending',
                            Colors.orange,
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

              const SizedBox(height: 8),

              // Created date
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Created ${_formatDate(company.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Build package toggle switches
  Widget _buildPackageSwitches(CompanyModel company) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audit Packages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // SIZA/WIETA Switch
              Expanded(
                child: _buildPackageSwitch(
                  company: company,
                  packageId: 'siza_wieta',
                  label: 'SIZA/WIETA',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              // GlobalG.A.P. Switch
              Expanded(
                child: _buildPackageSwitch(
                  company: company,
                  packageId: 'globalgap',
                  label: 'GlobalG.A.P.',
                  icon: Icons.eco,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSwitch({
    required CompanyModel company,
    required String packageId,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isEnabled = company.packages.contains(packageId);

    return GestureDetector(
      onTap: () {
        // Prevent disabling if it's the only package
        if (isEnabled && company.packages.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company must have at least one package enabled'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Toggle the package
        List<String> newPackages;
        if (isEnabled) {
          newPackages = company.packages.where((p) => p != packageId).toList();
        } else {
          newPackages = [...company.packages, packageId];
        }

        _updateCompanyPackages(company, newPackages);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? color : Colors.grey[300]!,
            width: isEnabled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isEnabled ? color : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
                    color: isEnabled ? color : Colors.grey,
                  ),
                ),
              ],
            ),
            Icon(
              isEnabled ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: isEnabled ? color : Colors.grey,
            ),
          ],
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