import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart' hide Importance, Priority;
import 'package:raheeq_main/services/notification_navigation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint('Handling a background message: ${message.messageId}');

  // Freshchat pushes are data-only (no `notification` block), so they'd
  // otherwise be silently dropped by this app's own handler. Without this,
  // Freshchat's SDK only picks new messages up on its own lazy sync when the
  // conversation screen is next opened, which shows up as a long delay.
  if (await Freshchat.isFreshchatNotification(message.data)) {
    Freshchat.handlePushNotification(message.data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Request permissions for iOS and Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: false,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create a high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      showBadge: false,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Update foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: false,
      sound: true,
    );

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      // Freshchat pushes are data-only (no `notification` block), so they'd
      // otherwise fall through untouched below. Forwarding them lets the SDK
      // update the open conversation immediately instead of relying on its
      // own lazy sync, which is what caused the long display delay.
      if (await Freshchat.isFreshchatNotification(message.data)) {
        Freshchat.handlePushNotification(message.data);
        return;
      }

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _showLocalNotification(message, channel);
      }
    });

    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleNotificationClick(message.toMap());
    });

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.toMap());
    }

    _isInitialized = true;

    // Print FCM Token for testing
    try {
      String? token = await getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<String?> getToken() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await _firebaseMessaging.getAPNSToken();
    }
    return await _firebaseMessaging.getToken();
  }

  void _showLocalNotification(
    RemoteMessage message,
    AndroidNotificationChannel channel,
  ) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon ?? '@drawable/ic_notification',
            importance: Importance.max,
            priority: Priority.high,
            // other properties...
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: false,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationClick(data);
      } catch (e) {
        debugPrint('Error decoding notification payload: $e');
      }
    }
  }

  Map<String, dynamic>? _pendingNotificationData;
  bool _isHomeScreenReady = false;

  void markHomeScreenReady() {
    _isHomeScreenReady = true;
    if (_pendingNotificationData != null) {
      final data = _pendingNotificationData!;
      _pendingNotificationData = null;
      _handleNotificationClick(data);
    }
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    debugPrint('Handling notification click with data: $data');

    if (!_isHomeScreenReady) {
      debugPrint('HomeScreen not ready, buffering notification click.');
      _pendingNotificationData = data;
      return;
    }

    // The data payload from RemoteMessage.toMap() is under the 'data' key
    final innerData = data['data'];

    // Routed through the same resolver the in-app notifications list uses, so
    // a push tap and a tap in the list land on the same page with the same
    // back stack. Order confirmations resolve to null and open nothing.
    final payload = (innerData is Map) ? innerData : data;
    final destination = NotificationNavigator.destinationFor(
      payload,
      fallbackToOrders: false,
    );
    if (destination == null) return;

    NotificationNavigator.open(destination);
  }
}
