# Complete Freshchat SDK & Push Notification Configuration Guide (Android & iOS)

This guide documents the complete setup for integrating the Freshchat Flutter SDK (`freshchat_sdk`) into your Flutter application, covering SDK initialization, UI integration, and detailed native push notification setup for both **iOS** (APNs) and **Android** (FCM).

---

## Table of Contents
1. [Overview & Dependencies](#1-overview--dependencies)
2. [Flutter (Dart) Integration](#2-flutter-dart-integration)
3. [iOS Setup & Push Notifications](#3-ios-setup--push-notifications)
4. [Android Setup & Push Notifications](#4-android-setup--push-notifications)
5. [Verification & Testing Checklist](#5-verification--testing-checklist)

---

## 1. Overview & Dependencies

### `pubspec.yaml`
Ensure `freshchat_sdk` is listed in your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  freshchat_sdk: ^0.9.6
  firebase_core: ^1.10.0      # Required for Android FCM Push Notifications
  firebase_messaging: ^11.1.0 # Required for Android FCM Push Notifications
```

---

## 2. Flutter (Dart) Integration

### A. Initialization
Initialize the Freshchat SDK early in your application lifecycle (e.g. inside `initState` of your main screen or after app startup):

```dart
import 'package:freshchat_sdk/freshchat_sdk.dart';

void initFreshchat() {
  Freshchat.init(
    "YOUR_APP_ID",       // From Freshchat Admin Portal -> Settings -> Account Settings -> Integration Settings
    "YOUR_APP_KEY",      // From Freshchat Admin Portal
    "YOUR_DOMAIN_URL",   // e.g. "msdk.freshchat.com" or "msdk.in.freshchat.com"
    teamMemberInfoVisible: true,
    cameraCaptureEnabled: true,
    gallerySelectionEnabled: true,
    responseExpectationEnabled: true,
  );
}
```

### B. User Identification & Profile
Associate logged-in user details with Freshchat:

```dart
void setUserProfile({
  required String userId,
  required String firstName,
  required String lastName,
  required String email,
  required String phone,
  required String phoneCountryCode,
}) async {
  // Update Freshchat User object
  FreshchatUser freshchatUser = await Freshchat.getUser();
  freshchatUser.setFirstName(firstName);
  freshchatUser.setLastName(lastName);
  freshchatUser.setEmail(email);
  freshchatUser.setPhone(phoneCountryCode, phone);

  await Freshchat.setUser(freshchatUser);

  // Identify user by unique external ID
  Freshchat.identifyUser(externalId: userId, restoreId: null);
}

// Reset on logout
void logoutFreshchat() {
  Freshchat.resetUser();
}
```

### C. Displaying Chat and FAQs
Trigger Freshchat screens from your UI:

```dart
// Open Chat Conversations UI
Freshchat.showConversations();

// Open FAQ / Knowledge Base UI
Freshchat.showFAQs();
```

---

## 3. iOS Setup & Push Notifications

### A. iOS Permissions (`ios/Runner/Info.plist`)
Freshchat allows users to upload photos, capture images, or record audio. Add the following keys to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Required for taking photos to attach to support messages.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Required for selecting photos from your library to attach to support messages.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Required for recording voice notes for support messages.</string>
```

### B. Xcode Capabilities
1. Open the project in Xcode (`ios/Runner.xcworkspace`).
2. Select the **Runner** target -> **Signing & Capabilities**.
3. Click **+ Capability**:
   - Add **Push Notifications**.
   - Add **Background Modes** and check **Remote notifications**.

---

### C. AppDelegate (`ios/Runner/AppDelegate.swift`)

Update your `AppDelegate.swift` to authorize notifications, send the APNs token to Freshchat, and route incoming Freshchat push notifications:

```swift
import UIKit
import Flutter
import UserNotifications
import freshchat_sdk // Import Freshchat Plugin module

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // 1. Request Notification Authorization
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                if let error = error {
                    print("Push authorization error: \(error.localizedDescription)")
                } else {
                    print("Push notification authorization granted: \(granted)")
                }
            }
        }
        
        // 2. Register for Remote Notifications
        application.registerForRemoteNotifications()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 3. Pass APNs Device Token to Freshchat
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let freshchatSdkPlugin = FreshchatSdkPlugin()
        freshchatSdkPlugin.setPushRegistrationToken(deviceToken)
    }
    
    // 4. Handle Foreground Notifications
    @available(iOS 10.0, *)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let freshchatSdkPlugin = FreshchatSdkPlugin()
        
        if freshchatSdkPlugin.isFreshchatNotification(userInfo) {
            freshchatSdkPlugin.handlePushNotification(userInfo)
            completionHandler([]) // Freshchat handles UI presentation
        } else {
            completionHandler([.alert, .sound, .badge]) // Pass to other notification handlers
        }
    }
    
    // 5. Handle Notification Taps (Background/Terminated State Response)
    @available(iOS 10.0, *)
    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let freshchatSdkPlugin = FreshchatSdkPlugin()
        
        if freshchatSdkPlugin.isFreshchatNotification(userInfo) {
            freshchatSdkPlugin.handlePushNotification(userInfo)
            completionHandler()
        } else {
            completionHandler()
        }
    }
}
```

---

## 4. Android Setup & Push Notifications

Freshchat Android uses Firebase Cloud Messaging (FCM) to deliver push notifications.

### A. Firebase Setup & Android Manifest (`android/app/src/main/AndroidManifest.xml`)

Ensure your app includes necessary permissions and receives FCM messages:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.flutter_dependency_issue">

    <!-- Network & Storage Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:label="Your App">
        
        <!-- Target Activity -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- Freshchat Notification Small Icon Customization -->
        <meta-data
            android:name="com.freshchat.sdk.android.small_icon"
            android:resource="@drawable/ic_notification" />

        <!-- Freshchat Notification Large Icon Customization -->
        <meta-data
            android:name="com.freshchat.sdk.android.large_icon"
            android:resource="@mipmap/ic_launcher" />

        <!-- Notification Sound Customization -->
        <meta-data
            android:name="com.freshchat.sdk.android.notification_sound"
            android:resource="@raw/notification_sound" />

    </application>
</manifest>
```

---

### B. Registering FCM Token with Freshchat in Flutter

To process FCM messages on Android, capture the FCM push token using `firebase_messaging` and register it with `freshchat_sdk`:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';

void setupAndroidFcmNotifications() async {
  // 1. Get FCM Token
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    // 2. Pass FCM token to Freshchat
    Freshchat.setPushRegistrationToken(fcmToken);
  }

  // 3. Listen for Token Refreshes
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    Freshchat.setPushRegistrationToken(newToken);
  });

  // 4. Intercept FCM messages in Foreground & Background
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    Freshchat.isFreshchatNotification(message.data).then((isFreshchat) {
      if (isFreshchat) {
        Freshchat.handlePushNotification(message.data);
      }
    });
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Freshchat.isFreshchatNotification(message.data).then((isFreshchat) {
      if (isFreshchat) {
        Freshchat.handlePushNotification(message.data);
      }
    });
  });
}
```

---

### C. Native Android `MyFirebaseMessagingService.java` (Optional Alternative)

If handling push notifications natively on Android rather than via Dart `firebase_messaging`:

```java
package com.example.flutter_dependency_issue;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.freshchat.consumer.sdk.Freshchat;

public class MyFirebaseMessagingService extends FirebaseMessagingService {

    @Override
    public void onNewToken(String token) {
        // Send new token to Freshchat
        Freshchat.getInstance(getApplicationContext()).setFcmToken(token);
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // Check if notification is from Freshchat
        if (Freshchat.isFreshchatNotification(remoteMessage)) {
            Freshchat.handleFcmMessage(getApplicationContext(), remoteMessage);
        } else {
            // Handle normal FCM messages for your app
        }
    }
}
```

---

## 5. Verification & Testing Checklist

| Platform | Verification Step | Status / Location |
|---|---|---|
| **Flutter** | `Freshchat.init(...)` called with correct App ID, Key, and Domain URL | [lib/main.dart](file:///c:/Users/Lenovo/Downloads/Compressed/flutter_dependency_issue/flutter_dependency_issue/lib/main.dart) |
| **iOS** | APNs push notification capability enabled in Xcode | Xcode project settings |
| **iOS** | `Info.plist` contains Camera, Photo Library, & Microphone usage strings | `ios/Runner/Info.plist` |
| **iOS** | `AppDelegate.swift` implements `didRegisterForRemoteNotificationsWithDeviceToken` and `FreshchatSdkPlugin.setPushRegistrationToken` | [ios/Runner/AppDelegate.swift](file:///c:/Users/Lenovo/Downloads/Compressed/flutter_dependency_issue/flutter_dependency_issue/ios/Runner/AppDelegate.swift) |
| **iOS** | `AppDelegate.swift` delegates `isFreshchatNotification` & `handlePushNotification` | [ios/Runner/AppDelegate.swift](file:///c:/Users/Lenovo/Downloads/Compressed/flutter_dependency_issue/flutter_dependency_issue/ios/Runner/AppDelegate.swift) |
| **Android** | `google-services.json` placed in `android/app/` | `android/app/google-services.json` |
| **Android** | FCM Token retrieved and passed via `Freshchat.setPushRegistrationToken(fcmToken)` | App Dart / FCM service logic |
| **Android** | Notification small icon meta-data specified in `AndroidManifest.xml` | `android/app/src/main/AndroidManifest.xml` |
