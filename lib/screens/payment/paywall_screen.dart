import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../widgets/primary_button.dart';
import 'purchase_success_screen.dart';

enum PaywallTab { plus, packs }

/// PetCare Plus subscription and scan packs, sold through Google Play.
/// Prices always come from Play, localized to the buyer's currency.
class PaywallScreen extends StatefulWidget {
  final PaywallTab initialTab;
  final String source;

  const PaywallScreen({super.key, this.initialTab = PaywallTab.plus, this.source = 'unknown'});

  static Future<void> open(
    BuildContext context, {
    required String source,
    PaywallTab tab = PaywallTab.plus,
  }) {
    return Navigator.push(
      context,
      AppRoutes.modalRise(PaywallScreen(initialTab: tab, source: source)),
    );
  }

  /// "$0.58" from a recurring price, keeping the store's currency symbol.
  static String perUnit(String formattedPrice, double raw, double divisor) {
    final symbol = formattedPrice.replaceAll(RegExp(r'[\d.,\s]'), '');
    return '$symbol${(raw / divisor).toStringAsFixed(2)}';
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late PaywallTab _tab = widget.initialTab;
  String? _selectedPlan = IapService.plans.first.productId;
  String _selectedPack = 'scans_popular_25';
  StreamSubscription<IapEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    track('paywall_view', {'source': widget.source, 'tab': widget.initialTab.name});
    final provider = Provider.of<AppProvider>(context, listen: false);
    _eventSub = provider.iapEvents.listen(_onIapEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!provider.iapAvailable) {
        provider.initIap();
      } else if (provider.packProducts.isEmpty && provider.plusOffers.isEmpty) {
        provider.loadIapProducts();
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _onIapEvent(IapEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case IapEventType.pending:
        _toast('Purchase pending — waiting for Google Play to confirm.', AppColors.primaryDark);
        break;
      case IapEventType.success:
        _toast('Purchase complete. ${event.scansGranted} scans added.', AppColors.criticalityLow);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.pop(context);
        });
        break;
      case IapEventType.subscribed:
        Navigator.pushReplacement(
          context,
          AppRoutes.fadeThrough(const PurchaseSuccessScreen()),
        );
        break;
      case IapEventType.restored:
        _toast(
          event.isPlus ? 'PetCare Plus restored.' : 'No active subscription found on this Google account.',
          event.isPlus ? AppColors.criticalityLow : AppColors.textMuted,
        );
        break;
      case IapEventType.failure:
        _toast(event.message ?? 'The purchase failed.', AppColors.criticalityEmergency);
        break;
      case IapEventType.canceled:
        _toast('Purchase canceled.', AppColors.textMuted);
        break;
    }
  }

  void _toast(String message, Color background) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: background));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final offers = provider.plusOffers;
    final packs = provider.packProducts;
    final petName = provider.selectedPet?.name ?? 'your pet';

    // Without subscription products in Play yet, only packs can be sold.
    final showPlus = offers.isNotEmpty;
    final tab = showPlus ? _tab : PaywallTab.packs;

    PlusOffer? selectedOffer = offers.where((o) => o.plan.productId == _selectedPlan).firstOrNull;
    selectedOffer ??= offers.isEmpty ? null : offers.first;
    final selectedPack = packs.where((p) => p.id == _selectedPack).firstOrNull ??
        (packs.isEmpty ? null : packs.first);

    if (provider.isPlus) return _AlreadyPlus(plan: provider.currentUser?.plan);

    final String ctaText;
    final String finePrint;
    VoidCallback? onBuy;
    if (tab == PaywallTab.plus && selectedOffer != null) {
      final offer = selectedOffer;
      if (offer.hasTrial) {
        ctaText = 'Start ${offer.trialDays}-day free trial';
        finePrint = 'Free for ${offer.trialDays} days, then ${offer.recurringPrice} per ${offer.plan.period}. '
            'Auto-renews until cancelled in Google Play › Subscriptions. '
            'Cancel before the trial ends to pay nothing.';
      } else {
        ctaText = 'Subscribe · ${offer.recurringPrice}/${offer.plan.period == 'year' ? 'yr' : 'wk'}';
        finePrint = 'Billed ${offer.recurringPrice} every ${offer.plan.period}. '
            'Auto-renews until cancelled in Google Play › Subscriptions.';
      }
      onBuy = () => provider.buyPlus(offer);
    } else if (selectedPack != null) {
      final pack = IapService.packFor(selectedPack.id);
      ctaText = 'Buy ${pack?.title ?? selectedPack.title} · ${selectedPack.price}';
      finePrint = 'One-time purchase through Google Play. Scans never expire.';
      onBuy = () => provider.buyScanPack(selectedPack);
    } else {
      ctaText = 'Loading…';
      finePrint = '';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: provider.isPurchasing ? null : () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: provider.isPurchasing ? null : () => provider.restorePurchases(),
            child: const Text('Restore purchases'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
        children: [
          Text('Peace of mind for $petName', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A single vet visit can cost a lot. Know first whether you need one.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (showPlus) ...[
            _Tabs(
              tab: tab,
              onChanged: (t) {
                setState(() => _tab = t);
                track('paywall_tab', {'tab': t.name});
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          if (provider.iapProductsLoading && offers.isEmpty && packs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (offers.isEmpty && packs.isEmpty)
            _ErrorPanel(
              message: provider.iapProductsError ?? 'The Play Store is not available on this device.',
              onRetry: () => provider.initIap().then((_) => provider.loadIapProducts()),
            )
          else if (tab == PaywallTab.plus) ...[
            const _Benefits(),
            const SizedBox(height: AppSpacing.md),
            for (final offer in offers) ...[
              _OptionCard(
                selected: offer.plan.productId == selectedOffer?.plan.productId,
                title: offer.plan.title,
                subtitle: offer.hasTrial
                    ? '${offer.trialDays} days free, then ${PaywallScreen.perUnit(offer.recurringPrice, offer.recurringRaw, offer.plan.period == 'year' ? 52 : 1)}/week'
                    : offer.plan.period == 'week'
                        ? 'Cancel anytime'
                        : '${PaywallScreen.perUnit(offer.recurringPrice, offer.recurringRaw, 52)}/week',
                price: '${offer.recurringPrice}/${offer.plan.period == 'year' ? 'yr' : 'wk'}',
                badge: _savingsBadge(offer, offers),
                onTap: () => setState(() => _selectedPlan = offer.plan.productId),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ] else ...[
            for (final product in packs) ...[
              _OptionCard(
                selected: product.id == selectedPack?.id,
                title: IapService.packFor(product.id)?.title ?? product.title,
                subtitle: '${PaywallScreen.perUnit(product.price, product.rawPrice, (IapService.packFor(product.id)?.scans ?? 1).toDouble())} per scan',
                price: product.price,
                badge: IapService.packFor(product.id)?.badge,
                onTap: () => setState(() => _selectedPack = product.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Packs never expire. AI Vet chat stays at '
              '${provider.currentUser?.chatDailyLimit ?? 5} free messages a day.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.surfaceElevated, boxShadow: AppShadows.floating),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  text: ctaText,
                  isLoading: provider.isPurchasing,
                  onPressed: onBuy,
                ),
                if (finePrint.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(finePrint, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                ],
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(AppConfig.privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _savingsBadge(PlusOffer offer, List<PlusOffer> offers) {
    if (offer.plan.period != 'year') return null;
    final weekly = offers.where((o) => o.plan.period == 'week').firstOrNull;
    if (weekly == null || weekly.recurringRaw <= 0) return 'BEST VALUE';
    final saving = 1 - offer.recurringRaw / (weekly.recurringRaw * 52);
    if (saving <= 0.05) return 'BEST VALUE';
    return 'SAVE ${(saving * 100).round()}%';
  }
}

class _Tabs extends StatelessWidget {
  final PaywallTab tab;
  final ValueChanged<PaywallTab> onChanged;

  const _Tabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget segment(PaywallTab value, String label) {
      final selected = tab == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceElevated : Colors.transparent,
              borderRadius: AppRadius.brPill,
              boxShadow: selected ? AppShadows.soft : null,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected ? AppColors.ink : AppColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: AppRadius.brPill),
      child: Row(
        children: [
          segment(PaywallTab.plus, 'PetCare Plus'),
          segment(PaywallTab.packs, 'Scan packs'),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    const items = ['Unlimited scans', 'Unlimited AI Vet', 'Recovery tracking', 'Up to 10 pets'];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: AppRadius.brMd),
      child: Wrap(
        runSpacing: AppSpacing.sm,
        children: [
          for (final item in items)
            FractionallySizedBox(
              widthFactor: 0.5,
              child: Row(
                children: [
                  const Icon(Icons.check_rounded, size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 6),
                  Flexible(child: Text(item, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textDark))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final VoidCallback onTap;

  const _OptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: selected ? AppColors.primaryDark : AppColors.alpha(AppColors.border, 0.9),
                width: 2,
              ),
              boxShadow: selected ? AppShadows.glow(AppColors.primary, opacity: 0.15) : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.primaryDark : AppColors.textLight,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: theme.textTheme.titleLarge),
                    if (badge != null)
                      Text(
                        badge!,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primaryDark),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: AppRadius.brLg),
      child: Column(
        children: [
          const Icon(Icons.storefront_outlined, size: 40, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text('Store unavailable', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: 'Try again',
            expand: false,
            height: 46,
            variant: ButtonVariant.tonal,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the offers when Plus is already active.
class _AlreadyPlus extends StatelessWidget {
  final PlanInfo? plan;

  const _AlreadyPlus({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productId = plan?.productId ?? IapService.plans.first.productId;
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.primaryDark),
            const SizedBox(height: AppSpacing.md),
            Text("You're on PetCare Plus", style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Unlimited scans and AI Vet chat are on.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Manage in Google Play',
              variant: ButtonVariant.tonal,
              onPressed: () => launchUrl(
                Uri.parse(AppConfig.manageSubscriptionUrl(productId)),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
