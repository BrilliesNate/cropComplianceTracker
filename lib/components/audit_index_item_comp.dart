import 'package:flutter/material.dart';

// Data models
class AuditIndexDocument {
  final String id;
  final String specificationName;
  final DateTime? expiryDate;
  final String documentPath;
  final String uploadedBy;
  final DateTime uploadedOn;

  AuditIndexDocument({
    required this.id,
    required this.specificationName,
    this.expiryDate,
    required this.documentPath,
    required this.uploadedBy,
    required this.uploadedOn,
  });
}

class AuditIndexCategory {
  final String name;
  final List<AuditIndexDocument> documents;
  final String description;
  final IconData icon;

  AuditIndexCategory({
    required this.name,
    required this.documents,
    this.description = '',
    this.icon = Icons.folder,
  });
}

// Component for document item within a category
class AuditIndexDocumentItem extends StatelessWidget {
  final AuditIndexDocument document;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const AuditIndexDocumentItem({
    Key? key,
    required this.document,
    required this.onView,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Manual date formatting
    String formatDate(DateTime date) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Specification name
          Expanded(
            flex: 3,
            child: Text(
              document.specificationName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Expiry date
          Expanded(
            flex: 2,
            child: Text(
              document.expiryDate != null
                  ? formatDate(document.expiryDate!)
                  : 'No expiry date',
              style: TextStyle(
                color: document.expiryDate != null && document.expiryDate!.isBefore(DateTime.now())
                    ? Colors.red
                    : Colors.black,
              ),
            ),
          ),

          // View button
          Expanded(
            flex: 1,
            child: TextButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),

          // Delete button
          Expanded(
            flex: 1,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),

          // Uploaded by
          Expanded(
            flex: 2,
            child: Text(document.uploadedBy),
          ),

          // Upload date
          Expanded(
            flex: 2,
            child: Text(document.uploadedOn != null
                ? formatDate(document.uploadedOn)
                : ''),
          ),
        ],
      ),
    );
  }
}

// Navigation card component for categories
class CategoryNavigationCard extends StatelessWidget {
  final AuditIndexCategory category;
  final VoidCallback onTap;

  const CategoryNavigationCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      category.icon,
                      color: const Color(0xFF28A745),
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Category name and document count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          '${category.documents.length} Documents',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Navigation indicator
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16.0,
                    color: Color(0xFF28A745),
                  ),
                ],
              ),
              if (category.description.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Text(
                  category.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}