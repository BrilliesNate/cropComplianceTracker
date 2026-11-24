import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cropCompliance/core/constants/app_constants.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/core/services/firestore_service.dart';
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/views/shared/app_scaffold_wrapper.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Admin page that defines WHAT each audit standard requires:
///
///   Standard (SIZA/WIETA, GlobalG.A.P., IPW, Fairtrade, SIZA Environmental)
///     └─ Categories  (e.g. "1. Internal Documentation")
///          └─ Document types  (e.g. "Document control procedure")
///
/// Everything here is global: it applies to every company on that standard.
/// Per-company choices live elsewhere — which standards a company has
/// (Company Management) and switching a document type off for one company
/// (Document Settings). See docs/category-management-guide.md.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = true;
  String? _error;
  List<CategoryModel> _categories = [];
  List<DocumentTypeModel> _types = [];

  String _packageId = AppConstants.defaultPackageId;
  String? _selectedCategoryId;
  bool _narrowShowTypes = false; // phone/tablet: category list ↔ its types
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Make the rest of the app reload categories / document types rather than
    // trust its session cache.
    FirestoreService.invalidateReferenceData();
    CategoryProvider.markOverridesStale();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Read straight from Firestore (not the app cache) so this page always
      // shows the true state. No orderBy: a category missing its 'order' field
      // would otherwise be invisible here too.
      final snaps = await Future.wait([
        _db.collection('categories').get(),
        _db.collection('documentTypes').get(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = snaps[0]
            .docs
            .map((d) => CategoryModel.fromMap(d.data(), d.id))
            .toList();
        _types = snaps[1]
            .docs
            .map((d) => DocumentTypeModel.fromMap(d.data(), d.id))
            .toList();
        _loading = false;
        _ensureSelection();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load categories: $e';
      });
    }
  }

  List<CategoryModel> _categoriesOf(String packageId) {
    final list = _categories.where((c) => c.packageId == packageId).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
    return list;
  }

  List<CategoryModel> get _packageCategories => _categoriesOf(_packageId);

  List<DocumentTypeModel> _typesOf(String categoryId) =>
      _types.where((t) => t.categoryId == categoryId).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  int _typeCountForPackage(String packageId) {
    final ids = _categoriesOf(packageId).map((c) => c.id).toSet();
    return _types.where((t) => ids.contains(t.categoryId)).length;
  }

  CategoryModel? _categoryById(String? id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  String _packageLabel(String id) {
    for (final p in AppConstants.auditPackages) {
      if (p.id == id) return p.label;
    }
    return id;
  }

  /// Keeps a valid category selected for the current standard.
  void _ensureSelection() {
    final cats = _packageCategories;
    if (cats.every((c) => c.id != _selectedCategoryId)) {
      _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
    }
  }

  void _afterWrite() {
    // Other screens must see the change, even while this page stays open.
    FirestoreService.invalidateReferenceData();
    CategoryProvider.markOverridesStale();
  }

  // ── Feedback helpers ───────────────────────────────────────────────────────

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 5 : 2),
    ));
  }

  /// Runs [task] behind a small blocking indicator ("Saving…" by default).
  Future<T?> _withProgress<T>(Future<T> Function() task,
      {String label = 'Saving…'}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 14),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    try {
      return await task();
    } catch (e) {
      _toast('Something went wrong: $e', error: true);
      return null;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _inform(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(message),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<int> _documentCountForType(String typeId) async {
    final agg = await _db
        .collection('documents')
        .where('documentTypeId', isEqualTo: typeId)
        .count()
        .get();
    return agg.count ?? 0;
  }

  // ── Category actions ───────────────────────────────────────────────────────

  Future<void> _addCategory() async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryDialog(
        initialPackageId: _packageId,
        existing: _categories,
      ),
    );
    if (draft == null) return;

    final siblings = _categoriesOf(draft.packageId);
    final order = siblings.isEmpty
        ? 1
        : siblings.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;

    final created = await _withProgress(() async {
      final ref = await _db.collection('categories').add({
        'name': draft.name,
        'description': draft.description,
        'order': order,
        'packageId': draft.packageId,
      });
      return CategoryModel(
        id: ref.id,
        name: draft.name,
        description: draft.description,
        order: order,
        packageId: draft.packageId,
      );
    });
    if (created == null || !mounted) return;

    _afterWrite();
    setState(() {
      _categories.add(created);
      _packageId = created.packageId;
      _selectedCategoryId = created.id;
      _narrowShowTypes = true;
      _clearSearch();
    });
    _toast('Category "${created.name}" added');
  }

  Future<void> _editCategory(CategoryModel category) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryDialog(
        initialPackageId: category.packageId,
        existing: _categories,
        editing: category,
      ),
    );
    if (draft == null) return;

    final movingStandard = draft.packageId != category.packageId;
    var order = category.order;
    if (movingStandard) {
      final typeCount = _typesOf(category.id).length;
      final ok = await _confirm(
        title: 'Move to ${_packageLabel(draft.packageId)}?',
        message:
            '"${category.name}" and its $typeCount document type(s) will move '
            'from ${_packageLabel(category.packageId)} to '
            '${_packageLabel(draft.packageId)}.\n\n'
            'Companies on ${_packageLabel(category.packageId)} will stop seeing '
            'it, and companies on ${_packageLabel(draft.packageId)} will start '
            'seeing it. Documents already uploaded are kept.',
        confirmLabel: 'Move category',
      );
      if (!ok) return;
      final siblings = _categoriesOf(draft.packageId);
      order = siblings.isEmpty
          ? 1
          : siblings.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;
    }

    final done = await _withProgress(() async {
      await _db.collection('categories').doc(category.id).update({
        'name': draft.name,
        'description': draft.description,
        'packageId': draft.packageId,
        'order': order,
      });
      return true;
    });
    if (done != true || !mounted) return;

    _afterWrite();
    setState(() {
      final i = _categories.indexWhere((c) => c.id == category.id);
      if (i != -1) {
        _categories[i] = category.copyWith(
          name: draft.name,
          description: draft.description,
          packageId: draft.packageId,
          order: order,
        );
      }
      _ensureSelection();
    });
    _toast(movingStandard
        ? 'Moved to ${_packageLabel(draft.packageId)}'
        : 'Category updated');
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final typeCount = _typesOf(category.id).length;
    if (typeCount > 0) {
      await _inform(
        'Category isn\'t empty',
        '"${category.name}" still has $typeCount document type(s).\n\n'
            'Move them to another category or delete them first, then delete '
            'the category. This protects documents companies have already '
            'uploaded.',
      );
      return;
    }
    final ok = await _confirm(
      title: 'Delete "${category.name}"?',
      message: 'This category has no document types. It will be removed from '
          '${_packageLabel(category.packageId)} for every company. '
          'This can\'t be undone.',
      confirmLabel: 'Delete category',
      destructive: true,
    );
    if (!ok) return;

    final done = await _withProgress(() async {
      await _db.collection('categories').doc(category.id).delete();
      return true;
    });
    if (done != true || !mounted) return;

    _afterWrite();
    setState(() {
      _categories.removeWhere((c) => c.id == category.id);
      _ensureSelection();
    });
    _toast('Category deleted');
  }

  /// Moves a category one place up (-1) or down (+1) within its standard.
  Future<void> _moveCategory(CategoryModel category, int delta) async {
    final list = _categoriesOf(category.packageId);
    final from = list.indexWhere((c) => c.id == category.id);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return;

    final moved = list.removeAt(from);
    list.insert(to, moved);

    // Renumber the whole standard 1..n so the order is always clean, even if
    // older categories shared numbers.
    final done = await _withProgress(() async {
      final batch = _db.batch();
      for (var i = 0; i < list.length; i++) {
        batch.update(_db.collection('categories').doc(list[i].id),
            {'order': i + 1});
      }
      await batch.commit();
      return true;
    });
    if (done != true || !mounted) return;

    _afterWrite();
    setState(() {
      for (var i = 0; i < list.length; i++) {
        final idx = _categories.indexWhere((c) => c.id == list[i].id);
        if (idx != -1) _categories[idx] = _categories[idx].copyWith(order: i + 1);
      }
    });
  }

  // ── Document type actions ──────────────────────────────────────────────────

  Future<void> _addType() async {
    if (_packageCategories.isEmpty) {
      await _inform('Add a category first',
          'Document types live inside a category. Add a category to ${_packageLabel(_packageId)} first.');
      return;
    }
    final draft = await showDialog<_DocTypeDraft>(
      context: context,
      builder: (_) => _DocTypeDialog(
        categories: _categories,
        types: _types,
        initialPackageId: _packageId,
        initialCategoryId: _selectedCategoryId,
        packageLabel: _packageLabel,
      ),
    );
    if (draft == null) return;

    final created = await _withProgress(() async {
      final data = draft.toMap()..['hasFormTemplate'] = false;
      final ref = await _db.collection('documentTypes').add(data);
      return DocumentTypeModel.fromMap(data, ref.id);
    });
    if (created == null || !mounted) return;

    _afterWrite();
    final category = _categoryById(created.categoryId);
    setState(() {
      _types.add(created);
      if (category != null) {
        _packageId = category.packageId;
        _selectedCategoryId = category.id;
        _narrowShowTypes = true;
      }
    });
    _toast('Document type "${created.name}" added');
  }

  Future<void> _editType(DocumentTypeModel type) async {
    final draft = await showDialog<_DocTypeDraft>(
      context: context,
      builder: (_) => _DocTypeDialog(
        categories: _categories,
        types: _types,
        initialPackageId:
            _categoryById(type.categoryId)?.packageId ?? _packageId,
        initialCategoryId: type.categoryId,
        editing: type,
        packageLabel: _packageLabel,
      ),
    );
    if (draft == null) return;

    // Moving to another category: uploaded documents carry the category too,
    // so they must move with the type or they'd sit under the wrong heading.
    final movingCategory = draft.categoryId != type.categoryId;
    var docsToMove = 0;
    if (movingCategory) {
      final counted = await _withProgress(() => _documentCountForType(type.id),
          label: 'Checking uploaded documents…');
      if (counted == null || !mounted) return; // couldn't check — don't guess
      docsToMove = counted;
      final target = _categoryById(draft.categoryId);
      final ok = await _confirm(
        title: 'Move to "${target?.name ?? 'another category'}"?',
        message: docsToMove == 0
            ? 'No documents have been uploaded for this type yet.'
            : '$docsToMove uploaded document(s) of this type will move with it, '
                'so they stay together in the Audit Index.',
        confirmLabel: 'Move',
      );
      if (!ok) return;
    }

    final done = await _withProgress(() async {
      // update() only touches these fields, so settings such as a linked form
      // template are kept.
      await _db.collection('documentTypes').doc(type.id).update(draft.toMap());

      if (movingCategory && docsToMove > 0) {
        final docs = await _db
            .collection('documents')
            .where('documentTypeId', isEqualTo: type.id)
            .get();
        for (var i = 0; i < docs.docs.length; i += 450) {
          final batch = _db.batch();
          for (final d in docs.docs.skip(i).take(450)) {
            batch.update(d.reference, {'categoryId': draft.categoryId});
          }
          await batch.commit();
        }
      }
      return true;
    });
    if (done != true || !mounted) return;

    _afterWrite();
    setState(() {
      final i = _types.indexWhere((t) => t.id == type.id);
      if (i != -1) {
        _types[i] = DocumentTypeModel(
          id: type.id,
          categoryId: draft.categoryId,
          name: draft.name,
          allowMultipleDocuments: draft.allowMultipleDocuments,
          isUploadable: draft.isUploadable,
          hasExpiryDate: draft.hasExpiryDate,
          hasNotApplicableOption: draft.hasNotApplicableOption,
          requiresSignature: draft.requiresSignature,
          signatureCount: draft.signatureCount,
          hasFormTemplate: type.hasFormTemplate,
          requiresSpecification: draft.requiresSpecification,
          hasReviewedDate: draft.hasReviewedDate,
        );
      }
    });
    _toast('Document type updated');
  }

  Future<void> _deleteType(DocumentTypeModel type) async {
    final count = await _withProgress(() => _documentCountForType(type.id),
        label: 'Checking uploaded documents…');
    if (count == null || !mounted) return;

    if (count > 0) {
      await _inform(
        'This document type is in use',
        'Companies have uploaded $count document(s) for "${type.name}". '
            'Deleting it would hide those documents from the Compliance '
            'Tracker and the Audit Index, so it can\'t be deleted.\n\n'
            'If a company doesn\'t need it, switch it off for that company in '
            'Document Settings instead.',
      );
      return;
    }

    final ok = await _confirm(
      title: 'Delete "${type.name}"?',
      message: 'No documents have been uploaded for it. It will disappear from '
          'every company\'s Compliance Tracker. This can\'t be undone.',
      confirmLabel: 'Delete document type',
      destructive: true,
    );
    if (!ok) return;

    final done = await _withProgress(() async {
      await _db.collection('documentTypes').doc(type.id).delete();
      return true;
    });
    if (done != true || !mounted) return;

    _afterWrite();
    setState(() => _types.removeWhere((t) => t.id == type.id));
    _toast('Document type deleted');
  }

  void _clearSearch() {
    _searchController.clear();
    _search = '';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    Widget body;
    if (!auth.isAdmin) {
      body = const Center(
          child: Text('You do not have permission to access this page'));
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ErrorDisplay(error: _error!, onRetry: _load);
    } else {
      body = LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIntro(),
              const SizedBox(height: 12),
              _buildStandardTabs(),
              const SizedBox(height: 12),
              Expanded(
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 320, child: _buildCategoryPanel(wide)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTypesPanel(wide)),
                        ],
                      )
                    : (_narrowShowTypes && _selectedCategoryId != null) ||
                            _search.isNotEmpty
                        ? _buildTypesPanel(wide)
                        : _buildCategoryPanel(wide),
              ),
            ],
          ),
        );
      });
    }

    return AppScaffoldWrapper(
      title: 'Category Management',
      backgroundColor: Colors.grey.shade100,
      child: body,
    );
  }

  BoxDecoration get _panelDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      );

  Widget _buildIntro() {
    return Container(
      decoration: _panelDecoration,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What each standard requires',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Pick a standard, then a category, then add or edit the '
                  'documents companies must provide. Changes apply to every '
                  'company on that standard.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline, size: 18),
            label: const Text('How this works'),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTabs() {
    final primary = Theme.of(context).primaryColor;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in AppConstants.auditPackages)
          Material(
            color: p.id == _packageId ? primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() {
                _packageId = p.id;
                _narrowShowTypes = false;
                _clearSearch();
                _ensureSelection();
              }),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: p.id == _packageId ? primary : Colors.grey.shade300,
                    width: p.id == _packageId ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: p.id == _packageId ? primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_categoriesOf(p.id).length} categories · '
                      '${_typeCountForPackage(p.id)} document types',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Category panel ─────────────────────────────────────────────────────────

  Widget _buildCategoryPanel(bool wide) {
    final cats = _packageCategories;
    final primary = Theme.of(context).primaryColor;

    return Container(
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Categories (${cats.length})',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add category'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cats.isEmpty
                ? _emptyState(
                    icon: Icons.folder_open_outlined,
                    title: 'No categories for ${_packageLabel(_packageId)} yet',
                    message:
                        'Categories group the documents a company must provide, '
                        'e.g. "Health & Safety".',
                    actionLabel: 'Add the first category',
                    onAction: _addCategory,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: cats.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final c = cats[i];
                      final selected = c.id == _selectedCategoryId;
                      final count = _typesOf(c.id).length;
                      return Material(
                        color: selected && wide
                            ? primary.withOpacity(0.08)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() {
                            _selectedCategoryId = c.id;
                            _narrowShowTypes = true;
                            _clearSearch();
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: selected && wide
                                      ? primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(13, 10, 4, 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.name.isEmpty ? '(no name)' : c.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: selected && wide
                                              ? primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        count == 1
                                            ? '1 document type'
                                            : '$count document types',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                _categoryMenu(c, i, cats.length),
                                if (!wide)
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade400),
                              ],
                            ),
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

  Widget _categoryMenu(CategoryModel c, int index, int total) {
    return PopupMenuButton<String>(
      tooltip: 'Category options',
      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            _editCategory(c);
            break;
          case 'up':
            _moveCategory(c, -1);
            break;
          case 'down':
            _moveCategory(c, 1);
            break;
          case 'delete':
            _deleteCategory(c);
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined, size: 20),
            title: Text('Rename / edit'),
          ),
        ),
        PopupMenuItem(
          value: 'up',
          enabled: index > 0,
          child: const ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.arrow_upward, size: 20),
            title: Text('Move up'),
          ),
        ),
        PopupMenuItem(
          value: 'down',
          enabled: index < total - 1,
          child: const ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.arrow_downward, size: 20),
            title: Text('Move down'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, size: 20),
            title: Text('Delete'),
          ),
        ),
      ],
    );
  }

  // ── Document types panel ───────────────────────────────────────────────────

  Widget _buildTypesPanel(bool wide) {
    final searching = _search.isNotEmpty;
    final category = _categoryById(_selectedCategoryId);

    List<DocumentTypeModel> rows;
    if (searching) {
      final ids = _packageCategories.map((c) => c.id).toSet();
      final q = _search.toLowerCase();
      rows = _types
          .where((t) => ids.contains(t.categoryId) && t.name.toLowerCase().contains(q))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      rows = category == null ? [] : _typesOf(category.id);
    }

    return Container(
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 4),
            child: Row(
              children: [
                if (!wide)
                  IconButton(
                    tooltip: 'Back to categories',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() {
                      _narrowShowTypes = false;
                      _clearSearch();
                    }),
                  )
                else
                  const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        searching
                            ? 'Search results in ${_packageLabel(_packageId)}'
                            : (category?.name ?? 'Select a category'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (!searching &&
                          category != null &&
                          category.description.isNotEmpty)
                        Text(
                          category.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                if (!searching && category != null)
                  IconButton(
                    tooltip: 'Edit category',
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: Colors.grey.shade600),
                    onPressed: () => _editCategory(category),
                  ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: _addType,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(wide ? 'Add document type' : 'Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search all document types in ${_packageLabel(_packageId)}',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon:
                    Icon(Icons.search, size: 20, color: Colors.grey.shade500),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(_clearSearch),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: rows.isEmpty
                ? (searching
                    ? _emptyState(
                        icon: Icons.search_off,
                        title: 'No document types match "$_search"',
                        message: 'Try a shorter search, or check another standard.',
                      )
                    : category == null
                        ? _emptyState(
                            icon: Icons.touch_app_outlined,
                            title: 'Select a category',
                            message:
                                'Choose a category on the left to see its document types.',
                          )
                        : _emptyState(
                            icon: Icons.description_outlined,
                            title: 'No document types in this category yet',
                            message:
                                'Add the documents companies must provide for "${category.name}".',
                            actionLabel: 'Add document type',
                            onAction: _addType,
                          ))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) => _typeRow(rows[i], searching),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _typeRow(DocumentTypeModel t, bool showCategory) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _editType(t),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name.isEmpty ? '(no name)' : t.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (showCategory)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _categoryById(t.categoryId)?.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _ruleChips(t),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: Colors.grey.shade600),
                onPressed: () => _editType(t),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Colors.grey.shade600),
                onPressed: () => _deleteType(t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The type's settings in plain words.
  List<Widget> _ruleChips(DocumentTypeModel t) {
    return [
      t.isUploadable
          ? _chip(Icons.upload_file, 'File upload')
          : _chip(Icons.edit_note, 'In-app form'),
      if (t.hasExpiryDate) _chip(Icons.event_outlined, 'Expires'),
      if (t.allowMultipleDocuments) _chip(Icons.library_add_outlined, 'Several allowed'),
      if (t.hasNotApplicableOption) _chip(Icons.do_not_disturb_alt, 'Can be N/A'),
      if (t.requiresSpecification) _chip(Icons.notes, 'Specification required'),
      if (t.hasReviewedDate) _chip(Icons.fact_check_outlined, 'Reviewed date'),
      if (t.requiresSignature)
        _chip(Icons.draw_outlined,
            t.signatureCount == 1 ? '1 signature' : '${t.signatureCount} signatures'),
    ];
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Help ───────────────────────────────────────────────────────────────────

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('How Category Management works',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HelpSection(
                        title: 'The three levels',
                        body:
                            '• Standard: SIZA/WIETA, GlobalG.A.P., IPW, Fairtrade or SIZA Environmental. Pick one with the buttons at the top.\n'
                            '• Category: a group of requirements inside that standard, e.g. "Health & Safety".\n'
                            '• Document type: one thing a company must provide, e.g. "First aid certificate".',
                      ),
                      _HelpSection(
                        title: 'Who sees it',
                        body:
                            'Everything on this page is shared. A document type you add appears in the '
                            'Compliance Tracker of every company that has that standard.\n\n'
                            '• Which standards a company has is set in Company Management.\n'
                            '• To switch a document type off for one company only, use Document Settings.',
                      ),
                      _HelpSection(
                        title: 'Adding a category',
                        body:
                            'Click "Add category", choose the standard, give it a clear name (you can start '
                            'it with a number, e.g. "3. Training") and an optional description. New categories '
                            'go to the bottom; use ⋮ → Move up / Move down to change the order.',
                      ),
                      _HelpSection(
                        title: 'Adding a document type',
                        body:
                            'Select a category and click "Add document type". Choose:\n'
                            '• File upload or In-app form: whether companies upload a file or fill in a form in the app.\n'
                            '• Expires: companies enter an expiry date; the document shows as expired after it and needs renewing.\n'
                            '• Several allowed: companies can upload more than one (e.g. one per worker).\n'
                            '• Can be N/A: companies may mark it "not applicable" to their farm.\n'
                            '• Signatures: how many people must sign it.',
                      ),
                      _HelpSection(
                        title: 'Editing and moving',
                        body:
                            'Click any document type to edit it. If you move it to another category, documents '
                            'companies already uploaded move with it. You can also move a whole category to '
                            'another standard from ⋮ → Rename / edit.',
                      ),
                      _HelpSection(
                        title: 'Deleting safely',
                        body:
                            '• A document type can only be deleted if no company has uploaded anything for it. '
                            'Otherwise, switch it off per company in Document Settings.\n'
                            '• A category can only be deleted once it has no document types.',
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(RouteConstants.overrid);
                      },
                      child: const Text('Open Document Settings'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final String body;
  const _HelpSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body,
              style: TextStyle(
                  fontSize: 13, height: 1.4, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

// ── Category dialog ──────────────────────────────────────────────────────────

class _CategoryDraft {
  final String name;
  final String description;
  final String packageId;
  _CategoryDraft(this.name, this.description, this.packageId);
}

class _CategoryDialog extends StatefulWidget {
  final String initialPackageId;
  final List<CategoryModel> existing;
  final CategoryModel? editing;

  const _CategoryDialog({
    required this.initialPackageId,
    required this.existing,
    this.editing,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.editing?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.editing?.description ?? '');
  late String _packageId = widget.initialPackageId;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CategoryDraft(_name.text.trim(), _description.text.trim(), _packageId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return _FormDialog(
      title: editing ? 'Edit category' : 'Add category',
      submitLabel: editing ? 'Save changes' : 'Add category',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _packageId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Standard',
                helperText: 'Companies on this standard will see the category.',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in AppConstants.auditPackages)
                  DropdownMenuItem(value: p.id, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() => _packageId = v ?? _packageId),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. 3. Training',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final name = (v ?? '').trim();
                if (name.isEmpty) return 'Enter a name';
                final clash = widget.existing.any((c) =>
                    c.id != widget.editing?.id &&
                    c.packageId == _packageId &&
                    c.name.trim().toLowerCase() == name.toLowerCase());
                if (clash) return 'This standard already has a category with this name';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What this category covers',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document type dialog ─────────────────────────────────────────────────────

class _DocTypeDraft {
  final String name;
  final String categoryId;
  final bool isUploadable;
  final bool hasExpiryDate;
  final bool allowMultipleDocuments;
  final bool hasNotApplicableOption;
  final bool requiresSignature;
  final int signatureCount;
  final bool requiresSpecification;
  final bool hasReviewedDate;

  _DocTypeDraft({
    required this.name,
    required this.categoryId,
    required this.isUploadable,
    required this.hasExpiryDate,
    required this.allowMultipleDocuments,
    required this.hasNotApplicableOption,
    required this.requiresSignature,
    required this.signatureCount,
    this.requiresSpecification = false,
    this.hasReviewedDate = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'categoryId': categoryId,
        'isUploadable': isUploadable,
        'hasExpiryDate': hasExpiryDate,
        'allowMultipleDocuments': allowMultipleDocuments,
        'hasNotApplicableOption': hasNotApplicableOption,
        'requiresSignature': requiresSignature,
        'signatureCount': requiresSignature ? signatureCount : 0,
        'requiresSpecification': requiresSpecification,
        'hasReviewedDate': hasReviewedDate,
      };
}

class _DocTypeDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<DocumentTypeModel> types;
  final String initialPackageId;
  final String? initialCategoryId;
  final DocumentTypeModel? editing;
  final String Function(String) packageLabel;

  const _DocTypeDialog({
    required this.categories,
    required this.types,
    required this.initialPackageId,
    required this.initialCategoryId,
    required this.packageLabel,
    this.editing,
  });

  @override
  State<_DocTypeDialog> createState() => _DocTypeDialogState();
}

class _DocTypeDialogState extends State<_DocTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.editing?.name ?? '');
  late String _packageId = widget.initialPackageId;
  String? _categoryId;
  late bool _isUploadable = widget.editing?.isUploadable ?? true;
  late bool _hasExpiry = widget.editing?.hasExpiryDate ?? false;
  late bool _multiple = widget.editing?.allowMultipleDocuments ?? false;
  late bool _canBeNA = widget.editing?.hasNotApplicableOption ?? false;
  late bool _signatures = widget.editing?.requiresSignature ?? false;
  late bool _needsSpec = widget.editing?.requiresSpecification ?? false;
  late bool _reviewed = widget.editing?.hasReviewedDate ?? false;
  late int _signatureCount = (widget.editing?.signatureCount ?? 0) > 0
      ? widget.editing!.signatureCount
      : 1;

  static const int _maxSignatures = 10;

  @override
  void initState() {
    super.initState();
    final cats = _categoriesOf(_packageId);
    _categoryId = cats.any((c) => c.id == widget.initialCategoryId)
        ? widget.initialCategoryId
        : (cats.isNotEmpty ? cats.first.id : null);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<CategoryModel> _categoriesOf(String packageId) =>
      widget.categories.where((c) => c.packageId == packageId).toList()
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DocTypeDraft(
        name: _name.text.trim(),
        categoryId: _categoryId!,
        isUploadable: _isUploadable,
        hasExpiryDate: _hasExpiry,
        allowMultipleDocuments: _multiple,
        hasNotApplicableOption: _canBeNA,
        requiresSignature: _signatures,
        signatureCount: _signatureCount,
        requiresSpecification: _needsSpec,
        hasReviewedDate: _reviewed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    final cats = _categoriesOf(_packageId);
    final primary = Theme.of(context).primaryColor;

    return _FormDialog(
      title: editing ? 'Edit document type' : 'Add document type',
      submitLabel: editing ? 'Save changes' : 'Add document type',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              autofocus: !editing,
              decoration: const InputDecoration(
                labelText: 'Document name',
                hintText: 'e.g. First aid certificate',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final name = (v ?? '').trim();
                if (name.isEmpty) return 'Enter a name';
                final clash = widget.types.any((t) =>
                    t.id != widget.editing?.id &&
                    t.categoryId == _categoryId &&
                    t.name.trim().toLowerCase() == name.toLowerCase());
                if (clash) return 'This category already has a document with this name';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _packageId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Standard',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final p in AppConstants.auditPackages)
                  DropdownMenuItem(value: p.id, child: Text(p.label)),
              ],
              onChanged: (v) => setState(() {
                _packageId = v ?? _packageId;
                final list = _categoriesOf(_packageId);
                _categoryId = list.isNotEmpty ? list.first.id : null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_packageId), // reset when the standard changes
              value: _categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                border: const OutlineInputBorder(),
                helperText: cats.isEmpty
                    ? '${widget.packageLabel(_packageId)} has no categories yet — add one first.'
                    : null,
              ),
              items: [
                for (final c in cats)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Choose a category' : null,
            ),
            const SizedBox(height: 20),
            const Text('How do companies provide it?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ChoiceCard(
              selected: _isUploadable,
              icon: Icons.upload_file,
              title: 'They upload a file',
              subtitle: 'A PDF, photo or Word document.',
              onTap: () => setState(() => _isUploadable = true),
            ),
            const SizedBox(height: 8),
            _ChoiceCard(
              selected: !_isUploadable,
              icon: Icons.edit_note,
              title: 'They fill in a form in the app',
              subtitle:
                  'The form\'s questions are set up separately in the form configuration.',
              onTap: () => setState(() => _isUploadable = false),
            ),
            const SizedBox(height: 20),
            const Text('Rules',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            _RuleSwitch(
              value: _hasExpiry,
              title: 'Has an expiry date',
              subtitle:
                  'Companies enter an expiry date. After it, the document shows as expired and needs renewing.',
              onChanged: (v) => setState(() => _hasExpiry = v),
            ),
            _RuleSwitch(
              value: _multiple,
              title: 'Allow more than one',
              subtitle: 'Companies can upload several, e.g. one per worker or per site.',
              onChanged: (v) => setState(() => _multiple = v),
            ),
            _RuleSwitch(
              value: _canBeNA,
              title: 'Can be marked "Not applicable"',
              subtitle: 'For requirements that don\'t apply to every farm.',
              onChanged: (v) => setState(() => _canBeNA = v),
            ),
            _RuleSwitch(
              value: _needsSpec,
              title: 'Specification required',
              subtitle:
                  'Companies must describe what the upload covers (e.g. site, period, worker group).',
              onChanged: (v) => setState(() => _needsSpec = v),
            ),
            _RuleSwitch(
              value: _reviewed,
              title: 'Has a "last reviewed" date',
              subtitle:
                  'For policies that don\'t expire but must be reviewed — companies enter the date it was last reviewed.',
              onChanged: (v) => setState(() => _reviewed = v),
            ),
            _RuleSwitch(
              value: _signatures,
              title: 'Needs signatures',
              subtitle: 'The document must be signed in the app before it counts.',
              onChanged: (v) => setState(() => _signatures = v),
            ),
            if (_signatures)
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 4),
                child: Row(
                  children: [
                    const Flexible(
                      child: Text('Number of signatures',
                          style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Fewer',
                      onPressed: _signatureCount > 1
                          ? () => setState(() => _signatureCount--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$_signatureCount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primary),
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      onPressed: _signatureCount < _maxSignatures
                          ? () => setState(() => _signatureCount++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Material(
      color: selected ? primary.withOpacity(0.06) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? primary : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? primary : Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? primary : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleSwitch extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _RuleSwitch({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Shared shell for the add/edit dialogs: title, scrollable body, actions.
/// The body scrolls, so the dialog never overflows on a short screen.
class _FormDialog extends StatelessWidget {
  final String title;
  final String submitLabel;
  final VoidCallback onSubmit;
  final Widget child;

  const _FormDialog({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: child,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: onSubmit,
                    child: Text(submitLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
