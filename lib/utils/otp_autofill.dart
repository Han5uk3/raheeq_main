import 'dart:async';
import 'dart:io';

import 'package:smart_auth/smart_auth.dart';

/// Shared owner of the Android SMS Retriever listener.
///
/// The retriever only matches messages that arrive *after* it is started, so it
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

  static const _arabicIndicZero = 0x0660;
  static const _extendedArabicIndicZero = 0x06F0;

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
      final res = await SmartAuth.instance.getSmsWithRetrieverApi(
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
  static String? _toAsciiDigits(String? code) {
    if (code == null) return null;

    final buffer = StringBuffer();
    for (final unit in code.runes) {
      if (unit >= _arabicIndicZero && unit <= _arabicIndicZero + 9) {
        buffer.writeCharCode(0x30 + unit - _arabicIndicZero);
      } else if (unit >= _extendedArabicIndicZero &&
          unit <= _extendedArabicIndicZero + 9) {
        buffer.writeCharCode(0x30 + unit - _extendedArabicIndicZero);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

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

    await SmartAuth.instance.removeSmsRetrieverApiListener();
  }
}
