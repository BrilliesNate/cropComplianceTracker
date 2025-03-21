import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/custom_app_bar.dart';
import '../shared/app_drawer.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/responsive_layout.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/recent_activity_list.dart';
import 'widgets/compliance_progress_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
      await documentProvider.initialize(authProvider.currentUser!.companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard',
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading dashboard data...')
          : hasError
          ? ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      )
          : ResponsiveLayout(
        mobileView: _buildMobileView(),
        tabletView: _buildTabletView(),
        desktopView: _buildDesktopView(),
      ),
    );
  }

  Widget _buildMobileView() {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (authProvider.isAdmin) ...[
            // Admin setup button - only for initial data setup
            ElevatedButton(
              onPressed: () {
                _setupInitialData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Setup Categories & Document Types'),
            ),
            const SizedBox(height: 16),
          ],

          const DashboardSummaryCard(),
          const SizedBox(height: 16),
          const ComplianceProgressChart(),
          const SizedBox(height: 16),
          const RecentActivityList(),

          if (authProvider.isAdmin) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminActionCard(
                            'User Management',
                            Icons.people,
                            Colors.blue,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.userManagement,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAdminActionCard(
                            'Category Management',
                            Icons.category,
                            Colors.orange,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.categoryManagement,
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildTabletView() {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (authProvider.isAdmin) ...[
            // Admin setup button - only for initial data setup
            ElevatedButton(
              onPressed: () {
                _setupInitialData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Setup Categories & Document Types'),
            ),
            const SizedBox(height: 16),
          ],

          const DashboardSummaryCard(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: ComplianceProgressChart(),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 400,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          const Expanded(
                            child: RecentActivityList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (authProvider.isAdmin) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminActionCard(
                            'User Management',
                            Icons.people,
                            Colors.blue,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.userManagement,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAdminActionCard(
                            'Category Management',
                            Icons.category,
                            Colors.orange,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.categoryManagement,
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildDesktopView() {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (authProvider.isAdmin) ...[
            // Admin setup button - only for initial data setup
            ElevatedButton(
              onPressed: () {
                _setupInitialData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
              child: const Text('Setup Categories & Document Types'),
            ),
            const SizedBox(height: 16),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: DashboardSummaryCard(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 220,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 3 / 2,
                              children: [
                                _buildActionCard(
                                  'Upload Document',
                                  Icons.upload_file,
                                  Colors.blue,
                                      () {
                                    Navigator.of(context).pushNamed(RouteConstants.auditTracker);
                                  },
                                ),
                                _buildActionCard(
                                  'View Audit Index',
                                  Icons.folder,
                                  Colors.amber,
                                      () {
                                    Navigator.of(context).pushNamed(RouteConstants.auditIndex);
                                  },
                                ),
                                _buildActionCard(
                                  'Check Compliance',
                                  Icons.assignment_turned_in,
                                  Colors.green,
                                      () {
                                    Navigator.of(context).pushNamed(RouteConstants.complianceReport);
                                  },
                                ),
                                _buildActionCard(
                                  'View Reports',
                                  Icons.assessment,
                                  Colors.purple,
                                      () {
                                    Navigator.of(context).pushNamed(RouteConstants.complianceReport);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 3,
                child: ComplianceProgressChart(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 400,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Activity',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          const Expanded(
                            child: RecentActivityList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (authProvider.isAdmin) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Controls',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdminActionCard(
                            'User Management',
                            Icons.people,
                            Colors.blue,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.userManagement,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAdminActionCard(
                            'Category Management',
                            Icons.category,
                            Colors.orange,
                                () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.categoryManagement,
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Setup initial data method with all 12 categories
  Future<void> _setupInitialData() async {
    final firestore = FirebaseFirestore.instance;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Setting up document categories...'),
          ],
        ),
      ),
    );

    try {
      // 1. Business Information and Compliance
      final businessCatRef = await firestore.collection('categories').add({
        'name': 'Business Information and Compliance',
        'description': 'Registration, tax, and compliance documentation',
        'order': 1,
      });

      // Business Information document types
      final businessDocTypes = [
        {
          'name': 'Company Registration Documents',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': false,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Tax Compliance Certificates',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Workmans Compensation Records',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'BEE Certification Documentation',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': true,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Company Organisational Chart',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Site Maps/Layouts',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': false,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Business Licences and Permits',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': true,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'WIETA/SIZA Membership Documentation',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
      ];

      for (var docType in businessDocTypes) {
        await firestore.collection('documentTypes').add({
          ...docType,
          'categoryId': businessCatRef.id,
        });
      }

      // 2. Management Systems
      final managementCatRef = await firestore.collection('categories').add({
        'name': 'Management Systems',
        'description': 'Policies, procedures, and risk assessments',
        'order': 2,
      });

      // Management Systems document types
      final managementDocTypes = [
        {
          'name': 'Ethical Code of Conduct',
          'allowMultipleDocuments': false,
          'isUploadable': false,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Document Control Procedure',
          'allowMultipleDocuments': false,
          'isUploadable': false,
          'hasExpiryDate': false,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Company Policies',
          'allowMultipleDocuments': true,
          'isUploadable': false,
          'hasExpiryDate': false,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Appointments (Ethical & Health and Safety)',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Risk Assessments',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Internal Audits Records',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': true,
          'signatureCount': 1,
        },
        {
          'name': 'Social Compliance Improvement Plans',
          'allowMultipleDocuments': true,
          'isUploadable': false,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Previous WIETA/SIZA Audit Reports',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Evidence of Closed Non-Conformances',
          'allowMultipleDocuments': true,
          'isUploadable': true,
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
        {
          'name': 'Continuous Improvement Plans',
          'allowMultipleDocuments': true,
          'isUploadable': true, // Could be form-fillable too per your spec
          'hasExpiryDate': true,
          'hasNotApplicableOption': false,
          'requiresSignature': false,
          'signatureCount': 0,
        },
      ];

      for (var docType in managementDocTypes) {
        await firestore.collection('documentTypes').add({
          ...docType,
          'categoryId': managementCatRef.id,
        });
      }

      // 3. Employment Documentation
      final employmentCatRef = await firestore.collection('categories').add({
        'name': 'Employment Documentation',
        'description': 'Contracts, agreements, and employee records',
        'order': 3,
      });

      // 4. Child Labor and Young Workers
      final childLaborCatRef = await firestore.collection('categories').add({
        'name': 'Child Labor and Young Workers',
        'description': 'Age verification and young worker protections',
        'order': 4,
      });

      // 5. Forced Labor Prevention
      final forcedLaborCatRef = await firestore.collection('categories').add({
        'name': 'Forced Labor Prevention',
        'description': 'Procedures and records to prevent forced labor',
        'order': 5,
      });

      // 6. Wages and Working Hours
      final wagesCatRef = await firestore.collection('categories').add({
        'name': 'Wages and Working Hours',
        'description': 'Wage documentation and working hour records',
        'order': 6,
      });

      // 7. Freedom of Association
      final associationCatRef = await firestore.collection('categories').add({
        'name': 'Freedom of Association',
        'description': 'Worker representation and collective bargaining',
        'order': 7,
      });

      // 8. Training and Development
      final trainingCatRef = await firestore.collection('categories').add({
        'name': 'Training and Development',
        'description': 'Training materials and records',
        'order': 8,
      });

      // 9. Health and Safety
      final healthSafetyCatRef = await firestore.collection('categories').add({
        'name': 'Health and Safety',
        'description': 'Procedures, records, and safety documentation',
        'order': 9,
      });

      // 10. Chemical and Pesticide Management
      final chemicalCatRef = await firestore.collection('categories').add({
        'name': 'Chemical and Pesticide Management',
        'description': 'Chemical handling, storage, and safety records',
        'order': 10,
      });

      // 11. Labour and Service Providers
      final serviceProvidersCatRef = await firestore.collection('categories').add({
        'name': 'Labour and Service Providers',
        'description': 'Contractor agreements and compliance records',
        'order': 11,
      });

      // 12. Environmental and Community Impact
      final environmentalCatRef = await firestore.collection('categories').add({
        'name': 'Environmental and Community Impact',
        'description': 'Environmental procedures and community engagement',
        'order': 12,
      });

      // Success message
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Refresh providers
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        await categoryProvider.initialize();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All categories and document types created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}