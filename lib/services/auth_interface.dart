import 'package:flutter/foundation.dart';
import '../models/auth_model.dart';

/// Clean authentication abstraction supporting simulated, REST JWT, or Firebase authentication.
abstract class IAuthService {
  /// Reactive notifier for authentication state changes.
  ValueNotifier<AuthState> get stateNotifier;

  /// Returns the current authentication state.
  AuthState get currentState;

  /// Returns the loaded profile of the currently logged-in client.
  ClientProfile? get currentProfile;

  /// Bootstraps authentication state, checking local persistence or token validity.
  Future<void> initialize();

  /// Validates credentials against authentication providers and logs the user in.
  Future<bool> login(String email, String password);

  /// Performs cleanup, resets authentication state, and signs out.
  Future<void> logout();

  /// Asynchronously loads or refreshes the logged-in client profile.
  Future<ClientProfile> loadClientProfile();
}
