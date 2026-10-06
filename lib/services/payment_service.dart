import '../config/api.dart';
import '../models/payment_model.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  // Call create-order endpoint
  Future<RazorpayOrder> createOrder({
    required double amount,
    required int scansPurchased,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.createOrder,
      data: {
        'amount': amount,
        'scansPurchased': scansPurchased,
      },
    );

    if (response.data == null) {
      throw 'Failed to create order.';
    }

    return RazorpayOrder.fromJson(response.data);
  }

  // Call verify-payment endpoint
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required int scansPurchased,
    required double amount,
  }) async {
    final response = await _apiService.post(
      ApiEndpoints.verifyPayment,
      data: {
        'razorpayOrderId': orderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
        'scansPurchased': scansPurchased,
        'amount': amount,
      },
    );

    if (response.data == null) {
      return false;
    }

    return response.data['success'] == true;
  }

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
