import 'package:flutter_tts/flutter_tts.dart';

class LearningTts {
  LearningTts._();

  static final FlutterTts _tts = FlutterTts();
  static bool _configured = false;

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _ensureConfigured();
    await _tts.stop();
    await _tts.speak(trimmed);
  }

  static Future<void> stop() async {
    await _ensureConfigured();
    await _tts.stop();
  }
}
