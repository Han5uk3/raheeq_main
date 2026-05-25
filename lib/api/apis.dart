import 'package:dio/dio.dart';
import '../storage/auth_storage.dart';

class ApiService {
  static const String baseUrl = 'https://api-staging.suqyarahiq.com/api/v1';
  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        )) {
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
            final refreshed = await refreshAccessToken();
            if (refreshed) {
              // Retry the failed request
              final opts = Options(
                method: e.requestOptions.method,
                headers: e.requestOptions.headers,
              );
              opts.headers?['Authorization'] = 'Bearer ${AuthStorage.accessToken}';
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
              // Handle logout
              await AuthStorage.clear();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Request OTP for phone number
  Future<Response> requestOtp({
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/request-otp',
        data: {
          'phoneNumber': phoneNumber,
          'countryCode': countryCode,
        },
      );
      return response;
    } catch (e) {
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
      final data = {
        'countryCode': countryCode,
        'phoneNumber': phoneNumber,
        'otp': otp,
        'fcmToken': ?fcmToken,
        'deviceType': deviceType,
        'deviceId': ?deviceId,
      };

      final response = await _dio.post(
        '/auth/verify-otp',
        data: data,
      );

      // Automatically store token if login successful
      if (response.statusCode == 200 && response.data['success'] == true) {
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

      final response = await _dio.post(
        '/auth/register',
        data: data,
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        await AuthStorage.saveTokens(
          accessToken: resData['accessToken'],
          refreshToken: resData['refreshToken'],
        );
        await AuthStorage.saveUserData(resData['user']);
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh Access Token
  Future<bool> refreshAccessToken() async {
    final refreshToken = AuthStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      // Use a separate Dio instance so interceptors don't loop on 401
      final dioRefresh = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await dioRefresh.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'] ?? response.data; // Depending on API response structure
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
    } catch (e) {
      return false;
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

      final response = await _dio.patch(
        '/me',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final resData = response.data['data'];
        await AuthStorage.saveUserData(resData);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }
}
