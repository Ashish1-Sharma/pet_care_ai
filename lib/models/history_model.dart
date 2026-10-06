import 'ai_response_model.dart';

class HistoryItem {
  final String id;
  final String createdAt;
  final List<String> imageUrls;
  final String criticality;
  final List<PossibleCondition> possibleConditions;
  final String petType;
  final String bodyPart;
  
  // Detailed fields in case they are returned or for navigation
  final String reason;
  final String whatOwnerShouldDo;
  final List<String> homeCare;
  final List<String> emergencySigns;
  final bool needVet;
  final String visitWithin;
  final String disclaimer;

  /// Saved pet this scan belongs to, if one was chosen.
  final String? petId;

  /// Id of the first scan in a recovery series (null for a first scan).
  final String? recoveryOf;

  /// The owner's thumbs up/down on the report, if given.
  final bool? accurate;

  HistoryItem({
    required this.id,
    required this.createdAt,
    required this.imageUrls,
    required this.criticality,
    required this.possibleConditions,
    required this.petType,
    required this.bodyPart,
    required this.reason,
    required this.whatOwnerShouldDo,
    required this.homeCare,
    required this.emergencySigns,
    required this.needVet,
    required this.visitWithin,
    required this.disclaimer,
    this.petId,
    this.recoveryOf,
    this.accurate,
  });

  /// Id of the series this scan belongs to (itself when it started one).
  String get seriesId => recoveryOf ?? id;

  DateTime? get createdAtDate => DateTime.tryParse(createdAt)?.toLocal();

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    final aiResponseJson = json['aiResponse'] as Map<String, dynamic>? ?? {};
    final aiResponse = AiResponseData.fromJson(aiResponseJson.isNotEmpty ? aiResponseJson : json);

    return HistoryItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      createdAt: json['createdAt'] ?? '',
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      criticality: aiResponse.criticality,
      possibleConditions: aiResponse.possibleConditions,
      petType: json['petType'] ?? 'Unknown',
      bodyPart: json['bodyPart'] ?? 'Unknown',
      reason: aiResponse.reason,
      whatOwnerShouldDo: aiResponse.whatOwnerShouldDo,
      homeCare: aiResponse.homeCare,
      emergencySigns: aiResponse.emergencySigns,
      needVet: aiResponse.needVet,
      visitWithin: aiResponse.visitWithin,
      disclaimer: aiResponse.disclaimer,
      petId: json['petId']?.toString(),
      recoveryOf: json['recoveryOf']?.toString(),
      accurate: json['feedback'] is Map ? json['feedback']['accurate'] as bool? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'createdAt': createdAt,
      'imageUrls': imageUrls,
      'criticality': criticality,
      'possibleConditions': possibleConditions.map((e) => e.toJson()).toList(),
      'petType': petType,
      'bodyPart': bodyPart,
      'reason': reason,
      'whatOwnerShouldDo': whatOwnerShouldDo,
      'homeCare': homeCare,
      'emergencySigns': emergencySigns,
      'needVet': needVet,
      'visitWithin': visitWithin,
      'disclaimer': disclaimer,
      'petId': petId,
      'recoveryOf': recoveryOf,
    };
  }

  // Convert to AiResponseData for displaying in ResultScreen
  AiResponseData toAiResponseData() {
    return AiResponseData(
      possibleCondition: possibleConditions.isNotEmpty ? possibleConditions.first.name : '',
      criticality: criticality,
      confidence: possibleConditions.isNotEmpty ? possibleConditions.first.probability : 0,
      reasoning: reason,
      summary: whatOwnerShouldDo,
      homeCare: homeCare,
      emergencySigns: emergencySigns,
      visitVet: visitWithin,
      disclaimer: disclaimer,
    );
  }
}
