import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../models/category_model.dart';
import '../../../models/document_model.dart';
import '../../../models/enums.dart';
import '../../shared/status_badge.dart';

class DocumentStatusTable extends StatelessWidget {
  const DocumentStatusTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    final categories = categoryProvider.categories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('No categories found'),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final category in categories) ...[
              _buildCategorySection(context, category, documentProvider),
              if (category != categories.last)
                const Divider(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      BuildContext context,
      CategoryModel category,
      DocumentProvider documentProvider,
      ) {
    final documents = documentProvider.getDocumentsByCategory(category.id);
    final totalDocuments = documents.length;

    // Calculate counts
    int approvedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;
    int expiredCount = 0;
    int notApplicableCount = 0;

    for (var doc in documents) {
      if (doc.isNotApplicable) {
        notApplicableCount++;
      } else if (doc.isExpired) {
        expiredCount++;
      } else if (doc.status == DocumentStatus.APPROVED) {
        approvedCount++;
      } else if (doc.status == DocumentStatus.PENDING) {
        pendingCount++;
      } else if (doc.status == DocumentStatus.REJECTED) {
        rejectedCount++;
      }
    }

    // Calculate compliance percentage
    double compliancePercentage = 0;
    if (totalDocuments > 0) {
      compliancePercentage = ((approvedCount + notApplicableCount) / totalDocuments) * 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          category.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                value: compliancePercentage / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForPercentage(compliancePercentage / 100),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Text(
                '${compliancePercentage.toStringAsFixed(0)}% Compliant',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            columns: const [
              DataColumn(label: Text('Document Type')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Last Updated')),
              DataColumn(label: Text('Expiry Date')),
              DataColumn(label: Text('Signatures')),
              DataColumn(label: Text('Comments')),
            ],
            rows: documents.map((document) {
              return _buildDocumentRow(context, document, documentProvider);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildStatusCount('Approved', approvedCount, Colors.green),
            _buildStatusCount('Pending', pendingCount, Colors.orange),
            _buildStatusCount('Rejected', rejectedCount, Colors.red),
            _buildStatusCount('Expired', expiredCount, Colors.red.shade700),
            _buildStatusCount('Not Applicable', notApplicableCount, Colors.grey),
          ],
        ),
      ],
    );
  }

  DataRow _buildDocumentRow(
      BuildContext context,
      DocumentModel document,
      DocumentProvider documentProvider,
      ) {
    // Get document type name
    final documentTypes = documentProvider.documentTypes;
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    final documentTypeName = documentType?.name ?? 'Unknown Document Type';

    return DataRow(
      cells: [
        DataCell(Text(documentTypeName)),
        DataCell(
          document.isNotApplicable
              ? const Text('Not Applicable')
              : StatusBadge(
            status: document.status,
            isExpired: document.isExpired,
          ),
        ),
        DataCell(Text(
          _formatDate(document.updatedAt),
        )),
        DataCell(Text(
          document.expiryDate != null
              ? _formatDate(document.expiryDate!)
              : 'N/A',
        )),
        DataCell(Text(
          '${document.signatures.length}/${documentType?.signatureCount ?? 0}',
        )),
        DataCell(Text(
          '${document.comments.length}',
        )),
      ],
    );
  }

  Widget _buildStatusCount(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}