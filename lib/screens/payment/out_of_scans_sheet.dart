import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../profile/referral_card.dart';
import 'paywall_screen.dart';

/// Shown when a scan is attempted with no credits: the best options first,
/// never a dead end.
class OutOfScansSheet extends StatelessWidget {
  final String? petName;

  const OutOfScansSheet({super.key, this.petName});

  static Future<void> show(BuildContext context, {String? petName}) {
    track('out_of_scans_view');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => OutOfScansSheet(petName: petName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final offers = provider.plusOffers;
    final trialOffer = offers.where((o) => o.hasTrial).firstOrNull ?? offers.firstOrNull;
    final starter = provider.packProducts
        .where((p) => p.id == IapService.packs.first.productId)
        .firstOrNull;
    final weekly = provider.currentUser?.freeWeeklyScans ?? 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.brPill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("You've used your free scans", style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your photos and notes are still here. Pick an option to see '
              '${petName ?? 'your pet'}\'s report.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),

            if (trialOffer != null) ...[
              _Option(
                highlighted: true,
                badge: 'BEST VALUE',
                title: trialOffer.hasTrial
                    ? 'Try PetCare Plus free for ${trialOffer.trialDays} days'
                    : 'Get PetCare Plus',
                subtitle: trialOffer.hasTrial
                    ? 'Unlimited scans and AI Vet chat. Then ${trialOffer.recurringPrice}/${trialOffer.plan.period}. Cancel anytime in Google Play.'
                    : 'Unlimited scans and AI Vet chat from ${trialOffer.recurringPrice}/${trialOffer.plan.period}.',
                onTap: () {
                  Navigator.pop(context);
                  PaywallScreen.open(context, source: 'out_of_scans');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            _Option(
              title: 'Buy ${IapService.packs.first.scans} scans',
              subtitle: 'One-time · never expire',
              trailing: starter?.price,
              onTap: () {
                if (starter != null) {
                  provider.buyScanPack(starter);
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                  PaywallScreen.open(context, source: 'out_of_scans', tab: PaywallTab.packs);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            if (provider.currentUser?.referralCode != null)
              _Option(
                title: 'Invite a friend',
                subtitle: 'You both get 2 free scans',
                trailing: 'Share',
                onTap: () => ReferralCard.share(context, provider.currentUser!.referralCode!),
              ),

            const SizedBox(height: AppSpacing.md),
            Text(
              'Free users get $weekly free scan${weekly == 1 ? '' : 's'} every Monday.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final String? badge;
  final bool highlighted;
  final VoidCallback onTap;

  const _Option({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.badge,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = highlighted ? Colors.white : AppColors.textDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: highlighted ? AppColors.gradientHero : null,
            color: highlighted ? null : AppColors.surfaceElevated,
            borderRadius: AppRadius.brMd,
            border: highlighted ? null : Border.all(color: AppColors.alpha(AppColors.border, 0.9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null)
                      Text(badge!, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.accent)),
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(color: fg)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: highlighted ? AppColors.alpha(Colors.white, 0.9) : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(trailing!, style: theme.textTheme.titleLarge?.copyWith(color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
