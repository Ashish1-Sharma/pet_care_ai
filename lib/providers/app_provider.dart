import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/user_model.dart';
import '../models/ai_response_model.dart';
import '../models/history_model.dart';
import '../models/payment_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final StreamController<IapEvent> _iapEventController =
      StreamController<IapEvent>.broadcast();

  bool _iapAvailable = false;
  bool _iapProductsLoading = false;
  String? _iapProductsError;
  List<ProductDetails> _iapProducts = [];
  String? _purchasingProductId;

  UserModel? _currentUser;
  String? _token;
  List<HistoryItem> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDemoMode = false;
  
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
  }

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  List<HistoryItem> get historyList => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get scanProgressMessage => _scanProgressMessage;
  bool get isDemoMode => _isDemoMode;

  // In-app purchase getters
  bool get iapAvailable => _iapAvailable;
  bool get iapProductsLoading => _iapProductsLoading;
  String? get iapProductsError => _iapProductsError;
  List<ProductDetails> get iapProducts => _iapProducts;
  String? get purchasingProductId => _purchasingProductId;
  bool get isPurchasing => _purchasingProductId != null;

  /// One-shot purchase outcomes, for toasts. Screens listen to this instead of
  /// trying to infer "a purchase just finished" from [notifyListeners].
  Stream<IapEvent> get iapEvents => _iapEventController.stream;

  // Clear errors helper
  void clearError() {
    _errorMessage = null;
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
    print('DEBUG: AppProvider.loginWithGoogle() triggered.');
    _isLoading = true;
    _errorMessage = null;
    _isDemoMode = false;
    notifyListeners();

    try {
      final credentials = await _authService.loginWithGoogle();
      if (credentials == null) {
        print('DEBUG: AppProvider.loginWithGoogle() - User cancelled login.');
        return false;
      }

      _token = credentials['token'];
      _currentUser = credentials['user'];

      print('DEBUG: AppProvider.loginWithGoogle() - Saving token and user to local storage...');
      await _storageService.saveToken(_token!);
      await _storageService.saveUser(_currentUser!);

      print('DEBUG: AppProvider.loginWithGoogle() - Sign-in process completed successfully.');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('DEBUG: AppProvider.loginWithGoogle() - ERROR caught during sign-in:');
      print('DEBUG: Error details: $e');
      print('DEBUG: Stacktrace:\n$stackTrace');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      if (!_isDemoMode) {
        await _authService.signOut();
      }
      await _storageService.clearAll();
      _token = null;
      _currentUser = null;
      _historyList = [];
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
      _currentUser = freshUser;
      await _storageService.saveUser(freshUser);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _scanProgressMessage = 'Uploading Images...';
    notifyListeners();

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

        final dummyResponse = AiResponseModel(
          success: true,
          remainingScans: (_currentUser?.remainingScans ?? 5) - 1,
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
          id: "demo_${DateTime.now().millisecondsSinceEpoch}",
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
          disclaimer: "Demo Assessment: This report is a simulated response created for review purposes."
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
      );

      // Deduct one scan locally first and sync fresh profile from server in background
      if (_currentUser != null) {
        final currentScans = _currentUser!.remainingScans;
        _currentUser = _currentUser!.copyWith(remainingScans: currentScans > 0 ? currentScans - 1 : 0);
        await _storageService.saveUser(_currentUser!);
      }

      // Fetch fresh profile in the background to ensure it is in sync with server
      refreshProfile().catchError((_) => null);

      await Future.delayed(const Duration(milliseconds: 800));
      return response;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      _scanProgressMessage = '';
      notifyListeners();
    }
  }

  // 8. Razorpay Order Generation
  Future<RazorpayOrder?> createOrder(double amount, int scansPurchased) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isDemoMode) {
        return RazorpayOrder(
          orderId: "demo_order_${DateTime.now().millisecondsSinceEpoch}",
          amount: (amount * 100).toInt(),
          currency: "INR",
          key: "demo_key_id",
        );
      }

      final order = await _paymentService.createOrder(
        amount: amount,
        scansPurchased: scansPurchased,
      );
      return order;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 9. Payment verification
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required int scansPurchased,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isDemoMode) {
        if (_currentUser != null) {
          final currentScans = _currentUser!.remainingScans;
          _currentUser = _currentUser!.copyWith(remainingScans: currentScans + scansPurchased);
          await _storageService.saveUser(_currentUser!);
        }
        notifyListeners();
        return true;
      }

      final success = await _paymentService.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        scansPurchased: scansPurchased,
        amount: amount,
      );

      if (success) {
        // Fetch fresh profile to sync scanning balance
        await refreshProfile();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 10. Google Play in-app purchases (consumable scan packs)
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
      } else {
        // Keep the catalogue order from IapService rather than Play's ordering.
        final byId = {for (final p in response.productDetails) p.id: p};
        _iapProducts = IapService.packs
            .map((pack) => byId[pack.productId])
            .whereType<ProductDetails>()
            .toList();

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
          await _deliverPurchase(purchase);
          break;

        case PurchaseStatus.error:
          _purchasingProductId = null;
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
          _iapEventController.add(IapEvent.canceled());
          if (purchase.pendingCompletePurchase) {
            await _iapService.complete(purchase);
          }
          notifyListeners();
          break;
      }
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
enum IapEventType { pending, success, failure, canceled }

class IapEvent {
  final IapEventType type;
  final String? message;
  final int scansGranted;

  const IapEvent._(this.type, {this.message, this.scansGranted = 0});

  factory IapEvent.pending() => const IapEvent._(IapEventType.pending);
  factory IapEvent.success(int scans) =>
      IapEvent._(IapEventType.success, scansGranted: scans);
  factory IapEvent.failure(String message) =>
      IapEvent._(IapEventType.failure, message: message);
  factory IapEvent.canceled() => const IapEvent._(IapEventType.canceled);
}
