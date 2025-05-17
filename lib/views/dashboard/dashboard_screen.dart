import 'dart:ui';

import 'package:cropcompliance/core/services/firestore_service.dart';
import 'package:cropcompliance/models/document_model.dart';
import 'package:cropcompliance/models/enums.dart';
import 'package:cropcompliance/models/user_model.dart';
import 'package:cropcompliance/theme/theme_constants.dart';
import 'package:cropcompliance/views/dashboard/widgets/circle_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'package:intl/intl.dart';
import 'dart:math' show min, max;

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
    final documentProvider =
        Provider.of<DocumentProvider>(context, listen: false);
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);

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
    final hasError =
        documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    // Calculate key metrics
    final totalDocTypes = documentProvider.documentTypes.length;
    final uploadedDocs = documentProvider.documents.length;
    final pendingDocs = documentProvider.pendingDocuments.length;
    final approvedDocs = documentProvider.approvedDocuments.length;
    final rejectedDocs =
        documentProvider.documents.where((doc) => doc.isRejected).length;
    final expiredDocs =
        documentProvider.documents.where((doc) => doc.isExpired).length;

    // Calculate completion percentage
    final completionRate =
        totalDocTypes > 0 ? uploadedDocs / totalDocTypes : 0.0;
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
      content = _buildDashboardContent(
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
      );
    }

    return AppScaffoldWrapper(
      title: 'Dashboard',
      backgroundColor:ThemeConstants.lightBackgroundColor,
      child: content,
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
    // Get the current user's company ID
    final currentCompanyId = authProvider.currentUser?.companyId;

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
            const Text(
              'Employees',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Use FutureBuilder to fetch users belonging to the current company
            FutureBuilder<List<UserModel>>(
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
                      'Error loading employees: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No employees found for this company'),
                  );
                }

                // Display users horizontally with add button at the beginning
                final users = snapshot.data!;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Add Employee Button - only show for Admin users
                      if (authProvider.isAdmin)
                        _buildAddEmployeeButton(context),

                      // Employee Avatars
                      ...users.map((user) => _buildEmployeeAvatar(context, user)).toList(),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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

// Helper method to build an employee avatar
  Widget _buildEmployeeAvatar(BuildContext context, UserModel user) {
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
    final color = _getColorFromName(user.name);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
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
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            user.role.name,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

// Helper method to fetch users for a specific company
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

          // Text at top left
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${authProvider.currentUser?.name.split(' ').first ?? "User"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Welcome back.',
                  style: TextStyle(
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
                    value: '$uploadedDocs/$totalDocTypes',
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
                        'documentId': selectedDocument?.id,
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
