import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';
import 'gradient_card.dart';

/// The scan-balance summary at the top of the home screen — now carrying the
/// signature gradient, which makes it the visual anchor of the screen.
class ScanBalanceCard extends StatelessWidget {
  final int remainingScans;
  final VoidCallback onBuyTap;

  const ScanBalanceCard({
    super.key,
    required this.remainingScans,
    required this.onBuyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = remainingScans <= 0;

    return GradientCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.alpha(Colors.white, 0.18),
              borderRadius: AppRadius.brSm,
              border: Border.all(color: AppColors.alpha(Colors.white, 0.22)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCAN BALANCE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.alpha(Colors.white, 0.75),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$remainingScans',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isEmpty
                          ? 'left'
                          : 'scan${remainingScans == 1 ? '' : 's'} left',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BuyButton(onTap: onBuyTap, emphasised: isEmpty),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final VoidCallback onTap;

  /// When the balance is zero, the button flips to the sand accent so the
  /// blocked state is obvious before the user hits the scan wall.
  final bool emphasised;

  const _BuyButton({required this.onTap, required this.emphasised});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: emphasised
                ? AppColors.accent
                : AppColors.alpha(Colors.white, 0.95),
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            emphasised ? 'Top up' : 'Buy more',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: emphasised ? AppColors.ink : AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
