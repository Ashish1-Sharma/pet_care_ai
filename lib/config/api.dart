class ApiEndpoints {
  static const String baseUrl = 'https://deeppink-crab-810475.hostingersite.com';
  
  static const String googleLogin = '/api/pet/google-login';
  static const String analyze = '/api/pet/analyze';
  static const String profile = '/api/pet/profile';
  static const String history = '/api/pet/history';
  
  static String deleteHistory(String id) => '/api/pet/history/$id';
  
  static const String createOrder = '/api/pet/create-order';
  static const String verifyPayment = '/api/pet/verify-payment';

  /// Google Play in-app purchase (consumable) redemption.
  static const String verifyPurchase = '/api/pet/verify-purchase';

  /// Vet chat
  static const String chat = '/api/pet/chat';
  static const String chatHistory = '/api/pet/chat/history';

}
