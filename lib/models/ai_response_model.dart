class PossibleCondition {
  final String name;
  final int probability;

  PossibleCondition({
    required this.name,
    required this.probability,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> json) {
    return PossibleCondition(
      name: json['name'] ?? '',
      probability: (json['probability'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'probability': probability,
    };
  }
}

class AiResponseData {
  final String possibleCondition;
  final String criticality;
  final int confidence;
  final String reasoning;
  final String summary;
  final List<String> homeCare;
  final List<String> emergencySigns;
  final String visitVet;
  final String disclaimer;

  AiResponseData({
    required this.possibleCondition,
    required this.criticality,
    required this.confidence,
    required this.reasoning,
    required this.summary,
    required this.homeCare,
    required this.emergencySigns,
    required this.visitVet,
    required this.disclaimer,
  });

  // Backward compatibility getters for UI code
  List<PossibleCondition> get possibleConditions {
    if (possibleCondition.isNotEmpty) {
      return [PossibleCondition(name: possibleCondition, probability: confidence)];
    }
    return [];
  }

  String get reason => reasoning;
  String get whatOwnerShouldDo => summary;
  
  bool get needVet {
    final lower = visitVet.toLowerCase();
    if (lower.contains('no') && !lower.contains('within') && !lower.contains('hours')) {
      return false;
    }
    return visitVet.isNotEmpty;
  }
  
  String get visitWithin => visitVet;

  factory AiResponseData.fromJson(Map<String, dynamic> json) {
    // Safely retrieve possibleCondition or possibleConditions fallback
    String condStr = json['possibleCondition'] ?? '';
    if (condStr.isEmpty && json['possibleConditions'] != null) {
      if (json['possibleConditions'] is List && (json['possibleConditions'] as List).isNotEmpty) {
        condStr = json['possibleConditions'][0]['name'] ?? '';
      } else {
        condStr = json['possibleConditions'].toString();
      }
    }

    // Safely retrieve confidence or probability fallback
    int confInt = 0;
    if (json['confidence'] != null) {
      confInt = (json['confidence'] as num).toInt();
    } else if (json['probability'] != null) {
      confInt = (json['probability'] as num).toInt();
    } else if (json['possibleConditions'] is List && (json['possibleConditions'] as List).isNotEmpty) {
      confInt = (json['possibleConditions'][0]['probability'] as num?)?.toInt() ?? 0;
    }

    return AiResponseData(
      possibleCondition: condStr,
      criticality: json['criticality'] ?? 'Low',
      confidence: confInt,
      reasoning: json['reasoning'] ?? json['reason'] ?? '',
      summary: json['summary'] ?? json['whatOwnerShouldDo'] ?? '',
      homeCare: (json['homeCare'] as List?)?.map((e) => e.toString()).toList() ?? [],
      emergencySigns: (json['emergencySigns'] as List?)?.map((e) => e.toString()).toList() ?? [],
      visitVet: json['visitVet'] ?? json['visitWithin'] ?? '',
      disclaimer: json['disclaimer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'possibleCondition': possibleCondition,
      'criticality': criticality,
      'confidence': confidence,
      'reasoning': reasoning,
      'summary': summary,
      'homeCare': homeCare,
      'emergencySigns': emergencySigns,
      'visitVet': visitVet,
      'disclaimer': disclaimer,
    };
  }
}

class AiResponseModel {
  final bool success;
  final int remainingScans;
  final AiResponseData? data;

  /// Server id of the saved scan, used for feedback and recovery follow-ups.
  final String? scanId;

  /// Id of the first scan in the recovery series this scan belongs to.
  final String? recoveryOf;
  final bool isPlus;

  AiResponseModel({
    required this.success,
    required this.remainingScans,
    this.data,
    this.scanId,
    this.recoveryOf,
    this.isPlus = false,
  });

  factory AiResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle root 'scan' object if present (as returned by POST /api/pet/analyze)
    final scan = json['scan'] as Map<String, dynamic>?;
    final Map<String, dynamic> aiResponseJson = scan != null
        ? (scan['aiResponse'] as Map<String, dynamic>? ?? {})
        : (json['data'] as Map<String, dynamic>? ?? json['aiResponse'] as Map<String, dynamic>? ?? {});

    return AiResponseModel(
      success: json['success'] ?? (scan != null),
      remainingScans:
          ((json['remainingScans'] ?? json['user']?['remainingScans'] ?? 0) as num)
              .toInt(),
      data: AiResponseData.fromJson(aiResponseJson),
      scanId: scan?['id']?.toString(),
      recoveryOf: scan?['recoveryOf']?.toString(),
      isPlus: json['isPlus'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'remainingScans': remainingScans,
      'data': data?.toJson(),
    };
  }
}
