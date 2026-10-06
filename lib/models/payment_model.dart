import '../config/app_config.dart';

class RazorpayOrder {
  final String orderId;
  final int amount; // in paise (e.g. 2000 paise = Rs 20)
  final String currency;
  final String key;

  RazorpayOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    final responseKey = json['key'] as String?;
    return RazorpayOrder(
      orderId: (json['id'] ?? json['orderId'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] ?? 'INR',
      key: (responseKey != null && responseKey.isNotEmpty)
          ? responseKey
          : AppConfig.fallbackRazorpayKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'currency': currency,
      'key': key,
    };
  }
}
