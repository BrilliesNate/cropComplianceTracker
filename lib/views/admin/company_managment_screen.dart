import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/company_model.dart';
// REMOVED: import 'package:cropCompliance/models/user_model.dart'; - no longer needed
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart'; // NEW: Added for document loading
import 'package:cropCompliance/views/farmable/farmable_link_dialog.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({Key? key}) : super(key: key);

  @override
  State<CompanyManagementScreen> createState() =>
      _CompanyManagementScreenState();
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

      final companies = companiesSnapshot.docs
          .map((doc) => CompanyModel.fromMap(doc.data(), doc.id))
          .toList();

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
  Future<void> _updateCompanyPackages(
      CompanyModel company, List<String> newPackages) async {
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

    return _companies
        .where((company) =>
            company.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            company.address.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // CHANGED: Simplified - no longer needs to find a user, just select company and load docs
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
            Text('You are about to manage:'),
            const SizedBox(height: 8),
            Text(
              company.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will see ALL documents for this company and can approve, reject, or upload documents.',
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
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // 1. Set the selected company in auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setSelectedCompany(company);

        // 2. Load documents for this company
        final documentProvider =
            Provider.of<DocumentProvider>(context, listen: false);
        await documentProvider.initialize(company.id);

        // Close loading indicator
        if (mounted) Navigator.of(context).pop();

        // 3. Navigate to dashboard (user view)
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteConstants.dashboard,
            (route) => false, // Clear the stack
          );
        }
      } catch (e) {
        // Close loading indicator if open
        if (mounted) Navigator.of(context).pop();

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
      content = RefreshIndicator(
        onRefresh: _loadCompanies,
        child: CustomScrollView(
          slivers: [
            // Header with search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Companies',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_companies.length} registered companies',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search companies...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Click on a company card to manage their documents and compliance status.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Company list
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _filteredCompanies.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No companies match your search'
                                    : 'No companies found',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final company = _filteredCompanies[index];
                          return _buildCompanyCard(company);
                        },
                        childCount: _filteredCompanies.length,
                      ),
                    ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'Company Management',
      child: content,
    );
  }

  Widget _buildCompanyCard(CompanyModel company) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              // Company header
              Row(
                children: [
                  // Company icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        company.name.isNotEmpty
                            ? company.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Company name and address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
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

              // Package switches
              _buildPackageSwitches(company),

              const SizedBox(height: 12),

              // Farmable integration row
              _buildFarmableRow(company),

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
                      _buildStatChip(
                          Icons.description, '-- Documents', Colors.grey),
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

  // ── Farmable integration row ──────────────────────────────────────────────
  Widget _buildFarmableRow(CompanyModel company) {
    final linked = company.hasFarmable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: linked ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: linked ? Colors.green.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('FARMABLE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              linked
                  ? 'Farm ID ${company.farmableLocationId} linked'
                  : 'Not connected',
              style: TextStyle(
                fontSize: 13,
                color: linked ? Colors.green.shade800 : Colors.grey.shade600,
                fontWeight: linked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => FarmableLinkDialog(
                company: company,
                onSaved: (newId) {
                  setState(() {
                    final idx =
                        _companies.indexWhere((c) => c.id == company.id);
                    if (idx >= 0) {
                      _companies[idx] = newId != null
                          ? company.copyWith(farmableLocationId: newId)
                          : company.copyWith(clearFarmable: true);
                    }
                  });
                },
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: linked ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                linked ? 'Change' : 'Link Farm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: linked ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build package toggle switches
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
          // Wraps onto a second line on narrow screens (phones).
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final p in const [
                (
                  id: 'siza_wieta',
                  label: 'SIZA/WIETA',
                  icon: Icons.people,
                  color: Colors.blue
                ),
                (
                  id: 'globalgap',
                  label: 'GlobalG.A.P.',
                  icon: Icons.eco,
                  color: Colors.green
                ),
                (
                  id: 'ipw',
                  label: 'IPW',
                  icon: Icons.wine_bar,
                  color: Colors.purple
                ),
                (
                  id: 'fairtrade',
                  label: 'Fairtrade',
                  icon: Icons.handshake_outlined,
                  color: Colors.teal
                ),
                (
                  id: 'siza_environmental',
                  label: 'SIZA Environmental',
                  icon: Icons.forest_outlined,
                  color: Colors.lightGreen
                ),
              ])
                SizedBox(
                  width: 210,
                  child: _buildPackageSwitch(
                    company: company,
                    packageId: p.id,
                    label: p.label,
                    icon: p.icon,
                    color: p.color,
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
