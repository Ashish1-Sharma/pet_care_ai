import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// One purchasable scan pack, as configured in Google Play Console.
///
/// [scans] mirrors the server-side map in `models/pet.iap.purchase.js` and is
/// used for display only — the backend is the authority on how many scans a
/// product actually grants, so the client never sends a scan count.
class ScanPack {
  final String productId;
  final String title;
  final int scans;
  final bool isPopular;
  final String? badge;

  const ScanPack({
    required this.productId,
    required this.title,
    required this.scans,
    this.isPopular = false,
    this.badge,
  });
}

/// A PetCare Plus subscription, configured in Play Console as its own
/// subscription product. The yearly one carries a free-trial offer whose ID
/// contains "trial" (see the server's pet.billing.js).
class PlusPlan {
  final String productId;
  final String title;

  /// "year" or "week", for per-period copy.
  final String period;
  final bool isBestValue;

  const PlusPlan({
    required this.productId,
    required this.title,
    required this.period,
    this.isBestValue = false,
  });
}

/// Store details for a [PlusPlan]: the offer to buy and its prices.
class PlusOffer {
  final PlusPlan plan;
  final ProductDetails product;

  /// The recurring price, e.g. "$29.99", even when a free trial comes first.
  final String recurringPrice;
  final double recurringRaw;
  final String currencyCode;

  /// Free-trial length in days, or 0 when the offer has no trial.
  final int trialDays;

  const PlusOffer({
    required this.plan,
    required this.product,
    required this.recurringPrice,
    required this.recurringRaw,
    required this.currencyCode,
    required this.trialDays,
  });

  bool get hasTrial => trialDays > 0;
}

/// Thin wrapper around [InAppPurchase] so the provider never touches the
/// plugin directly and the product catalogue lives in one place.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  /// Consumable products configured in Google Play Console.
  static const List<ScanPack> packs = [
    ScanPack(productId: 'scans_starter_5', title: '5 scans', scans: 5),
    ScanPack(
      productId: 'scans_popular_25',
      title: '25 scans',
      scans: 25,
      isPopular: true,
      badge: 'POPULAR',
    ),
    ScanPack(
      productId: 'scans_value_100',
      title: '100 scans',
      scans: 100,
      badge: 'BEST PRICE',
    ),
  ];

  /// Subscription products configured in Google Play Console.
  static const List<PlusPlan> plans = [
    PlusPlan(
      productId: 'petcare_plus_yearly',
      title: 'Yearly',
      period: 'year',
      isBestValue: true,
    ),
    PlusPlan(productId: 'petcare_plus_weekly', title: 'Weekly', period: 'week'),
  ];

  static Set<String> get productIds => {
    ...packs.map((pack) => pack.productId),
    ...plans.map((plan) => plan.productId),
  };

  static bool isSubscription(String productId) =>
      plans.any((plan) => plan.productId == productId);

  static ScanPack? packFor(String productId) {
    for (final pack in packs) {
      if (pack.productId == productId) return pack;
    }
    return null;
  }

  /// Purchase updates, including unfinished purchases replayed on app start.
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<bool> isAvailable() => _iap.isAvailable();

  /// Fetches localized titles and prices from the store.
  ///
  /// Throws when the store returns an error; product IDs the store does not
  /// recognise come back in [ProductDetailsResponse.notFoundIDs] and are
  /// reported by the caller rather than silently dropped.
  Future<ProductDetailsResponse> queryProducts() =>
      _iap.queryProductDetails(productIds);

  /// Picks, for each subscription, the offer to show: the free-trial offer
  /// when Play returns one (Play only returns offers the user is eligible
  /// for), otherwise the base plan.
  static List<PlusOffer> plusOffers(List<ProductDetails> details) {
    final offers = <PlusOffer>[];
    for (final plan in plans) {
      final candidates = details.where((d) => d.id == plan.productId).toList();
      if (candidates.isEmpty) continue;

      PlusOffer? best;
      for (final product in candidates) {
        final offer = _toOffer(plan, product);
        if (best == null || offer.trialDays > best.trialDays) best = offer;
      }
      offers.add(best!);
    }
    return offers;
  }

  static PlusOffer _toOffer(PlusPlan plan, ProductDetails product) {
    if (product is GooglePlayProductDetails &&
        product.subscriptionIndex != null &&
        product.productDetails.subscriptionOfferDetails != null) {
      final offer = product.productDetails
          .subscriptionOfferDetails![product.subscriptionIndex!];
      final phases = offer.pricingPhases;
      final recurring = phases.last;
      final trial = phases.firstWhere(
        (p) => p.priceAmountMicros == 0,
        orElse: () => recurring,
      );
      return PlusOffer(
        plan: plan,
        product: product,
        recurringPrice: recurring.formattedPrice,
        recurringRaw: recurring.priceAmountMicros / 1000000.0,
        currencyCode: recurring.priceCurrencyCode,
        trialDays: identical(trial, recurring)
            ? 0
            : _periodDays(trial.billingPeriod) * trial.billingCycleCount.clamp(1, 12),
      );
    }
    return PlusOffer(
      plan: plan,
      product: product,
      recurringPrice: product.price,
      recurringRaw: product.rawPrice,
      currencyCode: product.currencyCode,
      trialDays: 0,
    );
  }

  /// ISO-8601 period ("P3D", "P1W", "P1M") to an approximate day count.
  static int _periodDays(String period) {
    final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
    if (match == null) return 0;
    final n = int.parse(match.group(1)!);
    switch (match.group(2)) {
      case 'D':
        return n;
      case 'W':
        return n * 7;
      case 'M':
        return n * 30;
      default:
        return n * 365;
    }
  }

  /// Starts the Play purchase sheet. The result arrives on [purchaseStream].
  ///
  /// `autoConsume` is true so the consumable is immediately consumable again —
  /// this is what lets the same pack be bought repeatedly.
  Future<bool> buy(ProductDetails product) => _iap.buyConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
    autoConsume: true,
  );

  /// Starts a subscription purchase for the chosen offer. Subscriptions are
  /// acknowledged (never consumed) once the server has verified them.
  Future<bool> buySubscription(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  /// Re-delivers owned subscriptions as `restored` events on [purchaseStream].
  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Tells the store the purchase has been delivered. Must be called for every
  /// purchase whose [PurchaseDetails.pendingCompletePurchase] is true, including
  /// errored and canceled ones, or Play will keep replaying it.
  Future<void> complete(PurchaseDetails purchase) =>
      _iap.completePurchase(purchase);

  /// Explicitly consumes an Android purchase so the pack can be bought again.
  ///
  /// This is not redundant with `autoConsume`. The plugin tracks auto-consume in
  /// an in-memory set populated by [buy], so a purchase that is *resumed* on the
  /// next app start (the app was killed mid-purchase) is never auto-consumed —
  /// `completePurchase` only *acknowledges* it. An acknowledged-but-unconsumed
  /// consumable stays owned, and Play then refuses to sell that pack again.
  ///
  /// Failures are swallowed: the usual cause is that the item was already
  /// consumed by [buy]'s auto-consume, which is exactly the desired end state.
  Future<void> consumeIfAndroid(PurchaseDetails purchase) async {
    if (!Platform.isAndroid) return;
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await addition.consumePurchase(purchase);
    } catch (_) {
      // Already consumed, or the billing client is unavailable. Either way the
      // purchase has been credited and there is nothing useful to surface.
    }
  }
}
