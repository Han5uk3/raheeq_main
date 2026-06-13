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
          // Do not attempt token refresh or clear session for unauthenticated
          // auth endpoints (e.g. verify-otp, request-otp, register). These
          // endpoints can legitimately return 401 for bad credentials/otp
          // and should not log the user out or trigger navigation to Login.
          if (e.requestOptions.path.startsWith('/auth/') &&
              !e.requestOptions.path.contains('/auth/refresh-token')) {
            return handler.next(e);
          }

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
    String? email,
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
        if (email != null && email.isNotEmpty) 'email': email,
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

  /// Generate Freshchat JWT Token
  Future<Response> generateFreshchatToken(String freshchatUuid) async {
    try {
      log('API REQUEST: POST /me/freshchat-token with freshchatUuid: $freshchatUuid', name: 'FreshchatAPI');
      final response = await _dio.post(
        '/me/freshchat-token',
        data: {'freshchatUuid': freshchatUuid},
      );
      log('API RESPONSE [${response.statusCode}]: ${response.data}', name: 'FreshchatAPI');
      return response;
    } catch (e) {
      log('Error generating freshchat token: $e', name: 'FreshchatAPI', error: e);
      rethrow;
    }
  }

  /// Save Freshchat Restore ID
  Future<Response> saveFreshchatRestoreId(String restoreId) async {
    try {
      log('API REQUEST: POST /me/freshchat-restore-id with restoreId: $restoreId', name: 'FreshchatAPI');
      final response = await _dio.post(
        '/me/freshchat-restore-id',
        data: {'restoreId': restoreId},
      );
      log('API RESPONSE [${response.statusCode}]: ${response.data}', name: 'FreshchatAPI');
      return response;
    } catch (e) {
      log('Error saving freshchat restore ID: $e', name: 'FreshchatAPI', error: e);
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
  Future<Response> getWallet() async {
    try {
      final response = await _dio.get('/wallet');
      return response;
    } catch (e) {
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
          if (note != null) 'note': note,
          if (ibanBankAccountId != null) 'ibanBankAccountId': ibanBankAccountId,
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
          if (note != null) 'note': note,
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
  Future<Response> getUnreadNotificationsCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
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

  /// Get My Orders
  Future<Response> getMyOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/orders',
        queryParameters: {'page': page, 'limit': limit},
      );
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

  /// Rate Order (Sub Order)
  Future<Response> rateOrder({
    required String subOrderId,
    required int rating,
    required String reviewText,
  }) async {
    try {
      final data = {'rating': rating, 'reviewText': reviewText};
      final response = await _dio.post(
        '/orders/sub-orders/$subOrderId/review',
        data: data,
      );
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
}
