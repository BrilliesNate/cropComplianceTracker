import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../shared/custom_app_bar.dart';
import '../shared/app_drawer.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/responsive_layout.dart';
import 'widgets/report_summary.dart';
import 'widgets/document_status_table.dart';

class ComplianceReportScreen extends StatefulWidget {
  const ComplianceReportScreen({Key? key}) : super(key: key);

  @override
  State<ComplianceReportScreen> createState() => _ComplianceReportScreenState();
}

class _ComplianceReportScreenState extends State<ComplianceReportScreen> {
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
        title: 'Compliance Report',
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading compliance data...')
          : hasError
          ? ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      )
          : ResponsiveLayout(
        mobileView: _buildMobileView(context),
        tabletView: _buildTabletView(context),
        desktopView: _buildDesktopView(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Generate and export report
          _exportReport();
        },
        tooltip: 'Export Report',
        child: const Icon(Icons.file_download),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 24),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  Widget _buildTabletView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 24),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSummary(),
          const SizedBox(height: 32),
          Text(
            'Document Status by Category',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const DocumentStatusTable(),
        ],
      ),
    );
  }

  void _exportReport() {
    // In a real app, this would generate a PDF or Excel report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report export functionality will be implemented in a future update'),
      ),
    );
  }
}