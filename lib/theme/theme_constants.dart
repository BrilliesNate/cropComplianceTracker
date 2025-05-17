import 'package:flutter/material.dart';

class ThemeConstants {
  // Brand colors
  static const Color primaryColor = Color(0xFF43A047); // Refined modern green
  static const Color accentColor = Color(0xFFFDC060);  // Amber for highlights

  // Light theme colors
  static const Color lightBackgroundColor = Color(0xFFECECEC); // Soft neutral background
  static const Color lightCardColor = Colors.white;

  static const Color cardColors = Color(0xFFEFEFEF);

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF1A1A1A); // Softer dark
  static const Color darkCardColor = Color(0xFF2C2C2C);       // Subtle elevation
  static const Color darkAppBarColor = Color(0xFF2C2C2C);

  // Status colors (muted for clean dashboard)
  static const Color pendingColor = Color(0xFFFFD54F);   // Soft amber
  static const Color approvedColor = Color(0xFF81C784);  // Pastel green
  static const Color rejectedColor = Color(0xFFE57373);  // Soft red
  static const Color expiredColor = Color(0xFFFF8A65);   // Salmon

  // Text colors
  static const Color primaryTextColor = Color(0xFF1E1E1E);     // Nearly black for strong contrast
  static const Color secondaryTextColor = Color(0xFF616161);   // Soft neutral gray
  static const Color lightTextColor = Colors.white;

  // Accent / border / subtle elements
  static const Color neutralAccent = Color(0xFF90A4AE); // Blue-grey for subtle elements

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius
  static const double borderRadius = 12.0;
  static const double buttonRadius = 8.0;
}
