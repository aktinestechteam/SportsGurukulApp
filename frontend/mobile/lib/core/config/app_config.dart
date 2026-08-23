import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 30;

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5249/api';
    }

    return 'http://localhost:5249/api';
  }
}
