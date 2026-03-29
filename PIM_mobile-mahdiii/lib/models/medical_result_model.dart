class MedicalResultModel {
  const MedicalResultModel({
    required this.injured,
    required this.injuryProbability,
    required this.severity,
    required this.injuryType,
    required this.recoveryDays,
    required this.rehabilitation,
    required this.prevention,
    required this.warning,
  });

  final bool injured;
  final double injuryProbability;
  final String severity;
  final String injuryType;
  final int recoveryDays;
  final List<String> rehabilitation;
  final List<String> prevention;
  final String warning;

  factory MedicalResultModel.fromJson(Map<String, dynamic> json) {
    return MedicalResultModel(
      injured: _boolFrom(json, ['injured', 'isInjured', 'injury']),
      injuryProbability: _doubleFrom(json, [
        'injuryProbability',
        'probability',
        'risk',
      ]),
      severity: _stringFrom(json, ['severity', 'riskLevel']) ?? 'Mild',
      injuryType: _stringFrom(json, ['injuryType', 'type']) ?? 'None',
      recoveryDays: _intFrom(json, ['recoveryDays', 'days', 'recovery']),
      rehabilitation: _listFrom(json, ['rehabilitation', 'rehab', 'therapy']),
      prevention: _listFrom(json, ['prevention', 'tips']),
      warning: _stringFrom(json, ['warning', 'alert']) ?? '',
    );
  }

  static bool _boolFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower == 'true') {
          return true;
        }
        if (lower == 'false') {
          return false;
        }
      }
    }
    return false;
  }

  static String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  static int _intFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static double _doubleFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0.0;
  }

  static List<String> _listFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
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
    }
    return const [];
  }
}
