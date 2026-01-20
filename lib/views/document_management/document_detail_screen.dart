import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_model.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/models/enums.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/category_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:cropCompliance/views/document_management/widgets/document_viewer.dart';
import 'package:cropCompliance/views/document_management/widgets/signature_pad.dart';
import 'package:cropCompliance/views/shared/custom_app_bar.dart';
import 'package:cropCompliance/views/shared/error_display.dart';
import 'package:cropCompliance/views/shared/loading_indicator.dart';
import 'package:cropCompliance/views/shared/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({
    Key? key,
    required this.documentId,
  }) : super(key: key);

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Future<DocumentModel?>? _documentFuture;
  TextEditingController _commentController = TextEditingController();
  DocumentTypeModel? _documentType;
  bool _hasLoggedDocumentInfo = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadDocument() {
    if (_documentFuture == null) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      _documentFuture = documentProvider.getDocument(widget.documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final isAdmin = authProvider.currentUser?.role == UserRole.ADMIN;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Document Details',
        showBackButton: true,
      ),
      body: FutureBuilder<DocumentModel?>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading document...');
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              error: 'Error loading document: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _documentFuture = null;
                  _loadDocument();
                });
              },
            );
          }

          final document = snapshot.data;
          if (document == null) {
            return const Center(child: Text('Document not found'));
          }

          if (!_hasLoggedDocumentInfo) {
            print("DEBUG DocumentDetailScreen: Document ID: ${document.id}");
            print("DEBUG DocumentDetailScreen: File URLs count: ${document.fileUrls.length}");
            print("DEBUG DocumentDetailScreen: File URLs: ${document.fileUrls}");
            print("DEBUG DocumentDetailScreen: Status: ${document.status}");
            print("DEBUG DocumentDetailScreen: isNotApplicable: ${document.isNotApplicable}");
            _hasLoggedDocumentInfo = true;
          }

          if (_documentType == null) {
            categoryProvider.fetchDocumentTypes(document.categoryId);
            final documentTypes = categoryProvider.getDocumentTypes(document.categoryId);
            try {
              _documentType = documentTypes.firstWhere((dt) => dt.id == document.documentTypeId) as DocumentTypeModel?;
            } catch (_) {
              _documentType = null;
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // STATUS BANNER - Shows current state clearly
                _buildStatusBanner(document, isAdmin),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DOCUMENT INFO CARD
                      _buildDocumentInfoCard(document),

                      const SizedBox(height: 16),

                      // ACTION BUTTONS - Prominent and clear
                      _buildActionButtons(document, isAdmin, authProvider),

                      const SizedBox(height: 24),

                      // DOCUMENT FILES SECTION
                      if (!document.isNotApplicable) _buildFilesSection(document),

                      const SizedBox(height: 24),

                      // COMMENTS/HISTORY SECTION
                      _buildCommentsSection(document, isAdmin),

                      const SizedBox(height: 24),

                      // ADMIN REVIEW SECTION (only for admins)
                      if (isAdmin) _buildAdminReviewSection(document),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(DocumentModel document, bool isAdmin) {
    Color bannerColor;
    IconData bannerIcon;
    String bannerText;
    String bannerSubtext;

    if (document.isExpired) {
      bannerColor = Colors.red.shade700;
      bannerIcon = Icons.warning_amber_rounded;
      bannerText = 'DOCUMENT EXPIRED';
      bannerSubtext = 'This document has expired and needs to be updated';
    } else if (document.status == DocumentStatus.REJECTED) {
      bannerColor = Colors.orange.shade700;
      bannerIcon = Icons.cancel_outlined;
      bannerText = 'DOCUMENT REJECTED';
      bannerSubtext = 'Please review the feedback and resubmit';
    } else if (document.status == DocumentStatus.PENDING) {
      bannerColor = Colors.blue.shade700;
      bannerIcon = Icons.hourglass_empty_rounded;
      bannerText = 'PENDING REVIEW';
      bannerSubtext = isAdmin ? 'Awaiting your review' : 'Awaiting admin review';
    } else if (document.status == DocumentStatus.APPROVED) {
      bannerColor = Colors.green.shade700;
      bannerIcon = Icons.check_circle_outline;
      bannerText = 'APPROVED';
      bannerSubtext = document.expiryDate != null
          ? 'Valid until ${DateFormat('MMM d, y').format(document.expiryDate!)}'
          : 'Document is approved';
    } else {
      bannerColor = Colors.grey.shade700;
      bannerIcon = Icons.info_outline;
      bannerText = 'UNKNOWN STATUS';
      bannerSubtext = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bannerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bannerText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bannerSubtext,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentInfoCard(DocumentModel document) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _documentType?.name ?? 'Document',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Created',
                DateFormat('MMM d, y').format(document.createdAt)),
            if (document.expiryDate != null)
              _buildInfoRow(
                Icons.event_busy,
                'Expires',
                DateFormat('MMM d, y').format(document.expiryDate!),
                isError: document.isExpired,
              ),
            _buildInfoRow(Icons.update, 'Last Updated',
                DateFormat('MMM d, y').format(document.updatedAt)),
            if (document.specification != null && document.specification!.isNotEmpty)
              _buildInfoRow(Icons.description, 'Specification',
                  document.specification!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isError ? Colors.red : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isError ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DocumentModel document, bool isAdmin, AuthProvider authProvider) {
    final bool needsAction = document.isExpired || document.status == DocumentStatus.REJECTED;
    final bool canResubmit = needsAction && !isAdmin;
    final bool allowsMultiple = _documentType?.allowMultipleDocuments ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // PRIMARY UPLOAD/UPDATE BUTTON - Always visible
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed(
              RouteConstants.documentUpload,
              arguments: {
                'categoryId': document.categoryId,
                'documentTypeId': document.documentTypeId,
                'existingDocumentId': document.id, // Pass existing ID to update/replace
              },
            );
          },
          icon: const Icon(Icons.upload_file, size: 20),
          label: Text(
            needsAction
                ? 'UPLOAD NEW DOCUMENT (REPLACE)'
                : 'UPLOAD NEW VERSION',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: needsAction ? Colors.red.shade600 : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // ADD ANOTHER DOCUMENT BUTTON - Only if multiple documents allowed
        if (allowsMultiple && !needsAction) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                RouteConstants.documentUpload,
                arguments: {
                  'categoryId': document.categoryId,
                  'documentTypeId': document.documentTypeId,
                  // NO existingDocumentId = creates new document
                },
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('ADD ANOTHER DOCUMENT'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],

        // SIGNATURE BUTTON
        if (_documentType?.requiresSignature == true &&
            document.signatures.length < (_documentType?.signatureCount ?? 0)) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showSignatureDialog(context, document),
            icon: const Icon(Icons.draw, size: 20),
            label: const Text('ADD SIGNATURE'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilesSection(DocumentModel document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_open, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Document Files',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (document.fileUrls.isNotEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DocumentViewer(document: document),
            ),
          )
        else
          Card(
            elevation: 1,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No files uploaded yet',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentsSection(DocumentModel document, bool isAdmin) {
    final hasComments = document.comments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.comment, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Comments & History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (hasComments)
          ...document.comments.map((comment) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          comment.userName[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, y â€¢ h:mm a').format(comment.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    comment.text,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          )).toList()
        else
          Card(
            elevation: 1,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No comments yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdminReviewSection(DocumentModel document) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Admin Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // COMMENT INPUT
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add a comment (required for rejection)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),

            // ADMIN ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: document.status == DocumentStatus.APPROVED
                        ? null
                        : () => _updateDocumentStatus(document, DocumentStatus.APPROVED),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('APPROVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: document.status == DocumentStatus.REJECTED
                        ? null
                        : () => _updateDocumentStatus(document, DocumentStatus.REJECTED),
                    icon: const Icon(Icons.cancel),
                    label: const Text('REJECT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSignatureDialog(BuildContext context, DocumentModel document) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Your Signature',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SignaturePad(
                onSave: (file) async {
                  Navigator.of(context).pop();
                  final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);

                  if (authProvider.currentUser != null) {
                    final success = await documentProvider.addSignature(
                      document.id,
                      file,
                      authProvider.currentUser!,
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signature added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {
                        _documentFuture = null;
                        _loadDocument();
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDocumentStatus(DocumentModel document, DocumentStatus status) async {
    if (_commentController.text.isEmpty && status == DocumentStatus.REJECTED) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final success = await documentProvider.updateDocumentStatus(
        document.id,
        status,
        _commentController.text.isNotEmpty ? _commentController.text : null,
        authProvider.currentUser!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document ${status == DocumentStatus.APPROVED ? 'approved' : 'rejected'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        setState(() {
          _documentFuture = null;
          _loadDocument();
        });
      }
    }
  }
}