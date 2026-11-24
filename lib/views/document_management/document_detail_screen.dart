import 'package:cropCompliance/core/offline/pending_files_widgets.dart';
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
import 'package:cropCompliance/providers/locale_provider.dart';

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

  // NEW: Controllers for admin editable fields
  TextEditingController _specificationController = TextEditingController();
  DateTime? _selectedExpiryDate;
  bool _adminFieldsInitialized = false;

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
    _specificationController.dispose();
    super.dispose();
  }

  void _loadDocument() {
    if (_documentFuture == null) {
      final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
      _documentFuture = documentProvider.getDocument(widget.documentId);
    }
  }

  // NEW: Initialize admin editable fields with document values
  void _initializeAdminFields(DocumentModel document) {
    if (!_adminFieldsInitialized) {
      _specificationController.text = document.specification ?? '';
      _selectedExpiryDate = document.expiryDate;
      _adminFieldsInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final isAdmin = authProvider.currentUser?.role == UserRole.ADMIN;

    return Scaffold(
      appBar: CustomAppBar(
        title: context.l10n.docDetailsTitle,
        showBackButton: true,
      ),
      body: FutureBuilder<DocumentModel?>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingIndicator(message: context.l10n.docLoading);
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              error: context.l10n.docLoadError('${snapshot.error}'),
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
            return Center(
              child: Text(authProvider.isAuditer
                  ? context.l10n.docNotAvailable
                  : context.l10n.docNotFound),
            );
          }

          // Initialize admin fields when document loads
          if (isAdmin) {
            _initializeAdminFields(document);
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
                      // (auditors are read-only: no uploading, signing or resubmitting)
                      if (!authProvider.isAuditer) ...[
                        _buildActionButtons(document, isAdmin, authProvider),
                        const SizedBox(height: 24),
                      ],

                      // DOCUMENT FILES SECTION
                      if (!document.isNotApplicable) _buildFilesSection(document),

                      const SizedBox(height: 24),

                      // COMMENTS/HISTORY SECTION
                      // (internal review conversation — not shown to auditors)
                      if (!authProvider.isAuditer) ...[
                        _buildCommentsSection(document, isAdmin),
                        const SizedBox(height: 24),
                      ],

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
      bannerText = context.l10n.bannerExpired;
      bannerSubtext = context.l10n.bannerExpiredSub;
    } else if (document.status == DocumentStatus.REJECTED) {
      bannerColor = Colors.orange.shade700;
      bannerIcon = Icons.cancel_outlined;
      bannerText = context.l10n.bannerRejected;
      bannerSubtext = context.l10n.bannerRejectedSub;
    } else if (document.status == DocumentStatus.PENDING) {
      bannerColor = Colors.blue.shade700;
      bannerIcon = Icons.hourglass_empty_rounded;
      bannerText = context.l10n.bannerPending;
      bannerSubtext = isAdmin ? context.l10n.bannerAwaitingYou : context.l10n.bannerAwaitingAdmin;
    } else if (document.status == DocumentStatus.APPROVED) {
      bannerColor = Colors.green.shade700;
      bannerIcon = Icons.check_circle_outline;
      bannerText = context.l10n.bannerApprovedCaps;
      bannerSubtext = document.effectiveExpiryDate != null
          ? context.l10n.bannerValidUntil(DateFormat('MMM d, y').format(document.effectiveExpiryDate!))
          : context.l10n.bannerApproved;
    } else {
      bannerColor = Colors.grey.shade700;
      bannerIcon = Icons.info_outline;
      bannerText = context.l10n.bannerUnknown;
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
                  style: const TextStyle(
                    color: Colors.white70,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  context.l10n.docInformation,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(context.l10n.colDocumentType, _documentType?.name ?? context.l10n.unknown),
            _buildInfoRow(context.l10n.created, DateFormat('MMM d, y • h:mm a').format(document.createdAt)),
            _buildInfoRow(context.l10n.lastUpdated, DateFormat('MMM d, y • h:mm a').format(document.updatedAt)),
            if (document.effectiveExpiryDate != null)
              _buildInfoRow(
                context.l10n.expiryDateTitle,
                DateFormat('MMM d, y').format(document.effectiveExpiryDate!),
                valueColor: document.isExpired ? Colors.red : null,
              ),
            if (document.specification != null && document.specification!.isNotEmpty)
              _buildInfoRow(context.l10n.specification, document.specification!),
            _buildInfoRow(
              context.l10n.colStatus,
              document.status.toString().split('.').last,
              valueWidget: StatusBadge(status: document.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ?? Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DocumentModel document, bool isAdmin, AuthProvider authProvider) {
    // "Expiring soon" = has an expiry within 30 days and not yet expired, so
    // users can proactively upload a new version instead of waiting for expiry.
    final expiringSoon = document.effectiveExpiryDate != null &&
        !document.isExpired &&
        document.effectiveExpiryDate!
            .isBefore(DateTime.now().add(const Duration(days: 30)));

    // Only hide actions for approved docs that are NOT expired and NOT expiring
    // soon (and viewer isn't an admin).
    if (document.status == DocumentStatus.APPROVED &&
        !document.isExpired &&
        !expiringSoon &&
        !isAdmin) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  context.l10n.actions,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Upload-new-version for rejected, expired, OR expiring-soon docs
            if (document.isRejected || document.isExpired || expiringSoon)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentUpload,
                      arguments: {
                        'categoryId': document.categoryId,
                        'documentTypeId': document.documentTypeId,
                        'existingDocumentId': document.id,
                      },
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(document.isRejected
                      ? context.l10n.resubmitDocCaps
                      : context.l10n.uploadNewVersionCaps),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            // Sign button if signatures required and not complete
            if (_documentType != null &&
                _documentType!.requiresSignature &&
                document.signatures.length < _documentType!.signatureCount &&
                document.status != DocumentStatus.REJECTED) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSignatureDialog(context, document),
                  icon: const Icon(Icons.draw),
                  label: Text(
                    context.l10n.addSignatureCaps(document.signatures.length, _documentType!.signatureCount),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection(DocumentModel document) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open),
                const SizedBox(width: 8),
                Text(
                  context.l10n.docFilesCount(document.fileUrls.length + document.pendingFiles.length),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Files saved offline that are still waiting to upload.
            PendingFilesPanel(document: document),

            if (document.fileUrls.isEmpty && document.hasPendingFiles)
              const SizedBox.shrink()
            else if (document.fileUrls.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noFilesUploaded,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
            // Use DocumentViewer widget which handles file viewing internally
              DocumentViewer(document: document),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(DocumentModel document, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment),
            const SizedBox(width: 8),
            Text(
              context.l10n.commentsHistoryCount(document.comments.length),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (document.comments.isNotEmpty)
          ...document.comments.reversed.map((comment) => Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                          comment.userName.substring(0, 1).toUpperCase(),
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
                              DateFormat('MMM d, y • h:mm a').format(comment.createdAt),
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
                  context.l10n.noCommentsYet,
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
                Text(
                  context.l10n.adminReview,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // NEW: SPECIFICATION INPUT
            TextField(
              controller: _specificationController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.specification,
                hintText: context.l10n.editSpecHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // EXPIRY DATE PICKER — only for document types that use an expiry
            // date. A date sitting on a type that doesn't use one (stray data)
            // is still shown, with a note, so an admin can clear it.
            if (_showsExpiryField) ...[
            if (_documentType != null && !_documentType!.hasExpiryDate)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.strayExpiryNote,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: () => _selectExpiryDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.expiryDateTitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _selectedExpiryDate != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedExpiryDate = null;
                      });
                    },
                  )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedExpiryDate != null
                          ? DateFormat('MMM d, yyyy').format(_selectedExpiryDate!)
                          : context.l10n.selectExpiryOptional,
                      style: TextStyle(
                        color: _selectedExpiryDate != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (_selectedExpiryDate == null)
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ],

            // COMMENT INPUT
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.comment,
                hintText: context.l10n.commentHintReject,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.comment_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Info text about what will be updated
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.reviewSaveNote,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
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

  /// Whether the admin review panel should offer an expiry date: for types that
  /// use one (or when the type isn't known yet), or whenever a date is already
  /// set — so a stray date on a no-expiry type can be seen and cleared.
  bool get _showsExpiryField =>
      (_documentType?.hasExpiryDate ?? true) || _selectedExpiryDate != null;

  // NEW: Date picker for expiry date
  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      // Allow past dates: an already-expired document has a past expiry, and
      // opening the picker on it must not fail.
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      helpText: context.l10n.selectExpiryDate,
      cancelText: context.l10n.commonCancel,
      confirmText: context.l10n.actionSelect,
    );
    if (picked != null && picked != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = picked;
      });
    }
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
                context.l10n.addYourSignature,
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
                        SnackBar(
                          content: Text(context.l10n.signatureAdded),
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
        SnackBar(
          content: Text(context.l10n.rejectReasonRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // NEW: Get the edited specification and expiry date
      final newSpecification = _specificationController.text.trim().isNotEmpty
          ? _specificationController.text.trim()
          : null;

      final success = await documentProvider.updateDocumentStatus(
        document.id,
        status,
        _commentController.text.isNotEmpty ? _commentController.text : null,
        authProvider.currentUser!,
        specification: newSpecification,
        expiryDate: _selectedExpiryDate,
        // The admin cleared a date that was there — actually remove it.
        clearExpiryDate: _selectedExpiryDate == null && document.expiryDate != null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == DocumentStatus.APPROVED ? context.l10n.docApprovedOk : context.l10n.docRejectedOk),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        // Reset admin fields initialized flag so they reload on next view
        _adminFieldsInitialized = false;
        setState(() {
          _documentFuture = null;
          _loadDocument();
        });
      }
    }
  }
}