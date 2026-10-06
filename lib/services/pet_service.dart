import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api.dart';
import '../config/app_config.dart';
import '../models/pet_profile.dart';
import '../models/user_model.dart';
import '../models/ai_response_model.dart';
import '../models/history_model.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class PetService {
  final ApiService _apiService;

  PetService(this._apiService);

  // Reload/Fetch fresh user profile from backend
  Future<UserModel> getProfile() async {
    final response = await _apiService.get(ApiEndpoints.profile);
    if (response.data == null) {
      throw 'Failed to retrieve profile data.';
    }
    return UserModel.fromJson(response.data);
  }

  // Load history list from backend
  Future<List<HistoryItem>> getHistory() async {
    final response = await _apiService.get(ApiEndpoints.history);
    if (response.data is! List) {
      throw 'Invalid history response format.';
    }
    final List list = response.data;
    return list.map((item) => HistoryItem.fromJson(item)).toList();
  }

  // Delete history item from backend
  Future<void> deleteHistoryItem(String id) async {
    await _apiService.delete(ApiEndpoints.deleteHistory(id));
  }

  // Upload pet scan details
  Future<AiResponseModel> analyzePet({
    required String petType,
    required String bodyPart,
    required String description,
    required List<String> symptoms,
    required List<String> imagePaths,
    String? petId,
    String? recoveryOf,
  }) async {
    // Map symptom names to backend slugs (lower_case with underscores)
    final List<String> mappedSymptoms = symptoms.map((s) => Helpers.mapSymptomToSlug(s)).toList();

    // 1. Construct FormData fields supporting both array formats
    final Map<String, dynamic> fields = {
      'petType': petType,
      'bodyPart': bodyPart,
      'description': description,
      'symptoms': mappedSymptoms,
      'symptoms[]': mappedSymptoms,
      if (petId != null) 'petId': petId,
      if (recoveryOf != null) 'recoveryOf': recoveryOf,
    };

    final List<MultipartFile> files = [];
    for (final path in imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        final filename = path.split(Platform.pathSeparator).last;
        files.add(
          await MultipartFile.fromFile(path, filename: filename),
        );
      }
    }

    // Set fields and files under the required 'images[]' key name
    final formData = FormData.fromMap({
      ...fields,
      'images[]': files,
    });

    // 2. POST multipart request. Never retried automatically: a timed-out
    // scan may still complete server-side and spend a credit.
    final response = await _apiService.post(
      ApiEndpoints.analyze,
      data: formData,
      timeout: const Duration(milliseconds: AppConfig.scanTimeoutMs),
      retryOnTimeout: false,
    );

    // The backend returns `{ scan, aiResponse }` on success — there is no
    // `success` flag to test.
    if (response.data == null || response.data['aiResponse'] == null) {
      throw 'Analysis failed on server.';
    }

    return AiResponseModel.fromJson(response.data);
  }

  /// Thumbs up/down on a report's accuracy.
  Future<void> sendScanFeedback(String scanId, {required bool accurate}) async {
    await _apiService.post(
      ApiEndpoints.scanFeedback(scanId),
      data: {'accurate': accurate},
    );
  }

  // --- Saved pets ------------------------------------------------------------

  Future<PetProfile> createPet(PetProfile pet) async {
    final response = await _apiService.post(ApiEndpoints.pets, data: pet.toRequest());
    return PetProfile.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<PetProfile> updatePet(PetProfile pet) async {
    final response = await _apiService.put(ApiEndpoints.pet(pet.id), data: pet.toRequest());
    return PetProfile.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<void> deletePet(String petId) async {
    await _apiService.delete(ApiEndpoints.pet(petId));
  }

  // --- Referrals -------------------------------------------------------------

  /// Redeems a friend's invite code. Returns the updated profile.
  Future<UserModel> redeemReferral(String code) async {
    final response = await _apiService.post(
      ApiEndpoints.redeemReferral,
      data: {'code': code.trim().toUpperCase()},
    );
    return UserModel.fromJson(Map<String, dynamic>.from(response.data['user']));
  }
}
