import 'package:dio/dio.dart';
import 'dart:developer';
import '../storage/auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://api-staging.suqyarahiq.com/api/v1';
  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    // ── Logging interceptor (added first so it fires before auth) ──
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log(
            '┌── REQUEST ─────────────────────────────────────────────\n'
            '│ ${options.method} ${options.uri}\n'
            '│ Headers : ${options.headers}\n'
            '│ Body    : ${options.data}',
            name: 'API',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log(
            '├── RESPONSE ────────────────────────────────────────────\n'
            '│ ${response.statusCode} ${response.requestOptions.uri}\n'
            '│ Headers : ${response.headers.map}\n'
            '│ Body    : ${response.data}',
            name: 'API',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          log(
            '└── ERROR ───────────────────────────────────────────────\n'
            '│ ${e.requestOptions.method} ${e.requestOptions.uri}\n'
            '│ Status  : ${e.response?.statusCode}\n'
            '│ Message : ${e.message}\n'
            '│ Body    : ${e.response?.data}',
            name: 'API',
            error: e,
          );
          return handler.next(e);
        },
      ),
    );

    // ── Auth / token-refresh interceptor ──
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthStorage.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Avoid retrying if this is already a refresh token request
            if (e.requestOptions.path.contains('/auth/refresh-token')) {
              await AuthStorage.clear();
              return handler.next(e);
            }

            try {
              final refreshed = await refreshAccessToken();
              if (refreshed) {
                // Retry the failed request
                final opts = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                opts.headers?['Authorization'] =
                    'Bearer ${AuthStorage.accessToken}';
                try {
                  final cloneReq = await _dio.request(
                    e.requestOptions.path,
                    options: opts,
                    data: e.requestOptions.data,
                    queryParameters: e.requestOptions.queryParameters,
                  );
                  return handler.resolve(cloneReq);
                } catch (e2) {
                  return handler.next(e);
                }
              } else {
                // Handle logout on refresh token explicitly failing
                await AuthStorage.clear();
              }
            } catch (refreshErr) {
              // Network error during refresh, just pass original 401 error
              // without clearing session
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
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

  /// Verify OTP
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
      final data = {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'otp': otp,
        'fcmToken': ?fcmToken,
        'deviceType': deviceType,
        'deviceId': ?deviceId,
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
    required String email,
    required String firstName,
    required String lastName,
    required String gender,
    required String deviceType,
    String? fcmToken,
    required String registrationToken,
    String? deviceId,
  }) async {
    try {
      log('Registering user: $phoneNumber', name: 'AuthFlow');
      final data = {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'deviceType': deviceType,
        'fcmToken': ?fcmToken,
        'registrationToken': registrationToken,
        'deviceId': ?deviceId,
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
      final data = {
        'idToken': idToken,
        'deviceType': deviceType,
        'fcmToken': ?fcmToken,
        'deviceId': ?deviceId,
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
      final data = {
        'idToken': idToken,
        'deviceType': deviceType,
        'fcmToken': ?fcmToken,
        'deviceId': ?deviceId,
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
  Future<bool> refreshAccessToken() async {
    final refreshToken = AuthStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dioRefresh.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'] ?? response.data;
        final newAccessToken = resData['accessToken'];
        final newRefreshToken = resData['refreshToken'];
        if (newAccessToken != null && newRefreshToken != null) {
          await AuthStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return false;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user profile data
  Future<Response> getProfile() async {
    try {
      final response = await _dio.get('/me');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        await AuthStorage.saveUserData(resData);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Home page data
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
    String? gender,
    dynamic profileImage, // Can be local file String path or MultipartFile
  }) async {
    try {
      final Map<String, dynamic> map = {
        'firstName': ?firstName,
        'lastName': ?lastName,
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
      final response = await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken, 'fcmToken': ?fcmToken},
      );
      return response;
    } catch (e) {
      // Return null or rethrow, but we still proceed with local logout
      return null;
    }
  }

  /// Get Mosques data
  Future<Response> getMosques() async {
    try {
      final response = await _dio.get('/mosques');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Cities data
  Future<Response> getCities() async {
    try {
      final response = await _dio.get('/geography/cities');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Orphanages data
  Future<Response> getOrphanages() async {
    try {
      final response = await _dio.get('/orphanages');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get Miqat Mosques data
  Future<Response> getMiqatMosques() async {
    try {
      final response = await _dio.get('/mosques/miqat');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
