import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Common decorations, borders, shadows used throughout the app
class AppDecorations {
  AppDecorations._();

  // ============= BORDER RADIUS =============
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 15.0;
  static const double radiusXLarge = 20.0;
  static const double radiusRound = 999.0;

  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);

  // ============= SHADOWS =============
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: AppColors.shadow,
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: AppColors.shadowMedium,
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: AppColors.shadowStrong,
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  // Primary button shadow
  static List<BoxShadow> get shadowPrimary => [
    BoxShadow(
      color: AppColors.primaryPurple.withOpacity(0.4),
      offset: const Offset(0, 4),
      blurRadius: 15,
      spreadRadius: 0,
    ),
  ];

  // ============= COMMON DECORATIONS =============
  
  // Card decoration
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.cardBackground,
    borderRadius: borderRadiusLarge,
    boxShadow: shadowSmall,
  );

  // Gradient decoration
  static BoxDecoration get gradientPrimary => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: borderRadiusLarge,
    boxShadow: shadowPrimary,
  );

  // Info card decoration
  static BoxDecoration get infoCard => BoxDecoration(
    color: AppColors.primaryPurple.withOpacity(0.1),
    borderRadius: borderRadiusMedium,
    border: const Border(
      left: BorderSide(color: AppColors.primaryPurple, width: 4),
    ),
  );

  // Receipt card decoration
  static BoxDecoration get receiptCard => BoxDecoration(
    color: AppColors.backgroundSecondary,
    borderRadius: borderRadiusLarge,
    border: Border.all(color: AppColors.border, width: 2),
  );
}