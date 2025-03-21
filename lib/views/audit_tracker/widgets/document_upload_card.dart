import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/constants/route_constants.dart';
import '../../../models/document_type_model.dart';

class DocumentUploadCard extends StatefulWidget {
  final String categoryId;
  final DocumentTypeModel documentType;

  const DocumentUploadCard({
    Key? key,
    required this.categoryId,
    required this.documentType,
  }) : super(key: key);

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  List<File> _selectedFiles = [];
  DateTime? _expiryDate;
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: widget.documentType.allowMultipleDocuments,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files
              .where((file) => file.path != null)
              .map((file) => File(file.path!))
              .toList();
        });
      }
    } catch (e) {
      print('Error picking files: $e');
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _uploadDocuments() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.documentType.hasExpiryDate && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expiry date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final documentProvider = Provider.of<DocumentProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
    });

    try {
      if (authProvider.currentUser != null) {
        final document = await documentProvider.createDocument(
          user: authProvider.currentUser!,
          categoryId: widget.categoryId,
          documentTypeId: widget.documentType.id,
          files: _selectedFiles,
          expiryDate: _expiryDate,
        );

        if (document != null && mounted) {
          Navigator.of(context).pop();

          if (widget.documentType.requiresSignature) {
            Navigator.of(context).pushNamed(
              RouteConstants.documentDetail,
              arguments: {'documentId': document.id},
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading documents: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentType.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _pickFiles,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedFiles.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to select files',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported formats: PDF, JPG, JPEG, PNG, DOC, DOCX',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
                    : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Files:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = _selectedFiles[index];
                            final filename = file.path.split('/').last;

                            return ListTile(
                              leading: const Icon(Icons.description),
                              title: Text(
                                filename,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                              ),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (widget.documentType.hasExpiryDate) ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: _expiryDate != null
                    ? Text(
                  '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                )
                    : const Text('Select expiry date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectExpiryDate,
                tileColor: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                child: _isUploading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('Upload Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}