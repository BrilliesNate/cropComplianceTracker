import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';

class DashboardCommentsCard extends StatelessWidget {
  final String? selectedDocumentId;
  final DocumentProvider documentProvider;

  const DashboardCommentsCard({
    Key? key,
    required this.selectedDocumentId,
    required this.documentProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if we have a selected document
    DocumentModel? selectedDocument;

    if (selectedDocumentId != null) {
      // Try to find the selected document in the list
      try {
        selectedDocument = documentProvider.documents
            .firstWhere((doc) => doc.id == selectedDocumentId) as DocumentModel?;
      } catch (_) {
        // Document not found, ignore
      }
    }

    // If no document is selected or it doesn't have comments or isn't rejected,
    // find the latest rejected document with comments
    if (selectedDocument == null ||
        !selectedDocument.isRejected ||
        selectedDocument.comments.isEmpty) {

      // Find latest rejected document with comments
      final rejectedDocsWithComments = documentProvider.documents
          .where((doc) => doc.isRejected && doc.comments.isNotEmpty)
          .toList();

      if (rejectedDocsWithComments.isNotEmpty) {
        rejectedDocsWithComments.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        selectedDocument = rejectedDocsWithComments.first as DocumentModel?;
      }
    }

    // If no selected or rejected documents with comments, show placeholder
    if (selectedDocument == null || !selectedDocument.isRejected || selectedDocument.comments.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: ThemeConstants.cardColors,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // FIXED: Let content size itself
            children: [
              const Text(
                'Document Comment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              // FIXED: Removed Expanded, use Container with fixed height instead
              Container(
                height: 200, // Give it a reasonable fixed height
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No rejected documents with comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All documents are in good standing',
                        style: TextStyle(color: Colors.grey),
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

    // Get the document type name
    String documentTypeName = 'Unknown Document';
    try {
      final docType = documentProvider.documentTypes
          .firstWhere((dt) => dt.id == selectedDocument?.documentTypeId);
      documentTypeName = docType.name;
    } catch (_) {
      // Keep default name if not found
    }

    // Get the latest comment (should be first in the list, but we'll sort to be sure)
    final comments = selectedDocument.comments..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latestComment = comments.first;

    // Calculate priority stars (based on comment text length or other factors)
    int priorityLevel = min(5, max(1, (latestComment.text.length / 50).ceil()));
    String priorityStars = '★' * priorityLevel + '☆' * (5 - priorityLevel);

    // Format date and time
    String formattedDate = DateFormat('d MMMM yyyy / HH:mm').format(latestComment.createdAt);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // FIXED: Let content size itself
          children: [
            // Compact Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Document Comment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Compact status indicator (dot + text)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Rejected',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 12),

            // Compact Comment content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Document name
                Text(
                  documentTypeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Date - removed priority stars (not useful info)
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // Comment text with max height
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      latestComment.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Warning message - more subtle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Action required: Update and resubmit',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Compact Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RouteConstants.documentUpload,
                        arguments: {
                          'categoryId': selectedDocument?.categoryId,
                          'documentTypeId': selectedDocument?.documentTypeId,
                          'existingDocumentId': selectedDocument?.id,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Resubmit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RouteConstants.documentDetail,
                        arguments: {'documentId': selectedDocument?.id},
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}