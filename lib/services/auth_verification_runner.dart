import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthVerificationRunner {
  static Future<void> runFullSequence(BuildContext context) async {
    debugPrint('[AuthVerificationRunner] >>> STEP 1: Logging out for fresh install simulation...');
    await AuthService.instance.logout();
    await Future.delayed(const Duration(seconds: 4));

    debugPrint('[AuthVerificationRunner] >>> STEP 2: Logging in User A (Ahmed Shazly)...');
    final successA = await AuthService.instance.login(
      'ahmed.shazly.abdelgawad@new-build-egypt.com',
      'iliving2026',
    );
    debugPrint('[AuthVerificationRunner] User A login result: $successA');
    await Future.delayed(const Duration(seconds: 6));

    debugPrint('[AuthVerificationRunner] >>> STEP 3: Logging out User A...');
    await AuthService.instance.logout();
    await Future.delayed(const Duration(seconds: 4));

    debugPrint('[AuthVerificationRunner] >>> STEP 4: Logging in User B (Mahmoud Ghanem)...');
    final successB = await AuthService.instance.login(
      'mahmoud.ghanem.ibrahim@new-build-egypt.com',
      'iliving2026',
    );
    debugPrint('[AuthVerificationRunner] User B login result: $successB');
    await Future.delayed(const Duration(seconds: 6));

    debugPrint('[AuthVerificationRunner] >>> Full visual verification sequence in-app done!');
  }
}
