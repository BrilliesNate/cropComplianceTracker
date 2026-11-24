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
import 'package:cropCompliance/providers/locale_provider.dart';

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
  // All users, keyed by id — so an uploader who isn't in THIS company (an admin
  // who uploaded on the company's behalf, a removed user, or one carried over by
  // a company merge) still resolves to a name instead of "Unknown User".
  Map<String, UserModel> _allUsersById = {};
  final FirestoreService _firestoreService = FirestoreService();
  // False until documents and uploader names have both loaded, so the page
  // appears finished in one go instead of filling in piece by piece.
  late bool _ready;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final docs = Provider.of<DocumentProvider>(context, listen: false);
    // Documents already in memory for this company (the usual case when
    // arriving from the Audit Index) → draw immediately.
    _ready = auth.currentUser != null &&
        docs.currentContextCompanyId == (auth.effectiveCompany?.id ?? '') &&
        docs.documents.isNotEmpty &&
        // Uploader names: admins have every user in memory, auditors don't need
        // them; everyone else needs one quick lookup first.
        (auth.isAuditer || (auth.isAdmin && auth.allUsers.isNotEmpty));
    if (_ready) _useUsersInMemory(auth);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _useUsersInMemory(AuthProvider auth) {
    if (auth.isAdmin && auth.allUsers.isNotEmpty) {
      _allUsersById = {for (final u in auth.allUsers) u.id: u};
    }
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // Determine which company to load users for
      String companyId;
      if (authProvider.isManagingCompany && authProvider.selectedCompany != null) {
        // Admin is managing a specific company
        companyId = authProvider.selectedCompany!.id;
      } else if (authProvider.hasSelectedUser && authProvider.selectedUser != null) {
        // Admin has selected a specific user
        companyId = authProvider.selectedUser!.companyId;
      } else {
        // Regular user or admin viewing their own company
        companyId = authProvider.currentUser!.companyId;
      }

      try {
        // Documents (respecting company selection) and uploader names together.
        await Future.wait([
          documentProvider.refreshForUserContext(context),
          _loadUsers(companyId),
        ]);
      } finally {
        if (mounted) setState(() => _ready = true);
      }
    }
  }

  Future<void> _loadUsers(String companyId) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Auditors never need user records: the document carries the uploader's
      // name, and auditors are not allowed to read user accounts at all.
      if (auth.isAuditer) return;

      // Admins already hold every user in memory — no query needed.
      if (auth.isAdmin && auth.allUsers.isNotEmpty) {
        _useUsersInMemory(auth);
        return;
      }

      // Everyone else resolves from their own company's users (security rules
      // only let an admin list all users) — plus the uploader name stored on
      // each document.
      final users = auth.isAdmin
          ? await _firestoreService.getUsers()
          : await _firestoreService.getUsers(companyId: companyId);
      _allUsersById = {for (final u in users) u.id: u};
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  /// The label to show for a document's uploader. Prefers the name captured on
  /// the document at upload time; otherwise resolves the stored userId.
  String _uploaderLabel(dynamic document) {
    final captured = document.uploadedByName;
    if (captured is String && captured.trim().isNotEmpty) return captured;
    // Auditors can't look users up, so an older document with no stored name
    // reads as blank rather than a misleading "Unknown User".
    if (Provider.of<AuthProvider>(context, listen: false).isAuditer) return '—';
    return _getUserName(document.userId as String? ?? '');
  }

  String _getUserName(String userId) {
    final user = _allUsersById[userId];
    if (user == null) return context.l10n.unknownUser;
    // Show the actual person's name, whoever they are (admin included).
    return user.name.trim().isNotEmpty ? user.name : context.l10n.unknownUser;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    if (authProvider.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.pleaseLogIn),
        ),
      );
    }

    final isLoading = !_ready || documentProvider.isLoading;
    final hasError = documentProvider.error != null;
    final error = documentProvider.error ?? '';

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.categoryName,
        showBackButton: true,
      ),
      body: isLoading
          ? LoadingIndicator(message: context.l10n.docsLoading)
          : hasError
          ? ErrorDisplay(error: error, onRetry: _initializeData)
          : Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildGroupedDocumentTables(documentProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Auditors only ever see approved documents, so a status filter would just
    // offer them options that always come back empty.
    final isAuditer = Provider.of<AuthProvider>(context, listen: false).isAuditer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status Filter Dropdown
          if (!isAuditer) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButton<String?>(
              value: _statusFilter,
              hint: Text(context.l10n.filterLabel),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: null, child: Text(context.l10n.filterAll)),
                DropdownMenuItem(value: 'APPROVED', child: Text(context.l10n.statusApproved)),
                DropdownMenuItem(value: 'PENDING', child: Text(context.l10n.statusPending)),
                DropdownMenuItem(value: 'REJECTED', child: Text(context.l10n.statusRejected)),
                DropdownMenuItem(value: 'EXPIRED', child: Text(context.l10n.statusExpired)),
                DropdownMenuItem(value: 'NOT_APPLICABLE', child: Text('N/A')),
              ],
              onChanged: (value) {
                setState(() {
                  _statusFilter = value;
                });
              },
              icon: Icon(Icons.filter_list, size: 16, color: Colors.grey.shade600),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ],

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
                decoration: InputDecoration(
                  hintText: context.l10n.docsSearchHint,
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
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                context.l10n.docsNoneFound,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.docsTryAdjusting,
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
                        context.l10n.documentCount(documentsInGroup.length),
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

      final documentTypeName = documentType?.name ?? context.l10n.unknownDocumentType;

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
    // Check if mobile view
    final isMobile = MediaQuery.of(context).size.width < 650;

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
      child: isMobile
          ? _buildMobileDocumentList(documents)
          : _buildDesktopDocumentTable(documents),
    );
  }

  // MOBILE VERSION - Vertical cards
  Widget _buildMobileDocumentList(List<dynamic> documents) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final document = documents[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAdmin = authProvider.isAdmin;

        return Container(
          padding: const EdgeInsets.all(16),
          color: index.isEven ? Colors.white : Colors.grey.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Specification
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.description_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.specification,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          document.specification?.isNotEmpty == true
                              ? document.specification!
                              : context.l10n.specNone,
                          style: TextStyle(
                            fontSize: 13,
                            color: document.specification?.isNotEmpty == true
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontStyle: document.specification?.isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                        ),
                        if (document.reviewedDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.lastReviewedShort(_fmtReviewed(document.reviewedDate!)),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Uploaded By
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.uploadedBy,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _uploaderLabel(document),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Upload Date
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.uploadDate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(document.createdAt),
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Expiry Date
              Row(
                children: [
                  Icon(
                    document.effectiveExpiryDate != null && document.isExpired
                        ? Icons.warning_amber_rounded
                        : Icons.event_outlined,
                    size: 16,
                    color: document.effectiveExpiryDate != null && document.isExpired
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.expiryDateTitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          document.effectiveExpiryDate != null
                              ? DateFormat('MMM d, yyyy').format(document.effectiveExpiryDate!)
                              : context.l10n.expiryNone,
                          style: TextStyle(
                            fontSize: 13,
                            color: document.effectiveExpiryDate != null && document.isExpired
                                ? Colors.red.shade700
                                : document.effectiveExpiryDate != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: document.effectiveExpiryDate != null && document.isExpired
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status
              Row(
                children: [
                  Text(
                    context.l10n.statusLabelColon,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  StatusBadge(
                    status: document.status,
                    isExpired: document.isExpired,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Actions
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: Text(context.l10n.actionViewDetails),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // DESKTOP VERSION - Horizontal table (unchanged)
  Widget _buildDesktopDocumentTable(List<dynamic> documents) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  context.l10n.specification,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.uploadedBy,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.uploadDate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.expiryDateTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  context.l10n.colStatus,
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
                    // Specification (+ last reviewed, when the type has one)
                    Expanded(
                      flex: 3,
                      child: Text(
                        (document.specification?.isNotEmpty == true
                                ? document.specification!
                                : context.l10n.specNone) +
                            (document.reviewedDate != null
                                ? context.l10n.reviewedSuffix(_fmtReviewed(document.reviewedDate!))
                                : ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: document.specification?.isNotEmpty == true
                              ? Colors.black87
                              : Colors.grey.shade600,
                          fontStyle: document.specification?.isNotEmpty == true
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),

                    // Uploaded By
                    Expanded(
                      flex: 2,
                      child: Text(
                        _uploaderLabel(document),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),

                    // Upload Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('MMM d, yyyy').format(document.createdAt),
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),

                    // Expiry Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        document.effectiveExpiryDate != null
                            ? DateFormat('MMM d, yyyy').format(document.effectiveExpiryDate!)
                            : context.l10n.expiryNone,
                        style: TextStyle(
                          fontSize: 13,
                          color: document.effectiveExpiryDate != null && document.isExpired
                              ? Colors.red.shade700
                              : document.effectiveExpiryDate != null
                              ? Colors.black87
                              : Colors.grey.shade600,
                          fontWeight: document.effectiveExpiryDate != null && document.isExpired
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),

                    // Status
                    Expanded(
                      flex: 2,
                      child: StatusBadge(
                        status: document.status,
                        isExpired: document.isExpired,
                      ),
                    ),

                    // Actions
                    SizedBox(
                      width: 50,
                      child: IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            RouteConstants.documentDetail,
                            arguments: {'documentId': document.id},
                          );
                        },
                        tooltip: context.l10n.actionViewDetails,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Month names follow the app language.
String _fmtReviewed(DateTime d) => DateFormat('d MMM yyyy').format(d);
