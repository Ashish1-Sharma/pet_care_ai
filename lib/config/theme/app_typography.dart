import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale built on Plus Jakarta Sans.
///
/// Previously `main.dart` set `fontFamily: 'Inter'` on six styles, but no
/// font files were ever bundled — every style silently fell back to Roboto.
/// Sourcing the family through `google_fonts` fixes that.
class AppTypography {
  static TextTheme build() {
    final base = GoogleFonts.plusJakartaSansTextTheme();

    return base.copyWith(
      // Display — splash wordmark, onboarding headlines, login hero.
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 44,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        color: AppColors.ink,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 36,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.ink,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.ink,
      ),

      // Headline — screen titles, hero verdicts.
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.ink,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),

      // Title — section headers, card titles.
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: AppColors.textDark,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),

      // Body.
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        color: AppColors.textDark,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.55,
        color: AppColors.textMuted,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.5,
        color: AppColors.textLight,
      ),

      // Label — buttons, chips, nav, overlines.
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: AppColors.textLight,
      ),
    );
  }
}
