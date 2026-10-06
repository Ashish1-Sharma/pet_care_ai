import 'package:flutter/material.dart';
import 'theme/app_spacing.dart';

/// Shared page transitions.
///
/// The app has no router — every navigation is an imperative
/// `Navigator.push` with an inline `MaterialPageRoute`. These builders give
/// those call sites a consistent motion language without pulling in
/// `go_router`.
class AppRoutes {
  /// Cross-fade with a gentle scale. For root-level swaps: splash →
  /// onboarding → login → home.
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: AppDurations.slow,
      reverseTransitionDuration: AppDurations.medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 1.04, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Horizontal shared-axis slide. For forward navigation within a flow:
  /// scan → result, history → result, profile → payment.
  static Route<T> sharedAxis<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: AppDurations.medium,
      reverseTransitionDuration: AppDurations.medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final incoming =
            Tween<Offset>(
              begin: const Offset(0.22, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final outgoing =
            Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.12, 0),
            ).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOutCubic,
              ),
            );
        return SlideTransition(
          position: outgoing,
          child: SlideTransition(
            position: incoming,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }

  /// Vertical rise, for modal-feeling destinations.
  static Route<T> modalRise<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: AppDurations.medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}
