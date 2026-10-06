import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';
import 'primary_button.dart';

/// Illustration + copy + optional CTA. Used for empty history and for the
/// zero-scan-balance state, so "nothing here" reads as designed rather than
/// broken.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.alpha(AppColors.primary, 0.16),
                    AppColors.alpha(AppColors.teal, 0.05),
                  ],
                ),
              ),
              child: Icon(icon, size: 46, color: AppColors.primary),
            ).animate().scale(
              duration: AppDurations.slow,
              curve: Curves.easeOutBack,
              begin: const Offset(0.7, 0.7),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ).animate().fadeIn(duration: AppDurations.slow).moveY(begin: 14, end: 0),
      ),
    );
  }
}
