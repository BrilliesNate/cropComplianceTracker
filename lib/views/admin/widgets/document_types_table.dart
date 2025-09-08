import 'package:cropCompliance/models/document_type_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentTypesTable extends StatefulWidget {
  final List<DocumentTypeModel> documentTypes;
  final List<dynamic> categories;
  final String? categoryFilter;
  final Function(String?) onCategoryFilterChanged;
  final Function(DocumentTypeModel) onEdit;
  final Function(String) onDelete;
  final Function(DocumentTypeModel, Map<String, dynamic>) onQuickUpdate;

  const DocumentTypesTable({
    Key? key,
    required this.documentTypes,
    required this.categories,
    required this.categoryFilter,
    required this.onCategoryFilterChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onQuickUpdate,
  }) : super(key: key);

  @override
  State<DocumentTypesTable> createState() => _DocumentTypesTableState();
}

class _DocumentTypesTableState extends State<DocumentTypesTable> {
  final Set<String> _updatingItems = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter
            Row(
              children: [
                Icon(Icons.table_chart, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Document Types Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    value: widget.categoryFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ...widget.categories.map((category) {
                        return DropdownMenuItem<String?>(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }),
                    ],
                    onChanged: widget.onCategoryFilterChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Professional data table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('Document Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
                        Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
                        SizedBox(width: 70, child: Text('Multiple', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                        SizedBox(width: 70, child: Text('Upload', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                        SizedBox(width: 70, child: Text('Expiry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                        SizedBox(width: 70, child: Text('N/A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                        SizedBox(width: 90, child: Text('Signatures', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                        SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),

                  // Data rows
                  if (widget.documentTypes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No document types found',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...widget.documentTypes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final docType = entry.value;
                      final categoryName = _getCategoryName(docType.categoryId);
                      final isUpdating = _updatingItems.contains(docType.id);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: index.isEven ? Colors.white : Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Document Type Name
                            Expanded(
                              flex: 3,
                              child: Text(
                                docType.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),

                            // Category
                            Expanded(
                              flex: 2,
                              child: Text(
                                categoryName,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),

                            // Quick toggle switches - Normal size with loading states
                            SizedBox(
                              width: 70,
                              child: Center(
                                child: isUpdating ?
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                                ) :
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: docType.allowMultipleDocuments,
                                    onChanged: (value) => _updateProperty(docType, {'allowMultipleDocuments': value}),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 70,
                              child: Center(
                                child: isUpdating ?
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                                ) :
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: docType.isUploadable,
                                    onChanged: (value) => _updateProperty(docType, {'isUploadable': value}),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 70,
                              child: Center(
                                child: isUpdating ?
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                                ) :
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: docType.hasExpiryDate,
                                    onChanged: (value) => _updateProperty(docType, {'hasExpiryDate': value}),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 70,
                              child: Center(
                                child: isUpdating ?
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                                ) :
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: docType.hasNotApplicableOption,
                                    onChanged: (value) => _updateProperty(docType, {'hasNotApplicableOption': value}),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),

                            // Signatures - Compact display
                            SizedBox(
                              width: 90,
                              child: Center(
                                child: docType.requiresSignature
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        '${docType.signatureCount}',
                                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    GestureDetector(
                                      onTap: () => _showQuickSignatureEdit(docType),
                                      child: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
                                    ),
                                  ],
                                )
                                    : isUpdating ?
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).primaryColor),
                                ) :
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: docType.requiresSignature,
                                    onChanged: (value) => _updateProperty(docType, {
                                      'requiresSignature': value,
                                      'signatureCount': value ? 1 : 0,
                                    }),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),

                            // Actions - Compact buttons
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    onPressed: () => widget.onEdit(docType),
                                    tooltip: 'Edit',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    color: Colors.blue.shade600,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    onPressed: () => widget.onDelete(docType.id),
                                    tooltip: 'Delete',
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    color: Colors.red.shade600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String categoryId) {
    try {
      final category = widget.categories.firstWhere((c) => c.id == categoryId);
      return category.name;
    } catch (_) {
      return 'Unknown';
    }
  }

  // Quick update with loading state
  Future<void> _updateProperty(DocumentTypeModel docType, Map<String, dynamic> updates) async {
    setState(() {
      _updatingItems.add(docType.id);
    });

    try {
      await widget.onQuickUpdate(docType, updates);
    } finally {
      if (mounted) {
        setState(() {
          _updatingItems.remove(docType.id);
        });
      }
    }
  }

  // Quick inline signature count edit
  void _showQuickSignatureEdit(DocumentTypeModel docType) {
    final controller = TextEditingController(text: docType.signatureCount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        title: const Text('Signatures Required', style: TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 200,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Count',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
            onFieldSubmitted: (value) {
              final count = int.tryParse(value) ?? 1;
              if (count > 0) {
                Navigator.of(context).pop();
                _updateProperty(docType, {'signatureCount': count});
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text) ?? 1;
              if (count > 0) {
                Navigator.of(context).pop();
                _updateProperty(docType, {'signatureCount': count});
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}