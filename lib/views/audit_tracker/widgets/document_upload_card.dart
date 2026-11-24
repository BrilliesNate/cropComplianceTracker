import 'dart:io';
import 'dart:typed_data';

import 'package:cropCompliance/core/constants/route_constants.dart';
import 'package:cropCompliance/models/document_type_model.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/providers/document_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cropCompliance/providers/locale_provider.dart';

class DocumentUploadCard extends StatefulWidget {
  final String categoryId;
  final DocumentTypeModel documentType;
  final String? existingDocumentId;

  const DocumentUploadCard({
    Key? key,
    required this.categoryId,
    required this.documentType,
    this.existingDocumentId,
  }) : super(key: key);

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  List<FileUploadItem> _uploadItems = [];
  bool _isUploading = false;
  final TextEditingController _specificationController = TextEditingController();
  DateTime? _reviewedDate; // for document types with a reviewed date

  Future<void> _pickReviewedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reviewedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: context.l10n.reviewedPolicyHelp,
    );
    if (date != null) setState(() => _reviewedDate = date);
  }

  @override
  void dispose() {
    _specificationController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    // Grab the messenger now: this card is often popped right after a success
    // message, and a dismiss tap must not depend on a context that is gone.
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(); // replace, don't stack
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
        // A SnackBar with an action stays on screen until dismissed unless told
        // otherwise (Flutter's default since 3.29) — this one must time out.
        persist: false,
        action: SnackBarAction(
          label: context.l10n.actionDismiss,
          textColor: Colors.white,
          onPressed: messenger.hideCurrentSnackBar,
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: widget.documentType.allowMultipleDocuments,
        withData: kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          final newItems = result.files
              .where((file) => file.bytes != null && file.name != null)
              .map((file) {
            final tempFile = File(file.name!);
            // No expiry date unless the user picks one — and only types that use
            // expiry dates ask for one. (This used to stamp "today + 365 days" on
            // documents WITHOUT an expiry, which made them show as expired a
            // year later.)
            return FileUploadItem(
              file: tempFile,
              bytes: file.bytes!,
            );
          }).toList();

          setState(() {
            _uploadItems.addAll(newItems);
          });

          print("DEBUG: Web files selected: ${newItems.length}");
          for (var item in newItems) {
            print("DEBUG: Web file: ${item.file.path} with ${item.bytes!.length} bytes");
          }
        } else {
          final newItems = result.files
              .where((file) => file.path != null)
              .map((file) => FileUploadItem(
            file: File(file.path!),
            bytes: null,
          ))
              .toList();

          setState(() {
            _uploadItems.addAll(newItems);
          });

          print("DEBUG: Mobile/desktop files selected: ${newItems.length}");
        }
      }
    } catch (e) {
      print('Error picking files: $e');
      _showToast(context.l10n.uploadSelectFilesError('$e'), isError: true);
    }
  }

  Future<void> _selectExpiryDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _uploadItems[index].expiryDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _uploadItems[index] = _uploadItems[index].copyWith(expiryDate: date);
      });

      print("DEBUG: Selected expiry date for item $index: ${_uploadItems[index].expiryDate}");
      print("DEBUG: As milliseconds since epoch: ${_uploadItems[index].expiryDate?.millisecondsSinceEpoch}");
    }
  }

  String _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'ðŸ“„';
      case 'doc':
      case 'docx':
        return 'ðŸ“ƒ';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'ðŸ–¼ï¸';
      default:
        return 'ðŸ“Ž';
    }
  }

  Color _getFileColor(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Colors.red.shade100;
      case 'doc':
      case 'docx':
        return Colors.blue.shade100;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Future<void> _uploadDocuments() async {
    print("DEBUG: _uploadDocuments called");
    print("DEBUG: existingDocumentId: ${widget.existingDocumentId}");
    print("DEBUG: specification: ${_specificationController.text}");

    if (_uploadItems.isEmpty) {
      _showToast(context.l10n.uploadSelectFilesFirst, isError: true);
      return;
    }

    if (widget.documentType.hasExpiryDate) {
      final missingExpiryDates = _uploadItems.where((item) => item.expiryDate == null).isNotEmpty;
      if (missingExpiryDates) {
        _showToast(context.l10n.uploadSelectExpiryAll, isError: true);
        return;
      }
    }

    if (widget.documentType.requiresSpecification &&
        _specificationController.text.trim().isEmpty) {
      _showToast(context.l10n.uploadNeedSpecPlease,
          isError: true);
      return;
    }
    if (widget.documentType.hasReviewedDate && _reviewedDate == null) {
      _showToast(context.l10n.uploadNeedReviewedPlease, isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    // CRITICAL FIX: Create user with correct companyId for document creation
    // When admin manages a company, effectiveUser.companyId might be wrong/null
    // We override it with the effectiveCompany.id to ensure documents go to the right company
    if (authProvider.effectiveUser == null || authProvider.effectiveCompany == null) {
      _showToast(context.l10n.uploadNoContext, isError: true);
      return;
    }

    final effectiveUserWithCorrectCompany = authProvider.effectiveUser!.copyWith(
      companyId: authProvider.effectiveCompany!.id,
    );
    print('DEBUG: Using companyId: ${authProvider.effectiveCompany!.id} for upload');

    setState(() {
      _isUploading = true;
    });

    try {
      if (authProvider.currentUser != null) {
        final specification = _specificationController.text.trim().isEmpty
            ? null
            : _specificationController.text.trim();

        // Always create a NEW document record regardless of whether this is
        // a re-upload of an expired document. The old document is preserved
        // as-is in Firestore for history/audit purposes.
        {
          if (widget.existingDocumentId != null) {
            print("DEBUG: Creating new document as renewal (old doc ${widget.existingDocumentId} kept for history)");
          } else {
            print("DEBUG: Creating new document");
          }

          int successCount = 0;
          int failCount = 0;
          List<String> failedFiles = [];
          String? firstNewDocId; // to link the superseded old doc → new version

          for (var item in _uploadItems) {
            try {
              final filename = item.file.path.split('/').last;

              if (kIsWeb) {
                final webFile = {
                  'name': item.file.path,
                  'bytes': item.bytes,
                };

                print("DEBUG: Uploading web file: ${item.file.path} with expiry date: ${item.expiryDate}");

                final document = await documentProvider.createDocument(
                  user: effectiveUserWithCorrectCompany,
                  categoryId: widget.categoryId,
                  documentTypeId: widget.documentType.id,
                  files: [webFile],
                  expiryDate: item.expiryDate,
                  specification: specification,
                  reviewedDate: _reviewedDate,
                );

                if (document != null) {
                  print("DEBUG: Document created with ID: ${document.id}");
                  print("DEBUG: Document expiryDate: ${document.expiryDate}");
                  print("DEBUG: Document specification: ${document.specification}");
                  successCount++;
                  firstNewDocId ??= document.id;

                  if (mounted) {
                    _showToast(context.l10n.uploadedFileOk(filename), isError: false);
                  }

                  if (mounted &&
                      item == _uploadItems.last &&
                      widget.documentType.requiresSignature) {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  }
                } else {
                  failCount++;
                  failedFiles.add(filename);
                  if (mounted) {
                    _showToast(context.l10n.uploadedFileFailed(filename), isError: true);
                  }
                }
              } else {
                print("DEBUG: Uploading file: ${item.file.path} with expiry date: ${item.expiryDate}");

                final document = await documentProvider.createDocument(
                  user: effectiveUserWithCorrectCompany,
                  categoryId: widget.categoryId,
                  documentTypeId: widget.documentType.id,
                  files: [item.file],
                  expiryDate: item.expiryDate,
                  specification: specification,
                  reviewedDate: _reviewedDate,
                );

                if (document != null) {
                  print("DEBUG: Document created with ID: ${document.id}");
                  print("DEBUG: Document expiryDate: ${document.expiryDate}");
                  print("DEBUG: Document specification: ${document.specification}");
                  successCount++;
                  firstNewDocId ??= document.id;

                  if (mounted) {
                    _showToast(context.l10n.uploadedFileOk(filename), isError: false);
                  }

                  if (mounted &&
                      item == _uploadItems.last &&
                      widget.documentType.requiresSignature) {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  }
                } else {
                  failCount++;
                  failedFiles.add(filename);
                  if (mounted) {
                    _showToast(context.l10n.uploadedFileFailed(filename), isError: true);
                  }
                }
              }
            } catch (e) {
              final filename = item.file.path.split('/').last;
              print("ERROR uploading $filename: $e");
              failCount++;
              failedFiles.add(filename);
              if (mounted) {
                _showToast(context.l10n.uploadedFileError(filename), isError: true);
              }
            }
          }

          // If this upload replaces an existing (e.g. expired/rejected) document,
          // mark the old one superseded so it drops out of action items while
          // staying findable in the audit index.
          if (widget.existingDocumentId != null && successCount > 0) {
            await documentProvider.supersedeDocument(
              widget.existingDocumentId!,
              newDocumentId: firstNewDocId,
            );
          }

          if (mounted) {
            if (successCount > 0 && failCount == 0) {
              _showToast(context.l10n.uploadAllOk, isError: false);
              Navigator.of(context).pop();
            } else if (successCount > 0 && failCount > 0) {
              _showToast(context.l10n.uploadSomeFailed(successCount, failCount), isError: true);
              if (!widget.documentType.requiresSignature) {
                Navigator.of(context).pop();
              }
            } else if (successCount == 0 && failCount > 0) {
              _showToast(context.l10n.uploadAllFailed, isError: true);
            }
          }
        }
      }
    } catch (e) {
      print("ERROR during document upload: $e");
      print("ERROR stack trace: ${StackTrace.current}");
      _showToast(context.l10n.uploadDocsError('$e'), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_upload_outlined,
                  size: 28,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.documentType.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.documentType.hasExpiryDate
                  ? context.l10n.uploadCardSubtitleExpiry
                  : context.l10n.uploadCardSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const Divider(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.documentType.requiresSpecification
                      ? context.l10n.uploadSpecRequired
                      : context.l10n.specification,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _specificationController,
                  decoration: InputDecoration(
                    hintText: widget.documentType.requiresSpecification
                        ? context.l10n.uploadSpecHintLong
                        : context.l10n.uploadSpecHintOptional,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 2,
                ),
                if (widget.documentType.hasReviewedDate) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.dateLastReviewedRequired,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickReviewedDate,
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(_reviewedDate == null
                        ? context.l10n.uploadChooseReviewDate
                        : DateFormat('d MMM yyyy').format(_reviewedDate!)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            if (_uploadItems.isEmpty) ...[
              GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload,
                          size: 42,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.uploadTapToSelect,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.uploadSupportedFormats,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.uploadSelectedDocsTitle(_uploadItems.length),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(context.l10n.actionAddMore),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uploadItems.map((item) {
                  final filename = item.file.path.split('/').last;
                  final extension = filename.split('.').last.toUpperCase();

                  return Container(
                    width: 140,
                    child: Card(
                      elevation: 1,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: item.expiryDate == null && widget.documentType.hasExpiryDate
                            ? const BorderSide(color: Colors.red, width: 1)
                            : BorderSide.none,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _getFileColor(filename),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getFileIcon(filename),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      extension,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _uploadItems.remove(item);
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                            child: Text(
                              filename,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (kIsWeb && item.bytes != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: Text(
                                "${(item.bytes!.length / 1024).toStringAsFixed(1)} KB", // l10n-ignore: unit
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (widget.documentType.hasExpiryDate)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                              child: GestureDetector(
                                onTap: () => _selectExpiryDate(_uploadItems.indexOf(item)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: item.expiryDate != null
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: item.expiryDate != null
                                          ? Colors.green.shade300
                                          : Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: item.expiryDate != null
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.expiryDate != null
                                              ? DateFormat('dd/MM/yy').format(item.expiryDate!)
                                              : context.l10n.actionSetDate,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: item.expiryDate != null
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadDocuments,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(_uploadItems.length > 1
                          ? context.l10n.uploadingDocs
                          : context.l10n.uploadingDoc),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload),
                      const SizedBox(width: 8),
                      Text(
                        _uploadItems.isNotEmpty
                            ? (_uploadItems.length > 1
                            ? context.l10n.uploadNDocs(_uploadItems.length)
                            : context.l10n.uploadOneDoc)
                            : context.l10n.uploadSelectAndUpload,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FileUploadItem {
  final File file;
  final Uint8List? bytes;
  final DateTime? expiryDate;

  FileUploadItem({
    required this.file,
    this.bytes,
    this.expiryDate,
  });

  FileUploadItem copyWith({
    File? file,
    Uint8List? bytes,
    DateTime? expiryDate,
  }) {
    return FileUploadItem(
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}