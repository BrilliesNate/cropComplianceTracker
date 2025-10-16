import 'package:flutter/material.dart';
import 'theme_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: ThemeConstants.primaryColor,
      colorScheme: ColorScheme.light(
        primary: ThemeConstants.primaryColor,
        secondary: ThemeConstants.accentColor,
        background: ThemeConstants.lightBackgroundColor,
      ),
      scaffoldBackgroundColor: ThemeConstants.lightBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeConstants.primaryColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: ThemeConstants.primaryColor,
      colorScheme: ColorScheme.dark(
        primary: ThemeConstants.primaryColor,
        secondary: ThemeConstants.accentColor,
        background: ThemeConstants.darkBackgroundColor,
      ),
      scaffoldBackgroundColor: ThemeConstants.darkBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: ThemeConstants.darkAppBarColor,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConstants.primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}