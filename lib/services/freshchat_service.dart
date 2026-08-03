import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:freshchat_sdk/freshchat_user.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

import '../models/user.dart';

class FreshchatService {
  /// The welcome message is the bot flow's own first entry, so re-fires
  /// count as "fresh" once this much time has passed since the chat screen
  /// was last opened — matches the product's 20 minute session window.
  static const _welcomeStaleAfter = Duration(minutes: 20);

  static void init() {
    log(
      "Initializing Freshchat Service listeners...",
      name: "FreshchatService",
    );
    // A conversation being resolved ("End conversation" -> thank-you dialog)
    // means the *next* time the user opens the chat, it should look like a
    // fresh session again, regardless of how soon that happens. Freshchat's
    // event names aren't part of the plugin's public API, so this matches on
    // "resolv" rather than an exact constant — log the raw event below to
    // confirm/adjust the match if the underlying SDK naming differs.
    Freshchat.onFreshchatEvents.listen((event) {
      final eventName = (event is Map ? event['event_name'] : null)
          ?.toString();
      log("Freshchat event: $eventName", name: "FreshchatService");
      if (eventName != null && eventName.toLowerCase().contains('resolv')) {
        AuthStorage.setChatNeedsWelcome(true);
      }
    });

    // FCM tokens rotate (app reinstall, data clear, backup restore, etc.);
    // Freshchat only ever pushes to whatever token was last handed to it via
    // setPushRegistrationToken, so it has to be re-sent on every refresh, not
    // just once at startup.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      Freshchat.setPushRegistrationToken(token);
      log("Freshchat push registration token refreshed.", name: "FreshchatService");
    });

    // Listen for the restore ID generation when the user sends their first message
    Freshchat.onRestoreIdGenerated.listen((event) async {
      log(
        "Freshchat onRestoreIdGenerated event fired. Data: $event",
        name: "FreshchatService",
      );
      if (event == true) {
        FreshchatUser freshchatUser = await Freshchat.getUser;
        final restoreId = freshchatUser.getRestoreId();

        if (restoreId != null && restoreId.isNotEmpty) {
          log(
            "Attempting to save freshchat restore ID ($restoreId) to backend...",
            name: "FreshchatService",
          );
          try {
            await ApiService().saveFreshchatRestoreId(restoreId);
            log(
              "Freshchat restore ID saved successfully to backend.",
              name: "FreshchatService",
            );
          } catch (e) {
            log(
              "Failed to save Freshchat restore ID to backend: $e",
              name: "FreshchatService",
              error: e,
            );
          }
        } else {
          log(
            "Restore ID from FreshchatUser is null or empty. Skipping backend update.",
            name: "FreshchatService",
          );
        }
      } else {
        log(
          "Restore ID generated event is false. Skipping backend update.",
          name: "FreshchatService",
        );
      }
    });
  }

  /// Hands the current FCM token to Freshchat so it knows where to deliver
  /// push notifications for this device. The Freshchat dashboard's Firebase
  /// admin JSON / APNs auth key only let Freshchat's backend send through our
  /// Firebase project — it still needs this per-device token, which only the
  /// app can provide, or it has nothing to push to.
  static Future<void> registerPushToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        Freshchat.setPushRegistrationToken(token);
        log("Freshchat push registration token set.", name: "FreshchatService");
      } else {
        log("No FCM token available to register with Freshchat.", name: "FreshchatService");
      }
    } catch (e) {
      log(
        "Failed to set Freshchat push registration token: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }

  static bool _isTokenExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = jsonDecode(decoded);
      if (payloadMap.containsKey('exp')) {
        // give it a 5-minute buffer
        final exp = (payloadMap['exp'] * 1000) - 300000;
        return DateTime.now().millisecondsSinceEpoch > exp;
      }
    } catch (e) {
      return true;
    }
    return true;
  }

  static Future<void> refreshTokenIfNeeded() async {
    final user = AuthStorage.user;
    if (user == null) return;

    final currentToken = AuthStorage.freshchatToken;
    if (!_isTokenExpired(currentToken)) {
      log(
        "Freshchat token is still valid. Skipping refresh.",
        name: "FreshchatService",
      );
      return;
    }

    try {
      final freshchatUuid = await Freshchat.getFreshchatUserId;
      if (freshchatUuid.isNotEmpty) {
        log(
          "Generating Freshchat Token from backend...",
          name: "FreshchatService",
        );
        final response = await ApiService().generateFreshchatToken(
          freshchatUuid,
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          final token = response.data['data']['token'];
          if (token != null) {
            await AuthStorage.saveFreshchatToken(token);
            Freshchat.setUserWithIdToken(token);
            log(
              "User ID token refreshed successfully.",
              name: "FreshchatService",
            );
          }
        }
      }
    } catch (e) {
      log(
        "Failed to refresh Freshchat token: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }

  static Future<void> showConversations(
    BuildContext context, {
    List<String> tags = const [],
    String? filteredViewTitle,
  }) async {
    await refreshTokenIfNeeded();
    if (tags.isNotEmpty) await _maybeTriggerWelcomeBot(tags.first);
    Freshchat.showConversations(
      tags: tags,
      filteredViewTitle: filteredViewTitle,
    );
  }

  /// Nudges the bot's welcome flow when the chat screen is opened after a
  /// conversation was resolved, or after a long enough gap that it should
  /// feel like a fresh session — without touching the conversation itself,
  /// since [Freshchat.sendMessage] appends to the existing thread rather
  /// than resetting it.
  ///
  /// This can only react to entries that go through this method. Returning
  /// to an already-open native chat screen after briefly backgrounding the
  /// app isn't observable from here — the chat UI is a native screen, not a
  /// Flutter route, so there's no app-lifecycle hook for "the user is still
  /// on it".
  static Future<void> _maybeTriggerWelcomeBot(String tag) async {
    final now = DateTime.now();
    final lastOpened = AuthStorage.chatLastOpenedAt;
    final isStale =
        lastOpened == null || now.difference(lastOpened) > _welcomeStaleAfter;

    if (AuthStorage.chatNeedsWelcome || isStale) {
      log("Triggering Freshchat welcome bot for tag '$tag'.", name: "FreshchatService");
      Freshchat.sendMessage(tag, "Hello");
      await AuthStorage.setChatNeedsWelcome(false);
    }
    await AuthStorage.saveChatLastOpenedAt(now);
  }

  static Future<void> identifyUser(User user) async {
    // log(
    //   "Starting identifyUser flow for user: ${user.id}, existing restoreId: ${user.freshchatRestoreId}",
    //   name: "FreshchatService",
    // );
    try {
      final restoreId = user.freshchatRestoreId ?? "";
      // log(
      //   "Identifying user in SDK with externalId: ${user.id} and restoreId: $restoreId",
      //   name: "FreshchatService",
      // );
      Freshchat.identifyUser(externalId: user.id, restoreId: restoreId);

      // log(
      //   "Updating Freshchat user profile details for user: ${user.email}...",
      //   name: "FreshchatService",
      // );
      FreshchatUser freshchatUser = await Freshchat.getUser;
      freshchatUser.setFirstName(user.firstName);
      freshchatUser.setLastName(user.lastName);
      freshchatUser.setEmail(user.email);
      freshchatUser.setPhone(user.countryCode, user.phoneNumber);
      Freshchat.setUser(freshchatUser);
      // log(
      //   "Freshchat user profile details updated successfully.",
      //   name: "FreshchatService",
      // );
      log("AccessToken : ${AuthStorage.accessToken}");
    } catch (e) {
      log(
        "Failed to identify Freshchat user: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }
}
