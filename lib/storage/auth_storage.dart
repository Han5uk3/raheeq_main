import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../pages/authentication/login.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import '../services/freshchat_service.dart';

class AuthStorage {
  static const String boxName = 'authBox';
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String registrationTokenKey = 'registrationToken';
  static const String userDataKey = 'userData';
  static const String guestModeKey = 'guestMode';

  // Global key for programmatic routing (e.g. token invalidation redirection)
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ValueNotifier to track active login state
  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(
    false,
  );

  /// Completes once [init] has finished and the Hive box is open.
  /// Await [ready] before reading tokens to avoid the race condition
  /// where the splash screen checks the session before storage is open.
  static final Completer<void> _readyCompleter = Completer<void>();
  static Future<void> get ready => _readyCompleter.future;

  /// While true, [clear] still wipes storage but does NOT redirect to login.
  ///
  /// The splash screen owns routing until its 3.5s animation finishes, so a
  /// session that turns out to be dead during startup must not yank the user
  /// off the splash mid-animation. This covers every route into [clear] —
  /// the cold-start profile check in main.dart and the API client's own
  /// 401 -> refresh-failed -> logout path alike. The splash lowers this the
  /// moment it has made its own routing decision, after which session
  /// failures redirect immediately as before.
  static bool suppressLoginRedirect = true;

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
    isLoggedInNotifier.value = accessToken != null;
    isGuestNotifier.value = isGuest;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  static Box get _box => Hive.box(boxName);

  // -------------------------------------------------------------------
  // Guest mode (iOS only)
  // -------------------------------------------------------------------

  /// Notifies listeners when the app enters or leaves guest mode, so anything
  /// built while browsing as a guest can rebuild the moment a session exists.
  static final ValueNotifier<bool> isGuestNotifier = ValueNotifier<bool>(false);

  /// DEBUG SWITCH — set back to `false` before shipping.
  ///
  /// Guest mode is an iOS-only feature. This opens it on Android too so the
  /// flow can be exercised on an Android device. Everything that gates on the
  /// platform reads [guestModeSupported], so flipping this one constant back
  /// restores the iOS-only behaviour everywhere: the login button, [isGuest]
  /// and [enterGuestMode] alike.
  static const bool allowGuestModeOnAndroid = true;

  /// Whether this platform may enter guest mode at all.
  static bool get guestModeSupported =>
      Platform.isIOS || allowGuestModeOnAndroid;

  /// True while the user is browsing the app without a customer session.
  ///
  /// The platform gate is repeated here rather than left to the callers: a
  /// flag carried over by a restored backup then still can't put an
  /// unsupported platform into guest mode.
  static bool get isGuest {
    if (!guestModeSupported) return false;
    if (!Hive.isBoxOpen(boxName)) return false;
    return _box.get(guestModeKey) == true;
  }

  /// Starts browsing without signing in. No-op where guest mode is not
  /// supported — see [guestModeSupported].
  static Future<void> enterGuestMode() async {
    if (!guestModeSupported) return;
    await _box.put(guestModeKey, true);
    isGuestNotifier.value = true;
  }

  /// Leaves guest mode. Callers sending the user to the login screen call this
  /// first, so nothing left on screen still reads as a guest.
  static Future<void> exitGuestMode() async {
    if (!Hive.isBoxOpen(boxName)) return;
    await _box.delete(guestModeKey);
    isGuestNotifier.value = false;
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(accessTokenKey, accessToken);
    await _box.put(refreshTokenKey, refreshToken);
    // Every login path funnels through here, so this is the single place that
    // has to retire guest mode: a real session always supersedes it.
    await _box.delete(guestModeKey);
    isGuestNotifier.value = false;
    isLoggedInNotifier.value = true;
  }

  static Future<void> saveRegistrationToken(String regToken) async {
    await _box.put(registrationTokenKey, regToken);
  }

  static String? get registrationToken => _box.get(registrationTokenKey);

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.put(userDataKey, userData);

    // Kicked off, not awaited. This runs on the OTP path, and Freshchat sign-in
    // is several platform-channel round trips into an SDK we do not control —
    // one of them hanging would leave the user watching a spinner on a login
    // that has already succeeded. Nothing here needs the result, and the
    // service logs its own failures.
    final currentUser = user;
    if (currentUser != null) {
      unawaited(FreshchatService.authenticateUser(currentUser));
    }
  }

  static String? get accessToken => _box.get(accessTokenKey);
  static String? get refreshToken => _box.get(refreshTokenKey);

  static const String freshchatTokenKey = "freshchatToken";

  static Future<void> saveFreshchatToken(String token) async {
    await _box.put(freshchatTokenKey, token);
  }

  static String? get freshchatToken => _box.get(freshchatTokenKey);

  static User? get user {
    final raw = _box.get(userDataKey);
    if (raw == null) return null;
    final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);
    return User.fromJson(data);
  }

  static Future<void> clear() async {
    await _box.clear();
    isLoggedInNotifier.value = false;
    isGuestNotifier.value = false;

    try {
      Freshchat.resetUser();
    } catch (e) {
      debugPrint("Failed to reset Freshchat user: $e");
    }

    // Still on the splash screen: storage is wiped, but the splash finishes
    // its animation and routes to Login itself once the local session check
    // comes back empty. Redirecting here would cut the animation short.
    if (suppressLoginRedirect) return;

    // Programmatically push to Login on session failure
    navigatorKey.currentState?.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Login(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }
}
