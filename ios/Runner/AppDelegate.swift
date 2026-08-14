import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import freshchat_sdk

/// Temporary push diagnostics. `print` reaches `flutter run`'s console (stdout)
/// and `NSLog` reaches Xcode / Console.app (os_log); neither alone shows up in
/// both places, and a run that surfaces nothing is indistinguishable from a
/// hook that never fired. Remove once the push path is confirmed on a device.
private func freshchatLog(_ message: String) {
  print("[Freshchat] \(message)")
  NSLog("[Freshchat] %@", message)
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyB___mbW9IyVrmRpxFN1sYXwPjtZVhZ-x0")

    // Claim the notification-centre delegate before any plugin registers.
    //
    // Nothing sets this by default -- FlutterAppDelegate implements the
    // UNUserNotificationCenterDelegate methods but never assigns itself -- and
    // FLTFirebaseMessagingPlugin takes the slot for itself when it finds it
    // empty (it only steps aside for a delegate conforming to
    // FlutterAppLifeCycleProvider, which this class does). It then forwards to
    // whatever delegate it displaced, which in that case is nil, so the
    // Freshchat hooks below never ran at all: an agent's reply reached the
    // device as a push but never reached the SDK, leaving an open
    // conversation to pick it up only on its own sync when reopened.
    //
    // Registering first means firebase_messaging leaves us in place and still
    // receives every callback through the plugin chain that `super` fans out
    // to, so Messaging#onMessage and the local-notification path are unchanged.
    UNUserNotificationCenter.current().delegate = self

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// The raw APNs token, kept because it almost always arrives before the SDK
  /// that needs it. See `syncPushToken` below.
  private var apnsDeviceToken: Data?

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // APNs answers `registerForRemoteNotifications` within a moment of launch,
    // but `Freshchat.init` runs from Dart at the end of a long async chain --
    // dotenv, Hive, Firebase, a permission prompt, the network monitor. So the
    // token is handed to a Freshchat SDK that does not exist yet and is
    // dropped, leaving Freshchat with nowhere to push and the open
    // conversation falling back on its own slow polling.
    //
    // Dart calls this once `Freshchat.init` has gone through, and the
    // registration callback below re-sends on its own if the token happens to
    // land later, so either order ends with the SDK holding the token.
    let channel = FlutterMethodChannel(
      name: "com.rahiq.app/freshchat_push",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "syncPushToken" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let token = self?.apnsDeviceToken else {
        freshchatLog("syncPushToken: no APNs token cached yet")
        result(false)
        return
      }
      FreshchatSdkPlugin().setPushRegistrationToken(token)
      freshchatLog("syncPushToken: re-sent cached APNs token to SDK")
      result(true)
    }
  }

  // MARK: - Freshchat push
  //
  // The Dart side registers the FCM token with Freshchat, which is the Android
  // path — the plugin's iOS `setPushRegistrationToken` wants the raw APNs
  // token, and only the app delegate ever sees that. Without these three
  // hooks Freshchat has nowhere to push to and no way to hear about a message
  // that did arrive, so an open conversation only picked new messages up on
  // the SDK's own sync when the screen was reopened.
  //
  // Every branch either forwards to Freshchat or falls through to `super`, so
  // the app's own notifications keep reaching firebase_messaging and
  // flutter_local_notifications exactly as before.

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    apnsDeviceToken = deviceToken
    freshchatLog("APNs token received (\(deviceToken.count) bytes), handing to SDK")
    FreshchatSdkPlugin().setPushRegistrationToken(deviceToken)
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let plugin = FreshchatSdkPlugin()
    let payload = notification.request.content.userInfo
    let isFreshchat = plugin.isFreshchatNotification(payload)

    // Distinguishes "no push reached the device at all" (no line) from
    // "a push arrived but the SDK didn't claim it" (line, isFreshchat=false).
    freshchatLog("foreground push received, isFreshchat=\(isFreshchat)")

    if isFreshchat {
      // Hand it to the SDK and present nothing: the conversation the user is
      // looking at updates itself, and a banner over it would be noise.
      plugin.handlePushNotification(payload)
      completionHandler([])
      return
    }

    super.userNotificationCenter(
      center,
      willPresent: notification,
      withCompletionHandler: completionHandler
    )
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let plugin = FreshchatSdkPlugin()
    let payload = response.notification.request.content.userInfo

    if plugin.isFreshchatNotification(payload) {
      // Opens the conversation the notification came from.
      plugin.handlePushNotification(payload)
      completionHandler()
      return
    }

    super.userNotificationCenter(
      center,
      didReceive: response,
      withCompletionHandler: completionHandler
    )
  }
}
