import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:freshchat_sdk/freshchat_user.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

import '../models/user.dart';

class FreshchatService {
  /// The tag the chat screen is opened with, so the user lands in the support
  /// channel rather than a channel list.
  static const List<String> supportTags = ["chat_with_us"];

  /// Unread support messages, for the "Contact us" badge. A notifier rather
  /// than screen state because the count changes from the SDK's own events —
  /// a push arriving, or the user reading the thread on the native chat
  /// screen — not from anything the Flutter side does.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Re-reads the unread count from the SDK. Safe to call often; it is a
  /// local lookup, not a network round trip.
  ///
  /// Counts every channel rather than filtering on [supportTags]. The tag
  /// filter matches channels tagged that way *in the Freshchat dashboard*, and
  /// a tag that matches nothing there counts zero — while `showConversations`
  /// quietly falls back to showing all channels, so the chat works and only
  /// the badge stays dark. The app has a single entry into Freshchat, so
  /// every unread message it can receive is a support message anyway.
  static Future<void> refreshUnreadCount() async {
    try {
      final result = await Freshchat.getUnreadCountAsync;
      log("Freshchat unread lookup: $result", name: "FreshchatService");

      // Both platforms answer with {status, count}. A failed lookup still
      // carries a count — 0 on iOS — so trusting it would clear a badge that
      // should have stayed on. Android reports STATUS_SUCCESS/STATUS_ERROR.
      final status = result['status']?.toString().toUpperCase() ?? '';
      if (!status.contains('SUCCESS')) return;

      final raw = result['count'];
      final count = raw is int ? raw : int.tryParse('$raw') ?? 0;
      if (count != unreadCount.value) {
        unreadCount.value = count;
      }
    } catch (e) {
      log(
        "Failed to read Freshchat unread count: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }

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

    // Fires whenever the SDK's message count changes — a new message pushed
    // in, or the user reading the thread on the native chat screen, which is
    // what clears the badge again.
    Freshchat.onMessageCountUpdate.listen((_) => refreshUnreadCount());
    refreshUnreadCount();

    // FCM tokens rotate (app reinstall, data clear, backup restore, etc.);
    // Freshchat only ever pushes to whatever token was last handed to it via
    // setPushRegistrationToken, so it has to be re-sent on every refresh, not
    // just once at startup.
    if (Platform.isAndroid) {
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        Freshchat.setPushRegistrationToken(token);
        log(
          "Freshchat push registration token refreshed.",
          name: "FreshchatService",
        );
      });
    }

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
  ///
  /// Android only. The plugin's iOS `setPushRegistrationToken` takes the raw
  /// APNs token as `NSData`, which an FCM token string is not — that side is
  /// registered from `AppDelegate.didRegisterForRemoteNotifications`, the only
  /// place the real token exists.
  static Future<void> registerPushToken() async {
    if (!Platform.isAndroid) return;

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

  /// Nudges the bot's welcome flow when the chat screen is opened on a
  /// conversation Freshchat has told us it resolved.
  ///
  /// [Freshchat.sendMessage] posts a real message on the user's behalf — the
  /// SDK has no silent variant. It is taken up by the bot's own flow only
  /// when it lands on a resolved conversation, because that starts a new one
  /// for the bot to take over; sent into a conversation that is still open it
  /// just sits in the thread as a stray "Hello" from the user. So the
  /// greeting goes out on Freshchat's own resolve event and nothing else — a
  /// guess at when the conversation *might* have ended server-side is exactly
  /// what used to leave it visible.
  ///
  /// The cost is that a conversation auto-resolved server-side while the app
  /// was closed goes unnoticed: the user lands back in it with no greeting,
  /// and whatever they type triggers the bot the same way this would have.
  static Future<void> _maybeTriggerWelcomeBot(String tag) async {
    if (!AuthStorage.chatNeedsWelcome) return;

    log(
      "Triggering Freshchat welcome bot for tag '$tag'.",
      name: "FreshchatService",
    );
    Freshchat.sendMessage(tag, "Hello");
    await AuthStorage.setChatNeedsWelcome(false);
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

      // The count read at startup belonged to whoever the SDK had before this
      // user was restored, so take it again now that it means something.
      await refreshUnreadCount();
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
