import 'package:cropcompliance/components/audit_index_item_comp.dart';
import 'package:flutter/material.dart';

class DocumentListView extends StatefulWidget {
  final AuditIndexCategory category;

  const DocumentListView({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<DocumentListView> createState() => _DocumentListViewState();
}

class _DocumentListViewState extends State<DocumentListView> {
  // Group documents by specification name
  Map<String, List<AuditIndexDocument>> _groupedDocuments = {};
  List<String> _specificationNames = [];

  @override
  void initState() {
    super.initState();
    _groupDocuments();
  }

  void _groupDocuments() {
    // Clear any existing grouping
    _groupedDocuments = {};

    // Group documents by specification name
    for (var doc in widget.category.documents) {
      if (!_groupedDocuments.containsKey(doc.specificationName)) {
        _groupedDocuments[doc.specificationName] = [];
      }
      _groupedDocuments[doc.specificationName]!.add(doc);
    }

    // Get the list of specification names for headers
    _specificationNames = _groupedDocuments.keys.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header section with category details
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        widget.category.icon,
                        color: const Color(0xFF28A745),
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.category.description.isNotEmpty) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              widget.category.description,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                // Search and filter row
                Row(
                  children: [
                    // Search box
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search documents...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Filter dropdown
                    DropdownButton<String>(
                      hint: const Text('Filter by'),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Documents'),
                        ),
                        DropdownMenuItem(
                          value: 'expired',
                          child: Text('Expired Documents'),
                        ),
                        DropdownMenuItem(
                          value: 'expiring_soon',
                          child: Text('Expiring Soon'),
                        ),
                      ],
                      onChanged: (value) {
                        // Filter logic would go here
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Colors.grey[200],
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Specification Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Expiry Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(), // Space for view button
                ),
                Expanded(
                  flex: 1,
                  child: SizedBox(), // Space for delete button
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Uploaded By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Upload Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Document list grouped by specification name
          Expanded(
            child: _specificationNames.isEmpty
                ? const Center(
              child: Text('No documents found in this category.'),
            )
                : ListView.builder(
              itemCount: _specificationNames.length,
              itemBuilder: (context, index) {
                final specName = _specificationNames[index];
                final docs = _groupedDocuments[specName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Specification name header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      color: Colors.grey[100],
                      child: Row(
                        children: [
                          const Icon(Icons.description, color: Color(0xFF28A745), size: 20),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              specName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          Text(
                            '${docs.length} document${docs.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Documents in this specification
                    ...docs.map((doc) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: AuditIndexDocumentItem(
                        document: doc,
                        onView: () {
                          // Show snackbar for now, would typically open a document viewer
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Viewing document: ${doc.specificationName}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        onDelete: () {
                          // Show confirmation dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete the document "${doc.specificationName}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // Show snackbar to confirm deletion (would actually delete in real implementation)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Document "${doc.specificationName}" deleted'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )).toList(),

                    // Add a divider between specification groups
                    const Divider(height: 24.0, thickness: 1.0),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      // Floating action button to add a new document
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add a new document (not implemented here)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add document to ${widget.category.name} feature would go here'),
              backgroundColor: const Color(0xFF28A745),
            ),
          );
        },
        backgroundColor: const Color(0xFF28A745),
        child: const Icon(Icons.add),
      ),
    );
  }
}