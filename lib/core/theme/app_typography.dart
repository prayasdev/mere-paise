import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography definitions adhering strictly to the PRD:
/// - Wordmark: Blackletter / ornamental serif (Cinzel Decorative)
/// - Headings: High-contrast architectural serif (Cormorant Garamond / Cinzel)
/// - UI & Body: Sturdy humanist sans (Source Sans 3, w500/w600 for sharp legibility)
/// - Numbers: Monospaced tabular lining figures (IBM Plex Mono, w600)
class AppTypography {
  AppTypography._();

  // Wordmark
  static TextStyle wordmark({
    BuildContext? context,
    Color? color,
    double fontSize = 24,
  }) {
    return GoogleFonts.cinzelDecorative(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      color: color ?? AppColors.brass,
    );
  }

  // Headings
  static TextStyle headingLarge({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.cormorantGaramond(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: effective,
      height: 1.2,
    );
  }

  static TextStyle headingMedium({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: effective,
      height: 1.25,
    );
  }

  static TextStyle headingSmall({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.cormorantGaramond(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: effective,
    );
  }

  // Small-caps gothic section labels
  static TextStyle labelGothic({
    BuildContext? context,
    Color? color,
    double fontSize = 12,
  }) {
    final effective = color ?? (context != null ? AppColors.textSecondary(context) : null);
    return GoogleFonts.cinzel(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.3,
      color: effective,
    );
  }

  // Body & UI text (Enhanced with w500 / w600 for crisp, anti-aliased readability)
  static TextStyle bodyLarge({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.sourceSans3(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: effective,
    );
  }

  static TextStyle bodyMedium({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.sourceSans3(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: effective,
    );
  }

  static TextStyle bodySmall({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textSecondary(context) : null);
    return GoogleFonts.sourceSans3(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: effective,
    );
  }

  // Numbers (Tabular lining figures)
  static TextStyle amountKeypad({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.ibmPlexMono(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: effective,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle amountLarge({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.ibmPlexMono(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: effective,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle amountMedium({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.ibmPlexMono(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: effective,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle amountSmall({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textSecondary(context) : null);
    return GoogleFonts.ibmPlexMono(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: effective,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextStyle amountInline({
    BuildContext? context,
    Color? color,
  }) {
    final effective = color ?? (context != null ? AppColors.textPrimary(context) : null);
    return GoogleFonts.ibmPlexMono(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: effective,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
