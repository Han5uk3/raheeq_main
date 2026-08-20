import 'package:hive_flutter/hive_flutter.dart';

class AppStorage {
  static const String boxName = 'appBox';
  static const String localeKey = 'localeCode';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> saveLocale(String localeCode) async {
    await _box.put(localeKey, localeCode);
  }

  static String get localeCode => _box.get(localeKey, defaultValue: 'ar');

  static const String _lastDeepLinkKey = 'lastProcessedDeepLink';

  static Future<void> saveLastProcessedDeepLink(String uri) async {
    await _box.put(_lastDeepLinkKey, uri);
  }

  static String? get lastProcessedDeepLink => _box.get(_lastDeepLinkKey);

  static const String _latitudeKey = 'userLatitude';
  static const String _longitudeKey = 'userLongitude';

  static Future<void> saveUserLocation(double lat, double lng) async {
    await _box.put(_latitudeKey, lat);
    await _box.put(_longitudeKey, lng);
  }

  static double? get userLatitude => _box.get(_latitudeKey);
  static double? get userLongitude => _box.get(_longitudeKey);

  // Apple only releases the user's name on the FIRST authorization of an Apple
  // ID against this app; every later sign-in returns it as null. Cached here
  // rather than in authBox because AuthStorage.clear() wipes that box on
  // logout, and a user who logs out and signs in again still needs their name
  // pre-filled. Keyed by Apple's stable userIdentifier so a second Apple ID on
  // the same device never inherits the first one's details.
  static const String _appleProfilePrefix = 'appleProfile_';

  static Future<void> saveAppleProfile({
    required String userIdentifier,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    // Merged, not overwritten: later sign-ins carry nulls, and those must not
    // erase what the first authorization handed us.
    final merged = <String, String>{
      ...?appleProfile(userIdentifier),
      if (email != null && email.isNotEmpty) 'email': email,
      if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
      if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
    };
    if (merged.isEmpty) return;
    if (!Hive.isBoxOpen(boxName)) return;
    await _box.put('$_appleProfilePrefix$userIdentifier', merged);
  }

  static Map<String, String>? appleProfile(String userIdentifier) {
    // Reached from the login screen, which can render before _initDependencies
    // has opened the box. A missing cache is recoverable; a crash mid-sign-in
    // is not.
    if (!Hive.isBoxOpen(boxName)) return null;
    final raw = _box.get('$_appleProfilePrefix$userIdentifier');
    if (raw is! Map) return null;
    return raw.map((key, value) => MapEntry('$key', '$value'));
  }
}
