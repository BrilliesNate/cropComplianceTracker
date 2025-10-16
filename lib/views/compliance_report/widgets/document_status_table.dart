import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../models/category_model.dart';
import '../../../models/document_type_model.dart';
import '../../../models/document_model.dart';
import '../../../models/enums.dart';

class DocumentStatusTable extends StatelessWidget {
  const DocumentStatusTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categories = categoryProvider.categories;
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (categories.isEmpty) {
      return const Center(child: Text('No documents found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, categoryIndex) {
        final category = categories[categoryIndex];
        final docTypes = categoryProvider.getDocumentTypes(category.id);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047).withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category.name),
                      size: 16,
                      color: const Color(0xFF43A047),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${docTypes.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Document types under this category
              ...docTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final docType = entry.value;
                final documents = documentProvider.getDocumentsByType(docType.id);
                final document = documents.isNotEmpty ? documents.first : null;
                final isLast = index == docTypes.length - 1;

                return isMobile
                    ? _buildDocumentCardMobile(context, docType, document as DocumentModel?, isLast)
                    : _buildDocumentRowDesktop(context, docType, document as DocumentModel?, isLast);
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // DESKTOP VERSION - Keep existing horizontal layout
  Widget _buildDocumentRowDesktop(
      BuildContext context,
      DocumentTypeModel docType,
      DocumentModel? document,
      bool isLastInCategory,
      ) {
    final status = _getDocumentStatus(document);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastInCategory
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status['color'],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),

          // Document name
          Expanded(
            child: Text(
              docType.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),

          // Status badge - compact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status['label'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: status['color'],
              ),
            ),
          ),

          // Date (if available)
          if (document != null) ...[
            const SizedBox(width: 10),
            Text(
              DateFormat('MMM d').format(document.updatedAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MOBILE VERSION - New card-style vertical layout
  Widget _buildDocumentCardMobile(
      BuildContext context,
      DocumentTypeModel docType,
      DocumentModel? document,
      bool isLastInCategory,
      ) {
    final status = _getDocumentStatus(document);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLastInCategory
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document name with status dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: status['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  docType.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Status badge
          Row(
            children: [
              const Text(
                'Status: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status['label'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: status['color'],
                  ),
                ),
              ),
            ],
          ),

          // Date (if available)
          if (document != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Updated: ${DateFormat('MMM d, yyyy').format(document.updatedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],

          // Expiry date if available
          if (document?.expiryDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  document!.isExpired ? Icons.error_outline : Icons.event_available,
                  size: 12,
                  color: document.isExpired ? Colors.red.shade400 : Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Expires: ${DateFormat('MMM d, yyyy').format(document.expiryDate!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: document.isExpired ? Colors.red.shade600 : Colors.grey.shade600,
                    fontWeight: document.isExpired ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _getDocumentStatus(DocumentModel? document) {
    if (document == null) {
      return {
        'label': 'Not Uploaded',
        'color': Colors.grey.shade400,
      };
    }

    if (document.isNotApplicable) {
      return {
        'label': 'N/A',
        'color': Colors.grey.shade400,
      };
    }

    if (document.isExpired) {
      return {
        'label': 'Expired',
        'color': Colors.red.shade300,
      };
    }

    switch (document.status) {
      case DocumentStatus.APPROVED:
        return {
          'label': 'Approved',
          'color': const Color(0xFF43A047),
        };
      case DocumentStatus.PENDING:
        return {
          'label': 'Pending',
          'color': Colors.orange.shade500,
        };
      case DocumentStatus.REJECTED:
        return {
          'label': 'Rejected',
          'color': Colors.red.shade300,
        };
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('business')) return Icons.business;
    if (name.contains('management')) return Icons.settings;
    if (name.contains('employment')) return Icons.people;
    if (name.contains('child')) return Icons.child_care;
    if (name.contains('forced')) return Icons.security;
    if (name.contains('wages')) return Icons.payments;
    if (name.contains('association')) return Icons.groups;
    if (name.contains('training')) return Icons.school;
    if (name.contains('health')) return Icons.health_and_safety;
    if (name.contains('chemical')) return Icons.science;
    if (name.contains('service')) return Icons.handyman;
    if (name.contains('environmental')) return Icons.eco;
    return Icons.folder;
  }
}