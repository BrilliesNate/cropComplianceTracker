
import 'dart:math' show min, max;
import 'dart:ui';

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';
import 'package:cropCompliance/views/dashboard/widgets/circle_progress_bar.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:cropCompliance/views/shared/responsive_layout.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentPage = 1;
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

      // Use the new context-aware initialization method
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

    // Calculate key metrics
    final totalDocTypes = documentProvider.documentTypes.length;
    final uploadedDocs = documentProvider.documents.length;
    final pendingDocs = documentProvider.pendingDocuments.length;
    final approvedDocs = documentProvider.approvedDocuments.length;
    final rejectedDocs = documentProvider.documents.where((doc) => doc.isRejected).length;
    final expiredDocs = documentProvider.documents.where((doc) => doc.isExpired).length;

    // Calculate completion percentage
    final completionRate = totalDocTypes > 0 ? approvedDocs / totalDocTypes : 0.0;
    final completionPercentage = (completionRate * 100).toStringAsFixed(1);

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
      // Build the new dashboard layout
      content = Column(
        children: [
          // Selected User Banner (only show for admins with selected user)
          if (authProvider.isAdmin && authProvider.selectedUser != null)
            _buildSelectedUserBanner(context, authProvider),

          // Main dashboard content
          Expanded(
            child: _buildDashboardContent(
              context,
              authProvider,
              documentProvider,
              categoryProvider,
              completionPercentage,
              uploadedDocs,
              totalDocTypes,
              approvedDocs,
              pendingDocs,
              rejectedDocs,
              expiredDocs,
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

  // New method to build the selected user banner
  Widget _buildSelectedUserBanner(BuildContext context, AuthProvider authProvider) {
    final selectedUser = authProvider.selectedUser!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
          ],
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
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              authProvider.selectedCompany != null ? Icons.business : Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Context info
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

          // Clear selection button
          IconButton(
            onPressed: () async {
              final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
              authProvider.clearUserSelection();
              await documentProvider.refreshForUserContext(context);
            },
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
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
      CategoryProvider categoryProvider,
      String completionPercentage,
      int uploadedDocs,
      int totalDocTypes,
      int approvedDocs,
      int pendingDocs,
      int rejectedDocs,
      int expiredDocs,
      ) {
    return ResponsiveLayout(
      // Mobile view - Single column, stacked layout
      mobileView: _buildMobileLayout(
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

      // Tablet view - 2 column layout with adjusted spacing
      tabletView: _buildTabletLayout(
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

      // Desktop view - Your existing layout
      desktopView: _buildDesktopLayout(
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
    );
  }

// Mobile-specific layout - Fixed constraints
  Widget _buildMobileLayout(
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
    print('DEBUG: Building mobile layout');
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MOBILE DEBUG VIEW\nWidth: ${MediaQuery.of(context).size.width}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Simple metrics cards with fixed height
            SizedBox(
              height: 100,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Completion: $completionPercentage%\nApproved: $approvedDocs\nPending: $pendingDocs',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Your existing compliance overview card with constraints
            SizedBox(
              width: double.infinity,
              child: _buildComplianceOverviewCard(
                context,
                authProvider,
                completionPercentage,
                approvedDocs,
                uploadedDocs,
                pendingDocs,
                rejectedDocs,
                totalDocTypes,
              ),
            ),

            const SizedBox(height: 12),

            // Simple document list with fixed height
            SizedBox(
              height: 200,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Documents: ${documentProvider.documents.length}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Your existing employees card with constraints
            SizedBox(
              height: 200, // Fixed height to prevent layout issues
              child: _buildEmployeesCard(context, authProvider),
            ),

            const SizedBox(height: 12),

            // Your existing calendar card with constraints
            SizedBox(
              height: 300, // Fixed height to prevent layout issues
              child: _buildCalendarCard(context),
            ),

            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

// Mobile metrics grid - 2x2 layout for key stats
  Widget _buildMobileMetricsGrid(
      BuildContext context,
      String completionPercentage,
      int approvedDocs,
      int uploadedDocs,
      int pendingDocs,
      int rejectedDocs,
      ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: [
        _buildMobileMetricCard(
          'Completion',
          '$completionPercentage%',
          'Overall Progress',
          Icons.check_circle,
          Colors.green,
        ),
        _buildMobileMetricCard(
          'Approved',
          approvedDocs.toString(),
          'Documents',
          Icons.verified,
          Colors.blue,
        ),
        _buildMobileMetricCard(
          'Pending',
          pendingDocs.toString(),
          'Need Review',
          Icons.pending,
          Colors.orange,
        ),
        _buildMobileMetricCard(
          'Rejected',
          rejectedDocs.toString(),
          'Need Action',
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMobileMetricCard(
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// Mobile-friendly document status list
  Widget _buildMobileDocumentStatus(BuildContext context, DocumentProvider documentProvider) {
    final documents = documentProvider.documents;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Document Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (documents.length > 4)
                  TextButton(
                    onPressed: () {
                      // Navigate to full document list
                      Navigator.pushNamed(context, RouteConstants.auditIndex);
                    },
                    child: const Text('View All', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          // Show top 4 documents in list format
          ...documents.take(4).map((doc) => _buildMobileDocumentItem(doc, documentProvider)),
          if (documents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No documents found'),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDocumentItem(DocumentModel document, DocumentProvider documentProvider) {
    // Get document type name using your existing pattern
    final documentTypes = documentProvider.documentTypes;
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }
    final documentTypeName = documentType?.name ?? 'Unknown Document Type';

    // Status logic
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (document.status) {
      case DocumentStatus.APPROVED:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case DocumentStatus.PENDING:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case DocumentStatus.REJECTED:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documentTypeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                if (document.expiryDate != null)
                  Text(
                    'Expires: ${DateFormat('MMM dd, yyyy').format(document.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Tablet layout - 2 columns
  Widget _buildTabletLayout(
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
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - 40% width
          Expanded(
            flex: 4,
            child: Column(
              children: [
                _buildMobileMetricsGrid(
                  context,
                  completionPercentage,
                  approvedDocs,
                  uploadedDocs,
                  pendingDocs,
                  rejectedDocs,
                ),
                const SizedBox(height: 14),
                _buildEmployeesCard(context, authProvider),
                const SizedBox(height: 14),
                _buildCalendarCard(context),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right column - 60% width
          Expanded(
            flex: 6,
            child: Column(
              children: [
                _buildComplianceOverviewCard(
                  context,
                  authProvider,
                  completionPercentage,
                  approvedDocs,
                  uploadedDocs,
                  pendingDocs,
                  rejectedDocs,
                  totalDocTypes,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _buildDocumentsTable(context, documentProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Your existing desktop layout
  Widget _buildDesktopLayout(
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - 40% width
          Expanded(
            flex: 3, // 4 parts out of 10
            child: Column(
              children: [
                // Employees Card
                _buildEmployeesCard(context, authProvider),
                // Minimal spacing
                const SizedBox(height: 10),
                // Schedule Card
                _buildCalendarCard(context),
                // Minimal spacing
                const SizedBox(height: 10),
                // Document Comment Card - Expand to fill remaining space
                Expanded(
                  child: _buildDocumentCommentCard(context),
                ),
              ],
            ),
          ),
          // Space between columns
          const SizedBox(width: 16),
          // Right column - 60% width
          Expanded(
            flex: 7, // 6 parts out of 10
            child: Column(
              children: [
                // Compliance Overview Card
                _buildComplianceOverviewCard(
                  context,
                  authProvider,
                  completionPercentage,
                  approvedDocs,
                  uploadedDocs,
                  pendingDocs,
                  rejectedDocs,
                  totalDocTypes,),
                // Minimal spacing
                const SizedBox(height: 10),
                // Document Status Table - Expand to fill remaining space
                Expanded(
                  child: _buildDocumentsTable(context, documentProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesCard(BuildContext context, AuthProvider authProvider) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(56, 15, 56, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              authProvider.isAdmin && authProvider.selectedUser != null
                  ? 'All Users (Managing: ${authProvider.selectedUser!.name})'
                  : authProvider.isAdmin
                  ? 'All Users (Admin View)'
                  : 'Team Members',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // For admins, show all users they can manage
            if (authProvider.isAdmin)
              _buildAllUsersView(context, authProvider)
            else
            // For non-admins, show company users
              _buildCompanyUsersView(context, authProvider),
          ],
        ),
      ),
    );
  }

  // New method to show all users for admin
  Widget _buildAllUsersView(BuildContext context, AuthProvider authProvider) {
    if (authProvider.isLoadingUsers) {
      return const Center(
        child: SizedBox(
          height: 50,
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authProvider.allUsers.isEmpty) {
      return const Center(
        child: Text('No users found in the system'),
      );
    }

    final users = authProvider.allUsers;
    print('Dashboard: Displaying ${users.length} users for admin selection');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Add Employee Button
          _buildAddEmployeeButton(context),

          // All Users Avatars - admin can select any user
          ...users.map((user) => _buildEmployeeAvatar(
            context,
            user,
            isSelected: authProvider.selectedUser != null &&
                authProvider.selectedUser!.id == user.id,
            onTap: () => _selectUserForManagement(user),
            showCompany: true, // Show company info for admin
          )).toList(),
        ],
      ),
    );
  }

  // Method to show company users for non-admin
  Widget _buildCompanyUsersView(BuildContext context, AuthProvider authProvider) {
    // Get the current user's company ID
    final currentCompanyId = authProvider.currentUser?.companyId;

    return FutureBuilder<List<UserModel>>(
      future: _fetchUsersForCompany(currentCompanyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 50,
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading team members: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No team members found'),
          );
        }

        final users = snapshot.data!;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: users.map((user) => _buildEmployeeAvatar(
              context,
              user,
              isSelected: false, // Non-admins can't select users
              onTap: null, // No tap action for non-admins
              showCompany: false, // Don't show company for same company users
            )).toList(),
          ),
        );
      },
    );
  }

  // Enhanced method to handle user selection for management
  void _selectUserForManagement(UserModel user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    print('Dashboard: Admin selecting user: ${user.name} (${user.email}) from company: ${user.companyId}');

    // Set the selected user
    authProvider.selectUser(user);

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Loading documents for ${user.name}...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // Refresh the document provider for the new user context
      await documentProvider.refreshForUserContext(context);

      // Show success confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.isManagingCompany && authProvider.selectedCompany != null
                      ? 'Now managing company:'
                      : 'Now managing documents for:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(authProvider.isManagingCompany && authProvider.selectedCompany != null
                    ? authProvider.selectedCompany!.name
                    : '${user.name} (${user.email})'),
                if (!authProvider.isManagingCompany && user.companyId != authProvider.currentUser?.companyId)
                  Text(
                    'Company: ${user.companyId}',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Switch Back',
              textColor: Colors.white,
              onPressed: () async {
                authProvider.clearUserSelection();
                await documentProvider.refreshForUserContext(context);
              },
            ),
          ),
        );
      }

      print(authProvider.isManagingCompany
          ? 'Dashboard: Successfully switched to managing company: ${authProvider.selectedCompany?.name}'
          : 'Dashboard: Successfully switched to managing user: ${user.name}');
      print('Dashboard: Loaded ${documentProvider.documents.length} documents');

    } catch (e) {
      print('Dashboard: Error switching user context: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Helper method to build the Add Employee button
  Widget _buildAddEmployeeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // Navigate to user management screen or show a dialog to add a new user
              Navigator.of(context).pushNamed(RouteConstants.userManagement);
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add Employee',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Enhanced method to build an employee avatar with selection support
  Widget _buildEmployeeAvatar(
      BuildContext context,
      UserModel user, {
        bool isSelected = false,
        VoidCallback? onTap,
        bool showCompany = false,
      }) {
    // Get the user's initials (first letter of first and last name)
    final nameParts = user.name.split(' ');
    String initials = '';

    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0];

      if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
        initials += nameParts[1][0];
      }
    } else {
      initials = '?';
    }

    // Capitalize the initials
    initials = initials.toUpperCase();

    // Create a unique color based on the user's name
    Color color = _getColorFromName(user.name);

    // Use orange if selected
    if (isSelected) {
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: isSelected ? BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange, width: 2),
          ) : null,
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 18,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                child: Text(
                  user.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.orange : null,
                  ),
                ),
              ),
              Text(
                user.role.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.orange : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              // Show company info for admin view
              if (showCompany)
                Text(
                  user.companyId.length > 10
                      ? '${user.companyId.substring(0, 10)}...'
                      : user.companyId,
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to fetch users for a specific company (for non-admin users)
  Future<List<UserModel>> _fetchUsersForCompany(String? companyId) async {
    if (companyId == null) {
      return [];
    }

    final FirestoreService firestoreService = FirestoreService();
    return firestoreService.getUsers(companyId: companyId);
  }

  // Helper method to generate a consistent color based on a name
  Color _getColorFromName(String name) {
    // List of good, distinct colors
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    // Create a hash of the name and use it to select a color
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildComplianceOverviewCard(
      BuildContext context,
      AuthProvider authProvider,
      String completionPercentage,
      int approvedDocs,
      int uploadedDocs,
      int pendingDocs,
      int rejectedDocs,
      int totalDocTypes
      ) {
    final double percentage = double.parse(completionPercentage) / 100;

    // Determine whose name to show
    final displayName = authProvider.isAdmin && authProvider.selectedUser != null
        ? authProvider.selectedUser!.name.split(' ').first
        : authProvider.currentUser?.name.split(' ').first ?? "User";

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 350,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image1-4.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent gradient overlay
          Container(
            height: 350,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Text at top left - update to show selected user context
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.isAdmin && authProvider.selectedUser != null
                      ? 'Managing: $displayName'
                      : 'Hi, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.isAdmin && authProvider.selectedUser != null
                      ? 'Document compliance overview'
                      : 'Welcome back.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          // Gauge centered in the upper part of the card
          Positioned(
            top: 108,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: ThickLineSemiCircleGauge(
                  percentage: percentage,
                  baseColor: Colors.grey.withOpacity(0.5),
                  progressColor: Colors.green,
                  lineCount: 24,
                  dashLength: 40,
                  dashWidth: 8,
                  radius: 130,
                  startFromLeft: true,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      '${completionPercentage}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom stats bar with separate containers
          Positioned(
            bottom: 5, // Add margin from bottom
            left: 8, // Smaller margin from left
            right: 8, // Smaller margin from right
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Completion Rate KPI
                Expanded(
                  child: _buildKPIContainer(
                    icon: Icons.trending_up,
                    title: 'Completion Rate',
                    value: '$approvedDocs/$totalDocTypes',
                    subtitle: '$completionPercentage%',
                  ),
                ),
                const SizedBox(width: 6), // Space between containers

                // Approval Rate KPI
                Expanded(
                  child: _buildKPIContainer(
                    icon: Icons.check_circle_outline,
                    title: 'Approval Rate',
                    value: '$approvedDocs/$uploadedDocs',
                    subtitle:
                    '${(uploadedDocs > 0 ? (approvedDocs / uploadedDocs * 100).toStringAsFixed(1) : "0.0")}%',
                  ),
                ),
                const SizedBox(width: 6), // Space between containers

                // Pending Review KPI
                Expanded(
                  child: _buildKPIContainer(
                    icon: Icons.hourglass_empty,
                    title: 'Pending Review',
                    value: '$pendingDocs',
                    subtitle: 'Action Needed',
                  ),
                ),
                const SizedBox(width: 6), // Space between containers

                // Rejected Item KPI
                Expanded(
                  child: _buildKPIContainer(
                    icon: Icons.cancel_outlined,
                    title: 'Rejected Item',
                    value: '$rejectedDocs',
                    subtitle: 'Needs Attention',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a single KPI container with glass effect
  Widget _buildKPIContainer({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 75,
      // padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1), // Semi-transparent background
        borderRadius: BorderRadius.circular(12), // Rounded corners
        border: Border.all(
          color: Colors.white.withOpacity(0.5), // Thin white border
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      // Apply backdrop filter for glass effect
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          // Blur effect for glass
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
      BuildContext context,
      String title,
      String value,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    // Sample calendar data - in a real app, this would come from your provider
    final DateTime now = DateTime.now();
    final String currentMonth = DateFormat('MMMM yyyy').format(now);
    final List<String> weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    // For the example, we'll use fixed dates to match the UI mockup
    final List<int> days = [5, 6, 7, 8, 9, 10, 11];

    // Events on specific days
    final Map<int, bool> dayEvents = {
      7: true, // Event on day 7
      10: true, // Event on day 10
    };

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    // Previous month logic
                  },
                ),
                Text(
                  'April 2025', // Use currentMonth variable in real app
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // Next month logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((day) => SizedBox(
                width: 30,
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Calendar days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                final bool isToday = day == 7; // Let's assume day 7 is today
                final bool hasEvent = dayEvents[day] ?? false;

                return SizedBox(
                  width: 30,
                  height: 50,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              color: isToday ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTable(BuildContext context, DocumentProvider documentProvider) {
    // Get the documents from your provider
    final List<DocumentModel> documents = documentProvider.documents.cast<DocumentModel>();

    // Pagination state
    final int itemsPerPage = 6;
    final int totalPages = (documents.length / itemsPerPage).ceil();

    // State variables (Add these as class fields in your widget's State class)
    // int _currentPage = 1;

    // Calculate current view of documents
    final int startIndex = (_currentPage - 1) * itemsPerPage;
    final int endIndex = startIndex + itemsPerPage > documents.length
        ? documents.length
        : startIndex + itemsPerPage;

    final currentPageDocuments = documents.isNotEmpty
        ? documents.sublist(startIndex, endIndex)
        : <DocumentModel>[];

    // Table headers
    final headerStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontSize: 12,
    );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title inside padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Documents Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Table header with green gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF43A047), // Primary green
                            Color(0xFF2E7D32), // Darker green
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text('Document Type', style: headerStyle),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('Status', style: headerStyle),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('Last Updated', style: headerStyle),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text('Expiry Date', style: headerStyle),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text('Signatures', style: headerStyle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Table body with fixed row count
                    Expanded(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: currentPageDocuments.isEmpty
                            ? Center(child: Text('No documents found'))
                            : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentPageDocuments.length,
                          separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFC0C0C0)),
                          itemBuilder: (context, index) {
                            final doc = currentPageDocuments[index];

                            // Get document type name
                            String documentTypeName = 'Unknown Document';
                            try {
                              final docType = documentProvider.documentTypes
                                  .firstWhere((dt) => dt.id == doc.documentTypeId);
                              documentTypeName = docType.name;
                            } catch (_) {
                              // Keep default name if not found
                            }

                            // Status indicator
                            Widget statusWidget;
                            Color statusColor;
                            String statusText;
                            IconData statusIcon;

                            if (doc.isExpired) {
                              statusColor = Colors.red;
                              statusText = 'Expired';
                              statusIcon = Icons.error_outline;
                            } else {
                              switch (doc.status) {
                                case DocumentStatus.APPROVED:
                                  statusColor = Colors.green;
                                  statusText = 'Approved';
                                  statusIcon = Icons.check_circle;
                                  break;
                                case DocumentStatus.PENDING:
                                  statusColor = Colors.orange;
                                  statusText = 'Pending';
                                  statusIcon = Icons.hourglass_empty;
                                  break;
                                case DocumentStatus.REJECTED:
                                  statusColor = Colors.red;
                                  statusText = 'Rejected';
                                  statusIcon = Icons.cancel;
                                  break;
                                default:
                                  statusColor = Colors.grey;
                                  statusText = 'Unknown';
                                  statusIcon = Icons.help_outline;
                              }
                            }

                            statusWidget = Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );

                            // Alternating row colors
                            final rowColor = index.isEven ? Colors.grey[100] : Colors.white;

                            return GestureDetector(
                              onTap: (){
                                setState(() {
                                  _selectedDocumentId = doc.id;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: rowColor,
                                  border: _selectedDocumentId == doc.id
                                      ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                                      : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 16),
                                          child: Text(
                                            documentTypeName,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(child: statusWidget),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(DateFormat('MM/dd/yyyy').format(doc.updatedAt)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Center(
                                          child: Text(doc.expiryDate != null
                                              ? DateFormat('MM/dd/yyyy').format(doc.expiryDate!)
                                              : 'N/A'),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Text('${doc.signatures.length}/0'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Pagination controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First page button
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() {
                      _currentPage = 1;
                    });
                  }
                      : null,
                  color: _currentPage > 1 ? Theme.of(context).primaryColor : Colors.grey,
                  iconSize: 20,
                ),
                // Previous page button
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                      : null,
                  color: _currentPage > 1 ? Theme.of(context).primaryColor : Colors.grey,
                  iconSize: 20,
                ),

                // Page indicators
                // Determine how many page indicators to show
                ..._buildPageIndicators(context, totalPages),

                // Next page button
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                      : null,
                  color: _currentPage < totalPages ? Theme.of(context).primaryColor : Colors.grey,
                  iconSize: 20,
                ),
                // Last page button
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: _currentPage < totalPages
                      ? () {
                    setState(() {
                      _currentPage = totalPages;
                    });
                  }
                      : null,
                  color: _currentPage < totalPages ? Theme.of(context).primaryColor : Colors.grey,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Helper method to build page indicators
  List<Widget> _buildPageIndicators(BuildContext context, int totalPages) {
    // Show at most 5 page numbers at a time
    List<Widget> indicators = [];

    int startPage = max(1, min(_currentPage - 2, totalPages - 4));
    int endPage = min(startPage + 4, totalPages);

    if (totalPages <= 5) {
      // If we have 5 or fewer pages, show all of them
      startPage = 1;
      endPage = totalPages;
    }

    for (int i = startPage; i <= endPage; i++) {
      final isActive = i == _currentPage;

      indicators.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPage = i;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Theme.of(context).primaryColor : Colors.grey,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                i.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return indicators;
  }

  Widget _buildDocumentCommentCard(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);

    // Check if we have a selected document
    DocumentModel? selectedDocument;

    if (_selectedDocumentId != null) {
      // Try to find the selected document in the list
      try {
        selectedDocument = documentProvider.documents
            .firstWhere((doc) => doc.id == _selectedDocumentId) as DocumentModel?;
      } catch (_) {
        // Document not found, ignore
      }
    }

    // If no document is selected or it doesn't have comments or isn't rejected,
    // find the latest rejected document with comments
    if (selectedDocument == null ||
        !selectedDocument.isRejected ||
        selectedDocument.comments.isEmpty) {

      // Find latest rejected document with comments
      final rejectedDocsWithComments = documentProvider.documents
          .where((doc) => doc.isRejected && doc.comments.isNotEmpty)
          .toList();

      if (rejectedDocsWithComments.isNotEmpty) {
        rejectedDocsWithComments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        selectedDocument = rejectedDocsWithComments.first as DocumentModel?;

        // Update the selected document ID to match what we found
        if (selectedDocument != null) {
          _selectedDocumentId = selectedDocument.id;
        }
      }
    }

    // If no selected or rejected documents with comments, show placeholder
    if (selectedDocument == null || !selectedDocument.isRejected || selectedDocument.comments.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: ThemeConstants.cardColors,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Document Comment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No rejected documents with comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All documents are in good standing',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get the document type name
    String documentTypeName = 'Unknown Document';
    try {
      final docType = documentProvider.documentTypes
          .firstWhere((dt) => dt.id == selectedDocument?.documentTypeId);
      documentTypeName = docType.name;
    } catch (_) {
      // Keep default name if not found
    }

    // Get the latest comment (should be first in the list, but we'll sort to be sure)
    final comments = selectedDocument.comments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestComment = comments.first;

    // Calculate priority stars (based on comment text length or other factors)
    int priorityLevel = min(5, max(1, (latestComment.text.length / 50).ceil()));
    String priorityStars = '★' * priorityLevel + '☆' * (5 - priorityLevel);

    // Format date and time
    String formattedDate = DateFormat('d MMMM yyyy / HH:mm').format(latestComment.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Document Comment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.cancel,
                        color: Colors.red,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Rejected',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Comment content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.message,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Comment details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentTypeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$formattedDate • Priority Level: $priorityStars',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          latestComment.text.length > 50
                              ? latestComment.text.substring(0, 50) + '...'
                              : latestComment.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(latestComment.text),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '!!! Update document and resubmit as soon as possible !!!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay,
                    color: Colors.white,
                  ),
                  label: const Text('Resubmit'),
                  onPressed: () {
                    // Navigate to document upload/form screen with existing document ID
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentUpload,
                      arguments: {
                        'categoryId': selectedDocument?.categoryId,
                        'documentTypeId': selectedDocument?.documentTypeId,
                        'existingDocumentId': selectedDocument?.id,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to document detail screen
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': selectedDocument?.id},
                    );
                  },
                  child: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}