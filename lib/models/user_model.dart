import 'pet_profile.dart';

/// The active PetCare Plus subscription, as reported by the server.
class PlanInfo {
  final String productId;
  final String status;
  final DateTime? expiresAt;
  final bool autoRenewing;
  final bool isTrial;

  const PlanInfo({
    required this.productId,
    required this.status,
    required this.expiresAt,
    required this.autoRenewing,
    required this.isTrial,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      productId: json['productId'] ?? '',
      status: json['status'] ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt'] ?? '')?.toLocal(),
      autoRenewing: json['autoRenewing'] == true,
      isTrial: json['isTrial'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'status': status,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
    'autoRenewing': autoRenewing,
    'isTrial': isTrial,
  };

  bool get isYearly => productId.contains('yearly');
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String profileImage;
  final int remainingScans;

  final bool isPlus;
  final PlanInfo? plan;

  /// Null means unlimited (Plus).
  final int? chatRemainingToday;
  final int? chatDailyLimit;
  final int freeWeeklyScans;

  final String? referralCode;
  final bool referralRedeemed;
  final List<PetProfile> pets;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.remainingScans,
    this.isPlus = false,
    this.plan,
    this.chatRemainingToday,
    this.chatDailyLimit,
    this.freeWeeklyScans = 1,
    this.referralCode,
    this.referralRedeemed = false,
    this.pets = const [],
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
      remainingScans: (json['remainingScans'] as num?)?.toInt() ?? 0,
      isPlus: json['isPlus'] == true,
      plan: json['plan'] is Map<String, dynamic>
          ? PlanInfo.fromJson(json['plan'])
          : null,
      chatRemainingToday: (json['chatRemainingToday'] as num?)?.toInt(),
      chatDailyLimit: (json['chatDailyLimit'] as num?)?.toInt(),
      freeWeeklyScans: (json['freeWeeklyScans'] as num?)?.toInt() ?? 1,
      referralCode: json['referralCode'],
      referralRedeemed: json['referralRedeemed'] == true,
      pets: (json['pets'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PetProfile.fromJson)
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'remainingScans': remainingScans,
      'isPlus': isPlus,
      'plan': plan?.toJson(),
      'chatRemainingToday': chatRemainingToday,
      'chatDailyLimit': chatDailyLimit,
      'freeWeeklyScans': freeWeeklyScans,
      'referralCode': referralCode,
      'referralRedeemed': referralRedeemed,
      'pets': pets.map((p) => p.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Whether a new scan can start: Plus, or at least one scan credit.
  bool get canScan => isPlus || remainingScans > 0;

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? profileImage,
    int? remainingScans,
    bool? isPlus,
    int? chatRemainingToday,
    List<PetProfile>? pets,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      remainingScans: remainingScans ?? this.remainingScans,
      isPlus: isPlus ?? this.isPlus,
      plan: plan,
      chatRemainingToday: chatRemainingToday ?? this.chatRemainingToday,
      chatDailyLimit: chatDailyLimit,
      freeWeeklyScans: freeWeeklyScans,
      referralCode: referralCode,
      referralRedeemed: referralRedeemed,
      pets: pets ?? this.pets,
      createdAt: createdAt,
    );
  }
}
