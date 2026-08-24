import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class ConfigEnv {
  static Environment get currentEnvironment {
    if (kDebugMode) {
      return Environment.dev;
    } else if (kProfileMode) {
      return Environment.staging;
    } else {
      return Environment.prod;
    }
  }

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'http://localhost:8000';
      case Environment.staging:
        return 'https://staging-api.ihome.com.eg';
      case Environment.prod:
        return 'https://api.ihome.com.eg';
    }
  }

  static String get firebaseBucket {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'ihome-dev.appspot.com';
      case Environment.staging:
        return 'ihome-staging.appspot.com';
      case Environment.prod:
        return 'ihome-prod.appspot.com';
    }
  }

  static bool get enableAnalytics => currentEnvironment == Environment.prod;
}
