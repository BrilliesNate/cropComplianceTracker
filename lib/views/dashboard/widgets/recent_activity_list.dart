import 'package:cropcompliance/core/constants/route_constants.dart';
import 'package:cropcompliance/models/document_model.dart';
import 'package:cropcompliance/models/document_type_model.dart';
import 'package:cropcompliance/models/enums.dart';
import 'package:cropcompliance/providers/document_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


class RecentActivityList extends StatelessWidget {
  const RecentActivityList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);

    // Get recent documents (sorted by update date)
    final recentDocuments = List<DocumentModel>.from(documentProvider.documents)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Take only the first 10 documents
    final documents = recentDocuments.take(10).toList();

    if (documents.isEmpty) {
      return const Center(
        child: Text('No recent activity'),
      );
    }

    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, __) => const Divider(),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(document).withOpacity(0.1),
            child: Icon(
              _getStatusIcon(document),
              color: _getStatusColor(document),
            ),
          ),
          title: Text(
            _getDocumentTitle(document, documentProvider),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _getActivityDescription(document),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            DateFormat('MMM d, y').format(document.updatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: () {
            Navigator.of(context).pushNamed(
              RouteConstants.documentDetail,
              arguments: {'documentId': document.id},
            );
          },
        );
      },
    );
  }

  String _getDocumentTitle(DocumentModel document, DocumentProvider provider) {
    final documentTypes = provider.documentTypes;
    final documentType = documentTypes.firstWhere(
          (dt) => dt.id == document.documentTypeId,
      orElse: () => DocumentTypeModel(
        id: '',
        categoryId: '',
        name: 'Unknown Document Type',
        allowMultipleDocuments: false,
        isUploadable: false,
        hasExpiryDate: false,
        hasNotApplicableOption: false,
        requiresSignature: false,
        signatureCount: 0,
      ),
    );

    return documentType.name;
  }

  String _getActivityDescription(DocumentModel document) {
    if (document.isNotApplicable) {
      return 'Marked as Not Applicable';
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return 'Pending review';
      case DocumentStatus.APPROVED:
        return 'Approved on ${DateFormat('MMM d, y').format(document.updatedAt)}';
      case DocumentStatus.REJECTED:
        return 'Rejected - Requires attention';
      default:
        return '';
    }
  }

  IconData _getStatusIcon(DocumentModel document) {
    if (document.isExpired) {
      return Icons.warning;
    }

    if (document.isNotApplicable) {
      return Icons.not_interested;
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return Icons.hourglass_empty;
      case DocumentStatus.APPROVED:
        return Icons.check_circle;
      case DocumentStatus.REJECTED:
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(DocumentModel document) {
    if (document.isExpired) {
      return Colors.red;
    }

    if (document.isNotApplicable) {
      return Colors.grey;
    }

    switch (document.status) {
      case DocumentStatus.PENDING:
        return Colors.orange;
      case DocumentStatus.APPROVED:
        return Colors.green;
      case DocumentStatus.REJECTED:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}