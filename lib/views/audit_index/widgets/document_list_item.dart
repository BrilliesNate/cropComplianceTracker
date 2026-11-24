import 'package:cropCompliance/core/offline/pending_files_widgets.dart';
import 'package:cropCompliance/models/category_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/document_model.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../shared/status_badge.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class DocumentListItem extends StatelessWidget {
  final DocumentModel document;
  final DocumentProvider documentProvider;
  final CategoryProvider categoryProvider;

  const DocumentListItem({
    Key? key,
    required this.document,
    required this.documentProvider,
    required this.categoryProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get category and document type names
    final categories = categoryProvider.categories;
    CategoryModel? category;
    try {
      category = categories.firstWhere((c) => c.id == document.categoryId) as CategoryModel?;
    } catch (_) {
      category = null;
    }

    final documentTypes = documentProvider.documentTypes;
    DocumentTypeModel? documentType;
    try {
      documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
    } catch (_) {
      documentType = null;
    }

    final categoryName = category?.name ?? context.l10n.unknownCategory;
    final documentTypeName = documentType?.name ?? context.l10n.unknownDocumentType;

    return Card(
        margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
    ),
    child: InkWell(
    onTap: () {
    Navigator.of(context).pushNamed(
    RouteConstants.documentDetail,
    arguments: {'documentId': document.id},
    );
    },
    child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        documentTypeName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        context.l10n.categoryWithName(categoryName),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
    ),
    ),
      if (document.isSuperseded) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueGrey.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history, size: 12, color: Colors.blueGrey.shade400),
            const SizedBox(width: 4),
            Text(context.l10n.previousVersion,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade500)),
          ]),
        ),
        const SizedBox(width: 8),
      ],
      StatusBadge(
        status: document.status,
        isExpired: document.isExpired,
      ),
    ],
    ),
      const Divider(height: 24),
      Row(
        children: [
          _buildInfoItem(
            context,
            context.l10n.lastUpdated,
            DateFormat('MMM d, y').format(document.updatedAt),
            Icons.update,
          ),
          const SizedBox(width: 16),
          if (document.effectiveExpiryDate != null)
            _buildInfoItem(
              context,
              context.l10n.colExpires,
              DateFormat('MMM d, y').format(document.effectiveExpiryDate!),
              Icons.event,
              isExpired: document.isExpired,
            ),
          const Spacer(),
          if (document.hasPendingFiles) ...[
            PendingUploadChip(document: document),
            const SizedBox(width: 12),
          ],
          if (document.fileUrls.isNotEmpty)
            _buildInfoItem(
              context,
              context.l10n.files,
              document.fileUrls.length.toString(),
              Icons.attach_file,
            ),
          if (document.fileUrls.isNotEmpty && document.signatures.isNotEmpty)
            const SizedBox(width: 16),
          if (document.signatures.isNotEmpty)
            _buildInfoItem(
              context,
              context.l10n.signatures,
              document.signatures.length.toString(),
              Icons.draw,
            ),
          if ((document.fileUrls.isNotEmpty || document.signatures.isNotEmpty) && document.comments.isNotEmpty)
            const SizedBox(width: 16),
          if (document.comments.isNotEmpty)
            _buildInfoItem(
              context,
              context.l10n.comments,
              document.comments.length.toString(),
              Icons.comment,
            ),
        ],
      ),
      if (document.comments.isNotEmpty && document.isRejected) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.rejectionComment,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                document.comments.first.text,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
    ),
    ),
    ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context,
      String label,
      String value,
      IconData icon, {
        bool isExpired = false,
      }) {
    final textColor = isExpired ? Colors.red : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: textColor ?? Colors.grey,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}