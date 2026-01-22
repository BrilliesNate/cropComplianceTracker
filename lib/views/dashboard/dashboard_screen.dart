import 'dart:math' show min, max;

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:cropCompliance/views/dashboard/widgets/ashboard_documents_table.dart';
import 'package:cropCompliance/views/dashboard/widgets/dashboard_calendar_card.dart';
import 'package:cropCompliance/views/dashboard/widgets/dashboard_comments_card.dart';
import 'package:cropCompliance/views/dashboard/widgets/dashboard_compliance_card.dart';
import 'package:cropCompliance/views/dashboard/widgets/dashboard_employees_card.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _selectedDocumentId;

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

      // Set package filter based on company packages
      if (authProvider.effectiveCompany != null) {
        categoryProvider.setPackageFilter(authProvider.effectiveCompany!.packages);
      }

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

    // ============================================
    // UPDATED: Use package-aware filtering for metrics
    // ============================================

    // Get the company's packages
    final companyPackages = authProvider.effectivePackages;

    // Use the new package-aware method to get compliance stats
    final complianceStats = documentProvider.getComplianceStatsForPackages(companyPackages);

    final totalDocTypes = complianceStats['totalDocTypes'] as int;
    final uploadedDocs = complianceStats['uploadedDocs'] as int;
    final approvedDocs = complianceStats['approvedDocs'] as int;
    final pendingDocs = complianceStats['pendingDocs'] as int;
    final rejectedDocs = complianceStats['rejectedDocs'] as int;
    final completionPercentage = complianceStats['completionPercentage'] as String;

    // Debug logging
    print('DashboardScreen: Company packages: $companyPackages');
    print('DashboardScreen: Filtered stats - Total: $totalDocTypes, Approved: $approvedDocs, Completion: $completionPercentage%');

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
      // THIS IS THE KEY: Column with fixed items and ONE Expanded
      content = Column(
        children: [
          // Fixed height: Selected User Banner
          // if (authProvider.isAdmin && authProvider.selectedUser != null)
          //   _buildSelectedUserBanner(context, authProvider, documentProvider),

          // Expanded: Main scrollable dashboard content
          Expanded(
            child: _buildDashboardContent(
              context,
              authProvider,
              documentProvider,
              completionPercentage,
              approvedDocs,
              uploadedDocs,
              pendingDocs,
              rejectedDocs,
              totalDocTypes,
            ),
          ),
        ],
      );
    }

    return AppScaffoldWrapper(
      title: 'Dashboard',
      backgroundColor: ThemeConstants.lightBackgroundColor,
      child: content,
    );
  }

  Widget _buildSelectedUserBanner(BuildContext context, AuthProvider authProvider, DocumentProvider documentProvider) {
    final selectedUser = authProvider.selectedUser!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              authProvider.selectedCompany != null
                  ? Icons.business : Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.selectedCompany != null
                      ? 'ADMIN MODE: Managing Company'
                      : 'ADMIN MODE: Managing User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.selectedCompany != null
                      ? authProvider.selectedCompany!.name
                      : selectedUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (authProvider.selectedCompany != null)
                  Text(
                    'via ${selectedUser.name}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              authProvider.clearUserSelection();
              await documentProvider.refreshForUserContext(context);
            },
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Switch back to your own account',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context,
      AuthProvider authProvider,
      DocumentProvider documentProvider,
      String completionPercentage,
      int approvedDocs,
      int uploadedDocs,
      int pendingDocs,
      int rejectedDocs,
      int totalDocTypes,
      ) {
    // Check if mobile
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (isMobile) {
      // Mobile layout - single column, specific order
      return ListView(
        padding: EdgeInsets.zero,  // <-- NO PADDING ON LISTVIEW
        children: [
          // 1. Compliance card - NO PADDING (full width)
          DashboardComplianceCard(
            authProvider: authProvider,
            completionPercentage: completionPercentage,
            approvedDocs: approvedDocs,
            uploadedDocs: uploadedDocs,
            pendingDocs: pendingDocs,
            rejectedDocs: rejectedDocs,
            totalDocTypes: totalDocTypes,
          ),
          const SizedBox(height: 16),

          // 2. Comments card - ADD PADDING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardCommentsCard(
              selectedDocumentId: _selectedDocumentId,
              documentProvider: documentProvider,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Documents table - ADD PADDING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardDocumentsTable(
              documentProvider: documentProvider,
              selectedDocumentId: _selectedDocumentId,
              onDocumentSelected: (docId) {
                setState(() {
                  _selectedDocumentId = docId;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // 4. Users/Employees card - ADD PADDING
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DashboardEmployeesCard(authProvider: authProvider),
          ),
        ],
      );
    }

    // Desktop layout - two columns
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - 30%
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  DashboardEmployeesCard(authProvider: authProvider),
                  // const SizedBox(height: 16),
                  // DashboardCalendarCard(),
                  const SizedBox(height: 16),
                  DashboardCommentsCard(
                    selectedDocumentId: _selectedDocumentId,
                    documentProvider: documentProvider,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right column - 70%
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  DashboardComplianceCard(
                    authProvider: authProvider,
                    completionPercentage: completionPercentage,
                    approvedDocs: approvedDocs,
                    uploadedDocs: uploadedDocs,
                    pendingDocs: pendingDocs,
                    rejectedDocs: rejectedDocs,
                    totalDocTypes: totalDocTypes,
                  ),
                  const SizedBox(height: 16),
                  DashboardDocumentsTable(
                    documentProvider: documentProvider,
                    selectedDocumentId: _selectedDocumentId,
                    onDocumentSelected: (docId) {
                      setState(() {
                        _selectedDocumentId = docId;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}