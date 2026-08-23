import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Repository handling submission of Expression of Interest (EOI) leads.
class EoiRepository {
  EoiRepository._internal();

  /// Singleton access point.
  static final EoiRepository instance = EoiRepository._internal();

  static const String _productionEndpoint = 'https://new-build-egypt.com/api/v1/eoi/submit';

  Uri get _submitUri {
    if (kIsWeb) {
      final baseUri = Uri.parse(Uri.base.toString());
      if (baseUri.host == 'localhost' || baseUri.host == '127.0.0.1') {
        return Uri.parse('http://localhost:8000/api/v1/eoi/submit');
      } else {
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: '/api/v1/eoi/submit',
        );
      }
    } else {
      if (kDebugMode) {
        return Uri.parse('http://localhost:8000/api/v1/eoi/submit');
      }
      return Uri.parse(_productionEndpoint);
    }
  }

  /// Submits EOI details to Firebase Firestore and the local/remote backend server.
  Future<bool> submitEoi({
    required String name,
    required String email,
    required String phone,
    required double amount,
    required String compoundId,
    required String compoundTitle,
    required String unitType,
    String paymentMethod = 'Not Specified',
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'phone': phone,
      'amount': amount,
      'compound_id': compoundId,
      'compound_title': compoundTitle,
      'unit_type': unitType,
      'payment_method': paymentMethod,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    bool firestoreSuccess = false;
    bool httpSuccess = false;

    // 1. Try Firestore submission (cloud backup)
    try {
      await FirebaseFirestore.instance
          .collection('eois')
          .add(payload)
          .timeout(const Duration(seconds: 4));
      firestoreSuccess = true;
      debugPrint("[EoiRepository] Firestore EOI submission successful.");
    } catch (e) {
      debugPrint("[EoiRepository] Firestore EOI submission error: $e");
    }

    // 2. Try HTTP submission to backend server (live site if not localhost)
    if (_submitUri.host != 'localhost' && _submitUri.host != '127.0.0.1') {
      try {
        final response = await http.post(
          _submitUri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200 || response.statusCode == 201) {
          httpSuccess = true;
          debugPrint("[EoiRepository] HTTP EOI submission successful: ${response.body}");
        } else {
          debugPrint("[EoiRepository] HTTP EOI submission failed with code ${response.statusCode}: ${response.body}");
        }
      } catch (e) {
        debugPrint("[EoiRepository] HTTP EOI submission error: $e");
      }
    }

    // Return true if at least one submission was successful
    return firestoreSuccess || httpSuccess;
  }
}
