import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentTypeForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final List<dynamic> categories;
  final String? selectedCategoryId;
  final bool allowMultipleDocuments;
  final bool isUploadable;
  final bool hasExpiryDate;
  final bool hasNotApplicableOption;
  final bool requiresSignature;
  final int signatureCount;
  final DocumentTypeModel? editingDocType;
  final bool isLoading;
  final Function(String?) onCategoryChanged;
  final Function(bool) onAllowMultipleChanged;
  final Function(bool) onUploadableChanged;
  final Function(bool) onExpiryDateChanged;
  final Function(bool) onNotApplicableChanged;
  final Function(bool) onSignatureRequiredChanged;
  final Function(int) onSignatureCountChanged;
  final VoidCallback onSave;
  final VoidCallback onReset;

  const DocumentTypeForm({
    Key? key,
    required this.formKey,
    required this.nameController,
    required this.categories,
    required this.selectedCategoryId,
    required this.allowMultipleDocuments,
    required this.isUploadable,
    required this.hasExpiryDate,
    required this.hasNotApplicableOption,
    required this.requiresSignature,
    required this.signatureCount,
    required this.editingDocType,
    required this.isLoading,
    required this.onCategoryChanged,
    required this.onAllowMultipleChanged,
    required this.onUploadableChanged,
    required this.onExpiryDateChanged,
    required this.onNotApplicableChanged,
    required this.onSignatureRequiredChanged,
    required this.onSignatureCountChanged,
    required this.onSave,
    required this.onReset,
  }) : super(key: key);

  @override
  State<DocumentTypeForm> createState() => _DocumentTypeFormState();
}

class _DocumentTypeFormState extends State<DocumentTypeForm> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.editingDocType != null ? Icons.edit : Icons.add,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.editingDocType != null ? 'Edit Document Type' : 'Add Document Type',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (widget.editingDocType != null)
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: widget.onReset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: widget.isLoading ? null : widget.onSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      child: widget.isLoading
                          ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(widget.editingDocType != null ? 'Update' : 'Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Form fields in a compact layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Category dropdown
                        SizedBox(
                          height: 40,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              labelStyle: TextStyle(fontSize: 12),
                            ),
                            value: widget.selectedCategoryId,
                            style: const TextStyle(fontSize: 12, color: Colors.black),
                            items: widget.categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: widget.onCategoryChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Document type name
                        SizedBox(
                          height: 40,
                          child: TextFormField(
                            controller: widget.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Document Type Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              labelStyle: TextStyle(fontSize: 12),
                            ),
                            style: const TextStyle(fontSize: 12),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right column - Properties
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Properties',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        // Properties in a compact grid
                        Wrap(
                          spacing: 8,
                          runSpacing: 0,
                          children: [
                            _buildCompactCheckbox(
                              'Multiple Docs',
                              widget.allowMultipleDocuments,
                              widget.onAllowMultipleChanged,
                            ),
                            _buildCompactCheckbox(
                              'Uploadable',
                              widget.isUploadable,
                              widget.onUploadableChanged,
                            ),
                            _buildCompactCheckbox(
                              'Has Expiry',
                              widget.hasExpiryDate,
                              widget.onExpiryDateChanged,
                            ),
                            _buildCompactCheckbox(
                              'N/A Option',
                              widget.hasNotApplicableOption,
                              widget.onNotApplicableChanged,
                            ),
                            _buildCompactCheckbox(
                              'Signatures',
                              widget.requiresSignature,
                              widget.onSignatureRequiredChanged,
                            ),
                          ],
                        ),

                        // Signature count if required
                        if (widget.requiresSignature) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 120,
                            height: 35,
                            child: TextFormField(
                              initialValue: widget.signatureCount.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Sig. Count',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                labelStyle: TextStyle(fontSize: 11),
                              ),
                              style: const TextStyle(fontSize: 12),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final count = int.tryParse(value);
                                if (count == null || count <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                final count = int.tryParse(value) ?? 1;
                                widget.onSignatureCountChanged(count);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactCheckbox(String label, bool value, Function(bool) onChanged) {
    return SizedBox(
      width: 110,
      height: 30,
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: value,
              onChanged: (val) => onChanged(val ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}