import 'dart:async';

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

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
    isLoggedInNotifier.value = accessToken != null;
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(accessTokenKey, accessToken);
    await _box.put(refreshTokenKey, refreshToken);
    isLoggedInNotifier.value = true;
  }

  static Future<void> saveRegistrationToken(String regToken) async {
    await _box.put(registrationTokenKey, regToken);
  }

  static String? get registrationToken => _box.get(registrationTokenKey);

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.put(userDataKey, userData);

    try {
      final currentUser = user;
      if (currentUser != null) {
        await FreshchatService.identifyUser(currentUser);
      }
    } catch (e) {
      debugPrint("Failed to set Freshchat user: $e");
    }
  }

  static String? get accessToken => _box.get(accessTokenKey);
  static String? get refreshToken => _box.get(refreshTokenKey);

  static const String freshchatTokenKey = "freshchatToken";

  static Future<void> saveFreshchatToken(String token) async {
    await _box.put(freshchatTokenKey, token);
  }

  static String? get freshchatToken => _box.get(freshchatTokenKey);

  static const String chatNeedsWelcomeKey = "chatNeedsWelcome";

  static Future<void> setChatNeedsWelcome(bool value) async {
    await _box.put(chatNeedsWelcomeKey, value);
  }

  /// Defaults to true so a user who has never opened the chat still gets the
  /// bot's welcome flow on their first visit — there is no conversation yet
  /// for Freshchat to report as resolved.
  static bool get chatNeedsWelcome =>
      _box.get(chatNeedsWelcomeKey, defaultValue: true) as bool;

  static User? get user {
    final raw = _box.get(userDataKey);
    if (raw == null) return null;
    final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);
    return User.fromJson(data);
  }

  static Future<void> clear() async {
    await _box.clear();
    isLoggedInNotifier.value = false;

    try {
      Freshchat.resetUser();
    } catch (e) {
      debugPrint("Failed to reset Freshchat user: $e");
    }

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
