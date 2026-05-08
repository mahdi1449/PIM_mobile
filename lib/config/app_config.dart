import 'package:flutter/foundation.dart';

class AppConfig {
  // Backend base URL
  // For Android emulator: http://10.0.2.2:3000
  // For Flutter web/iOS simulator: http://localhost:3000
  // For physical device on same Wi-Fi: http://<YOUR_MAC_LOCAL_IP>:3000
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.trim();
    }
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:3000';
    }
    return 'http://192.168.1.181:3000';
  }

  // Player Value AI service
  // For Android emulator: http://10.0.2.2:8002
  // For Flutter web/iOS simulator: http://localhost:8002
  static const String _playerValueAiOverride = String.fromEnvironment(
    'PLAYER_VALUE_AI_BASE_URL',
    defaultValue: '',
  );
  static String get playerValueAiBaseUrl {
    if (_playerValueAiOverride.trim().isNotEmpty) {
      return _playerValueAiOverride.trim();
    }
    if (kIsWeb) {
      final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      return 'http://$host:8002';
    }
    return 'http://192.168.1.181:8002';
  }

  static String get apiBaseUrl => '$baseUrl/api';

  static const List<String> webrtcStunUrls = <String>[
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
  ];

  static const String _webrtcTurnUrlRaw = String.fromEnvironment(
    'WEBRTC_TURN_URL',
    defaultValue: '',
  );
  static const String _webrtcTurnUsernameRaw = String.fromEnvironment(
    'WEBRTC_TURN_USERNAME',
    defaultValue: '',
  );
  static const String _webrtcTurnCredentialRaw = String.fromEnvironment(
    'WEBRTC_TURN_CREDENTIAL',
    defaultValue: '',
  );

  static final String? webrtcTurnUrl = _webrtcTurnUrlRaw.trim().isEmpty
      ? null
      : _webrtcTurnUrlRaw.trim();
  static final String? webrtcTurnUsername =
      _webrtcTurnUsernameRaw.trim().isEmpty
      ? null
      : _webrtcTurnUsernameRaw.trim();
  static final String? webrtcTurnCredential =
      _webrtcTurnCredentialRaw.trim().isEmpty
      ? null
      : _webrtcTurnCredentialRaw.trim();
}
