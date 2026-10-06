import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/iap_service.dart';
import '../../widgets/primary_button.dart';

/// Google Play paywall for consumable scan packs.
///
/// Prices come from [ProductDetails.price], which Play localizes to the user's
/// currency — nothing about price is hardcoded here.
class BuyScansScreen extends StatefulWidget {
  const BuyScansScreen({super.key});

  @override
  State<BuyScansScreen> createState() => _BuyScansScreenState();
}

class _BuyScansScreenState extends State<BuyScansScreen> {
  StreamSubscription<IapEvent>? _eventSub;

  @override
  void initState() {
    super.initState();

    final provider = Provider.of<AppProvider>(context, listen: false);
    _eventSub = provider.iapEvents.listen(_onIapEvent);

    // The stream is already live from app start; this only refreshes the
    // catalogue if it failed to load earlier.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.iapAvailable && provider.iapProducts.isEmpty) {
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
        _toast(
          'Purchase pending — waiting for Google Play to confirm.',
          AppColors.primaryDark,
        );
        break;

      case IapEventType.success:
        _toast(
          'Purchase complete. ${event.scansGranted} scans added.',
          AppColors.criticalityLow,
        );
        // Let the toast land before leaving the screen.
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) Navigator.pop(context);
        });
        break;

      case IapEventType.failure:
        _toast(
          event.message ?? 'The purchase failed.',
          AppColors.criticalityEmergency,
        );
        break;

      case IapEventType.canceled:
        _toast('Purchase canceled.', AppColors.textMuted);
        break;
    }
  }

  void _toast(String message, Color background) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: background),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          // Blocked mid-purchase: leaving now would orphan the loading state.
          onPressed: provider.isPurchasing ? null : () => Navigator.pop(context),
        ),
        title: const Text('Buy scans'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        children: [
          Text('Top up your scans', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick a pack and get back to checking on your pet.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          if (provider.currentUser != null)
            Text(
              'Current balance: ${provider.currentUser!.remainingScans} scans',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primaryDark,
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          ..._buildBody(context, provider),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, AppProvider provider) {
    if (provider.iapProductsLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (!provider.iapAvailable || provider.iapProducts.isEmpty) {
      return [
        _ErrorPanel(
          message:
              provider.iapProductsError ??
              'The Play Store is not available on this device.',
          onRetry: () => provider.initIap().then((_) {
            if (provider.iapAvailable) provider.loadIapProducts();
          }),
        ),
      ];
    }

    return List.generate(provider.iapProducts.length, (index) {
      final product = provider.iapProducts[index];
      final pack = IapService.packFor(product.id);
      final isBusy = provider.purchasingProductId == product.id;

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _PackCard(
          title: pack?.title ?? product.title,
          scans: pack?.scans,
          // Localized, store-provided price string.
          price: product.price,
          isPopular: pack?.isPopular ?? false,
          isBusy: isBusy,
          // Only one purchase at a time.
          onSelect: provider.isPurchasing
              ? null
              : () => provider.buyScanPack(product),
        ),
      ).animate(delay: (index * 70).ms).fadeIn(
        duration: AppDurations.slow,
      ).moveY(begin: 16, end: 0, curve: Curves.easeOutCubic);
    });
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
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.alpha(AppColors.border, 0.8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Scan packs unavailable',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            text: 'Try again',
            expand: false,
            height: 46,
            variant: ButtonVariant.tonal,
            backgroundColor: AppColors.primary,
            textColor: AppColors.primaryDark,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// One purchasable pack. Mirrors the visual language of the Razorpay
/// `_PackageCard` so the two paywalls feel like the same app.
class _PackCard extends StatelessWidget {
  final String title;
  final int? scans;
  final String price;
  final bool isPopular;
  final bool isBusy;
  final VoidCallback? onSelect;

  const _PackCard({
    required this.title,
    required this.scans,
    required this.price,
    required this.isPopular,
    required this.isBusy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onGradient = isPopular ? Colors.white : AppColors.ink;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isPopular ? AppColors.gradientPrimary : null,
        color: isPopular ? null : AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: isPopular
            ? null
            : Border.all(color: AppColors.alpha(AppColors.border, 0.8)),
        boxShadow: isPopular
            ? AppShadows.glow(AppColors.teal, opacity: 0.3)
            : AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onGradient,
                        ),
                      ),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text(
                          'POPULAR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.ink,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (scans != null)
                  Text(
                    '$scans scans',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isPopular
                          ? AppColors.alpha(Colors.white, 0.8)
                          : AppColors.textMuted,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  price,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: onGradient,
                    fontSize: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          PrimaryButton(
            text: 'Buy',
            expand: false,
            height: 46,
            isLoading: isBusy,
            variant: isPopular ? ButtonVariant.filled : ButtonVariant.tonal,
            backgroundColor: isPopular ? Colors.white : AppColors.primary,
            textColor: AppColors.primaryDark,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}
