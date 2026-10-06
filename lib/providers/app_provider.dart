import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import '../models/user_model.dart';
import '../models/ai_response_model.dart';
import '../models/history_model.dart';
import '../models/pet_profile.dart';
import '../models/reminder.dart';
import '../services/analytics_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/pet_service.dart';
import '../services/payment_service.dart';
import '../services/iap_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;
  final AuthService _authService;
  final PetService _petService;
  final PaymentService _paymentService;
  final IapService _iapService;
  final NotificationService _notifications = NotificationService.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final StreamController<IapEvent> _iapEventController =
      StreamController<IapEvent>.broadcast();

  bool _iapAvailable = false;
  bool _iapProductsLoading = false;
  String? _iapProductsError;
  List<ProductDetails> _iapProducts = [];
  List<PlusOffer> _plusOffers = [];
  String? _purchasingProductId;

  UserModel? _currentUser;
  String? _token;
  List<HistoryItem> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorCode;
  bool _isDemoMode = false;

  String? _selectedPetId;
  List<Reminder> _reminders = [];

  // Progress tracking during scan
  String _scanProgressMessage = '';

  AppProvider()
      : _storageService = StorageService(),
        _apiService = ApiService(StorageService()),
        _authService = AuthService(ApiService(StorageService())),
        _petService = PetService(ApiService(StorageService())),
        _paymentService = PaymentService(ApiService(StorageService())),
        _iapService = IapService() {
    // Inject the logout callback to handle 401 expiration
    _apiService.onUnauthorized = logout;
    AnalyticsService.instance.attach(
      _apiService,
      canSend: () => isAuthenticated && !_isDemoMode,
    );
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  List<HistoryItem> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Machine-readable reason for the last failure (e.g. `NO_SCANS`).
  String? get errorCode => _errorCode;
  String get scanProgressMessage => _scanProgressMessage;
  bool get isDemoMode => _isDemoMode;
  bool get isPlus => _currentUser?.isPlus ?? false;

  List<PetProfile> get pets => _currentUser?.pets ?? const [];
  PetProfile? get selectedPet {
    if (pets.isEmpty) return null;
    return pets.firstWhere(
      (p) => p.id == _selectedPetId,
      orElse: () => pets.first,
    );
  }

  List<Reminder> get reminders =>
      [..._reminders]..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  // In-app purchase getters
  bool get iapAvailable => _iapAvailable;
  bool get iapProductsLoading => _iapProductsLoading;
  String? get iapProductsError => _iapProductsError;
  List<ProductDetails> get packProducts => IapService.packs
      .map((pack) => _iapProducts.where((p) => p.id == pack.productId).firstOrNull)
      .whereType<ProductDetails>()
      .toList();
  List<PlusOffer> get plusOffers => _plusOffers;
  String? get purchasingProductId => _purchasingProductId;
  bool get isPurchasing => _purchasingProductId != null;

  /// One-shot purchase outcomes, for toasts. Screens listen to this instead of
  /// trying to infer "a purchase just finished" from [notifyListeners].
  Stream<IapEvent> get iapEvents => _iapEventController.stream;

  // Clear errors helper
  void clearError() {
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
  }

  void _setError(Object e) {
    _errorMessage = e.toString();
    _errorCode = e is ApiException ? e.code : null;
  }

  Future<void> _setUser(UserModel user) async {
    _currentUser = user;
    await _storageService.saveUser(user);
    notifyListeners();
  }

  // 1. Splash Auth Check
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedToken = await _storageService.getToken();
      final savedUser = await _storageService.getUser();
      _selectedPetId = await _storageService.getSelectedPetId();
      _reminders = await _storageService.getReminders();

      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = savedUser;
        _isDemoMode = (savedToken == "demo_jwt_token");
        notifyListeners();

        // Fetch fresh profile in the background only if not in demo mode
        if (!_isDemoMode) {
          await refreshProfile().catchError((_) => null);
        } else {
          // Re-populate mock items
          _populateDemoHistory();
        }
        track('app_open');
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to load dummy items
  void _populateDemoHistory() {
    _historyList = [
      HistoryItem(
        id: "demo_1",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        imageUrls: [],
        criticality: "Moderate",
        possibleConditions: [PossibleCondition(name: "Allergic Dermatitis", probability: 80)],
        petType: "Dog",
        bodyPart: "Skin",
        reason: "Mild redness and scratching near the back of the neck.",
        whatOwnerShouldDo: "Prevent scratching with a collar and bathe with oatmeal shampoo.",
        homeCare: ["Bathe with cool water", "Apply soothing lotion"],
        emergencySigns: ["Breathing issues", "Severe swelling"],
        needVet: true,
        visitWithin: "24-48 Hours",
        disclaimer: "Demo Assessment: This is a placeholder report for demonstration purposes."
      ),
      HistoryItem(
        id: "demo_2",
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        imageUrls: [],
        criticality: "Low",
        possibleConditions: [PossibleCondition(name: "Otitis Externa", probability: 90)],
        petType: "Cat",
        bodyPart: "Ear",
        reason: "Scratching ears frequently and minor brown discharge.",
        whatOwnerShouldDo: "Clean the outer ear gently with specialized ear wipes. Monitor closely.",
        homeCare: ["Use pet-safe ear cleaner", "Monitor for head shaking"],
        emergencySigns: ["Balance loss", "Uncontrolled bleeding"],
        needVet: true,
        visitWithin: "Within 3-5 Days",
        disclaimer: "Demo Assessment: This is a placeholder report for demonstration purposes."
      )
    ];
  }

  // 2. Google Login
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    _isDemoMode = false;
    notifyListeners();

    try {
      final credentials = await _authService.loginWithGoogle();
      if (credentials == null) {
        return false;
      }

      _token = credentials['token'];
      _currentUser = credentials['user'];

      await _storageService.saveToken(_token!);
      await _storageService.saveUser(_currentUser!);

      track(credentials['isNewUser'] == true ? 'signup' : 'login');
      await _uploadPendingPet();

      // A purchase made on a previous install, or before signing in, can now
      // be linked to this account.
      unawaited(_purchaseSub == null ? initIap() : restorePurchases(silent: true));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AppProvider.loginWithGoogle failed: $e');
      _setError(e);
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// The pet entered during onboarding is saved to the account once signed in.
  Future<void> _uploadPendingPet() async {
    final pending = await _storageService.getPendingPet();
    if (pending == null) return;
    final alreadySaved = pets.any(
      (p) => p.name.toLowerCase() == pending.name.toLowerCase() && p.type == pending.type,
    );
    try {
      if (!alreadySaved) await addPet(pending);
      await _storageService.clearPendingPet();
    } catch (e) {
      debugPrint('Pending pet upload failed, will retry on next login: $e');
    }
  }

  // 2b. Demo Login
  Future<void> loginAsDemo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isDemoMode = true;
      _token = "demo_jwt_token";
      _currentUser = UserModel(
        id: 999,
        name: "Demo User",
        email: "demo@example.com",
        profileImage: "",
        remainingScans: 5,
        pets: const [
          PetProfile(id: 'demo_pet', name: 'Buddy', type: 'Dog', breed: 'Golden Retriever', age: '3 years'),
        ],
      );

      _populateDemoHistory();

      // Save to local storage
      await _storageService.saveToken(_token!);
      await _storageService.saveUser(_currentUser!);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AnalyticsService.instance.flush();
      if (!_isDemoMode) {
        await _authService.signOut();
      }
      await _storageService.clearAll();
      await _notifications.cancelAll();
      _token = null;
      _currentUser = null;
      _historyList = [];
      _reminders = [];
      _selectedPetId = null;
      _isDemoMode = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Refresh user profile (fetches scans and basic user info fresh)
  Future<void> refreshProfile() async {
    if (_isDemoMode) return;

    try {
      final freshUser = await _petService.getProfile();
      await _setUser(freshUser);
      await _syncAppNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Keeps the app's own notifications in line with the account: the weekly
  /// free scan only for free users, the trial heads-up only during a trial.
  Future<void> _syncAppNotifications() async {
    final user = _currentUser;
    if (user == null || _isDemoMode) return;
    if (!await _storageService.notificationsPrimed()) return;

    if (user.isPlus) {
      await _notifications.cancel(NotificationService.weeklyFreeScanId);
    } else {
      await _notifications.scheduleWeeklyFreeScan();
    }

    final plan = user.plan;
    if (user.isPlus && plan != null && plan.isTrial && plan.expiresAt != null) {
      final offer = _plusOffers.where((o) => o.plan.productId == plan.productId).firstOrNull;
      await _notifications.scheduleTrialEnding(plan.expiresAt!, offer?.recurringPrice ?? 'the plan price');
    } else {
      await _notifications.cancel(NotificationService.trialEndingId);
    }

    await _notifications.scheduleReengagement(selectedPet?.name ?? '');
  }

  /// Called after the user agrees to reminders (permission primer).
  Future<bool> enableNotifications() async {
    final granted = await _notifications.requestPermission();
    await _storageService.setNotificationsPrimed();
    track('notifications_permission', {'granted': granted});
    if (granted) {
      await _syncAppNotifications();
      for (final reminder in _reminders) {
        await _notifications.scheduleReminder(reminder);
      }
    }
    return granted;
  }

  Future<bool> notificationsPrimed() => _storageService.notificationsPrimed();

  // 5. Lazy-load scan history
  Future<void> fetchHistory() async {
    if (_isDemoMode) return; // Keep static list populated on loginAsDemo

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _petService.getHistory();
      _historyList = list;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// All scans in a recovery series, oldest first.
  List<HistoryItem> recoverySeries(String seriesId) {
    final items = _historyList.where((h) => h.seriesId == seriesId).toList();
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  HistoryItem? historyItem(String id) =>
      _historyList.where((h) => h.id == id).firstOrNull;

  // 6. Delete history item
  Future<bool> deleteHistoryItem(String id) async {
    try {
      if (_isDemoMode) {
        _historyList.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      }

      await _petService.deleteHistoryItem(id);
      _historyList.removeWhere((item) => item.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 7. Core AI Scanning Request with progressive loading feedback
  Future<AiResponseModel?> scanPet({
    required String petType,
    required String bodyPart,
    required String description,
    required List<String> symptoms,
    required List<String> imagePaths,
    String? petId,
    String? recoveryOf,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    _scanProgressMessage = 'Uploading Images...';
    notifyListeners();
    track('scan_start', {'bodyPart': bodyPart, 'followUp': recoveryOf != null});

    try {
      if (_isDemoMode) {
        // Step 1: Simulated uploads/processing delays for realistic user flow
        await Future.delayed(const Duration(milliseconds: 1200));

        _scanProgressMessage = 'Analyzing Images...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1000));

        _scanProgressMessage = 'Generating Health Report...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 1200));

        final demoId = "demo_${DateTime.now().millisecondsSinceEpoch}";
        final dummyResponse = AiResponseModel(
          success: true,
          remainingScans: (_currentUser?.remainingScans ?? 5) - 1,
          scanId: demoId,
          recoveryOf: recoveryOf,
          data: AiResponseData(
            possibleCondition: "Contact Dermatitis (Demo)",
            criticality: "Low",
            confidence: 85,
            reasoning: "The pattern of scratching and mild redness on the skin points to contact sensitivity (e.g. from grass, household cleaners, or certain fabric materials).",
            summary: "Wash the affected area, avoid applying harsh soaps, and prevent scratching. Monitor for skin breaks.",
            homeCare: [
              "Clean the area with tepid water and oatmeal shampoo.",
              "Keep the bedding clean and allergen-free.",
              "Apply cold compresses to soothe the irritated skin.",
              "Use an Elizabethan collar if scratching persists."
            ],
            emergencySigns: [
              "Rapidly spreading swelling around face/lips",
              "Respiratory difficulties or loud wheezing",
              "Extreme lethargy or sudden collapses"
            ],
            visitVet: "Not urgent. Consult a vet if irritation doesn't clear in 48 hours.",
            disclaimer: "Demo Assessment: This report is a simulated response created for review purposes. It is not an actual veterinary diagnosis."
          ),
        );

        // Add to local history list dynamically so the history tab updates instantly
        final newHistory = HistoryItem(
          id: demoId,
          createdAt: DateTime.now().toIso8601String(),
          imageUrls: imagePaths,
          criticality: "Low",
          possibleConditions: [PossibleCondition(name: "Contact Dermatitis (Demo)", probability: 85)],
          petType: petType,
          bodyPart: bodyPart,
          reason: "Redness and irritation observed around the $bodyPart area.",
          whatOwnerShouldDo: "Wash the affected area, avoid applying harsh soaps, and prevent scratching. Monitor for skin breaks.",
          homeCare: [
            "Clean the area with tepid water and oatmeal shampoo.",
            "Keep the bedding clean and allergen-free.",
            "Apply cold compresses to soothe the irritated skin.",
            "Use an Elizabethan collar if scratching persists."
          ],
          emergencySigns: [
            "Rapidly spreading swelling around face/lips",
            "Respiratory difficulties or loud wheezing",
            "Extreme lethargy or sudden collapses"
          ],
          needVet: false,
          visitWithin: "Not urgent. Consult a vet if irritation doesn't clear in 48 hours.",
          disclaimer: "Demo Assessment: This report is a simulated response created for review purposes.",
          petId: petId,
          recoveryOf: recoveryOf,
        );

        _historyList.insert(0, newHistory);

        // Update scan count locally
        if (_currentUser != null) {
          final currentScans = _currentUser!.remainingScans;
          _currentUser = _currentUser!.copyWith(remainingScans: currentScans > 0 ? currentScans - 1 : 0);
          await _storageService.saveUser(_currentUser!);
        }

        return dummyResponse;
      }

      // Step 1: Real standard scan flow
      await Future.delayed(const Duration(milliseconds: 1200));

      _scanProgressMessage = 'Analyzing Images...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 1000));

      _scanProgressMessage = 'Generating Health Report...';
      notifyListeners();

      final response = await _petService.analyzePet(
        petType: petType,
        bodyPart: bodyPart,
        description: description,
        symptoms: symptoms,
        imagePaths: imagePaths,
        petId: petId,
        recoveryOf: recoveryOf,
      );

      // The server reports the true balance after the scan.
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          remainingScans: response.remainingScans,
          isPlus: response.isPlus,
        );
        await _storageService.saveUser(_currentUser!);
      }
      track('scan_done', {
        'criticality': response.data?.criticality,
        'followUp': recoveryOf != null,
        'plus': response.isPlus,
      });

      // Keep history in step so recovery series include the new scan.
      unawaited(fetchHistory());

      await Future.delayed(const Duration(milliseconds: 800));
      return response;
    } catch (e) {
      _setError(e);
      if (_errorCode == 'NO_SCANS') {
        // The server knows best; resync so the UI shows the paywall state.
        unawaited(refreshProfile());
      }
      track('scan_failed', {'code': _errorCode});
      return null;
    } finally {
      _isLoading = false;
      _scanProgressMessage = '';
      notifyListeners();
    }
  }

  Future<void> sendScanFeedback(String scanId, {required bool accurate}) async {
    track('scan_feedback', {'accurate': accurate});
    if (_isDemoMode) return;
    try {
      await _petService.sendScanFeedback(scanId, accurate: accurate);
    } catch (e) {
      debugPrint('Feedback failed: $e');
    }
  }

  /// Asks Google Play to show its rating card, at most once every 60 days.
  /// Play decides whether it actually appears. Never gated on sentiment.
  Future<void> maybeRequestReview() async {
    if (_isDemoMode) return;
    final last = await _storageService.getLastReviewPrompt();
    if (last != null && DateTime.now().difference(last).inDays < 60) return;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await _storageService.setLastReviewPrompt(DateTime.now());
        track('review_prompt');
        await review.requestReview();
      }
    } catch (e) {
      debugPrint('Review prompt failed: $e');
    }
  }

  /// Chat responses carry the remaining free messages; keep the badge in sync.
  void updateChatRemaining(int? remaining) {
    final user = _currentUser;
    if (user == null || remaining == null) return;
    _currentUser = user.copyWith(chatRemainingToday: remaining);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Pets
  // ---------------------------------------------------------------------------

  Future<void> selectPet(String? petId) async {
    _selectedPetId = petId;
    await _storageService.setSelectedPetId(petId);
    notifyListeners();
  }

  Future<PetProfile> addPet(PetProfile pet) async {
    final saved = _isDemoMode
        ? PetProfile(
            id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
            name: pet.name,
            type: pet.type,
            breed: pet.breed,
            age: pet.age,
            weight: pet.weight,
          )
        : await _petService.createPet(pet);
    if (_currentUser != null) {
      await _setUser(_currentUser!.copyWith(pets: [...pets, saved]));
    }
    await selectPet(saved.id);
    track('pet_added', {'type': saved.type});
    return saved;
  }

  Future<void> updatePet(PetProfile pet) async {
    final saved = _isDemoMode ? pet : await _petService.updatePet(pet);
    if (_currentUser != null) {
      await _setUser(_currentUser!.copyWith(
        pets: pets.map((p) => p.id == saved.id ? saved : p).toList(),
      ));
    }
  }

  Future<void> deletePet(String petId) async {
    if (!_isDemoMode) await _petService.deletePet(petId);
    if (_currentUser != null) {
      await _setUser(_currentUser!.copyWith(
        pets: pets.where((p) => p.id != petId).toList(),
      ));
    }
    if (_selectedPetId == petId) await selectPet(null);
  }

  // ---------------------------------------------------------------------------
  // Referrals
  // ---------------------------------------------------------------------------

  Future<bool> redeemReferral(String code) async {
    _errorMessage = null;
    try {
      final user = await _petService.redeemReferral(code);
      await _setUser(user);
      track('referral_redeemed');
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Care reminders (device-local, delivered as notifications)
  // ---------------------------------------------------------------------------

  Future<Reminder> addReminder({
    required String title,
    required DateTime dueAt,
    PetProfile? pet,
    ReminderRepeat repeat = ReminderRepeat.none,
    String? recoveryScanId,
  }) async {
    final reminder = Reminder(
      id: await _storageService.nextReminderId(),
      title: title,
      petId: pet?.id,
      petName: pet?.name ?? 'your pet',
      dueAt: dueAt,
      repeat: repeat,
      recoveryScanId: recoveryScanId,
    );
    // One pending check-in per recovery series.
    if (recoveryScanId != null) {
      for (final old in _reminders.where((r) => r.recoveryScanId == recoveryScanId).toList()) {
        await _notifications.cancel(old.id);
        _reminders.remove(old);
      }
    }
    _reminders.add(reminder);
    await _storageService.saveReminders(_reminders);
    await _notifications.scheduleReminder(reminder);
    track('reminder_added', {'recovery': recoveryScanId != null, 'repeat': repeat.name});
    notifyListeners();
    return reminder;
  }

  /// Marks a reminder done: repeating ones roll to their next date.
  Future<void> completeReminder(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    _reminders.removeWhere((r) => r.id == reminder.id);
    if (reminder.repeat != ReminderRepeat.none) {
      var next = reminder.repeat.next(reminder.dueAt);
      while (!next.isAfter(DateTime.now())) {
        next = reminder.repeat.next(next);
      }
      final rolled = reminder.copyWith(dueAt: next);
      _reminders.add(rolled);
      await _notifications.scheduleReminder(rolled);
    }
    await _storageService.saveReminders(_reminders);
    notifyListeners();
  }

  Future<void> deleteReminder(Reminder reminder) async {
    await _notifications.cancel(reminder.id);
    _reminders.removeWhere((r) => r.id == reminder.id);
    await _storageService.saveReminders(_reminders);
    notifyListeners();
  }

  /// The pending recovery check-in for a series, if any.
  Reminder? recoveryReminderFor(String seriesId) =>
      _reminders.where((r) => r.recoveryScanId == seriesId).firstOrNull;

  // ---------------------------------------------------------------------------
  // 10. Google Play in-app purchases: scan packs + PetCare Plus
  // ---------------------------------------------------------------------------

  /// Connects to the store and starts listening for purchase updates.
  ///
  /// Called once at app start rather than from the paywall, because Play
  /// replays purchases that were interrupted (app killed mid-purchase) as soon
  /// as the stream is listened to. If we only listened while the paywall was
  /// open, those would be missed.
  Future<void> initIap() async {
    if (_purchaseSub != null) return; // already initialised
    if (_isDemoMode) {
      _iapAvailable = false;
      return;
    }

    _purchaseSub = _iapService.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        _iapEventController.add(
          IapEvent.failure('Purchase stream error: $error'),
        );
      },
    );

    try {
      _iapAvailable = await _iapService.isAvailable();
    } catch (e) {
      _iapAvailable = false;
      _iapProductsError = 'Store unavailable: $e';
    }
    notifyListeners();

    if (_iapAvailable) {
      await loadIapProducts();
      // Retry any purchase that was paid for but never credited.
      await retryPendingRedemptions();
      // Re-sync subscriptions (renewals, a reinstall, another device).
      if (isAuthenticated) await restorePurchases(silent: true);
    }
  }

  /// Fetches localized prices from Play. Prices are never hardcoded.
  Future<void> loadIapProducts() async {
    if (!_iapAvailable) return;

    _iapProductsLoading = true;
    _iapProductsError = null;
    notifyListeners();

    try {
      final response = await _iapService.queryProducts();

      if (response.error != null) {
        _iapProductsError = response.error!.message;
        _iapProducts = [];
        _plusOffers = [];
      } else {
        _iapProducts = response.productDetails;
        _plusOffers = IapService.plusOffers(_iapProducts);

        if (_iapProducts.isEmpty) {
          _iapProductsError =
              'No products available. Check that the product IDs are active in '
              'Play Console and the app was installed from a Play track.';
        } else if (response.notFoundIDs.isNotEmpty) {
          debugPrint('IAP: products not found: ${response.notFoundIDs}');
        }
      }
    } catch (e) {
      _iapProductsError = e.toString();
      _iapProducts = [];
      _plusOffers = [];
    } finally {
      _iapProductsLoading = false;
      notifyListeners();
    }
  }

  /// Launches the Play purchase sheet for [product].
  ///
  /// Returns whether the request was *sent*; the actual outcome arrives on
  /// [iapEvents] via the purchase stream.
  Future<bool> buyScanPack(ProductDetails product) async {
    if (_isPurchaseBlocked()) return false;

    _purchasingProductId = product.id;
    notifyListeners();
    track('purchase_start', {'product': product.id});

    try {
      final started = await _iapService.buy(product);
      if (!started) {
        _purchasingProductId = null;
        _iapEventController.add(
          IapEvent.failure('Could not start the purchase. Please try again.'),
        );
        notifyListeners();
      }
      return started;
    } catch (e) {
      _purchasingProductId = null;
      _iapEventController.add(IapEvent.failure(e.toString()));
      notifyListeners();
      return false;
    }
  }

  /// Starts a PetCare Plus subscription (with its free trial if eligible).
  Future<bool> buyPlus(PlusOffer offer) async {
    if (_isPurchaseBlocked()) return false;

    _purchasingProductId = offer.plan.productId;
    notifyListeners();
    track('purchase_start', {'product': offer.plan.productId, 'trial': offer.hasTrial});

    try {
      final started = await _iapService.buySubscription(offer.product);
      if (!started) {
        _purchasingProductId = null;
        _iapEventController.add(
          IapEvent.failure('Could not start the purchase. Please try again.'),
        );
        notifyListeners();
      }
      return started;
    } catch (e) {
      _purchasingProductId = null;
      _iapEventController.add(IapEvent.failure(e.toString()));
      notifyListeners();
      return false;
    }
  }

  bool _restoringSilently = false;

  /// Asks Play to re-deliver owned subscriptions. [silent] skips toasts, for
  /// the automatic sync at start-up and after login.
  Future<void> restorePurchases({bool silent = false}) async {
    if (_isDemoMode || !_iapAvailable || !isAuthenticated) {
      if (!silent) {
        _iapEventController.add(IapEvent.failure('The Play Store is not available right now.'));
      }
      return;
    }
    _restoringSilently = silent;
    try {
      await _iapService.restorePurchases();
      if (!silent) {
        // Give restored events a moment to arrive, then report the outcome.
        await Future.delayed(const Duration(seconds: 3));
        _iapEventController.add(IapEvent.restored(isPlus));
      }
    } catch (e) {
      if (!silent) _iapEventController.add(IapEvent.failure(e.toString()));
    } finally {
      // Late restored events after this point are treated as silent too.
      Future.delayed(const Duration(seconds: 5), () => _restoringSilently = false);
    }
  }

  bool _isPurchaseBlocked() {
    if (_isDemoMode) {
      _iapEventController.add(
        IapEvent.failure('Purchases are disabled in demo mode.'),
      );
      return true;
    }
    if (!_iapAvailable) {
      _iapEventController.add(
        IapEvent.failure('The Play Store is not available on this device.'),
      );
      return true;
    }
    if (_purchasingProductId != null) {
      return true; // a purchase is already in flight
    }
    return false;
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasingProductId = purchase.productID;
          _iapEventController.add(IapEvent.pending());
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (IapService.isSubscription(purchase.productID)) {
            await _deliverSubscription(
              purchase,
              userInitiated: _purchasingProductId == purchase.productID,
            );
          } else {
            await _deliverPurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          _purchasingProductId = null;
          track('purchase_failed', {'product': purchase.productID});
          _iapEventController.add(
            IapEvent.failure(
              purchase.error?.message ?? 'The purchase could not be completed.',
            ),
          );
          // Nothing to deliver, but the purchase must still be finished or
          // Play will keep replaying it.
          if (purchase.pendingCompletePurchase) {
            await _iapService.complete(purchase);
          }
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _purchasingProductId = null;
          track('purchase_canceled', {'product': purchase.productID});
          _iapEventController.add(IapEvent.canceled());
          if (purchase.pendingCompletePurchase) {
            await _iapService.complete(purchase);
          }
          notifyListeners();
          break;
      }
    }
  }

  /// Verifies a subscription on the backend, then acknowledges it with Play.
  /// If verification fails the purchase is left unacknowledged: Play replays
  /// it on the next start, and refunds it automatically if it never succeeds.
  Future<void> _deliverSubscription(
    PurchaseDetails purchase, {
    required bool userInitiated,
  }) async {
    final token = purchase.verificationData.serverVerificationData;
    if (token.isEmpty || !isAuthenticated) {
      if (userInitiated) _purchasingProductId = null;
      notifyListeners();
      return;
    }

    final wasPlus = isPlus;
    try {
      final user = await _paymentService.verifySubscription(
        productId: purchase.productID,
        purchaseToken: token,
      );
      await _setUser(user);
      if (purchase.pendingCompletePurchase) {
        await _iapService.complete(purchase);
      }
      if (userInitiated || (!wasPlus && user.isPlus && !_restoringSilently)) {
        track('purchase', {'product': purchase.productID, 'type': 'subscription'});
        _iapEventController.add(IapEvent.subscribed());
      }
      await _syncAppNotifications();
    } catch (e) {
      if (userInitiated) {
        _iapEventController.add(
          IapEvent.failure(
            'Payment went through but Plus could not be activated yet. '
            'We will retry automatically. ($e)',
          ),
        );
      }
      debugPrint('Subscription verification failed: $e');
    } finally {
      if (userInitiated) _purchasingProductId = null;
      notifyListeners();
    }
  }

  /// Credits scans on the backend, then finishes the purchase with Play.
  Future<void> _deliverPurchase(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData;

    if (token.isEmpty) {
      _purchasingProductId = null;
      _iapEventController.add(
        IapEvent.failure(
          'Purchase receipt was empty. Contact support with your order ID.',
        ),
      );
      notifyListeners();
      return;
    }

    // Queue before the network call: if the app dies mid-request, the token
    // survives and is retried on next start.
    await _storageService.addPendingPurchase(purchase.productID, token);

    final credited = await _redeemToken(purchase.productID, token);

    _purchasingProductId = null;

    if (credited) {
      // Finish with Play, then make sure the consumable is actually consumed
      // so this pack can be bought again. See IapService.consumeIfAndroid.
      if (purchase.pendingCompletePurchase) {
        await _iapService.complete(purchase);
      }
      await _iapService.consumeIfAndroid(purchase);
    }
    // On failure we deliberately do NOT complete the purchase: Play will
    // replay it on the next app start, which is a second retry path alongside
    // the locally queued token. Redemption is idempotent server-side, so both
    // firing is harmless.

    notifyListeners();
  }

  /// Sends one token to the backend. Returns whether scans were credited.
  Future<bool> _redeemToken(String productId, String token) async {
    try {
      final result = await _paymentService.verifyPurchase(
        productId: productId,
        purchaseToken: token,
      );

      await _storageService.removePendingPurchase(token);

      if (result.remainingScans != null && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          remainingScans: result.remainingScans,
        );
        await _storageService.saveUser(_currentUser!);
      } else {
        await refreshProfile();
      }

      if (result.alreadyCredited) {
        // A replay of a token we had already redeemed. The balance is correct,
        // so stay quiet rather than claiming a second purchase succeeded.
        debugPrint('IAP: token already credited, balance synced.');
      } else {
        track('purchase', {'product': productId, 'type': 'pack'});
        _iapEventController.add(IapEvent.success(result.scansGranted));
      }
      return true;
    } catch (e) {
      _iapEventController.add(
        IapEvent.failure(
          'Payment went through but scans could not be added yet. '
          'We will retry automatically. ($e)',
        ),
      );
      return false;
    }
  }

  /// Retries tokens that were paid for but never successfully credited.
  Future<void> retryPendingRedemptions() async {
    if (_isDemoMode || !isAuthenticated) return;

    final pending = await _storageService.getPendingPurchases();
    for (final entry in pending) {
      final productId = entry['productId'];
      final token = entry['purchaseToken'];
      if (productId == null || token == null) continue;
      await _redeemToken(productId, token);
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _iapEventController.close();
    super.dispose();
  }
}

/// A one-shot in-app purchase outcome, surfaced to the UI for toasts.
enum IapEventType { pending, success, subscribed, restored, failure, canceled }

class IapEvent {
  final IapEventType type;
  final String? message;
  final int scansGranted;

  /// For [IapEventType.restored]: whether Plus is active afterwards.
  final bool isPlus;

  const IapEvent._(this.type, {this.message, this.scansGranted = 0, this.isPlus = false});

  factory IapEvent.pending() => const IapEvent._(IapEventType.pending);
  factory IapEvent.success(int scans) =>
      IapEvent._(IapEventType.success, scansGranted: scans);
  factory IapEvent.subscribed() => const IapEvent._(IapEventType.subscribed);
  factory IapEvent.restored(bool isPlus) =>
      IapEvent._(IapEventType.restored, isPlus: isPlus);
  factory IapEvent.failure(String message) =>
      IapEvent._(IapEventType.failure, message: message);
  factory IapEvent.canceled() => const IapEvent._(IapEventType.canceled);
}
