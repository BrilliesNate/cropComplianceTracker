import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/document_type_model.dart';

class DocumentUploadCard extends StatefulWidget {
  final String categoryId;
  final DocumentTypeModel documentType;
  final String? existingDocumentId;

  const DocumentUploadCard({
    Key? key,
    required this.categoryId,
    required this.documentType,
    this.existingDocumentId, // For resubmission
  }) : super(key: key);

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  // Changed to store information about each file
  List<FileUploadItem> _uploadItems = [];
  bool _isUploading = false;

  // Helper method to show toasts/snackbars
  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
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
        withData: kIsWeb, // Important: Get file bytes for web
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          // For web, we need a custom approach
          final newItems = result.files
              .where((file) => file.bytes != null && file.name != null)
              .map((file) {
            // Create a file-like object with the path as the filename
            final tempFile = File(file.name!);
            // Create a new upload item with file and bytes
            return FileUploadItem(
              file: tempFile,
              bytes: file.bytes!, // Store bytes for web uploads
              expiryDate: widget.documentType.hasExpiryDate ? null : DateTime.now().add(const Duration(days: 365)), // Default expiry date if needed
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
          // For mobile/desktop
          final newItems = result.files
              .where((file) => file.path != null)
              .map((file) => FileUploadItem(
            file: File(file.path!),
            bytes: null, // No bytes needed for mobile/desktop
            expiryDate: widget.documentType.hasExpiryDate ? null : DateTime.now().add(const Duration(days: 365)), // Default expiry date if needed
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
      _showToast('Error selecting files: $e', isError: true);
    }
  }

  Future<void> _selectExpiryDate(int index) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _uploadItems[index].expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _uploadItems[index] = _uploadItems[index].copyWith(expiryDate: date);
      });

      // DEBUG: Print the selected date
      print("DEBUG: Selected expiry date for item $index: ${_uploadItems[index].expiryDate}");
      // Convert to Timestamp format for verification
      print("DEBUG: As milliseconds since epoch: ${_uploadItems[index].expiryDate?.millisecondsSinceEpoch}");
    }
  }

  String _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📎';
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
    if (_uploadItems.isEmpty) {
      _showToast('Please select files to upload', isError: true);
      return;
    }

    // Check if any document with expiry date required is missing the date
    if (widget.documentType.hasExpiryDate) {
      final missingExpiryDates = _uploadItems.where((item) => item.expiryDate == null).isNotEmpty;
      if (missingExpiryDates) {
        _showToast('Please select an expiry date for all documents', isError: true);
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      if (authProvider.currentUser != null) {
        // Determine if this is a new document or an update
        if (widget.existingDocumentId != null) {
          // Update existing document (resubmission)
          print("DEBUG: Resubmitting document: ${widget.existingDocumentId}");

          // Prepare files for upload based on platform
          List<dynamic> filesToUpload = [];
          for (var item in _uploadItems) {
            if (kIsWeb) {
              // For web platform
              if (item.bytes != null) {
                filesToUpload.add({
                  'name': item.file.path,
                  'bytes': item.bytes,
                });
              }
            } else {
              // For mobile/desktop
              filesToUpload.add(item.file);
            }
          }

          final document = await documentProvider.updateDocumentFiles(
            documentId: widget.existingDocumentId!,
            files: filesToUpload,
            user: authProvider.currentUser!,
            expiryDate: widget.documentType.hasExpiryDate ? _uploadItems.first.expiryDate : null,
          );

          if (document != null && mounted) {
            _showToast("Document successfully resubmitted", isError: false);
            Navigator.of(context).pop();
          } else if (mounted) {
            _showToast("Failed to resubmit document", isError: true);
          }
        } else {
          // Create new document
          print("DEBUG: Creating new document");

          int successCount = 0;
          int failCount = 0;
          List<String> failedFiles = [];

          // Upload each document individually with its own expiry date
          for (var item in _uploadItems) {
            try {
              final filename = item.file.path.split('/').last;

              if (kIsWeb) {
                // For web
                final webFile = {
                  'name': item.file.path,
                  'bytes': item.bytes,
                };

                print("DEBUG: Uploading web file: ${item.file.path} with expiry date: ${item.expiryDate}");

                final document = await documentProvider.createDocument(
                  user: authProvider.currentUser!,
                  categoryId: widget.categoryId,
                  documentTypeId: widget.documentType.id,
                  files: [webFile], // Single file with its own expiry date
                  expiryDate: item.expiryDate, // Individual expiry date for this file
                );

                if (document != null) {
                  print("DEBUG: Document created with ID: ${document.id}");
                  print("DEBUG: Document expiryDate: ${document.expiryDate}");
                  successCount++;

                  // Show individual success toast
                  if (mounted) {
                    _showToast("Successfully uploaded: $filename", isError: false);
                  }

                  // Handle signature requirement for the last document
                  if (mounted && item == _uploadItems.last && widget.documentType.requiresSignature) {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  }
                } else {
                  // Document is null (upload failed)
                  failCount++;
                  failedFiles.add(filename);
                  if (mounted) {
                    _showToast("Failed to upload: $filename", isError: true);
                  }
                }
              } else {
                // For mobile/desktop
                print("DEBUG: Uploading file: ${item.file.path} with expiry date: ${item.expiryDate}");

                final document = await documentProvider.createDocument(
                  user: authProvider.currentUser!,
                  categoryId: widget.categoryId,
                  documentTypeId: widget.documentType.id,
                  files: [item.file], // Single file with its own expiry date
                  expiryDate: item.expiryDate, // Individual expiry date for this file
                );

                if (document != null) {
                  print("DEBUG: Document created with ID: ${document.id}");
                  print("DEBUG: Document expiryDate: ${document.expiryDate}");
                  successCount++;

                  // Show individual success toast
                  if (mounted) {
                    _showToast("Successfully uploaded: $filename", isError: false);
                  }

                  // Handle signature requirement for the last document
                  if (mounted && item == _uploadItems.last && widget.documentType.requiresSignature) {
                    Navigator.of(context).pushNamed(
                      RouteConstants.documentDetail,
                      arguments: {'documentId': document.id},
                    );
                  }
                } else {
                  // Document is null (upload failed)
                  failCount++;
                  failedFiles.add(filename);
                  if (mounted) {
                    _showToast("Failed to upload: $filename", isError: true);
                  }
                }
              }
            } catch (e) {
              // Handle individual file upload error
              final filename = item.file.path.split('/').last;
              print("ERROR uploading $filename: $e");
              failCount++;
              failedFiles.add(filename);
              if (mounted) {
                _showToast("Error uploading: $filename", isError: true);
              }
            }
          }

          // After all uploads complete, show summary toast and possibly pop the screen
          if (mounted) {
            if (successCount > 0 && failCount == 0) {
              _showToast("All documents uploaded successfully!", isError: false);
              // Only pop if all uploads were successful
              Navigator.of(context).pop();
            } else if (successCount > 0 && failCount > 0) {
              _showToast("$successCount uploaded, $failCount failed", isError: true);
              // If mixed results and all successful ones don't need signatures, pop
              if (!widget.documentType.requiresSignature) {
                Navigator.of(context).pop();
              }
            } else if (successCount == 0 && failCount > 0) {
              _showToast("All uploads failed", isError: true);
              // Don't pop on complete failure
            }
          }
        }
      }
    } catch (e) {
      print("ERROR during document upload: $e");
      print("ERROR stack trace: ${StackTrace.current}");
      _showToast('Error uploading documents: $e', isError: true);
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
            // Header section
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
                  ? 'Upload documents and set expiry dates for each'
                  : 'Upload documents for this category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),

            const Divider(height: 24),

            // Upload section
            if (_uploadItems.isEmpty) ... [
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
                        'Tap to select files',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: PDF, JPG, JPEG, PNG, DOC, DOCX',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ... [
              // Document list section
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Documents (${_uploadItems.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add More'),
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

              // Document cards in a wrap layout (responsive to screen width)
              // Document cards in a wrap layout (responsive to screen width)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _uploadItems.map((item) {
                  final filename = item.file.path.split('/').last;
                  final extension = filename.split('.').last.toUpperCase();

                  return Container(
                    width: 140, // Fixed width for consistency
                    // Remove fixed height to let content determine size
                    child: Card(
                      elevation: 1,
                      clipBehavior: Clip.antiAlias, // Ensures clean edges
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: item.expiryDate == null && widget.documentType.hasExpiryDate
                            ? const BorderSide(color: Colors.red, width: 1)
                            : BorderSide.none,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Important: Use minimum space needed
                        children: [
                          // File header with icon and remove button
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

                          // File name
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

                          // File size for web
                          if (kIsWeb && item.bytes != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                              child: Text(
                                "${(item.bytes!.length / 1024).toStringAsFixed(1)} KB",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          // Remove the Spacer widget that was forcing expansion

                          // Expiry date section
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
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Expires',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          item.expiryDate != null
                                              ? Text(
                                            '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          )
                                              : const Text(
                                            'Set date',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
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
            ],

            const SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: _isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_uploadItems.length > 1
                        ? "Uploading Documents..."
                        : "Uploading Document..."),
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
                          ? "Upload ${_uploadItems.length} Documents"
                          : "Upload Document")
                          : "Select and Upload Documents",
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
        ),
      ),
    );
  }
}

// Class to store file information with its expiry date
class FileUploadItem {
  final File file;
  final Uint8List? bytes; // Only used for web
  final DateTime? expiryDate;

  FileUploadItem({
    required this.file,
    this.bytes,
    this.expiryDate,
  });

  // Helper method to create a copy with updated fields
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