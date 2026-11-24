import '../../core/utils/data_bootstrap.dart';
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
import 'package:cropCompliance/providers/locale_provider.dart';

class ComplianceReportScreen extends StatefulWidget {
  const ComplianceReportScreen({Key? key}) : super(key: key);

  @override
  State<ComplianceReportScreen> createState() => _ComplianceReportScreenState();
}

class _ComplianceReportScreenState extends State<ComplianceReportScreen> {
  late bool _ready; // one loader, then the finished page (no half-filled UI)

  @override
  void initState() {
    super.initState();
    _ready = isCompanyDataWarm(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      // Includes the company's switched-off document types, so the totals here
      // match the Dashboard and the Compliance Tracker.
      await loadCompanyData(context);
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    if (authProvider.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.pleaseLogIn),
        ),
      );
    }

    final isLoading = !_ready || documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    Widget content;
    if (isLoading) {
      content = LoadingIndicator(message: context.l10n.reportLoading);
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: () {
          setState(() => _ready = false);
          _initializeData();
        },
      );
    } else {
      content = _buildReportView(context);
    }

    return AppScaffoldWrapper(
      title: context.l10n.menuComplianceReport,
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildReportView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // ============================================
    // UPDATED: Use package-aware filtering for metrics
    // ============================================

    // Get the company's packages
    final companyPackages = authProvider.effectivePackages;

    // Use the new package-aware method to get compliance stats
    final complianceStats = documentProvider.getComplianceStatsForPackages(companyPackages);

    final totalDocTypes = complianceStats['totalDocTypes'] as int;
    final approvedDocs = complianceStats['approvedDocs'] as int;
    final pendingDocs = complianceStats['pendingDocs'] as int;
    final rejectedDocs = complianceStats['rejectedDocs'] as int;
    final completionRate = complianceStats['completionRate'] as double;

    // Debug logging
    print('ComplianceReportScreen: Company packages: $companyPackages');
    print('ComplianceReportScreen: Filtered stats - Total: $totalDocTypes, Approved: $approvedDocs, Completion: ${completionRate.toInt()}%');

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
                  Text(
                    context.l10n.menuComplianceReport,
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
                  _buildCompactMetric('${completionRate.toInt()}%', context.l10n.reportComplete, const Color(0xFF43A047)),
                  _buildCompactMetric('$approvedDocs', context.l10n.statusApproved, Colors.green.shade600),
                  _buildCompactMetric('$pendingDocs', context.l10n.statusPending, Colors.blue.shade600),
                  _buildCompactMetric('$rejectedDocs', context.l10n.statusRejected, Colors.orange.shade600),
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