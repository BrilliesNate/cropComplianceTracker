import 'package:cropcompliance/models/enums.dart';
import 'package:cropcompliance/theme/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../models/document_type_model.dart';
import '../../models/document_model.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'dart:developer' as developer;

class AuditTrackerScreen extends StatefulWidget {
  const AuditTrackerScreen({Key? key}) : super(key: key);

  @override
  State<AuditTrackerScreen> createState() => _AuditTrackerScreenState();
}

class _AuditTrackerScreenState extends State<AuditTrackerScreen> {
  bool _showDocuments = true; // Toggle between Documents and Audit List views
  Map<String, bool> _expandedCategories = {};
  Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    developer.log('AuditTrackerScreen - initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('AuditTrackerScreen - post frame callback triggered');
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _initializeData started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - authProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - documentProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    developer.log('AuditTrackerScreen - categoryProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    if (authProvider.currentUser != null) {
      developer.log('AuditTrackerScreen - User is logged in, initializing data');

      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - Starting category initialization');
      await categoryProvider.initialize();
      developer.log('AuditTrackerScreen - Category initialization completed: ${_stopwatch.elapsedMilliseconds}ms');

      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - Starting document initialization with companyId: ${authProvider.currentUser!.companyId}');
      await documentProvider.initialize(authProvider.currentUser!.companyId);
      developer.log('AuditTrackerScreen - Document initialization completed: ${_stopwatch.elapsedMilliseconds}ms');
      developer.log('AuditTrackerScreen - Document count: ${documentProvider.documents.length}');
      developer.log('AuditTrackerScreen - Document types count: ${documentProvider.documentTypes.length}');
    } else {
      developer.log('AuditTrackerScreen - No user logged in, skipping data initialization');
    }

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _initializeData completed: ${_stopwatch.elapsedMilliseconds}ms');
  }

  @override
  Widget build(BuildContext context) {
    developer.log('AuditTrackerScreen - build method called');
    _stopwatch.reset();
    _stopwatch.start();

    final authProvider = Provider.of<AuthProvider>(context);
    developer.log('AuditTrackerScreen - build: authProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final documentProvider = Provider.of<DocumentProvider>(context);
    developer.log('AuditTrackerScreen - build: documentProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    final categoryProvider = Provider.of<CategoryProvider>(context);
    developer.log('AuditTrackerScreen - build: categoryProvider accessed: ${_stopwatch.elapsedMilliseconds}ms');

    if (authProvider.currentUser == null) {
      developer.log('AuditTrackerScreen - build: No user logged in, showing login prompt');
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || categoryProvider.isLoading;
    final hasError = documentProvider.error != null || categoryProvider.error != null;
    final error = documentProvider.error ?? categoryProvider.error ?? '';

    developer.log('AuditTrackerScreen - build: isLoading=$isLoading, hasError=$hasError');

    Widget content;
    if (isLoading) {
      developer.log('AuditTrackerScreen - build: Showing loading indicator');
      content = const LoadingIndicator(message: 'Loading audit data...');
    } else if (hasError) {
      developer.log('AuditTrackerScreen - build: Showing error: $error');
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      _stopwatch.reset();
      _stopwatch.start();
      developer.log('AuditTrackerScreen - build: Starting to build content sections');

      developer.log('AuditTrackerScreen - build: Building KPI section');
      final kpiSection = _buildKPISection(documentProvider);
      developer.log('AuditTrackerScreen - build: KPI section built: ${_stopwatch.elapsedMilliseconds}ms');

      developer.log('AuditTrackerScreen - build: Building toggle buttons');
      final toggleButtons = _buildViewToggleButtons();
      developer.log('AuditTrackerScreen - build: Toggle buttons built: ${_stopwatch.elapsedMilliseconds}ms');

      developer.log('AuditTrackerScreen - build: Preparing main content view (documents or audit list)');
      final mainContent = _showDocuments
          ? _buildDocumentsView(documentProvider, categoryProvider)
          : _buildAuditListView(documentProvider, categoryProvider);
      developer.log('AuditTrackerScreen - build: Main content built: ${_stopwatch.elapsedMilliseconds}ms');

      content = Column(
        children: [
          kpiSection,
          toggleButtons,
          Expanded(child: mainContent),
        ],
      );
      developer.log('AuditTrackerScreen - build: Content column assembled: ${_stopwatch.elapsedMilliseconds}ms');
    }

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - build method completed: ${_stopwatch.elapsedMilliseconds}ms');

    return AppScaffoldWrapper(
      title: 'Compliance Tracker',
      backgroundColor: ThemeConstants.lightBackgroundColor,
      child: content,
    );
  }

  Widget _buildKPISection(DocumentProvider documentProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildKPISection started');

    final totalDocuments = documentProvider.documentTypes.length;
    final uploadedDocuments = documentProvider.documents.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final rejectedDocuments = documentProvider.rejectedDocuments.length;

    developer.log('AuditTrackerScreen - KPI counts - '
        'total: $totalDocuments, '
        'uploaded: $uploadedDocuments, '
        'approved: $approvedDocuments, '
        'pending: $pendingDocuments, '
        'rejected: $rejectedDocuments');

    // Calculate completion percentage
    double completionPercentage = 0;
    if (totalDocuments > 0) {
      completionPercentage = (uploadedDocuments / totalDocuments) * 100;
    }

    // Calculate approval rate percentage
    double approvalRate = 0;
    if (uploadedDocuments > 0) {
      approvalRate = (approvedDocuments / uploadedDocuments) * 100;
    }

    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final result = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit Compliance Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          isSmallScreen
              ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Completion',
                      '$uploadedDocuments/$totalDocuments',
                      '${completionPercentage.toStringAsFixed(1)}%',
                      Colors.blue,
                      Icons.insert_chart,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKPICard(
                      'Approval',
                      '$approvedDocuments/$uploadedDocuments',
                      '${approvalRate.toStringAsFixed(1)}%',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildKPICard(
                      'Pending',
                      '$pendingDocuments',
                      pendingDocuments > 0
                          ? "Action needed"
                          : "All clear",
                      Colors.orange,
                      Icons.hourglass_empty,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildKPICard(
                      'Rejected',
                      '$rejectedDocuments',
                      rejectedDocuments > 0
                          ? "Fix required"
                          : "All clear",
                      Colors.red,
                      Icons.error_outline,
                    ),
                  ),
                ],
              ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Completion Rate',
                  '$uploadedDocuments/$totalDocuments',
                  '${completionPercentage.toStringAsFixed(1)}%',
                  Colors.blue,
                  Icons.insert_chart,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Approval Rate',
                  '$approvedDocuments/$uploadedDocuments',
                  '${approvalRate.toStringAsFixed(1)}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Pending Review',
                  '$pendingDocuments',
                  pendingDocuments > 0 ? "Action needed" : "All clear",
                  Colors.orange,
                  Icons.hourglass_empty,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Rejected Items',
                  '$rejectedDocuments',
                  rejectedDocuments > 0 ? "Needs attention" : "All clear",
                  Colors.red,
                  Icons.error_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildKPISection completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  // KPI Card Widget
  Widget _buildKPICard(
      String title, String value, String subtitle, Color color, IconData icon) {
    // Check if we're on a small screen
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: isSmallScreen
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      )
          : Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor: _showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Action Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showDocuments = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !_showDocuments
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                foregroundColor:
                !_showDocuments ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Audit Checklist',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // State variable for showing approved documents
  bool _showApprovedDocuments = false;

  // Documents View (Action Items)
  Widget _buildDocumentsView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildDocumentsView started');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserRole = authProvider.currentUser?.role;
    final isAdmin = currentUserRole == UserRole.ADMIN;

    // Filter documents based on the _showApprovedDocuments toggle
    final documents = _showApprovedDocuments
        ? documentProvider.documents
        .where((doc) => doc.status == DocumentStatus.APPROVED)
        .toList()
        : documentProvider.documents
        .where((doc) => doc.status != DocumentStatus.APPROVED)
        .toList();

    developer.log('AuditTrackerScreen - Filtered ${documents.length} documents to display');

    if (documents.isEmpty) {
      developer.log('AuditTrackerScreen - No documents to display in this filter');
      return Center(
        child: Text(_showApprovedDocuments
            ? 'No approved documents'
            : 'No pending or rejected documents'),
      );
    }

    // Add a filter option at the top
    final result = Column(
      children: [
        // Filter toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text('Filter: '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Action Items'),
                selected: !_showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = false;
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Approved Documents'),
                selected: _showApprovedDocuments,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _showApprovedDocuments = true;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];

              // Find document type and category details
              DocumentTypeModel? documentType;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                documentType = documentProvider.documentTypes
                    .firstWhere((dt) => dt.id == document.documentTypeId)
                as DocumentTypeModel?;
                developer.log('AuditTrackerScreen - Found document type for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (_) {
                developer.log('AuditTrackerScreen - Document type not found for document ${index+1}/${documents.length}');
                documentType = null;
              }

              // Find category details
              CategoryModel? category;
              try {
                _stopwatch.reset();
                _stopwatch.start();
                category = categoryProvider.categories
                    .firstWhere((c) => c.id == document.categoryId);
                developer.log('AuditTrackerScreen - Found category for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');
              } catch (e) {
                developer.log('AuditTrackerScreen - Category not found for document ${index+1}/${documents.length}: ${e.toString()}');
                // Category not found, create a placeholder
                category = CategoryModel(
                  id: document.categoryId,
                  name: 'Unknown Category',
                  description: '',
                  order: 0,
                );
              }

              final documentName =
                  documentType?.name ?? 'Unknown Document Type';
              final categoryName = category.name;

              // Check if we're on a small screen
              final isSmallScreen = MediaQuery.of(context).size.width < 600;

              _stopwatch.reset();
              _stopwatch.start();
              final card = Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: isSmallScreen
                    ? _buildMobileDocumentCard(
                    document, documentName, categoryName, isAdmin)
                    : _buildDesktopDocumentCard(
                    document, documentName, categoryName, isAdmin),
              );
              developer.log('AuditTrackerScreen - Built card for document ${index+1}/${documents.length}: ${_stopwatch.elapsedMilliseconds}ms');

              return card;
            },
          ),
        ),
      ],
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildDocumentsView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  // Mobile document card with comments
  Widget _buildMobileDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document name and status
          Row(
            children: [
              Expanded(
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Category info
          Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expiry date
          if (document.expiryDate != null)
            Text(
              'Expires: ${DateFormat('MMM d, y').format(document.expiryDate!)}',
              style: TextStyle(
                fontSize: 13,
                color: document.isExpired ? Colors.red : Colors.grey.shade700,
              ),
            ),

          // Comments section
          if (document.comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Comments:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            ...document.comments.map((comment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y').format(comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 12),

          // Add resubmit button for rejected documents
          if (document.status == DocumentStatus.REJECTED) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                label: const Text('Resubmit'),
                onPressed: () {
                  // Navigate to document upload/form screen with existing document ID
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentUpload,
                    arguments: {
                      'categoryId': document.categoryId,
                      'documentTypeId': document.documentTypeId,
                      'documentId': document.id,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Update button for admin
          if (isAdmin)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Update'),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    RouteConstants.documentDetail,
                    arguments: {'documentId': document.id},
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Desktop document card with comments
  Widget _buildDesktopDocumentCard(DocumentModel document, String documentName,
      String categoryName, bool isAdmin) {
    return Column(
      children: [
        // Card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  documentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  document.expiryDate != null
                      ? 'Expires: ${DateFormat('MMM d, y').format(document.expiryDate!)}'
                      : 'No Expiry Date',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    document.isExpired ? Colors.red : Colors.grey.shade700,
                  ),
                ),
              ),
              document.isNotApplicable
                  ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Not Applicable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              )
                  : StatusBadge(
                status: document.status,
                isExpired: document.isExpired,
              ),
            ],
          ),
        ),

        // Description row with category and buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(categoryName),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              // Add resubmit button for rejected documents
              if (document.status == DocumentStatus.REJECTED)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 16),
                    label: const Text('Resubmit'),
                    onPressed: () {
                      // Navigate to document upload/form screen with existing document ID
                      Navigator.of(context).pushNamed(
                        RouteConstants.documentUpload,
                        arguments: {
                          'categoryId': document.categoryId,
                          'documentTypeId': document.documentTypeId,
                          'documentId': document.id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),

              if (isAdmin)
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update'),
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),

        // Add comments section
        if (document.comments.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                ...document.comments.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            comment.userName.isNotEmpty
                                ? comment.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y')
                                        .format(comment.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAuditListView(
      DocumentProvider documentProvider, CategoryProvider categoryProvider) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildAuditListView started');

    final categories = categoryProvider.categories;
    developer.log('AuditTrackerScreen - Categories count: ${categories.length}');

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    final result = ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        developer.log('AuditTrackerScreen - Building category item ${index+1}/${categories.length}');

        final category = categories[index];

        // Initialize expandedCategories map entry if needed
        if (!_expandedCategories.containsKey(category.id)) {
          _expandedCategories[category.id] = false;
        }

        final card = Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: [
              // Category header
              ListTile(
                leading: Icon(
                  _getCategoryIcon(category.name),
                  color: Theme.of(context).primaryColor,
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    _expandedCategories[category.id]!
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedCategories[category.id] =
                      !_expandedCategories[category.id]!;
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _expandedCategories[category.id] =
                    !_expandedCategories[category.id]!;
                  });
                },
              ),

              // Document types list (expandable)
              if (_expandedCategories[category.id]!) ...[
                const Divider(height: 1),
                _buildDocumentTypesList(
                    category.id, documentProvider, isSmallScreen),
              ],
            ],
          ),
        );

        developer.log('AuditTrackerScreen - Built category item ${index+1}/${categories.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return card;
      },
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildAuditListView completed: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  Widget _buildDocumentTypesList(String categoryId,
      DocumentProvider documentProvider, bool isSmallScreen) {
    _stopwatch.reset();
    _stopwatch.start();
    developer.log('AuditTrackerScreen - _buildDocumentTypesList started for category: $categoryId');

    final documentTypes = documentProvider.documentTypes
        .where((dt) => dt.categoryId == categoryId)
        .toList();

    developer.log('AuditTrackerScreen - Document types for category $categoryId: ${documentTypes.length}');

    if (documentTypes.isEmpty) {
      developer.log('AuditTrackerScreen - No document types found for category: $categoryId');
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No document types found for this category'),
      );
    }

    final result = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documentTypes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        _stopwatch.reset();
        _stopwatch.start();
        developer.log('AuditTrackerScreen - Building document type ${index+1}/${documentTypes.length} for category: $categoryId');

        final documentType = documentTypes[index];

        // Check if this document type has been uploaded
        final existingDocuments = documentProvider.documents
            .where((doc) => doc.documentTypeId == documentType.id)
            .toList();

        developer.log('AuditTrackerScreen - Found ${existingDocuments.length} existing documents for type: ${documentType.id}');

        final hasDocument = existingDocuments.isNotEmpty;
        final documentStatus = hasDocument
            ? existingDocuments.first.isNotApplicable
            ? 'Not Applicable'
            : existingDocuments.first.status.name
            : 'Not Uploaded';

        final listItem = isSmallScreen
            ? _buildMobileDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments)
            : _buildDesktopDocumentTypeItem(context, documentType, hasDocument,
            documentStatus, existingDocuments);

        developer.log('AuditTrackerScreen - Built document type ${index+1}/${documentTypes.length}: ${_stopwatch.elapsedMilliseconds}ms');
        return listItem;
      },
    );

    _stopwatch.stop();
    developer.log('AuditTrackerScreen - _buildDocumentTypesList completed for category $categoryId: ${_stopwatch.elapsedMilliseconds}ms');

    return result;
  }

  Widget _buildMobileDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentType.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            _getDocumentTypeDescription(documentType),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildStatusChip(documentStatus),
              const Spacer(),
              if (!hasDocument ||
                  (hasDocument && existingDocuments.first.isRejected))
                OutlinedButton(
                  onPressed: () =>
                      _navigateToDocumentUpload(context, documentType),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(documentType.isUploadable ? 'Upload' : 'Fill Form'),
                ),
              // ... rest of the code ...
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDocumentTypeItem(
      BuildContext context,
      DocumentTypeModel documentType,
      bool hasDocument,
      String documentStatus,
      List<DocumentModel> existingDocuments) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 24, right: 16),
      title: Text(documentType.name),
      subtitle: Text(
        _getDocumentTypeDescription(documentType),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip(documentStatus),
          const SizedBox(width: 8),
          if (!hasDocument ||
              (hasDocument && existingDocuments.first.isRejected))
            OutlinedButton(
              onPressed: () => _navigateToDocumentUpload(context, documentType),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(documentType.isUploadable ? 'Upload' : 'Fill Form'),
            ),
          // ... rest of the code ...
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'APPROVED':
      case 'Approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'PENDING':
      case 'Pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'REJECTED':
      case 'Rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'Not Applicable':
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        break;
      case 'Not Uploaded':
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getDocumentTypeDescription(DocumentTypeModel documentType) {
    List<String> properties = [];

    if (documentType.allowMultipleDocuments) {
      properties.add('Multiple documents allowed');
    }

    if (documentType.hasExpiryDate) {
      properties.add('Requires expiry date');
    }

    if (documentType.requiresSignature) {
      properties.add('Requires signature');
    }

    if (documentType.hasNotApplicableOption) {
      properties.add('Can be marked N/A');
    }

    return properties.join(' • ');
  }

  void _navigateToDocumentUpload(
      BuildContext context, DocumentTypeModel documentType) {
    developer.log('AuditTrackerScreen - Navigating to document upload/form: ${documentType.id}');

    if (documentType.isUploadable) {
      Navigator.of(context).pushNamed(
        RouteConstants.documentUpload,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    } else {
      Navigator.of(context).pushNamed(
        RouteConstants.documentForm,
        arguments: {
          'categoryId': documentType.categoryId,
          'documentTypeId': documentType.id,
        },
      );
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();

    if (name.contains('business') || name.contains('compliance')) {
      return Icons.business;
    } else if (name.contains('management')) {
      return Icons.settings;
    } else if (name.contains('employment')) {
      return Icons.people;
    } else if (name.contains('child') || name.contains('young')) {
      return Icons.child_care;
    } else if (name.contains('forced') || name.contains('labor prevention')) {
      return Icons.security;
    } else if (name.contains('wages') || name.contains('working')) {
      return Icons.payments;
    } else if (name.contains('association')) {
      return Icons.groups;
    } else if (name.contains('training')) {
      return Icons.school;
    } else if (name.contains('health') || name.contains('safety')) {
      return Icons.health_and_safety;
    } else if (name.contains('chemical') || name.contains('pesticide')) {
      return Icons.science;
    } else if (name.contains('service') || name.contains('provider')) {
      return Icons.handyman;
    } else if (name.contains('environmental') || name.contains('community')) {
      return Icons.eco;
    }

    return Icons.folder;
  }
}