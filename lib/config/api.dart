class ApiEndpoints {
  static const String baseUrl = 'https://deeppink-crab-810475.hostingersite.com';

  static const String googleLogin = '/api/pet/google-login';
  static const String analyze = '/api/pet/analyze';
  static const String profile = '/api/pet/profile';
  static const String history = '/api/pet/history';

  static String deleteHistory(String id) => '/api/pet/history/$id';
  static String scanFeedback(String id) => '/api/pet/history/$id/feedback';

  /// Google Play in-app purchase (consumable) redemption.
  static const String verifyPurchase = '/api/pet/verify-purchase';

  /// Google Play subscription (PetCare Plus) verification.
  static const String verifySubscription = '/api/pet/verify-subscription';

  /// Saved pets
  static const String pets = '/api/pet/pets';
  static String pet(String id) => '/api/pet/pets/$id';

  /// Referrals and product analytics
  static const String redeemReferral = '/api/pet/referral/redeem';
  static const String events = '/api/pet/events';

  /// Vet chat
  static const String chat = '/api/pet/chat';
  static const String chatHistory = '/api/pet/chat/history';

}
