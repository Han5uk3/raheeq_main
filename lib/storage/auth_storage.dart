import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

class AuthStorage {
  static const String boxName = 'authBox';
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String userDataKey = 'userData';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Box get _box => Hive.box(boxName);

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(accessTokenKey, accessToken);
    await _box.put(refreshTokenKey, refreshToken);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _box.put(userDataKey, userData);
  }

  static String? get accessToken => _box.get(accessTokenKey);
  static String? get refreshToken => _box.get(refreshTokenKey);
  
  static User? get user {
    final raw = _box.get(userDataKey);
    if (raw == null) return null;
    final Map<String, dynamic> data = Map<String, dynamic>.from(raw as Map);
    return User.fromJson(data);
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
