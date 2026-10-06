class AppConfig {
  static const String appName = 'PetCareAI';
  static const String appVersion = '1.1.0';
  static const int apiTimeoutMs = 15000; // 15 seconds

  /// AI scans upload photos and wait on the model, so they get longer.
  static const int scanTimeoutMs = 60000;

  // Configured Google OAuth Web Client ID (from Google Cloud Credentials)
  // This is required on Android/iOS to generate an idToken.
  static const String googleServerClientId = '117412405894-ofkcc6fsujohct5iffaet6tafsgfsjpa.apps.googleusercontent.com';

  static const String playPackageName = 'com.ashish.aipetcare';
  static const String supportEmail = 'infotechashar@gmail.com';
  static const String privacyPolicyUrl = 'https://asharinfotech.com/privacy.html';

  /// Play Store page, used in referral share text.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$playPackageName';

  /// Where users manage or cancel a subscription (Play's own page).
  static String manageSubscriptionUrl(String productId) =>
      'https://play.google.com/store/account/subscriptions'
      '?sku=$productId&package=$playPackageName';
}
