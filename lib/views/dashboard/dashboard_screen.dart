import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

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

    // Figure out what content to show
    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading dashboard data...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      content = SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(authProvider),
            const SizedBox(height: 24),
            _buildSummarySection(),
            const SizedBox(height: 24),
            _buildActionsSection(context),

            // Admin section if user is admin
            if (authProvider.isAdmin) ...[
              const SizedBox(height: 24),
              _buildAdminSection(context),
            ],
          ],
        ),
      );
    }

    return AppScaffoldWrapper(
      title: 'Dashboard',  // Changed from 'appBar' parameter to 'title'
      backgroundColor: Colors.grey[100],
      child: content,     // Changed from 'body' parameter to 'child'
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${authProvider.currentUser?.name ?? "User"}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage your compliance documents',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compliance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  'Total Documents',
                  '0',
                  Icons.folder_outlined,
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'Pending',
                  '0',
                  Icons.pending_outlined,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem(
                  'Approved',
                  '0',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildSummaryItem(
                  'Expired',
                  '0',
                  Icons.warning_amber_outlined,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionButton(
                  context,
                  'Upload Document',
                  Icons.upload_file_outlined,
                  Colors.blue,
                  RouteConstants.auditTracker,
                ),
                _buildActionButton(
                  context,
                  'View Audit Index',
                  Icons.folder_outlined,
                  Colors.orange,
                  RouteConstants.auditIndex,
                ),
                _buildActionButton(
                  context,
                  'Check Compliance',
                  Icons.assignment_turned_in_outlined,
                  Colors.green,
                  RouteConstants.complianceReport,
                ),
                _buildActionButton(
                  context,
                  'View Reports',
                  Icons.assessment_outlined,
                  Colors.purple,
                  RouteConstants.complianceReport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'User Management',
                    Icons.people_outlined,
                    Colors.blue,
                    RouteConstants.userManagement,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Category Management',
                    Icons.category_outlined,
                    Colors.orange,
                    RouteConstants.categoryManagement,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String route,
      ) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}