import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';

class DocumentTypesTable extends StatefulWidget {
  final List<DocumentTypeModel> documentTypes;
  final List<dynamic> categories;
  final String? categoryFilter;
  final Function(String?) onCategoryFilterChanged;
  final Function(DocumentTypeModel) onEdit;
  final Function(String) onDelete;
  final Function(DocumentTypeModel, Map<String, dynamic>) onQuickUpdate;

  const DocumentTypesTable({
    Key? key,
    required this.documentTypes,
    required this.categories,
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickUpdate,
  }) : super(key: key);

  @override
  State<DocumentTypesTable> createState() => _DocumentTypesTableState();
}

class _DocumentTypesTableState extends State<DocumentTypesTable> {
  final Set<String> _updatingItems = {};

  // Pagination
  static const int _itemsPerPage = 25;
  int _currentPage = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter and paginate document types
  List<DocumentTypeModel> get _filteredDocTypes {
    var filtered = widget.documentTypes;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((dt) =>
          dt.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  List<DocumentTypeModel> get _paginatedDocTypes {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredDocTypes.length);

    if (startIndex >= _filteredDocTypes.length) {
      return [];
    }

    return _filteredDocTypes.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredDocTypes.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 900;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Responsive layout
            _buildHeader(isNarrow),

            const SizedBox(height: 12),

            // Search and pagination info
            _buildSearchAndInfo(),

            const SizedBox(height: 12),

            // Table with fixed height for performance
            Container(
              height: 500, // Fixed height for virtual scrolling
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // Header row
                  _buildTableHeader(isNarrow),

                  // Data rows - Using ListView.builder for performance
                  Expanded(
                    child: _paginatedDocTypes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      itemCount: _paginatedDocTypes.length,
                      itemBuilder: (context, index) {
                        final docType = _paginatedDocTypes[index];
                        final globalIndex = _currentPage * _itemsPerPage + index;
                        return _buildTableRow(docType, globalIndex, isNarrow);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Pagination controls
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    if (isNarrow) {
      // Stack layout for narrow screens
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Document Types',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category filter dropdown - full width on narrow
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            value: widget.categoryFilter,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...widget.categories.map((category) {
                return DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _currentPage = 0);
              widget.onCategoryFilterChanged(value);
            },
          ),
        ],
      );
    }

    // Row layout for wide screens
    return Row(
      children: [
        Icon(Icons.table_chart, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        const Text(
          'Document Types Management',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        // Category filter dropdown - constrained width
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, minWidth: 150),
          child: DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            value: widget.categoryFilter,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Categories'),
              ),
              ...widget.categories.map((category) {
                return DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              setState(() => _currentPage = 0);
              widget.onCategoryFilterChanged(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndInfo() {
    return Row(
      children: [
        // Search box
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search document types...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Count info
        Text(
          '${_filteredDocTypes.length} items',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Document Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          if (!isNarrow) ...[
            Expanded(
              flex: 2,
              child: Text(
                'Category',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              ),
            ),
            _headerCell('Multi', 50),
            _headerCell('Upload', 50),
            _headerCell('Expiry', 50),
            _headerCell('N/A', 50),
            _headerCell('Sig', 50),
          ],
          SizedBox(
            width: 70,
            child: Text(
              'Actions',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(DocumentTypeModel docType, int index, bool isNarrow) {
    final categoryName = _getCategoryName(docType.categoryId);
    final isUpdating = _updatingItems.contains(docType.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Document Type Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isNarrow)
                  Text(
                    categoryName,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          if (!isNarrow) ...[
            // Category
            Expanded(
              flex: 2,
              child: Text(
                categoryName,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Toggle switches - compact
            _buildToggleCell(docType.allowMultipleDocuments, isUpdating,
                    (v) => _updateProperty(docType, {'allowMultipleDocuments': v})),
            _buildToggleCell(docType.isUploadable, isUpdating,
                    (v) => _updateProperty(docType, {'isUploadable': v})),
            _buildToggleCell(docType.hasExpiryDate, isUpdating,
                    (v) => _updateProperty(docType, {'hasExpiryDate': v})),
            _buildToggleCell(docType.hasNotApplicableOption, isUpdating,
                    (v) => _updateProperty(docType, {'hasNotApplicableOption': v})),

            // Signatures
            SizedBox(
              width: 50,
              child: Center(
                child: docType.requiresSignature
                    ? GestureDetector(
                  onTap: () => _showQuickSignatureEdit(docType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '${docType.signatureCount}',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
                    : _buildMiniToggle(false, isUpdating, (v) => _updateProperty(docType, {
                  'requiresSignature': v,
                  'signatureCount': v ? 1 : 0,
                })),
              ),
            ),
          ],

          // Actions
          SizedBox(
            width: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(Icons.edit_outlined, Colors.blue.shade600, () => widget.onEdit(docType)),
                _actionButton(Icons.delete_outline, Colors.red.shade600, () => widget.onDelete(docType.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCell(bool value, bool isUpdating, Function(bool) onChanged) {
    return SizedBox(
      width: 50,
      child: Center(
        child: isUpdating
            ? SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
        )
            : _buildMiniToggle(value, isUpdating, onChanged),
      ),
    );
  }

  Widget _buildMiniToggle(bool value, bool isUpdating, Function(bool) onChanged) {
    return Transform.scale(
      scale: 0.7,
      child: Switch(
        value: value,
        onChanged: isUpdating ? null : onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      color: color,
      splashRadius: 16,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No document types match "$_searchQuery"'
                : 'No document types found',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage = 0)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 0
              ? () => setState(() => _currentPage--)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          'Page ${_currentPage + 1} of $_totalPages',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: _currentPage < _totalPages - 1
              ? () => setState(() => _currentPage = _totalPages - 1)
              : null,
        ),
      ],
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      final category = widget.categories.firstWhere((c) => c.id == categoryId);
      return category.name;
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _updateProperty(DocumentTypeModel docType, Map<String, dynamic> updates) async {
    setState(() {
      _updatingItems.add(docType.id);
    });

    try {
      await widget.onQuickUpdate(docType, updates);
    } finally {
      if (mounted) {
        setState(() {
          _updatingItems.remove(docType.id);
        });
      }
    }
  }

  void _showQuickSignatureEdit(DocumentTypeModel docType) {
    final controller = TextEditingController(text: docType.signatureCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        title: const Text('Signatures Required', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 200,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Count',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            onFieldSubmitted: (value) {
              final count = int.tryParse(value) ?? 1;
              if (count > 0) {
                Navigator.of(context).pop();
                _updateProperty(docType, {'signatureCount': count});
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text) ?? 1;
              if (count > 0) {
                Navigator.of(context).pop();
                _updateProperty(docType, {'signatureCount': count});
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}