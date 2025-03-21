import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';

    final totalDocuments = documentProvider.documents.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final expiredDocuments = documentProvider.expiredDocuments.length;

    // Calculate compliance percentage
    double compliancePercentage = 0;
    if (totalDocuments > 0) {
      compliancePercentage = (approvedDocuments / totalDocuments) * 100;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $userName',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your compliance dashboard summary',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    '${compliancePercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Documents',
                    totalDocuments.toString(),
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Pending',
                    pendingDocuments.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Approved',
                    approvedDocuments.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Expired',
                    expiredDocuments.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}