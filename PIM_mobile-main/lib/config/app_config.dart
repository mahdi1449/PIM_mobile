class AppConfig {
  // Backend base URL
  // For Android emulator: http://10.0.2.2:3000
  // For iOS simulator: http://localhost:3000
  // For physical device on same Wi-Fi: http://<YOUR_MAC_LOCAL_IP>:3000
  static const String _baseUrlRaw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static String get baseUrl => _baseUrlRaw;

  // Player Value AI service
  // For Android emulator: http://10.0.2.2:8002
  // For iOS simulator: http://localhost:8002
  static const String playerValueAiBaseUrl = 'http://10.0.2.2:8002';

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
