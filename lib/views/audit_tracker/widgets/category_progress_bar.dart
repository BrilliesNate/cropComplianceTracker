import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../models/document_model.dart';

class CategoryProgressBar extends StatelessWidget {
  final String categoryId;

  const CategoryProgressBar({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final documents = documentProvider.getDocumentsByCategory(categoryId);

    // Calculate progress
    if (documents.isEmpty) {
      return _buildProgressBar(context, 0, 'No documents available');
    }

    int completedCount = 0;
    int pendingCount = 0;
    int rejectedCount = 0;

    for (var doc in documents) {
      if (doc.isComplete || doc.isNotApplicable) {
        completedCount++;
      } else if (doc.isPending) {
        pendingCount++;
      } else if (doc.isRejected) {
        rejectedCount++;
      }
    }

    final percentage = (completedCount / documents.length) * 100;
    final statusText = 'Completed: $completedCount / ${documents.length} (${percentage.toStringAsFixed(0)}%)';

    return Column(
      children: [
        _buildProgressBar(context, percentage / 100, statusText),
        const SizedBox(height: 8),
        _buildLegend(context, documents.length, completedCount, pendingCount, rejectedCount),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double value, String statusText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 16,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForPercentage(value),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLegend(
      BuildContext context,
      int total,
      int completed,
      int pending,
      int rejected,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(context, 'Completed', Colors.green, completed, total),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Pending', Colors.orange, pending, total),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Rejected', Colors.red, rejected, total),
      ],
    );
  }

  Widget _buildLegendItem(
      BuildContext context,
      String label,
      Color color,
      int count,
      int total,
      ) {
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count, ${percentage.toStringAsFixed(0)}%)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }
}