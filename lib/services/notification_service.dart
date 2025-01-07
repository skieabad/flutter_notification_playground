import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_playground/dashboard_page.dart';
import 'package:flutter_notification_playground/main.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupNotifications();
  NotificationService.instance.showNotification(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await setupNotifications();
    await _setupMessageHandlers();

    final token = await _messaging.getToken();
    log('Firebase messaging token:=== $token');
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    log('Notification permission status:=== ${settings.authorizationStatus}');
  }

  Future<void> setupNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettingsDarwin = DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        _handleNotificationTap(payload);
      },
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      showNotification(message);
    });

    // Handle background state messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle terminated state - check for initial message
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessage(initialMessage);
      });
    }
  }

  void showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification == null && android == null) {
      return;
    }

    await _localNotifications.show(
      notification.hashCode,
      notification?.title ?? '',
      notification?.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          // Add these flags for better handling when app is closed
          showWhen: true,
          autoCancel: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _handleMessage(RemoteMessage message) {
    log('Handling message:=== ${message.messageId}');
    _navigateToDashboard();
  }

  void _handleNotificationTap(String? payload) {
    log('Handling notification tap with payload:=== $payload');
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (ctx) => const DashboardPage(),
      ),
    );
  }
}
