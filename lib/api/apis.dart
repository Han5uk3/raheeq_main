import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:convert';
import 'dart:async';
import '../storage/auth_storage.dart';
import '../storage/app_storage.dart';
import 'package:raheeq_main/main.dart';

import 'package:raheeq_main/services/notification_service.dart';

/// Result of a splash-time session check.
enum SessionStatus {
  /// Access token is valid (or was just refreshed). Go to the app.
  valid,

  /// No token, or refresh token was rejected/expired. Go to login.
  invalid,

  /// Couldn't reach the server to refresh (no internet / server down).
  /// Don't log the user out for this - show a retry state instead.
  networkError,
}

class ApiService {
  static const String baseUrl = 'https://api-staging.suqyarahiq.com/api/v1';
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;

  /// Prevents multiple refresh requests from firing concurrently. Every
  /// caller that needs a fresh token (proactively on request, or reactively
  /// on a 401) awaits this same future, so only ONE network refresh call is
  /// ever in flight regardless of how many pages/APIs are hitting the
  /// service at once.
  Future<bool>? _refreshFuture;

  /// Prevents multiple logout calls.
  bool _loggingOut = false;

  /// Maximum retry count (per request) after a refresh.
  static const int _maxRetryCount = 1;

  static const String _retryKey = "_retry_count";

  /// How long before actual expiry we treat the access token as "expiring
  /// soon" and proactively refresh it, so requests don't race the clock.
  static const Duration _expiryBuffer = Duration(seconds: 20);

  /// Endpoints that must NEVER trigger token attachment or the
  /// refresh/retry flow (otherwise you get infinite loops or refresh calls
  /// that try to refresh themselves).
  static const List<String> _authExemptPaths = [
    '/auth/request-otp',
    '/auth/verify-otp',
    '/auth/register',
    '/auth/google',
    '/auth/apple',
    '/auth/refresh-token',
    '/auth/logout',
  ];

  /// Called when a request fails because the device has no internet
  /// connection or the server is unreachable (DNS failure, timeout, etc).
  /// Wire this in main.dart to show a snackbar via CustomSnackbar +
  /// AppLocalizations, similar to [onSessionExpired].
  VoidCallback? onConnectionError;

  /// Simple throttle so a burst of failing requests (e.g. a proactive
  /// refresh + the request that triggered it) doesn't spam the user with
  /// multiple snackbars at once.
  DateTime? _lastConnectionErrorShown;
  static const Duration _connectionErrorThrottle = Duration(seconds: 3);

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.error is SocketException;
  }

  void _notifyConnectionError(DioException e, {String context = ''}) {
    final now = DateTime.now();
    if (_lastConnectionErrorShown != null &&
        now.difference(_lastConnectionErrorShown!) < _connectionErrorThrottle) {
      return;
    }
    _lastConnectionErrorShown = now;

    _logNetwork(
      "No internet / server unreachable${context.isNotEmpty ? ' ($context)' : ''}: "
      "${e.requestOptions.method} ${e.requestOptions.path} — ${e.message}",
    );
    onConnectionError?.call();
  }

  void _logNetwork(String message) {
    debugPrint("[NETWORK] ${DateTime.now().toIso8601String()} $message");
  }

  /// Called once when the session is conclusively invalid (refresh token
  /// missing/expired/rejected). Wire this in main.dart / a router listener
  /// to navigate to the login screen and/or show a "session expired"
  /// snackbar via CustomSnackbar + AppLocalizations.
  VoidCallback? onSessionExpired;

  bool _isAuthExempt(String path) {
    return _authExemptPaths.any((exempt) => path.contains(exempt));
  }

  int _retryCount(RequestOptions options) {
    return (options.extra[_retryKey] ?? 0) as int;
  }

  RequestOptions _copyRequest(RequestOptions request) {
    request.extra[_retryKey] = _retryCount(request) + 1;

    return request;
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    _loggingOut = true;

    try {
      await AuthStorage.clear();
      _cachedTokenForExpiry = null;
      _cachedExpiry = null;
      _log("Session cleared. Notifying listeners.");
      onSessionExpired?.call();
    } finally {
      _loggingOut = false;
    }
  }

  Future<Response> _retryRequest(RequestOptions request) {
    final options = Options(
      method: request.method,
      headers: Map<String, dynamic>.from(request.headers),
      responseType: request.responseType,
      contentType: request.contentType,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      extra: request.extra,
    );

    options.headers?["Authorization"] = "Bearer ${AuthStorage.accessToken}";

    return _dio.request(
      request.path,
      data: request.data,
      queryParameters: request.queryParameters,
      options: options,
      cancelToken: request.cancelToken,
      onReceiveProgress: request.onReceiveProgress,
      onSendProgress: request.onSendProgress,
    );
  }

  void _log(String message) {
    debugPrint("[AUTH] ${DateTime.now().toIso8601String()} $message");
  }

  // ---------------------------------------------------------------------
  // JWT expiry inspection (no extra package required).
  // ---------------------------------------------------------------------

  String? _cachedTokenForExpiry;
  DateTime? _cachedExpiry;

  DateTime? _decodeJwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));

      if (payload is! Map<String, dynamic>) return null;
      final exp = payload['exp'];
      if (exp is! int) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    } catch (e) {
      _log("Could not decode token expiry: $e");
      return null;
    }
  }

  DateTime? _getAccessTokenExpiry(String token) {
    if (_cachedTokenForExpiry == token) return _cachedExpiry;

    final expiry = _decodeJwtExpiry(token);
    _cachedTokenForExpiry = token;
    _cachedExpiry = expiry;

    return expiry;
  }

  /// True if we have no token, or the token is already expired / about to
  /// expire within [_expiryBuffer]. If the token isn't a decodable JWT (or
  /// carries no `exp` claim) this returns false and we simply fall back to
  /// the reactive 401 -> refresh -> retry path.
  bool _isAccessTokenExpiringSoon() {
    final token = AuthStorage.accessToken;
    if (token == null || token.isEmpty) return true;

    final expiry = _getAccessTokenExpiry(token);
    if (expiry == null) return false;

    return DateTime.now().toUtc().isAfter(expiry.subtract(_expiryBuffer));
  }

  // ---------------------------------------------------------------------
  // Constructor + interceptor wiring
  // ---------------------------------------------------------------------

  ApiService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final locale = AppStorage.localeCode;
          options.headers["Accept-Language"] = locale.isNotEmpty ? locale : 'ar';

          if (_isAuthExempt(options.path)) {
            return handler.next(options);
          }

          // Proactively refresh BEFORE the request goes out if the token
          // is missing/expiring. Concurrent requests all funnel through
          // the same _ensureRefreshed() future, so N simultaneous calls
          // trigger exactly ONE refresh request, not N.
          if (_isAccessTokenExpiringSoon()) {
            try {
              await _ensureRefreshed();
            } catch (e) {
              // Network/server hiccup while refreshing proactively: let
              // the request go out with whatever token we have. If it's
              // truly invalid, the onError 401 path below will retry it.
              _log("Proactive refresh failed, continuing request: $e");
            }
          }

          final token = AuthStorage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (_isConnectionError(error)) {
            _notifyConnectionError(error);
          }

          final requestOptions = error.requestOptions;

          final isUnauthorized = error.response?.statusCode == 401;
          if (!isUnauthorized || _isAuthExempt(requestOptions.path)) {
            return handler.next(error);
          }

          if (_retryCount(requestOptions) >= _maxRetryCount) {
            _log("Retry limit hit for ${requestOptions.path}. Logging out.");
            await _logout();
            return handler.next(error);
          }

          bool refreshed;
          try {
            refreshed = await _ensureRefreshed();
          } catch (e) {
            // Refresh call itself failed due to network/server error, not
            // because the refresh token is invalid. Don't destroy the
            // session over a transient failure - surface the original
            // error and let the user retry the action.
            _log("Refresh errored (network/server), not logging out: $e");
            if (e is DioException && _isConnectionError(e)) {
              _notifyConnectionError(e, context: 'token refresh');
            }
            return handler.next(error);
          }

          if (!refreshed) {
            _log("Refresh token invalid/expired. Logging out.");
            await _logout();
            return handler.next(error);
          }

          try {
            final retried = await _retryRequest(_copyRequest(requestOptions));
            return handler.resolve(retried);
          } on DioException catch (e) {
            return handler.next(e);
          } catch (e) {
            return handler.next(error);
          }
        },
      ),
    );
  }

  /// Call this ONCE at splash/startup to decide where to route the user.
  ///
  /// - No tokens stored at all -> [SessionStatus.invalid] (show login).
  /// - Access token still comfortably valid -> [SessionStatus.valid],
  ///   no network call made.
  /// - Access token expiring/expired -> attempts a refresh (reuses the
  ///   same single-flight `_ensureRefreshed()` used by the interceptor,
  ///   so it's safe even if something else on the splash screen is also
  ///   about to make an API call).
  /// - Refresh explicitly rejected (invalid/expired refresh token) ->
  ///   clears storage and returns [SessionStatus.invalid].
  /// - Refresh failed due to network/server error -> returns
  ///   [SessionStatus.networkError] WITHOUT clearing storage, so the user
  ///   can retry once they have a connection instead of being logged out.
  Future<SessionStatus> checkSession() async {
    final accessToken = AuthStorage.accessToken;
    final refreshToken = AuthStorage.refreshToken;

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return SessionStatus.invalid;
    }

    if (!_isAccessTokenExpiringSoon()) {
      return SessionStatus.valid;
    }

    try {
      final refreshed = await _ensureRefreshed();
      if (refreshed) return SessionStatus.valid;

      await _logout();
      return SessionStatus.invalid;
    } catch (e) {
      _log("Session check: refresh failed due to network/server error: $e");
      return SessionStatus.networkError;
    }
  }

  Future<Response> requestOtp({
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      log('Requesting OTP for $countryCode $phoneNumber', name: 'AuthFlow');
      final response = await _dio.post(
        '/auth/request-otp',
        data: {'phoneNumber': phoneNumber, 'countryCode': countryCode},
      );
      log('Request OTP response data: ${response.data}', name: 'AuthFlow');
      return response;
    } catch (e) {
      log('Error requesting OTP: $e', name: 'AuthFlow', error: e);
      rethrow;
    }
  }

  // Verify OTP
  Future<Response> verifyOtp({
    required String countryCode,
    required String phoneNumber,
    required String otp,
    String? fcmToken,
    required String deviceType,
    String? deviceId,
  }) async {
    try {
      log('Verifying OTP for $countryCode $phoneNumber', name: 'AuthFlow');
      fcmToken ??= await NotificationService().getToken();
      final data = {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'otp': otp,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        'deviceType': deviceType,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        'locale': localeNotifier.value.languageCode,
      };

      final response = await _dio.post('/auth/verify-otp', data: data);
      log('Verify OTP response data: ${response.data}', name: 'AuthFlow');

      log('Verify OTP response: ${response.statusCode}', name: 'AuthFlow');
      // Automatically store token if login successful
      if (response.statusCode == 200 && response.data['success'] == true) {
        log('OTP verified successfully, saving tokens.', name: 'AuthFlow');
        final resData = response.data['data'];
        if (resData['userExists'] == true) {
          await AuthStorage.saveTokens(
            accessToken: resData['accessToken'],
            refreshToken: resData['refreshToken'],
          );
          await AuthStorage.saveUserData(resData['user']);
        }
      }

      return response;
    } catch (e) {
      log('Error verifying OTP: $e', name: 'AuthFlow', error: e);
      rethrow;
    }
  }

  /// Register new user
  Future<Response> register({
    required String countryCode,
    required String phoneNumber,
    String? email,
    required String firstName,
    required String lastName,
    String? gender,
    required String deviceType,
    String? fcmToken,
    required String registrationToken,
    String? deviceId,
  }) async {
    try {
      log('Registering user: $phoneNumber', name: 'AuthFlow');
      fcmToken ??= await NotificationService().getToken();
      final data = {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'firstName': firstName,
        'lastName': lastName,
       
        'deviceType': deviceType,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        'registrationToken': registrationToken,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        'locale': localeNotifier.value.languageCode,
      };

      final response = await _dio.post('/auth/register', data: data);

      log('Register response: ${response.statusCode}', name: 'AuthFlow');
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] == true) {
        log('User registered successfully, saving tokens.', name: 'AuthFlow');
        final resData = response.data['data'];
        await AuthStorage.saveTokens(
          accessToken: resData['accessToken'],
          refreshToken: resData['refreshToken'],
        );
        await AuthStorage.saveUserData(resData['user']);
      }

      return response;
    } catch (e) {
      log('Error during registration: $e', name: 'AuthFlow', error: e);
      rethrow;
    }
  }

  /// Google Login
  Future<Response> googleLogin({
    required String idToken,
    required String deviceType,
    String? fcmToken,
    String? deviceId,
  }) async {
    try {
      log('Initiating Google Login', name: 'AuthFlow');
      fcmToken ??= await NotificationService().getToken();
      final data = {
        'idToken': idToken,
        'deviceType': deviceType,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        'locale': localeNotifier.value.languageCode,
      };

      final response = await _dio.post('/auth/google', data: data);

      log('Google Login response: ${response.statusCode}', name: 'AuthFlow');
      if (response.statusCode == 200 && response.data['success'] == true) {
        log('Google Login successful, saving tokens.', name: 'AuthFlow');
        final resData = response.data['data'];
        if (resData['userExists'] == true) {
          await AuthStorage.saveTokens(
            accessToken: resData['accessToken'],
            refreshToken: resData['refreshToken'],
          );
          await AuthStorage.saveUserData(resData['user']);
        }
      }

      return response;
    } catch (e) {
      log('Error during Google Login: $e', name: 'AuthFlow', error: e);
      rethrow;
    }
  }

  /// Apple Login
  Future<Response> appleLogin({
    required String idToken,
    required String deviceType,
    String? fcmToken,
    String? deviceId,
  }) async {
    try {
      log('Initiating Apple Login', name: 'AuthFlow');
      fcmToken ??= await NotificationService().getToken();
      final data = {
        'idToken': idToken,
        'deviceType': deviceType,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        'locale': localeNotifier.value.languageCode,
      };

      final response = await _dio.post('/auth/apple', data: data);

      log('Apple Login response: ${response.statusCode}', name: 'AuthFlow');
      if (response.statusCode == 200 && response.data['success'] == true) {
        log('Apple Login successful, saving tokens.', name: 'AuthFlow');
        final resData = response.data['data'];
        if (resData['userExists'] == true) {
          await AuthStorage.saveTokens(
            accessToken: resData['accessToken'],
            refreshToken: resData['refreshToken'],
          );
          await AuthStorage.saveUserData(resData['user']);
        }
      }

      return response;
    } catch (e) {
      log('Error during Apple Login: $e', name: 'AuthFlow', error: e);
      rethrow;
    }
  }

  /// Refresh Access Token
  Future<bool> _ensureRefreshed() async {
    // Someone else is already refreshing.
    if (_refreshFuture != null) {
      _log("Refresh already in progress. Waiting...");
      return await _refreshFuture!;
    }

    _refreshFuture = _doRefresh();

    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    _log("Starting refresh...");

    final refreshToken = AuthStorage.refreshToken;

    if (refreshToken == null) {
      _log("No refresh token.");
      return false;
    }

    try {
      final dioRefresh = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept-Language': AppStorage.localeCode.isNotEmpty ? AppStorage.localeCode : 'ar',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dioRefresh.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] ?? response.data;

        await AuthStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        // Invalidate the cached expiry so the new token is decoded fresh.
        _cachedTokenForExpiry = null;
        _cachedExpiry = null;

        _log("Refresh successful.");

        return true;
      }

      _log("Refresh failed with unexpected response.");

      return false;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;

      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        _log("Refresh rejected. Status: $statusCode");

        return false;
      }

      _log("Refresh failed due to network/server error.");

      rethrow;
    }
  }

  /// Update User Locale
  Future<Response> updateLocale({
    required String locale,
    String? fcmToken,
  }) async {
    try {
      fcmToken ??= await NotificationService().getToken();
      final response = await _dio.patch(
        '/me/locale',
        data: {
          'locale': locale,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile data
  Future<Response> getProfile({String? etag}) async {
    try {
      final options = Options(
        validateStatus: (status) => status != null && status < 400,
      );
      if (etag != null && etag.isNotEmpty) {
        options.headers = {'If-None-Match': etag};
      }
      final response = await _dio.get('/me', options: options);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        await AuthStorage.saveUserData(resData);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Generate Freshchat JWT Token
  Future<Response> generateFreshchatToken(String freshchatUuid) async {
    try {
      log(
        'API REQUEST: POST /me/freshchat-token with freshchatUuid: $freshchatUuid',
        name: 'FreshchatAPI',
      );
      final response = await _dio.post(
        '/me/freshchat-token',
        data: {'freshchatUuid': freshchatUuid},
        options: Options(extra: {'hide_snackbar': true}),
      );
      log(
        'API RESPONSE [${response.statusCode}]: ${response.data}',
        name: 'FreshchatAPI',
      );
      return response;
    } catch (e) {
      log(
        'Error generating freshchat token: $e',
        name: 'FreshchatAPI',
        error: e,
      );
      rethrow;
    }
  }

  /// Save Freshchat Restore ID
  Future<Response> saveFreshchatRestoreId(String restoreId) async {
    try {
      log(
        'API REQUEST: POST /me/freshchat-restore-id with restoreId: $restoreId',
        name: 'FreshchatAPI',
      );
      final response = await _dio.post(
        '/me/freshchat-restore-id',
        data: {'restoreId': restoreId},
        options: Options(extra: {'hide_snackbar': true}),
      );
      log(
        'API RESPONSE [${response.statusCode}]: ${response.data}',
        name: 'FreshchatAPI',
      );
      return response;
    } catch (e) {
      log(
        'Error saving freshchat restore ID: $e',
        name: 'FreshchatAPI',
        error: e,
      );
      rethrow;
    }
  }

  Future<Response> getHome() async {
    try {
      final response = await _dio.get('/home');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile data using PATCH and FormData
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    dynamic profileImage, // Can be local file String path or MultipartFile
  }) async {
    try {
      final Map<String, dynamic> map = {
        'firstName': ?firstName,
        'lastName': ?lastName,
        'email': ?email,
        'gender': ?gender,
      };

      if (profileImage != null) {
        if (profileImage is String && profileImage.isNotEmpty) {
          map['profileImage'] = await MultipartFile.fromFile(
            profileImage,
            filename: profileImage.split('/').last,
          );
        } else if (profileImage is MultipartFile) {
          map['profileImage'] = profileImage;
        }
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.patch('/me', data: formData);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        await AuthStorage.saveUserData(resData);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update/Refresh FCM Device Token
  Future<Response> updateFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.patch(
        '/me/device-token',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceId': deviceId,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Notify backend of user logout
  Future<Response?> logout({
    required String refreshToken,
    String? fcmToken,
  }) async {
    try {
      fcmToken ??= await NotificationService().getToken();
      final response = await _dio.post(
        '/auth/logout',
        data: {
          'refreshToken': refreshToken,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        },
      );
      return response;
    } catch (e) {
      // Return null or rethrow, but we still proceed with local logout
      return null;
    }
  }

  /// Get Mosques data
  Future<Response> getMosques({
    int page = 1,
    int limit = 100,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
      if (latitude != null) queryParameters['latitude'] = latitude;
      if (longitude != null) queryParameters['longitude'] = longitude;

      final response = await _dio.get(
        '/mosques',
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Cities data
  Future<Response> getCities({bool showSnackbar = false, String? etag}) async {
    try {
      final options = Options(
        extra: {'show_snackbar': showSnackbar},
        validateStatus: (status) => status != null && status < 400,
      );
      if (etag != null && etag.isNotEmpty) {
        options.headers = {'If-None-Match': etag};
      }
      final response = await _dio.get('/geography/cities', options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Orphanages data
  Future<Response> getOrphanages({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/orphanages',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Miqat Mosques data
  Future<Response> getMiqatMosques({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/mosques/miqat',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Favorite Mosques
  Future<Response> getFavoriteMosques() async {
    try {
      final response = await _dio.get('/me/favorites/mosques');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Add Favorite Mosque
  Future<Response> addFavoriteMosque(String mosqueId) async {
    try {
      final response = await _dio.post(
        '/me/favorites/mosques',
        data: {'mosqueId': mosqueId},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete Favorite Mosque
  Future<Response> deleteFavoriteMosque(String mosqueId) async {
    try {
      final response = await _dio.delete('/me/favorites/mosques/$mosqueId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Checkout - Quick
  Future<Response> createCheckoutQuick({
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? subscription,
  }) async {
    try {
      final data = <String, dynamic>{'items': items};
      if (subscription != null) {
        data['subscription'] = subscription;
      }
      final response = await _dio.post('/checkout', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Checkout - Essential
  Future<Response> createCheckoutEssential({
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? subscription,
  }) async {
    try {
      final data = <String, dynamic>{'items': items};
      if (subscription != null) {
        data['subscription'] = subscription;
      }
      final response = await _dio.post('/checkout', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Checkout - Campaign
  Future<Response> createCheckoutCampaign({
    required String campaignId,
    required List<Map<String, dynamic>> items,
    Map<String, dynamic>? subscription,
  }) async {
    try {
      final data = <String, dynamic>{'campaignId': campaignId, 'items': items};
      if (subscription != null) {
        data['subscription'] = subscription;
      }
      final response = await _dio.post('/checkout', data: data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Reorder Checkout
  Future<Response> createReorder(String subOrderId) async {
    try {
      final response = await _dio.post(
        '/checkout/reorder',
        data: {'subOrderId': subOrderId},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Apply Coupon
  Future<Response> applyCoupon(String couponCode) async {
    try {
      final response = await _dio.post(
        '/checkout/coupon',
        data: {'couponCode': couponCode},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove Coupon
  Future<Response> removeCoupon() async {
    try {
      final response = await _dio.delete('/checkout/coupon');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle Wallet
  Future<Response> toggleWallet(bool useWallet) async {
    try {
      final response = await _dio.patch(
        '/checkout/wallet',
        data: {'useWallet': useWallet},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Subscription Plans
  Future<Response> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('/subscription-plans');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Wallet Data
  Future<Response> getWallet({int page = 1, int limit = 10}) async {
    try {
      log(
        'API REQUEST: GET /wallet (page: $page, limit: $limit)',
        name: 'WalletAPI',
      );
      final response = await _dio.get(
        '/wallet',
        queryParameters: {'page': page, 'limit': limit},
      );
      log(
        'API RESPONSE [${response.statusCode}]: ${response.data}',
        name: 'WalletAPI',
      );
      return response;
    } catch (e) {
      log('Error fetching wallet: $e', name: 'WalletAPI', error: e);
      rethrow;
    }
  }

  /// Create Checkout Order
  Future<Response> createOrder({
    required String paymentMethod,
    String? note,
    String? ibanBankAccountId,
    dynamic ibanReceipt,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final url = '/checkout/order';
      log('API REQUEST: POST $url', name: 'CreateOrder');
      if (paymentMethod == 'IBAN') {
        final Map<String, dynamic> map = {
          'paymentMethod': paymentMethod,
          'note': ?note,
          'ibanBankAccountId': ?ibanBankAccountId,
        };

        if (ibanReceipt != null) {
          if (ibanReceipt is String && ibanReceipt.isNotEmpty) {
            map['ibanReceipt'] = await MultipartFile.fromFile(
              ibanReceipt,
              filename: ibanReceipt.split('/').last,
            );
          } else if (ibanReceipt is MultipartFile) {
            map['ibanReceipt'] = ibanReceipt;
          }
        }
        log('API REQUEST BODY (FormData map): $map', name: 'CreateOrder');
        final formData = FormData.fromMap(map);
        final response = await _dio.post(url, data: formData);
        log(
          'API RESPONSE [${response.statusCode}]: ${response.data}',
          name: 'CreateOrder',
        );
        return response;
      } else {
        final data = <String, dynamic>{
          'paymentMethod': paymentMethod,
          'note': ?note,
        };
        log('API REQUEST BODY: $data', name: 'CreateOrder');
        final response = await _dio.post(url, data: data);
        log(
          'API RESPONSE [${response.statusCode}]: ${response.data}',
          name: 'CreateOrder',
        );
        return response;
      }
    } on DioException catch (e) {
      log(
        'API ERROR RESPONSE [${e.response?.statusCode}]: ${e.response?.data}',
        name: 'CreateOrder',
      );
      rethrow;
    } catch (e) {
      log('API ERROR: $e', name: 'CreateOrder');
      rethrow;
    }
  }

  /// Verify Payment
  Future<Response> verifyPayment({
    required String paymentId,
    String? transactionId,
  }) async {
    try {
      final data = <String, dynamic>{'tranRef': ?transactionId};

      final url = '/orders/$paymentId/verify-payment';
      log('API REQUEST: POST $url', name: 'VerifyPayment');
      log('API REQUEST BODY: $data', name: 'VerifyPayment');

      final response = await _dio.post(url, data: data);

      log(
        'API RESPONSE [${response.statusCode}]: ${response.data}',
        name: 'VerifyPayment',
      );

      return response;
    } on DioException catch (e) {
      log(
        'API ERROR RESPONSE [${e.response?.statusCode}]: ${e.response?.data}',
        name: 'VerifyPayment',
      );
      rethrow;
    } catch (e) {
      log('API ERROR: $e', name: 'VerifyPayment');
      rethrow;
    }
  }

  /// Get Bank Accounts for IBAN Payment
  Future<Response> getBankAccounts() async {
    try {
      log('API REQUEST: GET /bank-accounts', name: 'GetBankAccounts');
      final response = await _dio.get('/bank-accounts');
      log(
        'API RESPONSE [${response.statusCode}]: ${response.data}',
        name: 'GetBankAccounts',
      );
      return response;
    } on DioException catch (e) {
      log(
        'API ERROR RESPONSE [${e.response?.statusCode}]: ${e.response?.data}',
        name: 'GetBankAccounts',
      );
      rethrow;
    } catch (e) {
      log('API ERROR: $e', name: 'GetBankAccounts');
      rethrow;
    }
  }

  /// Get Customer Reviews
  Future<Response> getCustomerReviews({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/orders/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get All Notifications
  Future<Response> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Unread Notifications Count
  Future<Response> getUnreadNotificationsCount({
    bool showSnackbar = false,
    String? etag,
  }) async {
    try {
      final options = Options(
        extra: {'show_snackbar': showSnackbar},
        validateStatus: (status) => status != null && status < 400,
      );
      if (etag != null && etag.isNotEmpty) {
        options.headers = {'If-None-Match': etag};
      }
      final response = await _dio.get(
        '/notifications/unread-count',
        options: options,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Read Notification
  Future<Response> readNotification(String id) async {
    try {
      final response = await _dio.patch('/notifications/$id/read');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Read All Notifications
  Future<Response> readAllNotifications() async {
    try {
      final response = await _dio.patch('/notifications/read-all');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete Notification
  Future<Response> deleteNotification(String id) async {
    try {
      final response = await _dio.delete('/notifications/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete All Notifications
  Future<Response> clearAllNotifications() async {
    try {
      final response = await _dio.delete('/notifications');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Rate Sub Order
  Future<Response> rateOrder(
    String subOrderId,
    int rating,
    String reviewText,
  ) async {
    try {
      final response = await _dio.post(
        '/orders/sub-orders/$subOrderId/review',
        data: {'rating': rating, 'reviewText': reviewText},
      );
      return response;
    } catch (e) {
      log('Error rating order: $e', name: 'Orders');
      rethrow;
    }
  }

  /// Get My Orders
  Future<Response> getMyOrders({
    int page = 1,
    int limit = 20,
    String? tab,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (tab != null) {
        queryParams['tab'] = tab;
      }
      final response = await _dio.get('/orders', queryParameters: queryParams);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Order Details
  Future<Response> getOrderDetails(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Sub Order Details
  Future<Response> getSubOrderDetails(String id) async {
    try {
      final response = await _dio.get('/orders/$id/sub-orders');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get My Subscriptions
  Future<Response> getMySubscriptions({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/subscriptions',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Subscription Details
  Future<Response> getSubscriptionDetails(String id) async {
    try {
      final response = await _dio.get('/subscriptions/$id');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Sub Orders by Order ID
  Future<Response> getSubOrdersByOrderId(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/sub-orders');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get User Ratings (Reviews)
  Future<Response> getReviews({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/orders/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Gift Card Templates
  Future<Response> getGiftCardTemplates() async {
    try {
      final response = await _dio.get('/gift-card-templates');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Apply Gift Card
  Future<Response> applyGiftCard({
    required String itemId,
    required Map<String, dynamic> giftCardData,
  }) async {
    try {
      final response = await _dio.patch(
        '/checkout/items/$itemId/gift-card',
        data: {'giftCard': giftCardData},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Remove Gift Card
  Future<Response> removeGiftCard({required String itemId}) async {
    try {
      final response = await _dio.patch(
        '/checkout/items/$itemId/gift-card',
        data: {'giftCard': null},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Feedback
  Future<Response> createFeedback({required String message}) async {
    try {
      final response = await _dio.post('/feedback', data: {'message': message});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Create Complaint
  Future<Response> createComplaint({
    required String subOrderId,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/complaints',
        data: {'subOrderId': subOrderId, 'description': description},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Impact data
  Future<Response> getImpact({bool showSnackbar = false, String? etag}) async {
    try {
      final options = Options(
        extra: {'show_snackbar': showSnackbar},
        validateStatus: (status) => status != null && status < 400,
      );
      if (etag != null && etag.isNotEmpty) {
        options.headers = {'If-None-Match': etag};
      }
      final response = await _dio.get('/me/impact', options: options);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getMyChillers() async {
    try {
      final response = await _dio.get('/orders/my-chillers');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

class ApiDioException extends DioException {
  final String apiMessage;

  ApiDioException({
    required super.requestOptions,
    required this.apiMessage,
    super.response,
    super.type,
    super.error,
    super.message,
  });

  @override
  String toString() {
    return apiMessage;
  }
}
