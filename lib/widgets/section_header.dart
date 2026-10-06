import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';

/// A consistent section title, replacing the ad-hoc heading `Text` widgets
/// that were previously written inline on every screen.
///
/// Optionally renders a numbered badge, used by the scan form's step cards.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final int? step;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.step,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (step != null) ...[
            _StepBadge(step: step!),
            const SizedBox(width: AppSpacing.md),
          ] else if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.brSm,
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;

  const _StepBadge({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$step',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
