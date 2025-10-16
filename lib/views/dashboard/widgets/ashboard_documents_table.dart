import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';

class DashboardDocumentsTable extends StatefulWidget {
  final DocumentProvider documentProvider;
  final String? selectedDocumentId;
  final Function(String?) onDocumentSelected;

  const DashboardDocumentsTable({
    Key? key,
    required this.documentProvider,
    required this.selectedDocumentId,
    required this.onDocumentSelected,
  }) : super(key: key);

  @override
  State<DashboardDocumentsTable> createState() => _DashboardDocumentsTableState();
}

class _DashboardDocumentsTableState extends State<DashboardDocumentsTable> {
  int _currentPage = 1;
  String _sortBy = 'updated'; // updated, status, expiry
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    // Check if mobile
    final isMobile = MediaQuery.of(context).size.width < 650;

    // Get and sort documents
    List<DocumentModel> documents = List.from(widget.documentProvider.documents.cast<DocumentModel>());

    // Apply sorting
    documents.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'status':
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case 'expiry':
          final aExpiry = a.expiryDate ?? DateTime(2100);
          final bExpiry = b.expiryDate ?? DateTime(2100);
          comparison = aExpiry.compareTo(bExpiry);
          break;
        case 'updated':
        default:
          comparison = a.updatedAt.compareTo(b.updatedAt);
      }
      return _sortAscending ? comparison : -comparison;
    });

    // Pagination
    const int itemsPerPage = 10; // Show more items (was 6)
    final int totalPages = documents.isEmpty ? 1 : (documents.length / itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * itemsPerPage;
    final int endIndex = startIndex + itemsPerPage > documents.length
        ? documents.length
        : startIndex + itemsPerPage;
    final currentPageDocuments = documents.isNotEmpty
        ? documents.sublist(startIndex, endIndex)
        : <DocumentModel>[];

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${documents.length} total',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Compact Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 1),
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text('Document Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildSortableHeader('Status', 'status'),
                  ),
                  // Hide "Updated" column on mobile
                  if (!isMobile)
                    Expanded(
                      flex: 2,
                      child: _buildSortableHeader('Updated', 'updated'),
                    ),
                  Expanded(
                    flex: 2,
                    child: _buildSortableHeader('Expires', 'expiry'),
                  ),
                ],
              ),
            ),
          ),

          // Table Body - shrinkwrap to actual content
          currentPageDocuments.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text('No documents found', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: currentPageDocuments.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final doc = currentPageDocuments[index];
              return _buildDocumentRow(context, doc, index, isMobile);
            },
          ),

          // Compact Pagination
          if (documents.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPaginationButton(
                        Icons.chevron_left,
                        _currentPage > 1,
                            () => setState(() => _currentPage--),
                      ),
                      const SizedBox(width: 4),
                      _buildPaginationButton(
                        Icons.chevron_right,
                        _currentPage < totalPages,
                            () => setState(() => _currentPage++),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String title, String sortKey) {
    final isActive = _sortBy == sortKey;

    return InkWell(
      onTap: () {
        setState(() {
          if (_sortBy == sortKey) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = sortKey;
            _sortAscending = false;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            isActive
                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[500],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, DocumentModel doc, int index, bool isMobile) {
    // Find the document type name
    final docType = widget.documentProvider.documentTypes
        .firstWhere((type) => type.id == doc.documentTypeId, orElse: () => throw Exception('Type not found'));
    final documentTypeName = docType.name;

    final isSelected = widget.selectedDocumentId == doc.id;

    // Check if document is expiring soon (within 30 days)
    final isExpiringSoon = doc.expiryDate != null &&
        doc.expiryDate!.difference(DateTime.now()).inDays <= 30 &&
        doc.expiryDate!.isAfter(DateTime.now());

    // Status widget
    Widget statusWidget;
    switch (doc.status) {
      case DocumentStatus.APPROVED:
        statusWidget = _buildCompactStatus(Colors.green, 'Approved');
        break;
      case DocumentStatus.PENDING:
        statusWidget = _buildCompactStatus(Colors.orange, 'Pending');
        break;
      case DocumentStatus.REJECTED:
        statusWidget = _buildCompactStatus(Colors.red, 'Rejected');
        break;
    }

    return InkWell(
      onTap: () => widget.onDocumentSelected(doc.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.05) : null,
          border: isSelected
              ? Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3))
              : null,
        ),
        child: Row(
          children: [
            // Document Type
            Expanded(
              flex: 4,
              child: Text(
                documentTypeName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: statusWidget,
            ),

            // Updated Date - HIDDEN ON MOBILE
            if (!isMobile)
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('MMM d, yy').format(doc.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),

            // Expiry Date
            Expanded(
              flex: 2,
              child: doc.expiryDate != null
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isExpiringSoon)
                    Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  if (isExpiringSoon) const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      DateFormat('MMM d, yy').format(doc.expiryDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: isExpiringSoon ? Colors.orange : Colors.grey[700],
                        fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
                  : Text('—', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatus(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationButton(IconData icon, bool enabled, VoidCallback onPressed) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: enabled ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey[400],
        ),
      ),
    );
  }
}