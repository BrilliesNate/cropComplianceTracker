
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/user_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/views/shared/custom_app_bar.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:cropCompliance/views/shared/status_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryDocumentsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDocumentsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  State<CategoryDocumentsScreen> createState() => _CategoryDocumentsScreenState();
}

class _CategoryDocumentsScreenState extends State<CategoryDocumentsScreen> {
  String? _statusFilter;
  String _searchQuery = '';
  List<UserModel> _users = [];
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoadingUsers = false;

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

    if (authProvider.currentUser != null) {
      await documentProvider.initialize(authProvider.currentUser!.companyId);
      // Load users for the company to get names
      await _loadUsers(authProvider.currentUser!.companyId);
    }
  }

  Future<void> _loadUsers(String companyId) async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await _firestoreService.getUsers(companyId: companyId);
      setState(() {
        _users = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  String _getUserName(String userId) {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      return user.name;
    } catch (_) {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = documentProvider.isLoading || _isLoadingUsers;
    final hasError = documentProvider.error != null;
    final error = documentProvider.error ?? '';

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.categoryName,
        showBackButton: true,
      ),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading documents...')
          : hasError
          ? ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      )
          : Column(
        children: [
          _buildFilterControls(context),
          Expanded(
            child: _buildGroupedDocumentTables(documentProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status dropdown - Hide for auditors since they only see approved documents
          if (!authProvider.isAuditer)
            Container(
              height: 42,
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _statusFilter,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('All Statuses'),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  borderRadius: BorderRadius.circular(8),
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Statuses'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'APPROVED',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'PENDING',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'REJECTED',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'EXPIRED',
                      child: Text('Expired'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'NOT_APPLICABLE',
                      child: Text('Not Applicable'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
            ),

          // Show auditor info instead of status filter
          if (authProvider.isAuditer)
            Container(
              height: 42,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Showing Approved Documents Only',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Search field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedDocumentTables(DocumentProvider documentProvider) {
    // Get documents for this category
    List documents = documentProvider.getDocumentsByCategory(widget.categoryId);

    // Apply filters
    documents = _applyFilters(documents, documentProvider);

    if (documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No documents found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search criteria',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Group documents by document type name
    final groupedDocuments = _groupDocumentsByType(documents, documentProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedDocuments.entries.map((entry) {
          final documentTypeName = entry.key;
          final documentsInGroup = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Type Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 0, top: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        documentTypeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${documentsInGroup.length} document${documentsInGroup.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Document Table
              _buildDocumentTable(documentsInGroup),

              const SizedBox(height: 24), // Space between tables
            ],
          );
        }).toList(),
      ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> documents, DocumentProvider documentProvider) {
    var filteredDocs = documents.toList();

    // Role-based filtering: Auditors should only see approved documents
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuditer) {
      filteredDocs = filteredDocs.where((doc) => doc.isComplete).toList();
    }

    // Filter by status if selected
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      if (_statusFilter == 'APPROVED') {
        filteredDocs = filteredDocs.where((doc) => doc.isComplete).toList();
      } else if (_statusFilter == 'PENDING') {
        filteredDocs = filteredDocs.where((doc) => doc.isPending).toList();
      } else if (_statusFilter == 'REJECTED') {
        filteredDocs = filteredDocs.where((doc) => doc.isRejected).toList();
      } else if (_statusFilter == 'EXPIRED') {
        filteredDocs = filteredDocs.where((doc) => doc.isExpired).toList();
      } else if (_statusFilter == 'NOT_APPLICABLE') {
        filteredDocs = filteredDocs.where((doc) => doc.isNotApplicable).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final documentTypes = documentProvider.documentTypes;

      filteredDocs = filteredDocs.where((doc) {
        DocumentTypeModel? documentType;
        try {
          documentType = documentTypes.firstWhere((dt) => dt.id == doc.documentTypeId) as DocumentTypeModel?;
        } catch (_) {
          documentType = null;
        }

        if (documentType != null) {
          // Search in document name and specification
          final searchLower = _searchQuery.toLowerCase();
          final nameMatch = documentType.name.toLowerCase().contains(searchLower);
          final specMatch = doc.specification?.toLowerCase().contains(searchLower) ?? false;
          return nameMatch || specMatch;
        }

        return false;
      }).toList();
    }

    return filteredDocs;
  }

  Map<String, List<dynamic>> _groupDocumentsByType(List<dynamic> documents, DocumentProvider documentProvider) {
    final Map<String, List<dynamic>> grouped = {};
    final documentTypes = documentProvider.documentTypes;

    for (final document in documents) {
      DocumentTypeModel? documentType;
      try {
        documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
      } catch (_) {
        documentType = null;
      }

      final documentTypeName = documentType?.name ?? 'Unknown Document Type';

      if (!grouped.containsKey(documentTypeName)) {
        grouped[documentTypeName] = [];
      }
      grouped[documentTypeName]!.add(document);
    }

    // Sort each group by creation date (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    return grouped;
  }

  Widget _buildDocumentTable(List<dynamic> documents) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Specification',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Uploaded By',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Upload Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Actions column
              ],
            ),
          ),

          // Table body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: documents.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final document = documents[index];

              return Container(
                color: index.isEven ? Colors.white : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Specification
                      Expanded(
                        flex: 3,
                        child: Text(
                          document.specification?.isNotEmpty == true
                              ? document.specification!
                              : 'No specification provided',
                          style: TextStyle(
                            fontSize: 13,
                            color: document.specification?.isNotEmpty == true
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontStyle: document.specification?.isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Uploaded By
                      Expanded(
                        flex: 2,
                        child: Text(
                          _getUserName(document.userId),
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Upload Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('MMM d, y').format(document.createdAt),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),

                      // Expiry Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          document.expiryDate != null
                              ? DateFormat('MMM d, y').format(document.expiryDate!)
                              : 'No Expiry',
                          style: TextStyle(
                            color: document.isExpired
                                ? Colors.red
                                : Colors.grey.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Status - Fixed to not stretch
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: document.isNotApplicable
                              ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                              : StatusBadge(
                            status: document.status,
                            isExpired: document.isExpired,
                          ),
                        ),
                      ),

                      // Action button
                      SizedBox(
                        width: 50,
                        child: IconButton(
                          icon: const Icon(Icons.visibility, size: 18),
                          tooltip: 'View Document',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              RouteConstants.documentDetail,
                              arguments: {'documentId': document.id},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}