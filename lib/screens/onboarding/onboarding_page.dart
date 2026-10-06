import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../widgets/animated_marks.dart';
import '../../widgets/lottie_or_fallback.dart';

/// Content model for a single onboarding slide.
class OnboardingContent {
  final String lottieAsset;
  final IconData icon;
  final String overline;
  final String title;
  final String body;

  /// Backdrop gradient for this slide; the carousel lerps between them as
  /// the user swipes.
  final List<Color> gradient;

  const OnboardingContent({
    required this.lottieAsset,
    required this.icon,
    required this.overline,
    required this.title,
    required this.body,
    required this.gradient,
  });

  static const List<OnboardingContent> pages = [
    OnboardingContent(
      lottieAsset: 'assets/animations/onboarding_1.json',
      icon: Icons.photo_camera_rounded,
      overline: 'STEP ONE',
      title: 'Snap your pet',
      body:
          'Take up to three clear photos of what worries you — a paw, an eye, '
          'a patch of skin. That is all the AI needs to start.',
      gradient: [Color(0xFF10B981), Color(0xFF0B5F58)],
    ),
    OnboardingContent(
      lottieAsset: 'assets/animations/onboarding_2.json',
      icon: Icons.auto_awesome_rounded,
      overline: 'STEP TWO',
      title: 'AI reads the symptoms',
      body:
          'Add the symptoms you have noticed and a short description. Your '
          'photos and notes are analysed together in seconds.',
      gradient: [Color(0xFF0E9488), Color(0xFF0A4E63)],
    ),
    OnboardingContent(
      lottieAsset: 'assets/animations/onboarding_3.json',
      icon: Icons.assignment_turned_in_rounded,
      overline: 'STEP THREE',
      title: 'Get a vet-ready report',
      body:
          'Receive likely conditions, an urgency rating and home-care advice — '
          'clear enough to act on, detailed enough to show your vet.',
      gradient: [Color(0xFF0B7A6E), Color(0xFF062A25)],
    ),
  ];
}

/// A single slide: animated artwork, overline, headline, body.
class OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  /// Drives the parallax: 0 when centred, ±1 when a full page away.
  final double offset;

  const OnboardingPage({
    super.key,
    required this.content,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork drifts faster than the text, creating depth on swipe.
          Center(
            child: Transform.translate(
              offset: Offset(offset * -70, 0),
              child: LottieOrFallback(
                asset: content.lottieAsset,
                width: 190,
                height: 190,
                fallback: PulseMark(icon: content.icon, size: 190),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Transform.translate(
            offset: Offset(offset * -28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.overline,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.alpha(Colors.white, 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                Text(
                  content.title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  content.body,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.alpha(Colors.white, 0.8),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: AppDurations.slow),
    );
  }
}
