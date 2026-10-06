import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_profile.dart';
import '../models/reminder.dart';
import '../models/user_model.dart';

class StorageService {
  final _secureStorage = const FlutterSecureStorage();
  static const String _jwtKey = 'auth_jwt_token';
  static const String _userKey = 'cached_user_profile';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _pendingPurchasesKey = 'pending_iap_redemptions';
  static const String _pendingPetKey = 'onboarding_pending_pet';
  static const String _selectedPetKey = 'selected_pet_id';
  static const String _remindersKey = 'care_reminders';
  static const String _nextReminderIdKey = 'next_reminder_id';
  static const String _lastReviewPromptKey = 'last_review_prompt_at';
  static const String _notificationsPrimedKey = 'notifications_primed';

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

  // --- Onboarding pet ---------------------------------------------------------
  // The pet entered before sign-in; uploaded to the account right after login.

  Future<void> savePendingPet(PetProfile pet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingPetKey, jsonEncode(pet.toJson()));
  }

  Future<PetProfile?> getPendingPet() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingPetKey);
    if (jsonStr == null) return null;
    try {
      return PetProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingPet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPetKey);
  }

  Future<String?> getSelectedPetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedPetKey);
  }

  Future<void> setSelectedPetId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_selectedPetKey);
    } else {
      await prefs.setString(_selectedPetKey, id);
    }
  }

  // --- Care reminders (device-local) -------------------------------------------

  Future<List<Reminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_remindersKey);
    if (jsonStr == null) return [];
    try {
      return (jsonDecode(jsonStr) as List)
          .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReminders(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _remindersKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
  }

  /// Notification ids for reminders start at 1000, clear of the app's own.
  Future<int> nextReminderId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_nextReminderIdKey) ?? 1000;
    await prefs.setInt(_nextReminderIdKey, id + 1);
    return id;
  }

  Future<DateTime?> getLastReviewPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastReviewPromptKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setLastReviewPrompt(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReviewPromptKey, at.toIso8601String());
  }

  /// Whether the "turn on reminders" explainer has been shown.
  Future<bool> notificationsPrimed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsPrimedKey) ?? false;
  }

  Future<void> setNotificationsPrimed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPrimedKey, true);
  }

  // Clear all data (Logout)
  // Note: the onboarding flag deliberately survives logout — a returning user
  // signing back in should not be walked through the intro again.
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
    await setSelectedPetId(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
  }
}
