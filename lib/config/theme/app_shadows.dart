import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Elevation tokens. Replaces the hand-rolled `BoxShadow(black @2-8%, …)`
/// that was duplicated across ~10 widgets.
///
/// Shadows are tinted with [AppColors.ink] rather than pure black so
/// elevation reads as depth in the surrounding palette instead of grey haze.
class AppShadows {
  /// Barely-there lift, for chips and inputs.
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.alpha(AppColors.ink, 0.04),
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];

  /// Default card elevation — two layers: a tight contact shadow plus a
  /// wide diffuse one.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.alpha(AppColors.ink, 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.alpha(AppColors.ink, 0.06),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  /// For elements that float above content: the bottom nav, sticky bars.
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.alpha(AppColors.ink, 0.10),
      blurRadius: 32,
      offset: const Offset(0, 14),
    ),
  ];

  /// Coloured halo, for gradient CTAs and the splash logo mark.
  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
    BoxShadow(
      color: AppColors.alpha(color, opacity),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];
}
