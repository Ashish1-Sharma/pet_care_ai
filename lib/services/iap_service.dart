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

  const ScanPack({
    required this.productId,
    required this.title,
    required this.scans,
    this.isPopular = false,
  });
}

/// Thin wrapper around [InAppPurchase] so the provider never touches the
/// plugin directly and the product catalogue lives in one place.
class IapService {
  final InAppPurchase _iap = InAppPurchase.instance;

  /// Consumable products configured in Google Play Console.
  static const List<ScanPack> packs = [
    ScanPack(productId: 'scans_starter_5', title: 'Starter', scans: 5),
    ScanPack(
      productId: 'scans_popular_25',
      title: 'Popular',
      scans: 25,
      isPopular: true,
    ),
    ScanPack(productId: 'scans_value_100', title: 'Value', scans: 100),
  ];

  static Set<String> get productIds =>
      packs.map((pack) => pack.productId).toSet();

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

  /// Starts the Play purchase sheet. The result arrives on [purchaseStream].
  ///
  /// `autoConsume` is true so the consumable is immediately consumable again —
  /// this is what lets the same pack be bought repeatedly.
  Future<bool> buy(ProductDetails product) => _iap.buyConsumable(
    purchaseParam: PurchaseParam(productDetails: product),
    autoConsume: true,
  );

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
