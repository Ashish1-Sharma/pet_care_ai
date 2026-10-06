import 'package:flutter/widgets.dart';

/// Spacing and shape scale. Replaces the per-widget hardcoded paddings and
/// radii that were previously re-invented on every screen.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Standard horizontal page gutter.
  static const double gutter = 20;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: gutter);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardTight = EdgeInsets.all(md);

  // Vertical rhythm helpers — terser than SizedBox at call sites.
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
}

/// Corner radius scale. The bold restyle pushes cards to 28.
class AppRadius {
  static const double sm = 12;
  static const double md = 20;
  static const double lg = 28;
  static const double pill = 100;

  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brLg = BorderRadius.circular(lg);
  static final BorderRadius brPill = BorderRadius.circular(pill);

  /// Top-only large radius, for sheets rising from the bottom.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

/// Shared motion durations, so timing feels coherent across screens.
class AppDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration stagger = Duration(milliseconds: 70);

  /// Minimum time the splash stays up, regardless of how fast auth resolves.
  static const Duration splashFloor = Duration(milliseconds: 2000);
}
