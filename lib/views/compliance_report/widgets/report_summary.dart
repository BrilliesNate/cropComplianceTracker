import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/document_provider.dart';
import '../../../providers/auth_provider.dart';

class ReportSummary extends StatelessWidget {
  const ReportSummary({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final documentProvider = Provider.of<DocumentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';

    final totalDocuments = documentProvider.documents.length;
    final pendingDocuments = documentProvider.pendingDocuments.length;
    final approvedDocuments = documentProvider.approvedDocuments.length;
    final rejectedDocuments = documentProvider.rejectedDocuments.length;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compliance Summary Report',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generated on ${DateFormat('MMMM d, y').format(DateTime.now())}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prepared for: $userName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildComplianceGauge(context, compliancePercentage),
                ),
              ],
            ),
            const Divider(height: 40),
            Text(
              'Summary Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Documents',
                    totalDocuments,
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Approved',
                    approvedDocuments,
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pending',
                    pendingDocuments,
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Rejected',
                    rejectedDocuments,
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expiredDocuments > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Warning: Expired Documents',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have $expiredDocuments expired document${expiredDocuments > 1 ? 's' : ''}. Please update these documents as soon as possible.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceGauge(BuildContext context, double percentage) {
    final color = _getColorForPercentage(percentage / 100);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text('Compliant'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getComplianceStatusText(percentage),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      int value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage < 0.3) return Colors.red;
    if (percentage < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getComplianceStatusText(double percentage) {
    if (percentage < 30) return 'High Risk';
    if (percentage < 70) return 'Moderate Risk';
    if (percentage < 90) return 'Good Standing';
    return 'Excellent';
  }
}