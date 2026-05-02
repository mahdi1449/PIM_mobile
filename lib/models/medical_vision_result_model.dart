class MedicalVisionTopK {
  const MedicalVisionTopK({required this.label, required this.confidence});

  final String label;
  final double confidence;

  factory MedicalVisionTopK.fromJson(Map<String, dynamic> json) {
    return MedicalVisionTopK(
      label: (json['label'] ?? 'unknown').toString(),
      confidence: _doubleFrom(json['confidence']).clamp(0.0, 1.0),
    );
  }

  static double _doubleFrom(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class MedicalVisionResultModel {
  const MedicalVisionResultModel({
    required this.label,
    required this.injuryName,
    required this.equipmentName,
    required this.confidence,
    required this.topK,
    required this.advice,
    required this.rehab,
    required this.muscles,
    this.model,
    this.inferenceMs,
  });

  final String label;
  final String injuryName;
  final String equipmentName;
  final double confidence;
  final List<MedicalVisionTopK> topK;
  final List<String> advice;
  final List<String> rehab;
  final List<String> muscles;
  final String? model;
  final int? inferenceMs;

  factory MedicalVisionResultModel.fromJson(Map<String, dynamic> json) {
    final confidence = _doubleFrom(json['confidence']);
    final normalizedConfidence =
        (confidence > 1 ? confidence / 100 : confidence).clamp(0.0, 1.0);

    final topK = _listFrom(json['topK'])
        .map((item) => MedicalVisionTopK.fromJson(item as Map<String, dynamic>))
        .toList();

    return MedicalVisionResultModel(
      label: (json['label'] ?? 'unknown').toString(),
      injuryName: (json['injuryName'] ?? json['label'] ?? 'Unknown').toString(),
      equipmentName: (json['equipmentName'] ?? json['label'] ?? 'Unknown')
          .toString(),
      confidence: normalizedConfidence,
      topK: topK.isEmpty
          ? [
              MedicalVisionTopK(
                label: (json['label'] ?? 'unknown').toString(),
                confidence: normalizedConfidence,
              ),
            ]
          : topK,
      advice: _stringListFrom(json['advice']),
      rehab: _stringListFrom(json['rehab']),
      muscles: _stringListFrom(json['muscles']),
      model: json['model']?.toString(),
      inferenceMs: _intFrom(json['inferenceMs']),
    );
  }

  static double _doubleFrom(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int? _intFrom(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static List<dynamic> _listFrom(dynamic value) {
    if (value is List) {
      return value;
    }
    return const [];
  }

  static List<String> _stringListFrom(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      return value
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
