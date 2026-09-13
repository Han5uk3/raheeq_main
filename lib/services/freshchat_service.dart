import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freshchat_sdk/freshchat_sdk.dart';
import 'package:raheeq_main/api/apis.dart';
import 'package:raheeq_main/storage/auth_storage.dart';

import '../models/user.dart';

class FreshchatService {
  /// Talks to the app delegate, which owns the raw APNs token. Nothing on the
  /// Dart side can reach it: the plugin's iOS `setPushRegistrationToken`
  /// expects `NSData`, so the Flutter method takes a token string it cannot
  /// use here. iOS only.
  static const MethodChannel _pushChannel = MethodChannel(
    'com.rahiq.app/freshchat_push',
  );

  /// The tag the chat screen is opened with, so the user lands in the support
  /// channel rather than a channel list.
  static const List<String> supportTags = ["chat_with_us"];

  /// In-flight [ensureAuthenticated] call, so the several things that can ask
  /// for authentication at once — startup, opening the chat, the SDK's own
  /// token-status event — share one attempt instead of racing to mint
  /// competing tokens.
  static Future<void>? _authInFlight;

  /// Tokens the SDK has rejected in a row. A token signed with the wrong key is
  /// rejected every time, and the SDK reports each rejection as an event that
  /// asks us to authenticate again — so without a stop the app would mint and
  /// re-mint against the backend for as long as it stayed open. Reset the
  /// moment one is accepted.
  static int _rejectedTokens = 0;
  static const int _maxRejectedTokens = 3;

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
  /// A read already running. The SDK answers `getUnreadCountAsync` through a
  /// callback it does not always fire, and count-changed events arrive in
  /// bursts, so without this a burst stacks several unanswered calls on top of
  /// one that is already stuck.
  static Future<void>? _unreadReadInFlight;

  /// Set when a refresh is asked for while one is running, so the change that
  /// prompted it is picked up afterwards rather than dropped.
  static bool _unreadReadQueued = false;

  static Future<void> refreshUnreadCount() {
    if (_unreadReadInFlight != null) {
      _unreadReadQueued = true;
      return _unreadReadInFlight!;
    }
    return _unreadReadInFlight = _readUnreadCount().whenComplete(() {
      _unreadReadInFlight = null;
      if (_unreadReadQueued) {
        _unreadReadQueued = false;
        refreshUnreadCount();
      }
    });
  }

  static Future<void> _readUnreadCount() async {
    try {
      // Bounded because callers await it on paths that matter — the login flow
      // among them — and this is only a badge. If the SDK's channel is wedged,
      // a stale count is the right failure; a login that never finishes is not.
      final result = await Freshchat.getUnreadCountAsync.timeout(
        const Duration(seconds: 5),
      );
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
    // Nothing here restarts the bot any more. That is the bot's own job now,
    // via the "start new conversation" action at the end of its flow — the app
    // has no silent way to do it, since `Freshchat.sendMessage` is the plugin's
    // only send and it posts as the customer, leaving a visible "Hello" in the
    // thread.
    //
    // Worth knowing before reaching for an app-side trigger again: the SDK
    // reports no resolution event at all. `Event$EventName` in
    // freshchat-android 6.5.10 has 41 constants and none names a conversation
    // being resolved, and `FCPropertyResolutionStatus` rides only on
    // `FCEventCsatSubmit` — so reading it means showing the customer a CSAT
    // survey.
    Freshchat.onFreshchatEvents.listen((event) {
      final map = event is Map ? event : const {};
      final eventName = map['event_name']?.toString();
      final properties = map['properties'];

      // Properties are logged in full because anything built on these events
      // depends on exact strings the SDK never documents; the resolution
      // matcher that sat here for months, matching a name no event has, is
      // what guessing at them costs.
      log(
        "Freshchat event: $eventName ${properties ?? ''}",
        name: "FreshchatService",
      );
      if (eventName == null) return;

      final name = eventName.toLowerCase();

      // `FCEventIdTokenStatusChange` — the documented signal that the SDK's
      // view of our JWT moved, which includes it lapsing mid-session. Left
      // unanswered the SDK drops to unauthenticated and stops syncing, and the
      // conversation goes still until something else forces a refresh.
      if (name.contains('token')) {
        ensureAuthenticated().then((_) => registerPushToken());
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

    // On iOS, listen for callbacks from AppDelegate when APNs token arrives
    if (Platform.isIOS) {
      _pushChannel.setMethodCallHandler((call) async {
        if (call.method == 'onApnsTokenReceived') {
          log(
            "APNs token received by AppDelegate; syncing with Freshchat...",
            name: "FreshchatService",
          );
          await registerPushToken(maxRetries: 3);
        }
      });
    }

    // The plugin's own hook for "the SDK wants a fresh token". It overlaps
    // with the token event above rather than replacing it — either may fire
    // first depending on platform, and [ensureAuthenticated] is idempotent, so
    // listening to both costs a status read and closes the gap if one is
    // silent.
    Freshchat.onJwtRefresh.listen((_) async {
      log("Freshchat asked for a fresh JWT.", name: "FreshchatService");
      await ensureAuthenticated();
      await registerPushToken();
    });

    // `onRestoreIdGenerated` is deliberately not listened to. The restore id
    // belongs to the external-id scheme that JWT replaces, and Freshchat does
    // not mint one for a JWT user — the listener only ever logged that it had
    // nothing to save.
  }

  /// Hands the current push token (APNs on iOS, FCM on Android) to Freshchat
  /// with automatic retries so that early startup or network delays do not
  /// drop the token.
  static Future<bool> registerPushToken({
    int maxRetries = 5,
    Duration delay = const Duration(milliseconds: 600),
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final success = await _executeTokenRegistration();
      if (success) {
        log(
          "Freshchat push token registered successfully (attempt $attempt/$maxRetries).",
          name: "FreshchatService",
        );
        return true;
      }
      if (attempt < maxRetries) {
        log(
          "Freshchat push token not ready on attempt $attempt/$maxRetries; retrying in ${delay.inMilliseconds}ms...",
          name: "FreshchatService",
        );
        await Future.delayed(delay);
      }
    }
    log(
      "Freshchat push token registration unconfirmed after $maxRetries attempts.",
      name: "FreshchatService",
    );
    return false;
  }

  static Future<bool> _executeTokenRegistration() async {
    if (Platform.isIOS) {
      try {
        final applied = await _pushChannel.invokeMethod<bool>('syncPushToken');
        log(
          "Freshchat APNs token sync response: $applied",
          name: "FreshchatService",
        );
        return applied == true;
      } catch (e) {
        log(
          "Failed to re-send APNs token to Freshchat: $e",
          name: "FreshchatService",
          error: e,
        );
        return false;
      }
    }

    if (!Platform.isAndroid) return false;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        Freshchat.setPushRegistrationToken(token);
        log(
          "Freshchat FCM push registration token set (${token.length > 10 ? token.substring(0, 10) : token}...).",
          name: "FreshchatService",
        );
        return true;
      } else {
        log("No FCM token available yet.", name: "FreshchatService");
        return false;
      }
    } catch (e) {
      log(
        "Failed to set Freshchat push registration token: $e",
        name: "FreshchatService",
        error: e,
      );
      return false;
    }
  }

  /// Reads the token status straight from the SDK.
  ///
  /// The copy in storage cannot answer this. It says nothing about whether the
  /// SDK ever received a token — after a cold start it holds none, however
  /// fresh ours is — and nothing about whether Freshchat accepted it, since a
  /// token can sit well inside its `exp` and still be rejected for being
  /// signed with the wrong key. Both leave the SDK unauthenticated, which is
  /// the state that stops conversations syncing.
  static Future<JwtTokenStatus> _idTokenStatus() async {
    try {
      return await Freshchat.getUserIdTokenStatus;
    } catch (e) {
      log(
        "Failed to read Freshchat JWT status: $e",
        name: "FreshchatService",
        error: e,
      );
      // Treat an unreadable status as "no token": re-sending one the SDK
      // already has is harmless, skipping one it needs is not.
      return JwtTokenStatus.TOKEN_NOT_SET;
    }
  }

  /// Brings the SDK to an authenticated state, doing the least work that gets
  /// it there.
  ///
  /// With user authentication enforced, Freshchat gates the SDK on this: a user
  /// whose token is missing or still processing waits about thirty seconds on
  /// the chat screen and is then dropped out of it, and one whose token was
  /// rejected cannot open it at all. Short of either extreme an unauthenticated
  /// SDK simply does not sync, which is what left replies sitting on the server
  /// until something forced a reload.
  ///
  /// Safe to call from anywhere, as often as you like — concurrent callers
  /// share the one attempt, and a healthy token costs a single status read.
  static Future<void> ensureAuthenticated() {
    return _authInFlight ??= _authenticate().whenComplete(() {
      _authInFlight = null;
    });
  }

  static Future<void> _authenticate() async {
    try {
      if (AuthStorage.user == null) return;

      final status = await _idTokenStatus();
      log("Freshchat JWT status: $status", name: "FreshchatService");

      // Already good, or a token is mid-handshake and a second one would only
      // restart it.
      if (status == JwtTokenStatus.TOKEN_VALID) {
        _rejectedTokens = 0;
        return;
      }
      if (status == JwtTokenStatus.TOKEN_NOT_PROCESSED) return;

      if (status == JwtTokenStatus.TOKEN_INVALID &&
          ++_rejectedTokens > _maxRejectedTokens) {
        log(
          "Freshchat rejected $_rejectedTokens tokens; giving up for this "
          "session. Check that the backend signs with the account's current "
          "encrypted key and that the payload carries freshchat_uuid and "
          "reference_id.",
          name: "FreshchatService",
        );
        return;
      }

      // Cold start: the SDK holds nothing, but the token saved last session is
      // still good and still names the same `freshchat_uuid`, so restoring with
      // it costs a method call rather than a round trip.
      final stored = AuthStorage.freshchatToken;
      if (status == JwtTokenStatus.TOKEN_NOT_SET && !_isTokenExpired(stored)) {
        log(
          "Restoring Freshchat user with the stored token.",
          name: "FreshchatService",
        );
        Freshchat.restoreUserWithIdToken(stored!);
        await _awaitTokenSettled();
        return;
      }

      final token = await _mintIdToken();
      if (token == null) return;

      // [Freshchat.restoreUserWithIdToken] is the call for a signed-in user: it
      // creates the user the token's `reference_id` names, or picks up the
      // existing one — and their conversation history — on a reinstall or a
      // second device. [Freshchat.setUserWithIdToken] is the other half of the
      // pair and only updates a user already restored, so authenticating with
      // it (as this did) left the SDK holding a token for a user it never
      // restored.
      Freshchat.restoreUserWithIdToken(token);
      log(
        "Freshchat user restored with a fresh token.",
        name: "FreshchatService",
      );
      await _awaitTokenSettled();
    } catch (e) {
      // Most callers here are fire-and-forget event listeners, so an escaping
      // error would surface as an unhandled async error rather than anything
      // useful.
      log(
        "Freshchat authentication failed: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }

  /// Waits for the SDK to finish processing a token it was just handed.
  ///
  /// `restoreUserWithIdToken` returns the moment the token is handed over — the
  /// SDK validates it against the server afterwards and sits at
  /// `TOKEN_NOT_PROCESSED` until that lands. Treating hand-over as done meant
  /// [showConversations] opened the chat on an SDK that was still
  /// unauthenticated, so the first visit went on settling the session rather
  /// than syncing, and a bot flow waiting on a conversation resolved
  /// server-side needed one extra open before it restarted.
  ///
  /// Only reached on the cold-start and expiry paths; a token already valid
  /// returns from [_authenticate] before this, so the chat screen normally
  /// opens with no wait at all.
  static Future<void> _awaitTokenSettled() async {
    const step = Duration(milliseconds: 150);
    const limit = Duration(seconds: 5);
    final deadline = DateTime.now().add(limit);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(step);
      final status = await _idTokenStatus();
      if (status == JwtTokenStatus.TOKEN_NOT_PROCESSED ||
          status == JwtTokenStatus.TOKEN_NOT_SET) {
        continue;
      }
      log("Freshchat token settled as $status.", name: "FreshchatService");
      if (status == JwtTokenStatus.TOKEN_VALID) _rejectedTokens = 0;
      return;
    }

    log(
      "Freshchat token still unsettled after ${limit.inSeconds}s; opening "
      "the chat anyway.",
      name: "FreshchatService",
    );
  }

  /// Asks the backend for a JWT naming this device's Freshchat user and stores
  /// it, or returns null if it could not be obtained.
  ///
  /// The token's `freshchat_uuid` claim has to match the uuid the SDK is
  /// currently using, which is why that goes up with the request; the backend
  /// pairs it with the caller's own `reference_id` and signs with the account's
  /// encrypted key.
  static Future<String?> _mintIdToken() async {
    try {
      final freshchatUuid = await Freshchat.getFreshchatUserId;
      if (freshchatUuid.isEmpty) {
        log(
          "No Freshchat uuid yet; skipping token generation.",
          name: "FreshchatService",
        );
        return null;
      }

      final response = await ApiService().generateFreshchatToken(freshchatUuid);
      if (response.statusCode != 200 || response.data['success'] != true) {
        log(
          "Backend declined to mint a Freshchat token: ${response.statusCode}",
          name: "FreshchatService",
        );
        return null;
      }

      final token = response.data['data']?['token'] as String?;
      if (token == null || token.isEmpty) {
        log("Backend returned no Freshchat token.", name: "FreshchatService");
        return null;
      }

      await AuthStorage.saveFreshchatToken(token);
      return token;
    } catch (e) {
      log(
        "Failed to generate Freshchat token: $e",
        name: "FreshchatService",
        error: e,
      );
      return null;
    }
  }

  /// Cheap local pre-check, used only to decide whether the stored token is
  /// worth re-sending before spending a round trip on a new one. Anything it
  /// cannot parse counts as expired, so the fallback is always the safe one.
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

  /// Opens the chat, filtered to [tags] so the customer lands in the support
  /// channel rather than a channel list.
  ///
  /// The tag filter was tested as a suspect for the SDK reopening a *resolved*
  /// conversation (`1141219366823673`) while the backend routes the bot's
  /// replies into a newly created one, and cleared: dropping it puts the
  /// customer on `ChannelListActivity` instead, and entering the channel from
  /// there still takes two visits before the bot's opening message appears. The
  /// entry path makes no difference, so the filter stays and the defect is
  /// Freshworks' — see docs/freshchat-support-ticket.md.
  static Future<void> showConversations(
    BuildContext context, {
    List<String> tags = supportTags,
    String? filteredViewTitle = "Rahiq Support",
  }) async {
    await ensureAuthenticated();
    // Guarantee push token is registered for this user before entering the chat
    await registerPushToken(maxRetries: 3);
    final effectiveTags = tags.isEmpty ? supportTags : tags;
    Freshchat.showConversations(
      tags: effectiveTags,
      filteredViewTitle: filteredViewTitle ?? "Rahiq Support",
    );
  }

  /// Signs [user] in to Freshchat.
  ///
  /// Identity comes from the JWT the backend signs, not from `identifyUser`'s
  /// external-id/restore-id pair. Those are the two alternative restore schemes
  /// and Freshchat is explicit that they should not be mixed — running both had
  /// the SDK restoring one user off a restore id while the token authorised
  /// another. With user authentication enforced on the account, JWT is the one
  /// that counts.
  ///
  /// Called at startup and again on every profile save, so it has to stay cheap
  /// when there is nothing to do; [ensureAuthenticated] settles that from the
  /// SDK's own token status without a round trip in the common case.
  static Future<void> authenticateUser(User user) async {
    try {
      // Authenticate here rather than leaving it to the first
      // `showConversations`. An unauthenticated SDK does not sync, so deferring
      // it meant nothing Freshchat pushed could land until the user had opened
      // the chat at least once that session — and the badge that is supposed to
      // draw them there stayed at whatever it was when the app started.
      await ensureAuthenticated();

      // Re-bind the push token to the user the restore just settled on. It was
      // handed over at startup, while the SDK was still on the anonymous user
      // it boots with, and Freshchat delivers to whichever user a token is
      // registered against — so left alone it kept pointing at the user this
      // call replaced, and nothing it sent reached the device.
      await registerPushToken();

      // No `Freshchat.setUser` here. The account runs strict JWT identification,
      // which rejects it outright —
      //
      //   MethodNotAllowedException: setUser() is not allowed because strict
      //   mode of identifying users with JWT is enabled for this account
      //
      // — and the profile it used to push is already in the token the backend
      // signs (`first_name`, `last_name`, `phone_number` alongside
      // `reference_id` and `freshchat_uuid`), so it was redundant as well as
      // rejected. Anything else an agent should see goes in those claims.

      // The count read at startup belonged to whoever the SDK had before this
      // user was restored, so take it again now that it means something.
      await refreshUnreadCount();
    } catch (e) {
      log(
        "Failed to authenticate Freshchat user: $e",
        name: "FreshchatService",
        error: e,
      );
    }
  }
}
