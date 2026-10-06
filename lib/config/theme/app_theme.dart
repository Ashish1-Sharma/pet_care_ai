import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The single source of truth for app-wide styling.
///
/// Replaces the inline `ThemeData` that used to live in `main.dart`, and
/// centralises the input decoration that was previously duplicated in
/// `pet_selector.dart` and `scan_tab.dart`.
class AppTheme {
  static ThemeData get light {
    final textTheme = AppTypography.build();

    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textDark,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: textTheme.headlineSmall,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),

      // Shared input styling for every TextField / DropdownButtonFormField.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textLight),
        labelStyle: textTheme.titleSmall,
        floatingLabelStyle: textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.criticalityEmergency),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(
            color: AppColors.criticalityEmergency,
            width: 1.8,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.alpha(AppColors.primary, 0.5),
          elevation: 0,
          minimumSize: const Size.fromHeight(58),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelMedium,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(58),
          textStyle: textTheme.labelLarge,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: textTheme.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceSunken,
        circularTrackColor: AppColors.surfaceSunken,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Standard decoration for an elevated white surface.
  static BoxDecoration surfaceCard({
    double radius = AppRadius.lg,
    Color? color,
    bool bordered = true,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(radius),
      border: bordered
          ? Border.all(color: AppColors.alpha(AppColors.border, 0.7))
          : null,
      boxShadow: AppShadows.card,
    );
  }
}
