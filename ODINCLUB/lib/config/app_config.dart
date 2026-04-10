import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // Backend base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 est l'alias localhost pour l'émulateur Android
      return 'http://10.0.2.2:3000/api';
    } else {
      // Pour iOS ou desktop
      return 'http://localhost:3000/api';
    }
  }
  static String get apiBaseUrl => baseUrl;

  static String get playerValueAiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8300';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8300';
    } else {
      return 'http://localhost:8300';
    }
  }
}
