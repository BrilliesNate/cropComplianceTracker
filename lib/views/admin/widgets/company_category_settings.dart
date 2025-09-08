import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyCategorySettings extends StatefulWidget {
  final List<Map<String, dynamic>> companies;
  final String? selectedCompanyId;
  final Map<String, bool> enabledCategories;
  final List<dynamic> categories;
  final Function(String?) onCompanyChanged;
  final Function(String, bool) onCategoryToggle;
  final VoidCallback onSave;
  final bool isLoading;

  const CompanyCategorySettings({
    Key? key,
    required this.companies,
    required this.selectedCompanyId,
    required this.enabledCategories,
    required this.categories,
    required this.onCompanyChanged,
    required this.onCategoryToggle,
    required this.onSave,
    required this.isLoading,
  }) : super(key: key);

  @override
  State<CompanyCategorySettings> createState() => _CompanyCategorySettingsState();
}

class _CompanyCategorySettingsState extends State<CompanyCategorySettings> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.business, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Company Category Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : widget.onSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Company selection
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  labelStyle: TextStyle(fontSize: 12),
                ),
                value: widget.selectedCompanyId,
                style: const TextStyle(fontSize: 12, color: Colors.black),
                items: widget.companies.map((company) {
                  return DropdownMenuItem<String>(
                    value: company['id'] as String,
                    child: Text(company['name'] as String),
                  );
                }).toList(),
                onChanged: widget.onCompanyChanged,
              ),
            ),

            if (widget.selectedCompanyId != null) ...[
              const SizedBox(height: 12),

              // Categories table
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 50, child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),

                    // Category rows
                    ...widget.categories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final isEnabled = widget.enabledCategories[category.id] ?? true;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            SizedBox(
                              width: 50,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: isEnabled,
                                  onChanged: (value) => widget.onCategoryToggle(category.id, value),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isEnabled ? Colors.black : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(
                                category.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }
}