// views/audit_index/audit_index_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/route_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/data_bootstrap.dart';
import '../../models/document_model.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/providers/locale_provider.dart';
import 'package:cropCompliance/models/enums.dart';

class AuditIndexScreen extends StatefulWidget {
  const AuditIndexScreen({Key? key}) : super(key: key);

  @override
  State<AuditIndexScreen> createState() => _AuditIndexScreenState();
}

class _AuditIndexScreenState extends State<AuditIndexScreen> {
  String _selectedPackage = 'siza_wieta'; // Default package

  late bool _ready; // see DashboardScreen: one loader, then the finished page

  @override
  void initState() {
    super.initState();
    _ready = isCompanyDataWarm(context, withOverrides: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    // Set initial package filter based on company's available packages
    final packages = authProvider.effectivePackages;
    if (packages.isNotEmpty) _selectedPackage = packages.first;

    try {
      await loadCompanyData(
        context,
        packages: packages.isNotEmpty ? [_selectedPackage] : null,
        withOverrides: false,
      );
    } finally {
      if (mounted) setState(() => _ready = true);
    }
  }

  void _onPackageSelected(String packageId) {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    setState(() {
      _selectedPackage = packageId;
    });

    categoryProvider.setPackageFilter([packageId]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    if (authProvider.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.pleaseLogIn),
        ),
      );
    }

    final isLoading = !_ready || categoryProvider.isLoading || documentProvider.isLoading;
    final hasError = categoryProvider.error != null || documentProvider.error != null;
    final error = categoryProvider.error ?? documentProvider.error ?? '';

    Widget content;
    if (isLoading) {
      content = LoadingIndicator(message: context.l10n.categoriesLoading);
    } else if (hasError) {
      content = ErrorDisplay(
        error: error,
        onRetry: () {
          setState(() => _ready = false);
          _initializeData();
        },
      );
    } else {
      content = Column(
        children: [
          // Package toggle buttons (only show if company has multiple packages)
          if (authProvider.hasBothPackages)
            _buildPackageToggle(authProvider),

          // Category list
          Expanded(
            child: _buildCategoryList(categoryProvider, documentProvider),
          ),
        ],
      );
    }

    return AppScaffoldWrapper(
      title: context.l10n.menuAuditIndex,
      backgroundColor: Colors.grey[100],
      child: content,
    );
  }

  IconData _packageIcon(String id) {
    switch (id) {
      case 'globalgap':
        return Icons.eco;
      case 'ipw':
        return Icons.wine_bar;
      case 'fairtrade':
        return Icons.handshake_outlined;
      case 'siza_environmental':
        return Icons.forest_outlined;
      default:
        return Icons.people;
    }
  }

  Widget _buildPackageToggle(AuthProvider authProvider) {
    // Only show toggles for packages this company actually has enabled.
    final enabled = AppConstants.auditPackages
        .where((p) => authProvider.effectivePackages.contains(p.id))
        .toList();
    if (enabled.length < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          for (int i = 0; i < enabled.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: _buildPackageButton(
                packageId: enabled[i].id,
                label: enabled[i].label,
                icon: _packageIcon(enabled[i].id),
                isSelected: _selectedPackage == enabled[i].id,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageButton({
    required String packageId,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor
          : Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: () => _onPackageSelected(packageId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(CategoryProvider categoryProvider, DocumentProvider documentProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = authProvider.isAdmin;

    // Filter out duplicates by creating a unique list of category IDs
    final categories = categoryProvider.categories;
    final uniqueIds = <String>{};
    final uniqueCategories = categories.where((category) =>
        uniqueIds.add(category.id)
    ).toList();

    if (uniqueCategories.isEmpty) {
      return Center(
        child: Text(context.l10n.categoriesNoneFound),
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
                    context.l10n.docCountShort(documentCount),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                // Admin delete menu
                if (isAdmin && documentCount > 0) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete_all') {
                        _showDeleteAllConfirmation(category.id, category.name, documentsInCategory);
                      } else if (value == 'delete_selected') {
                        _showSelectDocumentsDialog(category.id, category.name, documentsInCategory);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete_selected',
                        child: Row(
                          children: [
                            Icon(Icons.checklist, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.deleteSelectedEllipsis),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete_all',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(context.l10n.deleteAllCount(documentCount)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else
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
    } else if (name.contains('forced') || name.contains('labor prevention')) { // l10n-ignore: matches stored names
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

  // Show confirmation dialog to delete ALL documents in a category
  void _showDeleteAllConfirmation(String categoryId, String categoryName, List<DocumentModel> documents) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(context.l10n.deleteAllDocsTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.deleteAllDocsIn(documents.length),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.cannotBeUndone,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete(documents.map((d) => d.id).toList(), authProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.deleteAllCaps(documents.length)),
          ),
        ],
      ),
    );
  }

  // Show dialog to select which documents to delete
  void _showSelectDocumentsDialog(String categoryId, String categoryName, List<DocumentModel> documents) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.checklist, color: Colors.orange.shade700, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.selectDocsToDelete),
                      Text(
                        categoryName,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Select all / Deselect all buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.selectedOfTotal(selectedIds.length, documents.length),
                        style: TextStyle(
                          color: selectedIds.isNotEmpty ? Colors.red : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedIds.addAll(documents.map((d) => d.id));
                              });
                            },
                            child: Text(context.l10n.actionSelectAll),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedIds.clear();
                              });
                            },
                            child: Text(context.l10n.actionClear),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  // Document list
                  Expanded(
                    child: ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        final isSelected = selectedIds.contains(doc.id);
                        final docType = documentProvider.getDocumentTypeById(doc.documentTypeId);
                        final docTypeName = docType?.name ?? context.l10n.unknownType;

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(doc.id);
                              } else {
                                selectedIds.remove(doc.id);
                              }
                            });
                          },
                          title: Text(
                            docTypeName,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            context.l10n.docDeleteLine(
                                doc.status.label(context.l10n),
                                doc.fileUrls.length,
                                doc.createdAt.toString().substring(0, 10)),
                            style: const TextStyle(fontSize: 11),
                          ),
                          isThreeLine: true,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Colors.red,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () {
                  Navigator.of(context).pop();
                  _confirmSelectedDelete(selectedIds.toList(), authProvider);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(context.l10n.deleteCaps(selectedIds.length)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Confirm deletion of selected documents
  void _confirmSelectedDelete(List<String> documentIds, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 28),
            const SizedBox(width: 12),
            Text(context.l10n.confirmDeleteTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.confirmDeleteDocs(documentIds.length)),
            const SizedBox(height: 16),
            Text(
              context.l10n.cannotBeUndone,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBulkDelete(documentIds, authProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  // Perform the actual bulk delete
  Future<void> _performBulkDelete(List<String> documentIds, AuthProvider authProvider) async {
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(context.l10n.deletingDocs(documentIds.length)),
          ],
        ),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    try {
      for (String docId in documentIds) {
        final result = await documentProvider.deleteDocument(
          documentId: docId,
          user: authProvider.currentUser!,
          reason: 'Bulk delete from Audit Index', // l10n-ignore: stored audit log
        );

        if (result) {
          successCount++;
        } else {
          failCount++;
        }
      }
    } catch (e) {
      print('Error during bulk delete: $e');
    }

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // Show result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? context.l10n.deletedDocsOk(successCount)
                : context.l10n.deletedSomeFailed(successCount, failCount),
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      // Refresh the data
      await documentProvider.refreshForUserContext(context);
    }
  }
}