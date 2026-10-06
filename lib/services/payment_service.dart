import '../config/api.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Google Play billing calls to the backend. Razorpay was removed: Play
/// policy requires Play Billing for digital goods such as scans.
class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  /// Redeems a Google Play consumable purchase token for scans.
  ///
  /// Only the product ID and token are sent — the server owns the product ->
  /// scans mapping and takes the user from the JWT, so neither can be spoofed.
  /// The call is idempotent: replaying a token returns success with
  /// `alreadyCredited: true` rather than granting scans twice.
  Future<IapRedemptionResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.verifyPurchase,
      data: {
        'product_id': productId,
        'purchase_token': purchaseToken,
      },
    );

    final data = response.data;
    if (data is! Map || data['success'] != true) {
      throw 'Purchase could not be verified.';
    }

    return IapRedemptionResult(
      alreadyCredited: data['alreadyCredited'] == true,
      scansGranted: (data['scansGranted'] as num?)?.toInt() ?? 0,
      remainingScans: (data['remainingScans'] as num?)?.toInt(),
    );
  }

  /// Links a PetCare Plus subscription to the account. Idempotent, so it is
  /// also used to re-sync on app start ("restore"). Returns the fresh profile.
  Future<UserModel> verifySubscription({
    required String productId,
    required String purchaseToken,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.verifySubscription,
      data: {
        'product_id': productId,
        'purchase_token': purchaseToken,
      },
    );

    final data = response.data;
    if (data is! Map || data['success'] != true || data['user'] is! Map) {
      throw 'Subscription could not be verified.';
    }
    return UserModel.fromJson(Map<String, dynamic>.from(data['user']));
  }
}

/// Outcome of redeeming a purchase token on the backend.
class IapRedemptionResult {
  final bool alreadyCredited;
  final int scansGranted;
  final int? remainingScans;

  const IapRedemptionResult({
    required this.alreadyCredited,
    required this.scansGranted,
    this.remainingScans,
  });
}
