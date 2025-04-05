import 'package:cropcompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/document_model.dart';
import '../../models/enums.dart';
import '../shared/custom_app_bar.dart';
import '../shared/loading_indicator.dart';
import '../shared/error_display.dart';
import '../shared/status_badge.dart';
import 'widgets/document_viewer.dart';
import 'widgets/signature_pad.dart';

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
    // Only set the future if it hasn't been set already
    if (_documentFuture == null) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      _documentFuture = documentProvider.getDocument(widget.documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);

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
            return const Center(
              child: Text('Document not found'),
            );
          }

          // Print debug info only once when document is first loaded
          if (!_hasLoggedDocumentInfo) {
            print("Document ID: ${document.id}");
            print("File URLs: ${document.fileUrls}");
            print("File URLs count: ${document.fileUrls.length}");
            _hasLoggedDocumentInfo = true;
          }

          // Get document type information - avoid repeated fetches
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _documentType?.name ?? 'Document',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            StatusBadge(
                              status: document.status,
                              isExpired: document.isExpired,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Created on',
                          DateFormat('MMM d, y').format(document.createdAt),
                        ),
                        if (document.expiryDate != null)
                          _buildInfoRow(
                            'Expires on',
                            DateFormat('MMM d, y').format(document.expiryDate!),
                            isError: document.isExpired,
                          ),
                        _buildInfoRow(
                          'Status',
                          document.status.name,
                        ),
                        if (document.isNotApplicable)
                          _buildInfoRow(
                            'Applicability',
                            'Marked as Not Applicable',
                          ),
                      ],
                    ),
                  ),
                ),

                // Document content
                if (!document.isNotApplicable) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Document Files',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (document.fileUrls.isNotEmpty)
                    DocumentViewer(document: document)
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No document files available (${document.fileUrls.length} files)',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'This document does not have any uploaded files. You can add files by updating the document.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                // Signature section
                if (_documentType?.requiresSignature == true &&
                    !document.isNotApplicable &&
                    document.status != DocumentStatus.REJECTED) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Signatures',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required signatures: ${_documentType?.signatureCount}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          if (document.signatures.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: document.signatures.length,
                              itemBuilder: (context, index) {
                                final signature = document.signatures[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(signature.userName),
                                  subtitle: Text(
                                    'Signed on ${DateFormat('MMM d, y').format(signature.signedAt)}',
                                  ),
                                  trailing: Image.network(
                                    signature.imageUrl,
                                    height: 40,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                                  ),
                                );
                              },
                            ),

                          if (document.signatures.length < (_documentType?.signatureCount ?? 0)) ...[
                            if (document.signatures.isNotEmpty)
                              const Divider(height: 32),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.draw),
                              label: const Text('Add Signature'),
                              onPressed: () {
                                _showSignatureDialog(context, document);
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ] else
                            const Text(
                              'All required signatures have been collected',
                              style: TextStyle(color: Colors.green),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Admin actions
                if (authProvider.isAdmin || authProvider.isAuditer) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Admin Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Comment',
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Approve'),
                                  onPressed: document.status == DocumentStatus.APPROVED
                                      ? null
                                      : () => _updateDocumentStatus(
                                    document,
                                    DocumentStatus.APPROVED,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Reject'),
                                  onPressed: document.status == DocumentStatus.REJECTED
                                      ? null
                                      : () => _updateDocumentStatus(
                                    document,
                                    DocumentStatus.REJECTED,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Comments section
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: document.comments.isNotEmpty
                        ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: document.comments.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final comment = document.comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: const Icon(Icons.person),
                          ),
                          title: Row(
                            children: [
                              Text(comment.userName),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, y').format(comment.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(comment.text),
                          ),
                          isThreeLine: true,
                        );
                      },
                    )
                        : const Center(
                      child: Text('No comments yet'),
                    ),
                  ),
                ),

                // Add comment section (for all users)
                if (!document.isNotApplicable) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Add Comment',
                              hintText: 'Type your comment here...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.send),
                            label: const Text('Submit Comment'),
                            onPressed: () => _addComment(document),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
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
              const Text(
                'Please sign below:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SignaturePad(
                onSave: (file) async {
                  Navigator.of(context).pop();

                  final documentProvider = Provider.of<DocumentProvider>(
                    context,
                    listen: false,
                  );
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

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
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to add signature'),
                          backgroundColor: Colors.red,
                        ),
                      );
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

  Future<void> _updateDocumentStatus(
      DocumentModel document,
      DocumentStatus status,
      ) async {
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update document status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addComment(DocumentModel document) async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final success = await documentProvider.addComment(
        document.id,
        _commentController.text,
        authProvider.currentUser!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _commentController.clear();
        setState(() {
          _documentFuture = null;
          _loadDocument();
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}