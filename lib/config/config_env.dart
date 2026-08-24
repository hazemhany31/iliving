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
        return 'https://staging-api.iliving.com.eg';
      case Environment.prod:
        return 'https://api.iliving.com.eg';
    }
  }

  static String get firebaseBucket {
    switch (currentEnvironment) {
      case Environment.dev:
        return 'iliving-dev.appspot.com';
      case Environment.staging:
        return 'iliving-staging.appspot.com';
      case Environment.prod:
        return 'iliving-prod.appspot.com';
    }
  }

  static bool get enableAnalytics => currentEnvironment == Environment.prod;
}
