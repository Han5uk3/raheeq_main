import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Switches the app reads live from Firestore, so a button can be shown or
/// hidden without shipping a new build.
///
/// Each platform has its own document in the `App_settings` collection,
/// `android` and `ios`, holding the same fields, so a switch can be set
/// differently for the two apps.
///
/// A switch is on only while this platform's document holds `true` for it. A
/// missing document or field, a value of another type, or a read the security
/// rules refuse all leave it off. Firestore keeps the last value it received on
/// the device, so a switch holds its state when the app starts offline.
class AppSettings {
  AppSettings._();

  static final Completer<void> _firebaseReady = Completer<void>();

  /// Called once Firebase has been initialized. main.dart starts the app
  /// before that finishes, so a screen can ask for a switch first; its stream
  /// waits for this rather than touching Firestore too early.
  static void firebaseInitialized() {
    if (!_firebaseReady.isCompleted) _firebaseReady.complete();
  }

  /// Whether the profile tab offers to delete the account.
  static Stream<bool> showDeleteAccount() => _watch('showDeleteAccount');

  /// Whether the login page offers to continue as a guest.
  static Stream<bool> showGuestMode() => _watch('showGuestLogin');

  /// This platform's document: `App_settings/ios` or `App_settings/android`.
  static String get _documentPath =>
      'App_Settings/${Platform.isIOS ? 'ios' : 'android'}';

  static Stream<bool> _watch(String field) async* {
    await _firebaseReady.future;
    final path = _documentPath;
    yield* FirebaseFirestore.instance
        .doc(path)
        .snapshots()
        .map((snapshot) => snapshot.data()?[field] == true)
        .handleError((Object error) {
          log('Could not read $path: $error', name: 'AppSettings');
        })
        .distinct();
  }
}
