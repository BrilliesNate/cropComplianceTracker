import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/enums.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
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

      // Use the company-aware method instead of the old initialize method
      await documentProvider.refreshForUserContext(context);
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

    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading compliance data...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      content = _buildReportView(context);
    }

    return AppScaffoldWrapper(
      title: 'Compliance Report',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildReportView(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Calculate metrics
    final totalDocTypes = documentProvider.documentTypes.length;
    final approvedDocs = documentProvider.documents.where((doc) => doc.status == DocumentStatus.APPROVED).length;
    final pendingDocs = documentProvider.documents.where((doc) => doc.status == DocumentStatus.PENDING).length;
    final rejectedDocs = documentProvider.documents.where((doc) => doc.status == DocumentStatus.REJECTED).length;

    final completionRate = totalDocTypes > 0 ? (approvedDocs / totalDocTypes * 100) : 0.0;

    return Column(
      children: [
        // Compact header with metrics
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Title row
              Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 16, color: const Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  const Text(
                    'Compliance Report',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, y').format(DateTime.now()),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Compact metrics row
              Row(
                children: [
                  _buildCompactMetric('${completionRate.toInt()}%', 'Complete', const Color(0xFF43A047)),
                  _buildCompactMetric('$approvedDocs', 'Approved', Colors.green.shade600),
                  _buildCompactMetric('$pendingDocs', 'Pending', Colors.blue.shade600),
                  _buildCompactMetric('$rejectedDocs', 'Rejected', Colors.orange.shade600),
                ],
              ),
            ],
          ),
        ),

        // Document list takes remaining space
        Expanded(
          child: const DocumentStatusTable(),
        ),
      ],
    );
  }

  Widget _buildCompactMetric(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}