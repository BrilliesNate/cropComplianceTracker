import 'package:flutter/material.dart';

class ComplianceTrackerViewTesting extends StatefulWidget {
  const ComplianceTrackerViewTesting({Key? key}) : super(key: key);

  @override
  State<ComplianceTrackerViewTesting> createState() => _ComplianceTrackerViewTestingState();
}

class _ComplianceTrackerViewTestingState extends State<ComplianceTrackerViewTesting> {
  final List<ComplianceItem> _complianceItems = [
    ComplianceItem(
      id: 1,
      standard: 'WIETA',
      compliance: 0.85,
      lastUpdate: DateTime.now().subtract(const Duration(days: 5)),
      status: ComplianceStatus.compliant,
    ),
    ComplianceItem(
      id: 2,
      standard: 'SIZA',
      compliance: 0.72,
      lastUpdate: DateTime.now().subtract(const Duration(days: 10)),
      status: ComplianceStatus.needsAttention,
    ),
    ComplianceItem(
      id: 3,
      standard: 'GlobalGAP',
      compliance: 0.93,
      lastUpdate: DateTime.now().subtract(const Duration(days: 2)),
      status: ComplianceStatus.compliant,
    ),
    ComplianceItem(
      id: 4,
      standard: 'Food Safety',
      compliance: 0.65,
      lastUpdate: DateTime.now().subtract(const Duration(days: 15)),
      status: ComplianceStatus.critical,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate overall compliance percentage
    final overallCompliance = _complianceItems.isEmpty
        ? 0.0
        : _complianceItems.map((e) => e.compliance).reduce((a, b) => a + b) /
        _complianceItems.length;

    // Count standards by status
    final compliantCount = _complianceItems
        .where((item) => item.status == ComplianceStatus.compliant)
        .length;

    final needsAttentionCount = _complianceItems
        .where((item) => item.status == ComplianceStatus.needsAttention)
        .length;

    final criticalCount = _complianceItems
        .where((item) => item.status == ComplianceStatus.critical)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Tracker'),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF28A745).withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compliance Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Overall Compliance Card
                  Expanded(
                    flex: 2,
                    child: _buildOverallComplianceCard(overallCompliance),
                  ),
                  const SizedBox(width: 16),
                  // Status Counts Card
                  Expanded(
                    flex: 3,
                    child: _buildStatusCountsCard(
                        compliantCount,
                        needsAttentionCount,
                        criticalCount
                    ),
                  ),
                ],
              ),
            ),

            // Standards Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Standards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Show all standards or filter action
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),

            // Standards List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _complianceItems.length,
              itemBuilder: (context, index) {
                return _buildComplianceCard(_complianceItems[index]);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new standard action
        },
        backgroundColor: const Color(0xFF28A745),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverallComplianceCard(double compliance) {
    // Determine color based on compliance level
    Color progressColor;
    if (compliance >= 0.8) {
      progressColor = Colors.green;
    } else if (compliance >= 0.6) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Compliance',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(compliance * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: compliance,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCountsCard(int compliant, int needsAttention, int critical) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusCount(
              'Compliant',
              compliant.toString(),
              Icons.check_circle_outline,
              Colors.green,
            ),
            _buildStatusCount(
              'Needs Attention',
              needsAttention.toString(),
              Icons.warning_amber_outlined,
              Colors.orange,
            ),
            _buildStatusCount(
              'Critical',
              critical.toString(),
              Icons.error_outline,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCount(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 28,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }

  Widget _buildComplianceCard(ComplianceItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _getStatusIcon(item.status),
                    const SizedBox(width: 12),
                    Text(
                      item.standard,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(item.compliance * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getColorForStatus(item.status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.compliance,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorForStatus(item.status),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last updated: ${_formatDate(item.lastUpdate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // View details action
                  },
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(ComplianceStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case ComplianceStatus.compliant:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case ComplianceStatus.needsAttention:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case ComplianceStatus.critical:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 20,
    );
  }

  Color _getColorForStatus(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.compliant:
        return Colors.green;
      case ComplianceStatus.needsAttention:
        return Colors.orange;
      case ComplianceStatus.critical:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ComplianceItem {
  final int id;
  final String standard;
  final double compliance;
  final DateTime lastUpdate;
  final ComplianceStatus status;

  ComplianceItem({
    required this.id,
    required this.standard,
    required this.compliance,
    required this.lastUpdate,
    required this.status,
  });
}

enum ComplianceStatus {
  compliant,
  needsAttention,
  critical,
}