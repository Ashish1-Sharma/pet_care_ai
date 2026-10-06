class AppConfig {
  static const String appName = 'Pet Scan AI';
  static const String appVersion = '1.0.0';
  static const int apiTimeoutMs = 15000; // 15 seconds

  // Configured Google OAuth Web Client ID (from Google Cloud Credentials)
  // This is required on Android/iOS to generate an idToken.
  static const String googleServerClientId = '117412405894-ofkcc6fsujohct5iffaet6tafsgfsjpa.apps.googleusercontent.com';

  // Fallback Razorpay Key ID if not returned by backend create-order API
  static const String fallbackRazorpayKey = 'rzp_test_SmCD6EvOnV1wCQ';
}
