import 'package:cropcompliance/models/document_type_model.dart';
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
import 'widgets/document_list_item.dart';
import 'widgets/document_filter.dart';

class AuditIndexScreen extends StatefulWidget {
  const AuditIndexScreen({Key? key}) : super(key: key);

  @override
  State<AuditIndexScreen> createState() => _AuditIndexScreenState();
}

class _AuditIndexScreenState extends State<AuditIndexScreen> {
  String? _selectedCategoryId;
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
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();
      await documentProvider.initialize(authProvider.currentUser!.companyId);

      // Set first category as selected if available
      if (categoryProvider.categories.isNotEmpty && mounted) {
        setState(() {
          _selectedCategoryId = categoryProvider.categories.first.id;
        });
      }
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
        title: 'Audit Index',
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const LoadingIndicator(message: 'Loading audit data...')
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
    );
  }

  Widget _buildMobileView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DocumentFilter(
                categories: categories,
                selectedCategoryId: _selectedCategoryId,
                statusFilter: _statusFilter,
                searchQuery: _searchQuery,
                onCategoryChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                onStatusChanged: (value) {
                  setState(() {
                    _statusFilter = value;
                  });
                },
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildDocumentList(),
        ),
      ],
    );
  }

  Widget _buildTabletView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DocumentFilter(
            categories: categories,
            selectedCategoryId: _selectedCategoryId,
            statusFilter: _statusFilter,
            searchQuery: _searchQuery,
            onCategoryChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            onStatusChanged: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        Expanded(
          child: _buildDocumentList(),
        ),
      ],
    );
  }

  Widget _buildDesktopView(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DocumentFilter(
            categories: categories,
            selectedCategoryId: _selectedCategoryId,
            statusFilter: _statusFilter,
            searchQuery: _searchQuery,
            onCategoryChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
            onStatusChanged: (value) {
              setState(() {
                _statusFilter = value;
              });
            },
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            isDesktop: true,
          ),
        ),
        Expanded(
          child: _buildDocumentList(),
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    // Filter documents based on selected category
    var documents = _selectedCategoryId != null
        ? documentProvider.getDocumentsByCategory(_selectedCategoryId!)
        : documentProvider.documents;

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
        child: Text('No documents found'),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return DocumentListItem(
          document: document,
          documentProvider: documentProvider,
          categoryProvider: categoryProvider,
        );
      },
    );
  }
}