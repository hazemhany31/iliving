import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Reusable API client wrapping HTTP requests with built-in timeouts, retries, and clean logging.
class ApiClient {
  ApiClient._internal();

  /// Singleton access point.
  static final ApiClient instance = ApiClient._internal();

  final http.Client _client = http.Client();

  /// Executes an HTTP GET request with retries and timeout boundaries.
  Future<http.Response> get(Uri url, {Map<String, String>? headers, int retries = 3, Duration timeout = const Duration(seconds: 10)}) async {
    int attempts = 0;
    while (attempts < retries) {
      attempts++;
      try {
        debugPrint("[ApiClient] GET Request attempt $attempts/$retries to: $url");
        final response = await _client.get(url, headers: headers).timeout(timeout);
        return response;
      } on TimeoutException catch (e) {
        debugPrint("[ApiClient] Timeout during request attempt $attempts/$retries: $e");
        if (attempts >= retries) rethrow;
      } on Exception catch (e) {
        debugPrint("[ApiClient] Network exception during request attempt $attempts/$retries: $e");
        if (attempts >= retries) rethrow;
      }
      // Wait briefly before retrying
      await Future.delayed(Duration(milliseconds: 300 * attempts));
    }
    throw http.ClientException("Request failed after $retries attempts", url);
  }
}
