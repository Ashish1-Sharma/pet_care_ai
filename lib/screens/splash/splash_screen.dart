import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/animated_marks.dart';
import '../../widgets/mint_backdrop.dart';
import '../login/login_screen.dart';
import '../home/navigation_container.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Auth resolution and the intro animation run concurrently — the animation
  /// is a floor on how long the splash shows, not an added delay. (It
  /// previously awaited a hard 1800 ms *before* even starting the auth check.)
  Future<void> _bootstrap() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final storage = StorageService();

    final results = await Future.wait([
      Future(() async {
        final seenOnboarding = await storage.hasSeenOnboarding();
        await provider.checkAuthStatus();
        return seenOnboarding;
      }),
      Future.delayed(AppDurations.splashFloor),
    ]);

    if (!mounted) return;

    // Start the Play billing connection and the purchase stream listener.
    // Deliberately not awaited: it must not delay the splash, and its real job
    // is to pick up purchases that were interrupted on a previous run.
    unawaited(provider.initIap());

    final seenOnboarding = results[0] as bool;

    final Widget next;
    if (!seenOnboarding) {
      next = const OnboardingScreen();
    } else if (provider.isAuthenticated) {
      next = const NavigationContainer();
    } else {
      next = const LoginScreen();
    }

    Navigator.pushReplacement(context, AppRoutes.fadeThrough(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The backdrop is light now, so the status bar icons must be dark.
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: MintBackdrop.top,
        body: MintBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                Image.asset(
                      'assets/logo.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (context, error, stack) => const PulseMark(size: 160),
                    )
                    .animate()
                    .fadeIn(duration: AppDurations.slow)
                    .scale(
                      duration: AppDurations.slow,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.85, 0.85),
                    ),

                const SizedBox(height: AppSpacing.lg),

                // Two-tone wordmark: dark "Pet", brand-green "Scan AI".
                Text.rich(
                      TextSpan(
                        style: theme.textTheme.displayMedium,
                        children: [
                          const TextSpan(text: 'Pet '),
                          TextSpan(
                            text: 'Scan AI',
                            style: TextStyle(color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .moveY(begin: 14, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: AppSpacing.sm),

                Text(
                      'Instant AI pet health scanner',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    )
                    .animate(delay: 340.ms)
                    .fadeIn(duration: 500.ms)
                    .moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),

                const Spacer(flex: 4),

                // Indeterminate progress hairline.
                SizedBox(
                  width: 300,
                  child: ClipRRect(
                    borderRadius: AppRadius.brPill,
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      backgroundColor: AppColors.alpha(AppColors.border, 0.9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDark,
                      ),
                    ),
                  ),
                ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
