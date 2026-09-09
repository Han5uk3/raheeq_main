import 'dart:async';
import 'dart:io';

import 'package:smart_auth/smart_auth.dart';

import 'package:raheeq_main/utils/digits.dart';

/// Shared owner of the Android SMS User Consent listener.
///
/// Unlike the SMS Retriever API, User Consent shows the user a system dialog
/// with the SMS content and asks them to approve before the code is read, so
/// no app-signature hash needs to be embedded in the SMS text.
///
/// The listener only matches messages that arrive *after* it is started, so it
/// has to be armed before the OTP is requested, not after the OTP screen opens.
/// Arming is de-duplicated: a listener that is already waiting is reused, so
/// re-arming can never drop an SMS that landed in between.
class OtpAutofill {
  OtpAutofill._();

  static final OtpAutofill instance = OtpAutofill._();

  /// Matches the 4 digit code in the SMS body. Dart's `\d` is ASCII only, so
  /// Arabic-Indic and Extended Arabic-Indic digits are matched explicitly —
  /// an Arabic SMS template would otherwise never autofill.
  static const _codeMatcher = r'[0-9٠-٩۰-۹]{4}';

  Completer<String?>? _pending;
  int _generation = 0;

  bool get isSupported => Platform.isAndroid;

  /// Whether a listener is currently registered and waiting for an SMS.
  bool get isArmed => _pending != null;

  /// Identifies the listener started by the most recent [arm].
  int get generation => _generation;

  /// Starts listening, or returns the listener that is already running.
  Future<String?> arm() {
    if (!isSupported) return Future.value(null);

    final existing = _pending;
    if (existing != null) return existing.future;

    final completer = Completer<String?>();
    _pending = completer;
    _generation++;
    _listen(completer);
    return completer.future;
  }

  Future<void> _listen(Completer<String?> completer) async {
    String? code;
    try {
      final res = await SmartAuth.instance.getSmsWithUserConsentApi(
        matcher: _codeMatcher,
      );
      code = res.hasData ? _toAsciiDigits(res.data?.code) : null;
    } finally {
      if (identical(_pending, completer)) _pending = null;
      if (!completer.isCompleted) completer.complete(code);
    }
  }

  /// The API expects ASCII digits, so a code lifted from an Arabic template has
  /// to be folded back before it reaches the input.
  static String? _toAsciiDigits(String? code) =>
      code == null ? null : Digits.toLatin(code);

  /// Stops the listener started by [generation].
  ///
  /// A stale caller — an OTP screen being disposed after a newer flow already
  /// re-armed — is ignored, so it cannot tear down the live listener.
  Future<void> cancel(int generation) async {
    if (!isSupported || generation != _generation) return;

    final pending = _pending;
    if (pending == null) return;
    _pending = null;

    // Complete explicitly: the plugin never invokes its callback once the
    // receiver is unregistered, so anything awaiting this would hang forever.
    if (!pending.isCompleted) pending.complete(null);

    await SmartAuth.instance.removeUserConsentApiListener();
  }
}
