import 'package:flutter/material.dart';

/// Design tokens for colour.
///
/// The original emerald/slate names are preserved so existing screens keep
/// compiling; the tokens below `// --- New visual language ---` are the bold
/// restyle additions.
class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFD1FAE5);

  // Neutral Colors
  static const Color background = Color(0xFFF6F8F7);
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1F2937); // Slate 800
  static const Color textMuted = Color(0xFF6B7280); // Slate 500
  static const Color textLight = Color(0xFF9CA3AF); // Slate 400
  static const Color border = Color(0xFFE5E7EB);

  // Criticality Colors
  static const Color criticalityLow = Color(0xFF10B981); // Green
  static const Color criticalityModerate = Color(0xFFFBBF24); // Yellow
  static const Color criticalityHigh = Color(0xFFF97316); // Orange
  static const Color criticalityEmergency = Color(0xFFEF4444); // Red

  // Severity background tints
  static const Color criticalityLowBg = Color(0xFFECFDF5);
  static const Color criticalityModerateBg = Color(0xFFFEF3C7);
  static const Color criticalityHighBg = Color(0xFFFFEDD5);
  static const Color criticalityEmergencyBg = Color(0xFFFEE2E2);

  // --- New visual language ---

  /// Deep teal-ink. Used for display headings and dark gradient stops.
  static const Color ink = Color(0xFF062A25);
  static const Color inkSoft = Color(0xFF0E4A40);

  /// Warm sand accent, for highlights and secondary CTAs.
  static const Color accent = Color(0xFFFFB37B);
  static const Color accentDark = Color(0xFFF08A3E);
  static const Color accentLight = Color(0xFFFFF1E4);

  /// Teal partner to [primary] — the second stop of the signature gradient.
  static const Color teal = Color(0xFF0E9488);

  /// Layered surfaces.
  static const Color surface = Color(0xFFF6F8F7);
  static const Color surfaceElevated = Colors.white;
  static const Color surfaceSunken = Color(0xFFEFF3F1);
  static const Color overlayScrim = Color(0xCC062A25);

  /// Signature emerald → teal gradient. The strongest "new app" signal;
  /// used on splash, primary CTA, balance card and report hero.
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, teal],
  );

  /// Deeper variant for full-bleed backdrops (splash, login header).
  static const LinearGradient gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF0E9488), Color(0xFF0B5F58)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );

  /// Severity → gradient, for the report hero.
  static LinearGradient gradientForCriticality(Color base) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [base, Color.lerp(base, ink, 0.45)!],
    );
  }

  /// Convenience: opacity without the deprecated `withOpacity`.
  static Color alpha(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }
}
