import 'dart:ui';
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:cropCompliance/providers/auth_provider.dart';
import 'package:cropCompliance/theme/theme_constants.dart';

class DashboardComplianceCard extends StatelessWidget {
  final AuthProvider authProvider;
  final String completionPercentage;
  final int approvedDocs;
  final int uploadedDocs;
  final int pendingDocs;
  final int rejectedDocs;
  final int totalDocTypes;

  const DashboardComplianceCard({
    Key? key,
    required this.authProvider,
    required this.completionPercentage,
    required this.approvedDocs,
    required this.uploadedDocs,
    required this.pendingDocs,
    required this.rejectedDocs,
    required this.totalDocTypes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    if (isMobile) {
      return _buildMobileCard(context);
    } else {
      return _buildDesktopCard(context);
    }
  }

  // Mobile version - NO CARD, full width image with KPIs
  Widget _buildMobileCard(BuildContext context) {
    final double percentage = double.parse(completionPercentage) / 100;

    final displayName = authProvider.isAdmin && authProvider.selectedUser != null
        ? authProvider.selectedUser!.name.split(' ').first
        : authProvider.currentUser?.name.split(' ').first ?? "User";

    return Stack(
      children: [
        // Background image - full width
        Container(
          height: 350,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/image1-4.webp'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Semi-transparent gradient overlay
        Container(
          height: 350,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),

        // Text at top left
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                authProvider.isAdmin && authProvider.selectedUser != null
                    ? 'Managing: $displayName'
                    : 'Hi, $displayName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                authProvider.isAdmin && authProvider.selectedUser != null
                    ? 'Document compliance overview'
                    : 'Welcome back.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Gauge centered
        Positioned(
          top: 108,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 120,
            child: CustomPaint(
              painter: ThickLineSemiCircleGauge(
                percentage: percentage,
                baseColor: Colors.grey.withOpacity(0.5),
                progressColor: Colors.green,
                lineCount: 24,
                dashLength: 25,
                dashWidth: 5,
                radius: 85,
                startFromLeft: true,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${completionPercentage}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // KPI containers at bottom in 2x2 grid
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKPIContainer(
                      context,
                      icon: Icons.trending_up,
                      title: 'Completion Rate',
                      value: '$approvedDocs/$totalDocTypes',
                      subtitle: '$completionPercentage%',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildKPIContainer(
                      context,
                      icon: Icons.check_circle_outline,
                      title: 'Approval Rate',
                      value: '$approvedDocs/$uploadedDocs',
                      subtitle:
                      '${(uploadedDocs > 0 ? (approvedDocs / uploadedDocs * 100).toStringAsFixed(1) : "0.0")}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildKPIContainer(
                      context,
                      icon: Icons.hourglass_empty,
                      title: 'Pending Review',
                      value: '$pendingDocs',
                      subtitle: 'Action Needed',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildKPIContainer(
                      context,
                      icon: Icons.cancel_outlined,
                      title: 'Rejected Item',
                      value: '$rejectedDocs',
                      subtitle: 'Needs Attention',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Desktop version - UNCHANGED with Card
  Widget _buildDesktopCard(BuildContext context) {
    final double percentage = double.parse(completionPercentage) / 100;

    final displayName = authProvider.isAdmin && authProvider.selectedUser != null
        ? authProvider.selectedUser!.name.split(' ').first
        : authProvider.currentUser?.name.split(' ').first ?? "User";

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: ThemeConstants.cardColors,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background image
          Container(
            height: 350,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/image1-4.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Semi-transparent gradient overlay
          Container(
            height: 350,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Text at top left
          Positioned(
            top: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.isAdmin && authProvider.selectedUser != null
                      ? 'Managing: $displayName'
                      : 'Hi, $displayName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.isAdmin && authProvider.selectedUser != null
                      ? 'Document compliance overview'
                      : 'Welcome back.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          // Gauge centered in the upper part of the card
          Positioned(
            top: 108,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: ThickLineSemiCircleGauge(
                  percentage: percentage,
                  baseColor: Colors.grey.withOpacity(0.5),
                  progressColor: Colors.green,
                  lineCount: 24,
                  dashLength: 40,
                  dashWidth: 8,
                  radius: 130,
                  startFromLeft: true,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      '${completionPercentage}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom stats bar with separate containers
          Positioned(
            bottom: 5,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildKPIContainer(
                    context,
                    icon: Icons.trending_up,
                    title: 'Completion Rate',
                    value: '$approvedDocs/$totalDocTypes',
                    subtitle: '$completionPercentage%',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKPIContainer(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Approval Rate',
                    value: '$approvedDocs/$uploadedDocs',
                    subtitle:
                    '${(uploadedDocs > 0 ? (approvedDocs / uploadedDocs * 100).toStringAsFixed(1) : "0.0")}%',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKPIContainer(
                    context,
                    icon: Icons.hourglass_empty,
                    title: 'Pending Review',
                    value: '$pendingDocs',
                    subtitle: 'Action Needed',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildKPIContainer(
                    context,
                    icon: Icons.cancel_outlined,
                    title: 'Rejected Item',
                    value: '$rejectedDocs',
                    subtitle: 'Needs Attention',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // KPI container with glass effect
  Widget _buildKPIContainer(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required String subtitle,
      }) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for the semi-circle gauge
class ThickLineSemiCircleGauge extends CustomPainter {
  final double percentage;
  final Color baseColor;
  final Color progressColor;
  final int lineCount;
  final double dashLength;
  final double dashWidth;
  final double radius;
  final bool startFromLeft;

  ThickLineSemiCircleGauge({
    required this.percentage,
    required this.baseColor,
    required this.progressColor,
    this.lineCount = 24,
    this.dashLength = 40,
    this.dashWidth = 8,
    this.radius = 100,
    this.startFromLeft = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, height * 0.6); // Positioned to show top half-circle

    // Calculate how many lines should be colored based on percentage
    final int progressLines = (percentage * lineCount).round();

    // Draw the lines
    for (int i = 0; i < lineCount; i++) {
      // Calculate angle - start from π (left side) if startFromLeft is true
      // This reverses the direction so progress goes from left to right
      double angle;
      if (startFromLeft) {
        angle = dart_math.pi - (i / (lineCount - 1)) * dart_math.pi; // Start from left (π) and go to right (0)
      } else {
        angle = (i / (lineCount - 1)) * dart_math.pi; // Start from right (0) and go to left (π)
      }

      // Determine line color - also need to adjust the progress calculation
      bool isProgress;
      if (startFromLeft) {
        isProgress = i < progressLines; // First lines are progress if starting from left
      } else {
        isProgress = i < progressLines; // No change needed if starting from right
      }

      final color = isProgress ? progressColor : baseColor;

      // Create paint for this line
      final paint = Paint()
        ..color = color
        ..strokeWidth = dashWidth
        ..strokeCap = StrokeCap.round;

      // Calculate inner point (where the dash starts)
      final double innerX = center.dx + radius * dart_math.cos(angle);
      final double innerY = center.dy - radius * dart_math.sin(angle);

      // Calculate outer point (where the dash ends, adding dashLength to radius)
      final double outerX = center.dx + (radius + dashLength) * dart_math.cos(angle);
      final double outerY = center.dy - (radius + dashLength) * dart_math.sin(angle);

      // Draw the dash
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}