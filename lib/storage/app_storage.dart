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

  static String get localeCode => _box.get(localeKey, defaultValue: 'en');

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
}
