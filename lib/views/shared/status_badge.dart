import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../theme/theme_constants.dart';

class StatusBadge extends StatelessWidget {
  final DocumentStatus status;
  final bool isExpired;

  const StatusBadge({
    Key? key,
    required this.status,
    this.isExpired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (isExpired) {
      color = ThemeConstants.expiredColor;
      label = 'Expired';
      icon = Icons.warning;
    } else {
      switch (status) {
        case DocumentStatus.PENDING:
          color = ThemeConstants.pendingColor;
          label = 'Pending';
          icon = Icons.hourglass_empty;
          break;
        case DocumentStatus.APPROVED:
          color = ThemeConstants.approvedColor;
          label = 'Approved';
          icon = Icons.check_circle;
          break;
        case DocumentStatus.REJECTED:
          color = ThemeConstants.rejectedColor;
          label = 'Rejected';
          icon = Icons.cancel;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}