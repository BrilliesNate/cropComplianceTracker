import 'dart:math' show pi, cos, sin;

import 'package:flutter/material.dart';

// Custom painter with thick, long dashes on a medium-sized circle
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
        angle = pi - (i / (lineCount - 1)) * pi; // Start from left (π) and go to right (0)
      } else {
        angle = (i / (lineCount - 1)) * pi; // Start from right (0) and go to left (π)
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
      final double innerX = center.dx + radius * cos(angle);
      final double innerY = center.dy - radius * sin(angle);

      // Calculate outer point (where the dash ends, adding dashLength to radius)
      final double outerX = center.dx + (radius + dashLength) * cos(angle);
      final double outerY = center.dy - (radius + dashLength) * sin(angle);

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