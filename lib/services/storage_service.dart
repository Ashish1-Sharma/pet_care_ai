import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();
  static const String _jwtKey = 'auth_jwt_token';
  static const String _userKey = 'cached_user_profile';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _pendingPurchasesKey = 'pending_iap_redemptions';

  // Securely save JWT
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _jwtKey, value: token);
  }

  // Get JWT
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _jwtKey);
  }

  // Clear JWT
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _jwtKey);
  }

  // Save User info
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(user.toJson());
    await prefs.setString(_userKey, jsonStr);
  }

  // Get User info
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // Clear User info
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Whether the onboarding carousel has already been completed or skipped
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // --- Unredeemed Google Play purchases -------------------------------------
  // autoConsume means Play consumes the item the moment it is purchased, so a
  // token whose backend credit call failed cannot be recovered from Play. We
  // persist those tokens and retry them on the next app start.

  Future<List<Map<String, String>>> getPendingPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingPurchasesKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addPendingPurchase(String productId, String purchaseToken) async {
    final pending = await getPendingPurchases();
    if (pending.any((p) => p['purchaseToken'] == purchaseToken)) return;
    pending.add({'productId': productId, 'purchaseToken': purchaseToken});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPurchasesKey, jsonEncode(pending));
  }

  Future<void> removePendingPurchase(String purchaseToken) async {
    final pending = await getPendingPurchases();
    pending.removeWhere((p) => p['purchaseToken'] == purchaseToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPurchasesKey, jsonEncode(pending));
  }

  // Clear all data (Logout)
  // Note: the onboarding flag deliberately survives logout — a returning user
  // signing back in should not be walked through the intro again.
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
  }
}
