import 'package:flutter/material.dart';
import '../../../models/category_model.dart';

class DocumentFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String? statusFilter;
  final String searchQuery;
  final Function(String?) onCategoryChanged;
  final Function(String?) onStatusChanged;
  final Function(String) onSearchChanged;
  final bool isDesktop;

  const DocumentFilter({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.statusFilter,
    required this.searchQuery,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Documents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCategoryDropdown(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusDropdown(context),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSearchField(context),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildCategoryDropdown(context),
                  const SizedBox(height: 16),
                  _buildStatusDropdown(context),
                  const SizedBox(height: 16),
                  _buildSearchField(context),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      value: selectedCategoryId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Categories'),
        ),
        ...categories.map((category) {
          return DropdownMenuItem<String?>(
            value: category.id,
            child: Text(category.name),
          );
        }).toList(),
      ],
      onChanged: onCategoryChanged,
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      value: statusFilter,
      items: const [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('All Statuses'),
        ),
        DropdownMenuItem<String?>(
          value: 'APPROVED',
          child: Text('Approved'),
        ),
        DropdownMenuItem<String?>(
          value: 'PENDING',
          child: Text('Pending'),
        ),
        DropdownMenuItem<String?>(
          value: 'REJECTED',
          child: Text('Rejected'),
        ),
        DropdownMenuItem<String?>(
          value: 'EXPIRED',
          child: Text('Expired'),
        ),
        DropdownMenuItem<String?>(
          value: 'NOT_APPLICABLE',
          child: Text('Not Applicable'),
        ),
      ],
      onChanged: onStatusChanged,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Search',
        hintText: 'Search by document type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      controller: TextEditingController(text: searchQuery),
      onChanged: onSearchChanged,
    );
  }
}