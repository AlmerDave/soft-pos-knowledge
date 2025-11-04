import 'package:flutter/material.dart';

/// Centralized color palette for the entire app
/// Easy to modify and create theme variants
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============= PRIMARY COLORS =============
  static const Color primary = Color(0xFF667eea);
  static const Color primaryPurple = Color(0xFF667eea);
  static const Color secondary = Color(0xFF764ba2);
  static const Color primaryDeepPurple = Color(0xFF764ba2);
  
  // ============= GRADIENT COLORS =============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryDeepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============= SEMANTIC COLORS =============
  static const Color success = Color(0xFF10b981);
  static const Color error = Color(0xFFef4444);
  static const Color warning = Color(0xFFfbbf24);
  static const Color info = Color(0xFF3b82f6);

  // ============= NEUTRAL COLORS =============
  static const Color textPrimary = Color(0xFF1a1a1a);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  static const Color backgroundTertiary = Color(0xFFF5F5F5);
  
  static const Color surface = Color(0xFFF9FAFB);
  
  static const Color border = Color(0xFFe0e0e0);
  static const Color borderLight = Color(0xFFf0f0f0);
  
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color overlay = Color(0x66000000);

  // ============= NFC ANIMATION COLORS =============
  static const Color nfcWave = primaryPurple;
  static const Color nfcIcon = primaryPurple;
  
  // ============= LOG COLORS =============
  static const Color logBackground = Color(0xFF1a1a1a);
  static const Color logText = Color(0xFFFFFFFF);
  static const Color logLoading = warning;
  static const Color logSuccess = success;
  static const Color logInfo = info;

  // ============= SHADOW COLORS =============
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowMedium = Colors.black.withOpacity(0.15);
  static Color shadowStrong = Colors.black.withOpacity(0.25);

  // ============= DARK MODE COLORS =============
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
}