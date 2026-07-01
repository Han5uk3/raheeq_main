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
}
