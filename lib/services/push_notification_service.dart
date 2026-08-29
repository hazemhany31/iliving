import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../repositories/firestore/firestore_notification_repository.dart';

/// Top-level handler for FCM background messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[PushNotificationService] Background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging (FCM) and local notification display.
///
/// Responsibilities:
/// 1. Request notification permissions (iOS / Android 13+)
/// 2. Obtain and persist FCM device token in Firestore
/// 3. Display local notification banners when app is in foreground
/// 4. Handle notification taps for deep linking
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? get _messaging {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseMessaging.instance;
      }
    } catch (_) {}
    return null;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _currentUserId;
  StreamSubscription<String>? _tokenRefreshSub;

  /// The Android notification channel used for high-importance notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'iliving_high_importance',
    'iLiving Notifications',
    description: 'Push notifications for payments, maintenance, and reminders.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM, request permissions, and set up local notification display.
  /// Call this once during app bootstrap (after Firebase.initializeApp).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[PushNotificationService] Firebase not initialized. Skipping push notification setup.');
        _initialized = true;
        return;
      }
      final messaging = _messaging;
      if (messaging == null) {
        _initialized = true;
        return;
      }

      // Register background handler
      try {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      } catch (e) {
        debugPrint('[PushNotificationService] onBackgroundMessage note: $e');
      }

      // Request permission (iOS shows a dialog; Android 13+ shows a dialog)
      NotificationSettings? settings;
      try {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          announcement: true,
          criticalAlert: false,
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[PushNotificationService] requestPermission note: $e');
      }

      debugPrint(
        '[PushNotificationService] Permission status: ${settings?.authorizationStatus}',
      );

      if (settings?.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushNotificationService] Notifications denied by user.');
        _initialized = true;
        return;
      }

      // Initialize local notifications plugin
      try {
        await _initializeLocalNotifications().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('[PushNotificationService] _initializeLocalNotifications note: $e');
      }

      // Create the Android notification channel
      try {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      } catch (_) {}

      // Listen for foreground FCM messages and display as local notifications
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background (not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a terminated state via notification
      try {
        final initialMessage = await messaging.getInitialMessage().timeout(const Duration(seconds: 2));
        if (initialMessage != null) {
          _handleNotificationTap(initialMessage);
        }
      } catch (_) {}

      // Set foreground notification presentation options for iOS
      try {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}

      _initialized = true;
      debugPrint('[PushNotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[PushNotificationService] Initialization error: $e');
      _initialized = true; // Mark as initialized to prevent repeated attempts
    }
  }

  /// Register the device FCM token for a specific user.
  /// Call after user login.
  Future<void> registerTokenForUser(String userId) async {
    _currentUserId = userId;

    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await FirestoreNotificationRepository().saveFcmToken(userId, token);
        debugPrint('[PushNotificationService] Token registered for user $userId');
      }

      // Listen for token refreshes
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        if (_currentUserId != null && newToken.isNotEmpty) {
          await FirestoreNotificationRepository()
              .saveFcmToken(_currentUserId!, newToken);
          debugPrint('[PushNotificationService] Token refreshed for $_currentUserId');
        }
      });
    } catch (e) {
      debugPrint('[PushNotificationService] Token registration error: $e');
    }
  }

  /// Unregister the device FCM token. Call on user logout.
  Future<void> unregisterToken(String userId) async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;
      final token = await messaging.getToken();
      if (token != null) {
        await FirestoreNotificationRepository().removeFcmToken(userId, token);
      }
      _tokenRefreshSub?.cancel();
      _currentUserId = null;
      debugPrint('[PushNotificationService] Token unregistered for user $userId');
    } catch (e) {
      debugPrint('[PushNotificationService] Token unregister error: $e');
    }
  }

  /// Show a local notification on the device.
  /// This is called from NotificationService after saving to Firestore,
  /// so every in-app action that creates a notification also pushes to the device.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use timestamp as notification ID to ensure uniqueness
      final id = DateTime.now().millisecondsSinceEpoch % 2147483647;

      await _localNotifications.show(id, title, body, details, payload: payload);
      debugPrint('[PushNotificationService] Local notification shown: $title');
    } catch (e) {
      debugPrint('[PushNotificationService] Show notification error: $e');
    }
  }

  // ─── Private helpers ───────────────────────────────────────────────

  Future<void> _initializeLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // Already handled by FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint(
      '[PushNotificationService] Foreground message: ${notification.title}',
    );

    showLocalNotification(
      title: notification.title ?? 'iLiving',
      body: notification.body ?? '',
      payload: message.data['deepLinkRoute'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint(
      '[PushNotificationService] Notification tapped: ${message.data}',
    );
    // Deep link handling can be added here in the future
    // e.g., navigate to a specific screen based on message.data['deepLinkRoute']
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint(
      '[PushNotificationService] Local notification tapped: ${response.payload}',
    );
    // Deep link handling for local notifications
  }
}
