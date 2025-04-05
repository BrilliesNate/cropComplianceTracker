// views/audit_index/category_documents_screen.dart
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_model.dart';
import '../../models/enums.dart';
import '../../core/constants/route_constants.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';

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

    final isLoading = documentProvider.isLoading;
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
            child: _buildDocumentTable(documentProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context) {
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
          // Status dropdown
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

  Widget _buildDocumentTable(DocumentProvider documentProvider) {
    // Get documents for this category
    var documents = documentProvider.getDocumentsByCategory(widget.categoryId);

    // Filter by status if selected
    if (_statusFilter != null && _statusFilter!.isNotEmpty) {
      if (_statusFilter == 'APPROVED') {
        documents = documents.where((doc) => doc.isComplete).toList();
      } else if (_statusFilter == 'PENDING') {
        documents = documents.where((doc) => doc.isPending).toList();
      } else if (_statusFilter == 'REJECTED') {
        documents = documents.where((doc) => doc.isRejected).toList();
      } else if (_statusFilter == 'EXPIRED') {
        documents = documents.where((doc) => doc.isExpired).toList();
      } else if (_statusFilter == 'NOT_APPLICABLE') {
        documents = documents.where((doc) => doc.isNotApplicable).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final documentTypes = documentProvider.documentTypes;

      documents = documents.where((doc) {
        DocumentTypeModel? documentType;
        try {
          documentType = documentTypes.firstWhere((dt) => dt.id == doc.documentTypeId) as DocumentTypeModel?;
        } catch (_) {
          documentType = null;
        }

        if (documentType != null) {
          return documentType.name.toLowerCase().contains(_searchQuery.toLowerCase());
        }

        return false;
      }).toList();
    }

    if (documents.isEmpty) {
      return const Center(
        child: Text('No documents found for this category'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Document Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expiry Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Uploaded Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 50), // Width for actions column
              ],
            ),
          ),
          const Divider(height: 0),

          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: documents.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, index) {
                final document = documents[index];
                DocumentTypeModel? documentType;
                try {
                  documentType = documentProvider.documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
                } catch (_) {
                  documentType = null;
                }

                final documentName = documentType?.name ?? 'Unknown Document Type';

                return Container(
                  color: index.isEven ? Colors.white : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        // Document Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            documentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
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
                            ),
                          ),
                        ),
                        // Status
                        Expanded(
                          flex: 2,
                          child: document.isNotApplicable
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
                        ),
                        // Uploaded Date
                        Expanded(
                          flex: 2,
                          child: Text(
                            DateFormat('MMM d, y').format(document.createdAt),
                          ),
                        ),
                        // Action button
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Document',
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
          ),
        ],
      ),
    );
  }
}