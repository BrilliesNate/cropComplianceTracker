import 'package:flutter/material.dart';

class ThemeConstants {
  // Brand colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green for agriculture
  static const Color accentColor = Color(0xFFFFA000);  // Amber for warnings/alerts

  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkAppBarColor = Color(0xFF1E1E1E);

  // Status colors
  static const Color pendingColor = Color(0xFFFFC107);
  static const Color approvedColor = Color(0xFF4CAF50);
  static const Color rejectedColor = Color(0xFFF44336);
  static const Color expiredColor = Color(0xFFFF5722);

  // Text colors
  static const Color primaryTextColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color lightTextColor = Colors.white;

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double borderRadius = 12.0;
  static const double buttonRadius = 8.0;
}