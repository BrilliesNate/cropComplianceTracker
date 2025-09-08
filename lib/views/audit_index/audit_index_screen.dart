// views/audit_index/audit_index_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';

class AuditIndexScreen extends StatefulWidget {
  const AuditIndexScreen({Key? key}) : super(key: key);

  @override
  State<AuditIndexScreen> createState() => _AuditIndexScreenState();
}

class _AuditIndexScreenState extends State<AuditIndexScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await categoryProvider.initialize();

      // Use the company-aware method instead of the old initialize method
      await documentProvider.refreshForUserContext(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    final isLoading = categoryProvider.isLoading || documentProvider.isLoading;
    final hasError = categoryProvider.error != null || documentProvider.error != null;
    final error = categoryProvider.error ?? documentProvider.error ?? '';

    Widget content;
    if (isLoading) {
      content = const LoadingIndicator(message: 'Loading categories...');
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: _initializeData,
      );
    } else {
      content = _buildCategoryList(categoryProvider, documentProvider);
    }

    return AppScaffoldWrapper(
      title: 'Audit Index',
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  Widget _buildCategoryList(CategoryProvider categoryProvider, DocumentProvider documentProvider) {
    // Filter out duplicates by creating a unique list of category IDs
    final categories = categoryProvider.categories;
    final uniqueIds = <String>{};
    final uniqueCategories = categories.where((category) =>
        uniqueIds.add(category.id)
    ).toList();

    if (uniqueCategories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: uniqueCategories.length,
      itemBuilder: (context, index) {
        final category = uniqueCategories[index];

        // Get document count for this category
        final documentsInCategory = documentProvider.getDocumentsByCategory(category.id);
        final documentCount = documentsInCategory.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                Icon(
                  _getCategoryIcon(category.name),
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                if (documentCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _buildDocumentCountBadge(documentCount),
                  ),
              ],
            ),
            title: Text(category.name),
            subtitle: Text(
              category.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (documentCount > 0)
                  Text(
                    '$documentCount doc${documentCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () {
              Navigator.of(context).pushNamed(
                RouteConstants.categoryDocuments,
                arguments: {'categoryId': category.id, 'categoryName': category.name},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDocumentCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
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