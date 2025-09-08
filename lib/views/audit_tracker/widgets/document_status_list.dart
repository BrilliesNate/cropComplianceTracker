

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/views/shared/status_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DocumentStatusList extends StatelessWidget {
  final String categoryId;

  const DocumentStatusList({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

    final documentTypes = categoryProvider.getDocumentTypes(categoryId);

    if (documentTypes.isEmpty) {
      return const Center(
        child: Text('No document types found for this category'),
      );
    }

    return ListView.builder(
      itemCount: documentTypes.length,
      itemBuilder: (context, index) {
        final documentType = documentTypes[index];
        final documents = documentProvider.getDocumentsByType(documentType.id);

        return _buildDocumentTypeCard(
          context,
          documentType,
          documents,
        );
      },
    );
  }

  Widget _buildDocumentTypeCard(
      BuildContext context,
      DocumentTypeModel documentType,
      List<DocumentModel> documents,
      ) {
    final hasDocuments = documents.isNotEmpty;
    final isNotApplicable = hasDocuments && documents.first.isNotApplicable;
    final status = hasDocuments ? documents.first.status : DocumentStatus.PENDING;
    final isExpired = hasDocuments && documents.first.isExpired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        documentType.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDocumentTypeDescription(documentType),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (hasDocuments && !isNotApplicable)
                  StatusBadge(
                    status: status,
                    isExpired: isExpired,
                  )
                else if (isNotApplicable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Not Applicable',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (documentType.isUploadable)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentUpload,
                          arguments: {
                            'categoryId': categoryId,
                            'documentTypeId': documentType.id,
                          },
                        );
                      },
                    ),
                  ),
                if (documentType.isUploadable && !documentType.isUploadable)
                  const SizedBox(width: 8),
                if (!documentType.isUploadable)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_document),
                      label: const Text('Fill Form'),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentForm,
                          arguments: {
                            'categoryId': categoryId,
                            'documentTypeId': documentType.id,
                          },
                        );
                      },
                    ),
                  ),
                if (hasDocuments)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          RouteConstants.documentDetail,
                          arguments: {'documentId': documents.first.id},
                        );
                      },
                      tooltip: 'View Document',
                    ),
                  ),
                if (documentType.hasNotApplicableOption)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.not_interested,
                        color: isNotApplicable ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        _showNotApplicableDialog(context, documentType);
                      },
                      tooltip: 'Mark as Not Applicable',
                    ),
                  ),
              ],
            ),
            if (hasDocuments && documents.first.isRejected && documents.first.comments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rejection Reason:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        documents.first.comments.first.text,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDocumentTypeDescription(DocumentTypeModel documentType) {
    List<String> descriptions = [];

    if (documentType.allowMultipleDocuments) {
      descriptions.add('Multiple documents allowed');
    }

    if (documentType.hasExpiryDate) {
      descriptions.add('Requires expiry date');
    }

    if (documentType.requiresSignature) {
      final count = documentType.signatureCount;
      descriptions.add('Requires $count signature${count > 1 ? 's' : ''}');
    }

    return descriptions.join(' • ');
  }

  void _showNotApplicableDialog(
      BuildContext context,
      DocumentTypeModel documentType,
      ) {

    print("Need to fix this as the authProvider.currentUser is apperintly flucking null");

    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: const Text('Mark as Not Applicable'),
    //     content: Text(
    //       'Are you sure you want to mark "${documentType.name}" as not applicable to your business?',
    //     ),
    //     actions: [
    //       TextButton(
    //         onPressed: () {
    //           Navigator.of(context).pop();
    //         },
    //         child: const Text('Cancel'),
    //       ),
    //       ElevatedButton(
    //         onPressed: () {
    //           final documentProvider = Provider.of<DocumentProvider>(
    //             context,
    //             listen: false,
    //           );
    //           final authProvider = Provider.of<AuthProvider>(
    //             context,
    //             listen: false,
    //           );
    //
    //           if (authProvider.currentUser != null) {
    //            var user = authProvider.currentUser;
    //             documentProvider.createDocument(
    //               user: user!,
    //               categoryId: categoryId,
    //               documentTypeId: documentType.id,
    //               files: [],
    //               isNotApplicable: true,
    //             );
    //           }
    //
    //           Navigator.of(context).pop();
    //         },
    //         child: const Text('Mark as Not Applicable'),
    //       ),
    //     ],
    //   ),
    // );
  }
}