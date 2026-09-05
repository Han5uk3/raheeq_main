# Freshchat Mobile SDK Integration Code Reference

This document provides the complete, isolated code snippets of the Freshchat SDK integration in our Flutter application (**Rahiq**), prepared for review by the **Freshchat Developer Support Team**.

---

## 1. Environment & Setup Details

| Parameter | Value |
|---|---|
| **Freshchat Account** | `suqyarahiq.myfreshworks.com` |
| **SDK Domain** | `msdk.freshchat.com` |
| **Flutter Plugin** | `freshchat_sdk: ^0.10.34` |
| **Android Native SDK** | `com.github.freshworks-oss:freshchat-android:6.5.10` |
| **iOS Native SDK** | `FreshchatSDK: 6.4.9` |
| **User Authentication Mode** | **Strict JWT mode enabled** (`restoreUserWithIdToken`) |
| **Channel Filter Tag** | `["chat_with_us"]` |

---

## 2. UI Pages & Screens (Dart / Flutter)

### A. Contact Us Page (`lib/pages/home/pages/contact_us_page.dart`)
This page handles the primary user action to initiate support chat. A loading state is displayed to prevent duplicate intent dispatching while the native Freshchat activity takes over.

```dart
// lib/pages/home/pages/contact_us_page.dart

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:raheeq_main/services/freshchat_service.dart';
import 'package:raheeq_main/common_widgets/water_loading.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  bool _isNavigating = false;

  Future<void> _handleTap(
    BuildContext context,
    VoidCallback action, {
    bool showLoader = false,
  }) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    if (showLoader) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder: (context) => Center(
          child: Container(
            height: 100,
            width: 100,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: WaterLoadingIndicator(size: 20),
          ),
        ),
      );
      // Brief pause before launching intent
      await Future.delayed(const Duration(milliseconds: 200));
    }

    action();

    // Allow native Freshchat Activity / View Controller to transition
    await Future.delayed(const Duration(seconds: 1));

    if (mounted && showLoader) {
      Navigator.pop(context); // Dismiss loader
    }

    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // "Contact Us / Chat with Us" card trigger
          _buildCard(
            context: context,
            title: "Contact Us",
            description: "Chat with customer support team",
            icon: Icons.chat_bubble_outline,
            onTap: () {
              _handleTap(context, () {
                log(
                  "Attempting to open Freshchat conversations with tags: ['chat_with_us'] and title: 'Rahiq Support'",
                  name: "FreshchatService",
                );
                FreshchatService.showConversations(
                  context,
                  tags: FreshchatService.supportTags, // ['chat_with_us']
                  filteredViewTitle: "Rahiq Support",
                );
              }, showLoader: true);
            },
          ),
        ],
      ),
    );
  }
}
```

---

### B. Home Screen (`lib/pages/home/home_screen.dart`)
Monitors the unread message count via `ValueNotifier`, updates the bottom navigation badge, refreshes count on app lifecycle resume, and intercepts bottom navigation tab taps.

```dart
// lib/pages/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:raheeq_main/services/freshchat_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial fetch of unread messages count
    FreshchatService.refreshUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Since the chat is a native screen, closing or returning from it
  /// does not trigger Flutter widget rebuilds. Re-reading count on resume ensures accuracy.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FreshchatService.refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages(context)[_currentIndex],
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: FreshchatService.unreadCount,
        builder: (context, unreadChats, _) => CustomBottomNavBar(
          currentIndex: _currentIndex,
          items: [
            CustomBottomNavItem(icon: Icons.home_outlined, label: "Home"),
            CustomBottomNavItem(icon: Icons.shopping_bag_outlined, label: "Orders"),
            CustomBottomNavItem(
              icon: Icons.support_agent_outlined,
              label: "Contact Us",
              badgeCount: unreadChats, // Unread chat badge count
            ),
            CustomBottomNavItem(icon: Icons.person_outline, label: "Account"),
          ],
          onTap: (index) {
            // Tapping tab index 2 directly triggers the chat conversation screen
            if (index == 2) {
              FreshchatService.showConversations(
                context,
                tags: FreshchatService.supportTags,
                filteredViewTitle: "Rahiq Support",
              );
            } else {
              setState(() {
                _currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}
```

---

### C. Profile Screen Logout Flow (`lib/pages/home/pages/profile_tab.dart`)
Wipes user identity from the Freshchat SDK when logging out to ensure clean state separation across user accounts.

```dart
// lib/pages/home/pages/profile_tab.dart

import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

Future<void> _logout() async {
  // 1. Invalidate session on backend
  await ApiService().logout(refreshToken: AuthStorage.refreshToken ?? '');

  // 2. Reset Freshchat SDK user so next login does not inherit prior conversation threads
  Freshchat.resetUser();

  // 3. Clear local device storage and return to Login
  await AuthStorage.clear();
}
```

---

## 3. Application Startup & Initialization (`lib/main.dart`)

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/services/freshchat_service.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Load Freshchat credentials
  final freshchatAppId = dotenv.env['FRESHCHAT_APP_ID'];
  final freshchatAppKey = dotenv.env['FRESHCHAT_APP_KEY'];
  final freshchatDomain = dotenv.env['FRESHCHAT_DOMAIN'];

  if (freshchatAppId != null &&
      freshchatAppId.isNotEmpty &&
      freshchatAppKey != null &&
      freshchatAppKey.isNotEmpty &&
      freshchatDomain != null &&
      freshchatDomain.isNotEmpty) {
    
    // 1. Initialize Freshchat SDK
    Freshchat.init(freshchatAppId, freshchatAppKey, freshchatDomain);

    // 2. Register Freshchat event & token listeners
    FreshchatService.init();

    // Allow native SDK init to settle
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Hand over push token for chat push notifications
    await FreshchatService.registerPushToken();

    // 4. Authenticate user via JWT if session exists
    try {
      final user = AuthStorage.user;
      if (user != null) {
        await FreshchatService.authenticateUser(user);
      }
    } catch (e) {
      debugPrint("Failed to set Freshchat user: $e");
    }
  }

  runApp(const MyApp());
}
```

---

## 4. Freshchat Service Wrapper (`lib/services/freshchat_service.dart`)

This service encapsulates all Freshchat SDK interactions (JWT auth, token registration, conversation launching, and unread counters).

```dart
// lib/services/freshchat_service.dart

import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';
import '../models/user.dart';

class FreshchatService {
  static const MethodChannel _pushChannel = MethodChannel('com.rahiq.app/freshchat_push');
  static const List<String> supportTags = ["chat_with_us"];
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Future<void>? _authInFlight;
  static bool _unreadCountInFlight = false;

  /// Setup event and push listeners
  static void init() {
    Freshchat.onFreshchatEvents.listen((event) {
      final eventName = event["event_name"]?.toString() ?? "unknown";
      log("Freshchat event: $eventName", name: "FreshchatService");
    });

    Freshchat.onMessageCountUpdate.listen((_) => refreshUnreadCount());

    // Refresh push token on token change
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      Freshchat.setPushRegistrationToken(token);
    });

    // JWT token refresh request hook
    Freshchat.onJwtRefresh.listen((_) async {
      log("Freshchat asked for a fresh JWT.", name: "FreshchatService");
      await ensureAuthenticated();
      await registerPushToken();
    });
  }

  /// Launch conversations view with specific tag filter
  static Future<void> showConversations(
    BuildContext context, {
    List<String> tags = supportTags,
    String? filteredViewTitle = "Rahiq Support",
  }) async {
    await ensureAuthenticated();
    await registerPushToken(maxRetries: 3);

    final effectiveTags = tags.isEmpty ? supportTags : tags;
    Freshchat.showConversations(
      tags: effectiveTags,
      filteredViewTitle: filteredViewTitle ?? "Rahiq Support",
    );
  }

  /// Strict JWT Authentication Flow
  static Future<void> ensureAuthenticated() async {
    if (_authInFlight != null) {
      return _authInFlight;
    }
    final completer = Completer<void>();
    _authInFlight = completer.future;

    try {
      final status = await Freshchat.getUserIdTokenStatus;
      if (status == JwtTokenStatus.TOKEN_VALID) {
        completer.complete();
        return;
      }

      // Obtain backend-minted JWT token containing freshchat_uuid
      final token = await _getOrGenerateToken();
      if (token != null && token.isNotEmpty) {
        // Restore user via JWT
        Freshchat.restoreUserWithIdToken(token);
      }
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _authInFlight = null;
    }
  }

  /// Fetch unread counts via getUnreadCountAsync with 5-second safety timeout
  static Future<void> refreshUnreadCount() async {
    if (_unreadCountInFlight) return;
    _unreadCountInFlight = true;

    try {
      final result = await Freshchat.getUnreadCountAsync.timeout(
        const Duration(seconds: 5),
      );
      if (result['status'] == 'STATUS_SUCCESS') {
        final count = (result['count'] as num?)?.toInt() ?? 0;
        unreadCount.value = count;
      }
    } catch (e) {
      log("Failed to read Freshchat unread count: $e", name: "FreshchatService");
    } finally {
      _unreadCountInFlight = false;
    }
  }

  /// Push token registration
  static Future<bool> registerPushToken({int maxRetries = 5}) async {
    if (Platform.isAndroid) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        Freshchat.setPushRegistrationToken(token);
        return true;
      }
    } else if (Platform.isIOS) {
      // APNs token handed over through native AppDelegate channel
      return (await _pushChannel.invokeMethod<bool>('syncPushToken')) == true;
    }
    return false;
  }
}
```

---

## 5. Push Notification Forwarding (`lib/services/notification_service.dart`)

```dart
// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart' hide Importance, Priority;
import 'package:raheeq_main/services/freshchat_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intercept Freshchat background data-only pushes
  if (await Freshchat.isFreshchatNotification(message.data)) {
    Freshchat.handlePushNotification(message.data);
  }
}

class NotificationService {
  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground push interception
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (await Freshchat.isFreshchatNotification(message.data)) {
        Freshchat.handlePushNotification(message.data);
        FreshchatService.refreshUnreadCount();
        return;
      }
    });

    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (await Freshchat.isFreshchatNotification(message.data)) {
        Freshchat.handlePushNotification(message.data);
        return;
      }
    });

    // Cold start from notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && await Freshchat.isFreshchatNotification(initialMessage.data)) {
      Freshchat.handlePushNotification(initialMessage.data);
    }
  }
}
```

---

## 6. Native Platform Configurations

### A. Android: FileProvider Configuration (`android/app/src/main/res/values/strings.xml`)
```xml
<!-- android/app/src/main/res/values/strings.xml -->
<resources>
    <!-- Overrides empty FileProvider string required for camera attachments -->
    <string name="freshchat_file_provider_authority" translatable="false">com.rahiq.main.provider</string>
</resources>
```

### B. iOS: APNs & Push Delegate (`ios/Runner/AppDelegate.swift`)
```swift
// ios/Runner/AppDelegate.swift

import UIKit
import Flutter
import freshchat_sdk

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let pushChannel = FlutterMethodChannel(
      name: "com.rahiq.app/freshchat_push",
      binaryMessenger: controller.binaryMessenger
    )

    pushChannel.setMethodCallHandler { (call, result) in
      if call.method == "syncPushToken" {
        if let token = self.cachedApnsToken {
          FreshchatSdkPlugin().setPushRegistrationToken(token)
          result(true)
        } else {
          result(false)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    FreshchatSdkPlugin().setPushRegistrationToken(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Intercept remote notification payload
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let plugin = FreshchatSdkPlugin()
    if plugin.isFreshchatNotification(userInfo) {
      plugin.handlePushNotification(userInfo)
      completionHandler(.newData)
      return
    }
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
```
