import 'package:cropcompliance/components/audit_index_item_comp.dart';
import 'package:cropcompliance/screens/auditIndex/documents_item_view.dart';
import 'package:flutter/material.dart';

class AuditIndexView extends StatelessWidget {
  const AuditIndexView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Hardcoded data for now
    final List<AuditIndexCategory> categories = [
      AuditIndexCategory(
        name: 'Business Requirements',
        description: 'Documents related to company registration, tax compliance, and business licensing.',
        icon: Icons.business,
        documents: [
          AuditIndexDocument(
            id: '1',
            specificationName: 'Company Registration Documents',
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            documentPath: 'registration.pdf',
            uploadedBy: 'John Smith',
            uploadedOn: DateTime.now().subtract(const Duration(days: 30)),
          ),AuditIndexDocument(
            id: '10',
            specificationName: 'Company Registration Documents',
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            documentPath: 'registration.pdf',
            uploadedBy: 'John Smith',
            uploadedOn: DateTime.now().subtract(const Duration(days: 30)),
          ),
          AuditIndexDocument(
            id: '2',
            specificationName: 'Tax Compliance Certificate',
            expiryDate: DateTime.now().add(const Duration(days: 60)),
            documentPath: 'tax_certificate.pdf',
            uploadedBy: 'Sarah Johnson',
            uploadedOn: DateTime.now().subtract(const Duration(days: 20)),
          ),
        ],
      ),
      AuditIndexCategory(
        name: 'Labor Practices',
        description: 'Employment contracts, worker policies, compensation documents, and related records.',
        icon: Icons.people,
        documents: [
          AuditIndexDocument(
            id: '3',
            specificationName: 'Employment Contracts',
            expiryDate: null, // No expiry
            documentPath: 'contracts.pdf',
            uploadedBy: 'James Brown',
            uploadedOn: DateTime.now().subtract(const Duration(days: 45)),
          ),
          AuditIndexDocument(
            id: '4',
            specificationName: 'Workers Compensation Insurance',
            expiryDate: DateTime.now().subtract(const Duration(days: 10)), // Expired
            documentPath: 'insurance.pdf',
            uploadedBy: 'Emma Davis',
            uploadedOn: DateTime.now().subtract(const Duration(days: 60)),
          ),
        ],
      ),
      AuditIndexCategory(
        name: 'Health and Safety',
        description: 'Safety protocols, risk assessments, and health management procedures.',
        icon: Icons.health_and_safety,
        documents: [
          AuditIndexDocument(
            id: '5',
            specificationName: 'Risk Assessment Report',
            expiryDate: DateTime.now().add(const Duration(days: 180)),
            documentPath: 'risk_assessment.pdf',
            uploadedBy: 'Robert Wilson',
            uploadedOn: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ],
      ),
      AuditIndexCategory(
        name: 'Environmental Compliance',
        description: 'Environmental impact assessments, waste management plans, and sustainability reports.',
        icon: Icons.eco,
        documents: [
          AuditIndexDocument(
            id: '6',
            specificationName: 'Environmental Impact Assessment',
            expiryDate: DateTime.now().add(const Duration(days: 730)), // 2 years
            documentPath: 'eia_report.pdf',
            uploadedBy: 'Lisa Chen',
            uploadedOn: DateTime.now().subtract(const Duration(days: 90)),
          ),
          AuditIndexDocument(
            id: '7',
            specificationName: 'Waste Management Plan',
            expiryDate: DateTime.now().add(const Duration(days: 180)),
            documentPath: 'waste_management.pdf',
            uploadedBy: 'David Miller',
            uploadedOn: DateTime.now().subtract(const Duration(days: 45)),
          ),
        ],
      ),
      AuditIndexCategory(
        name: 'Quality Control',
        description: 'Quality management systems, certifications, and product testing reports.',
        icon: Icons.verified,
        documents: [
          AuditIndexDocument(
            id: '8',
            specificationName: 'ISO 9001 Certification',
            expiryDate: DateTime.now().add(const Duration(days: 365)),
            documentPath: 'iso9001.pdf',
            uploadedBy: 'Michael Clark',
            uploadedOn: DateTime.now().subtract(const Duration(days: 70)),
          ),
        ],
      ),
    ];

    // Calculate total documents across all categories
    final int totalDocuments = categories.fold(0, (sum, category) => sum + category.documents.length);

    // Calculate expiring soon documents (within 30 days)
    final int expiringSoonCount = categories.fold(0, (sum, category) {
      return sum + category.documents.where((doc) {
        if (doc.expiryDate == null) return false;
        final daysUntilExpiry = doc.expiryDate!.difference(DateTime.now()).inDays;
        return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
      }).length;
    });

    // Calculate expired documents
    final int expiredCount = categories.fold(0, (sum, category) {
      return sum + category.documents.where((doc) {
        if (doc.expiryDate == null) return false;
        return doc.expiryDate!.isBefore(DateTime.now());
      }).length;
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Index'),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with search
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document Audit Index',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Select a category to view all related documents.',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Search box
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Statistics summary cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildStatCard(
                    context: context,
                    title: 'Total Documents',
                    value: totalDocuments.toString(),
                    icon: Icons.insert_drive_file,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16.0),
                  _buildStatCard(
                    context: context,
                    title: 'Expiring Soon',
                    value: expiringSoonCount.toString(),
                    icon: Icons.warning,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16.0),
                  _buildStatCard(
                    context: context,
                    title: 'Expired',
                    value: expiredCount.toString(),
                    icon: Icons.error,
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Document Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Category navigation cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  childAspectRatio: 1.6, // Width to height ratio
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryNavigationCard(
                    category: categories[index],
                    onTap: () {
                      // Navigate to document list view for this category
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DocumentListView(
                            category: categories[index],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32.0),
          ],
        ),
      ),
      // Floating action button to add a new document
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add a new document (not implemented here)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add document feature would go here'),
              backgroundColor: Color(0xFF28A745),
            ),
          );
        },
        backgroundColor: const Color(0xFF28A745),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper method to build a statistics card
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8.0),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}