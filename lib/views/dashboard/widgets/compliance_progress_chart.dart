import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/category_provider.dart';
import '../../../providers/document_provider.dart';

class ComplianceProgressChart extends StatelessWidget {
  const ComplianceProgressChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final documentProvider = Provider.of<DocumentProvider>(context);

    // Calculate compliance percentage by category
    final categories = categoryProvider.categories;
    final categoryComplianceMap = <String, double>{};

    for (var category in categories) {
      final docs = documentProvider.getDocumentsByCategory(category.id);
      if (docs.isEmpty) {
        categoryComplianceMap[category.id] = 0;
      } else {
        final completedDocs = docs.where((doc) => doc.isComplete || doc.isNotApplicable).length;
        categoryComplianceMap[category.id] = (completedDocs / docs.length) * 100;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compliance Progress by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ...categories.map((category) {
              final compliance = categoryComplianceMap[category.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          '${compliance.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: compliance / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForPercentage(compliance / 100),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}