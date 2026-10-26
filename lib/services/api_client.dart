import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/product.dart';

/// Thin typed wrapper around the eShop API documented at /openapi/v1.json.
class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: kIsWeb
                  ? Uri.base.resolve('/api').toString()
                  : 'https://accessories-eshop.runasp.net/api',
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            ),
          ),
      _storage = storage ?? const FlutterSecureStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage.read(key: 'accessToken');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (error) {
            // Public browsing must still work if secure storage is temporarily
            // unavailable (for example, before iOS Keychain is unlocked).
            debugPrint('Could not read saved access token: $error');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final canRefresh =
              error.response?.statusCode == 401 &&
              request.extra['authRetry'] != true &&
              !request.path.endsWith('/auth/login') &&
              !request.path.endsWith('/auth/register') &&
              !request.path.endsWith('/auth/verify-email') &&
              !request.path.endsWith('/auth/refresh-token');
          if (!canRefresh) {
            handler.next(error);
            return;
          }

          try {
            final accessToken = await _refreshAccessToken();
            if (accessToken == null) {
              await _clearTokens();
              handler.next(error);
              return;
            }
            request
              ..headers['Authorization'] = 'Bearer $accessToken'
              ..extra['authRetry'] = true;
            handler.resolve(await _dio.fetch<dynamic>(request));
          } catch (_) {
            await _clearTokens();
            handler.next(error);
          }
        },
      ),
    );
  }

  final Dio _dio;
  final FlutterSecureStorage _storage;
  Future<String?>? _refreshing;

  Future<String?> _refreshAccessToken() async {
    final pending = _refreshing;
    if (pending != null) return pending;

    final future = _performTokenRefresh();
    _refreshing = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
    }
  }

  Future<String?> _performTokenRefresh() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) return null;
    final data = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh-token',
      data: {'refreshToken': refreshToken},
    );
    final accessToken = data.data?['accessToken'] as String?;
    final rotatedRefreshToken = data.data?['refreshToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) return null;
    await _storage.write(key: 'accessToken', value: accessToken);
    if (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty) {
      await _storage.write(key: 'refreshToken', value: rotatedRefreshToken);
    }
    return accessToken;
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<bool> hasSession() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String errorMessage(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map) {
        final detail = body['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        // ASP.NET often returns a generic `message` alongside a more useful
        // nested errors map, e.g. errors.generalErrors[0]. Prefer that detail.
        final validationMessage = _firstErrorMessage(body['errors']);
        if (validationMessage != null) return validationMessage;

        for (final key in ['message', 'title']) {
          final message = body[key];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      } else if (body is String && body.trim().isNotEmpty) {
        return body.trim();
      }
      if (error.response == null) {
        return 'Could not connect. Check your internet connection and try again.';
      }
      return 'Request failed (${error.response?.statusCode}). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  int? statusCode(Object error) =>
      error is DioException ? error.response?.statusCode : null;

  String? _firstErrorMessage(Object? errors) {
    if (errors is String && errors.trim().isNotEmpty) return errors.trim();
    if (errors is Iterable) {
      for (final item in errors) {
        final message = _firstErrorMessage(item);
        if (message != null) return message;
      }
    }
    if (errors is Map) {
      for (final item in errors.values) {
        final message = _firstErrorMessage(item);
        if (message != null) return message;
      }
    }
    return null;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await _dio.get(path, queryParameters: query)).data;
  Future<dynamic> post(String path, [Object? body]) async =>
      (await _dio.post(path, data: body)).data;
  Future<dynamic> put(String path, [Object? body]) async =>
      (await _dio.put(path, data: body)).data;
  Future<dynamic> delete(String path, {Object? body}) async =>
      (await _dio.delete(path, data: body)).data;

  Future<List<Product>> products({String? search, String? category}) async {
    final data = await get(
      '/products',
      query:
          {
            'searchTerm': search,
            'category': category,
            'page': 1,
            'pageSize': 50,
          }..removeWhere(
            (_, value) => value == null || value == 'All' || value == '',
          ),
    );
    final items = (data as Map<String, dynamic>)['items'] as List? ?? const [];
    return items
        .map((item) => Product.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> categories() async {
    final data = await get('/categories') as List;
    final result = <Map<String, dynamic>>[];
    for (final group in data) {
      final map = Map<String, dynamic>.from(group as Map);
      final list = map['categories'];
      if (list is List) {
        result.addAll(list.map((e) => Map<String, dynamic>.from(e as Map)));
      }
    }
    return result;
  }

  Future<void> login(String email, String password) async {
    final data =
        await post('/auth/login', {'email': email, 'password': password})
            as Map;
    await _storage.write(
      key: 'accessToken',
      value: data['accessToken'] as String?,
    );
    await _storage.write(
      key: 'refreshToken',
      value: data['refreshToken'] as String?,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await post('/auth/register', {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  Future<void> logout() async {
    try {
      await post('/auth/logout');
    } finally {
      await _clearTokens();
    }
  }

  Future<Map<String, dynamic>> currentUser() async =>
      Map<String, dynamic>.from(await get('/auth/me') as Map);
  Future<Map<String, dynamic>> cart() async =>
      Map<String, dynamic>.from(await get('/cart') as Map);
  Future<void> addCartItem(String productId, {int quantity = 1}) async {
    await post('/cart/items', {'productId': productId, 'quantity': quantity});
  }

  Future<List<dynamic>> addresses() async => await get('/addresses') as List;
  Future<dynamic> createAddress(Map<String, dynamic> data) =>
      post('/addresses', data);
  Future<dynamic> updateAddress(String id, Map<String, dynamic> data) =>
      put('/addresses/$id', {'id': id, ...data});
  Future<dynamic> deleteAddress(String id) => delete('/addresses/$id');
  Future<Map<String, dynamic>> orders({int limit = 20}) async =>
      Map<String, dynamic>.from(
        await get('/orders', query: {'limit': limit}) as Map,
      );
  Future<dynamic> checkout({
    required String addressId,
    required String paymentMethod,
    String? couponCode,
  }) => post('/orders/checkout', {
    'shippingAddressId': addressId,
    'paymentMethod': paymentMethod,
    'couponCode': couponCode,
  });
  Future<dynamic> orderHistory(String orderId) =>
      get('/orders/history/$orderId');
  Future<dynamic> applyCoupon(String couponCode) =>
      post('/cart/apply-coupon', {'couponCode': couponCode});
  Future<dynamic> productReviews(
    String id, {
    int page = 1,
    int pageSize = 20,
  }) => get('/reviews/$id', query: {'page': page, 'pageSize': pageSize});
  Future<dynamic> createReview(
    String id, {
    required int rating,
    String? comment,
  }) => post('/reviews/$id', {
    'productId': id,
    'rating': rating,
    'comment': comment,
  });
  Future<dynamic> offers({int page = 1, int pageSize = 20}) =>
      get('/offers', query: {'page': page, 'pageSize': pageSize});
  Future<dynamic> coupons() => get('/coupons');
  Future<dynamic> notifications({
    bool includeRead = false,
    int page = 1,
    int pageSize = 20,
  }) => get(
    '/notifications',
    query: {'includeRead': includeRead, 'page': page, 'pageSize': pageSize},
  );
  Future<dynamic> markNotificationRead(String id) =>
      post('/notifications/$id/read');
  Future<dynamic> getImageUploadUrl() => get('/files/image');
  Future<dynamic> verifyEmail(String email, String otp) =>
      post('/auth/verify-email', {'email': email, 'otp': otp});
  Future<dynamic> resendOtp(String email) =>
      post('/auth/resend-otp', {'email': email});
  Future<dynamic> validateOtp(String email, String otp) =>
      post('/auth/validate-otp', {'email': email, 'otp': otp});
  Future<dynamic> forgotPassword(String email) =>
      post('/auth/forgot-password', {'email': email});
  Future<dynamic> resetPassword(String email, String otp, String newPassword) =>
      post('/auth/reset-password', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
  Future<dynamic> changePassword(
    String currentPassword,
    String newPassword,
    String confirmNewPassword,
  ) => post('/auth/change-password', {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
    'confirmNewPassword': confirmNewPassword,
  });
  Future<dynamic> refreshToken(String token) async {
    final data =
        await post('/auth/refresh-token', {'refreshToken': token}) as Map;
    await _storage.write(
      key: 'accessToken',
      value: data['accessToken'] as String?,
    );
    await _storage.write(
      key: 'refreshToken',
      value: data['refreshToken'] as String?,
    );
    return data;
  }

  Future<dynamic> googleMobileLogin(String idToken) =>
      post('/auth/google/mobile', {'idToken': idToken});
  Future<dynamic> googleLoginUrl(String returnUrl) =>
      get('/auth/google/login', query: {'returnUrl': returnUrl});
  Future<dynamic> checkAdmin() => get('/auth/admin');
  Future<dynamic> createProduct(Map<String, dynamic> data) =>
      post('/products', data);
  Future<dynamic> updateProduct(String id, Map<String, dynamic> data) =>
      put('/products/$id', data);
  Future<dynamic> deleteProduct(String id) => delete('/products/$id');
  Future<dynamic> createCategory(Map<String, dynamic> data) =>
      post('/categories', data);
  Future<dynamic> category(String id) => get('/categories/$id');
  Future<dynamic> updateCategory(String id, Map<String, dynamic> data) =>
      put('/categories/$id', data);
  Future<dynamic> deleteCategory(String id) => delete('/categories/$id');
  Future<dynamic> updateCartItem(String id, int quantity) =>
      put('/cart/items/$id', {'id': id, 'quantity': quantity});
  Future<dynamic> decrementCartItem(String itemId, int quantity) =>
      post('/cart/items/decrement', {'itemId': itemId, 'quantity': quantity});
  Future<dynamic> deleteCartItem(String id) => delete('/cart/items/$id');
  Future<dynamic> adminOrders({
    String? period,
    int page = 1,
    int pageSize = 20,
  }) => get(
    '/orders/admin',
    query: {'period': period, 'page': page, 'pageSize': pageSize},
  );
  Future<dynamic> updateOrderStatus(
    String orderId,
    String status, {
    String? notes,
  }) => put('/orders/admin/order-status', {
    'orderId': orderId,
    'status': status,
    'notes': notes,
  });
  Future<dynamic> createOffer(Map<String, dynamic> data) =>
      post('/offers', data);
  Future<dynamic> createCoupon(Map<String, dynamic> data) =>
      post('/coupons', data);
  Future<dynamic> bulkMarkNotificationsRead(List<String> ids) =>
      post('/notifications/bulk-read', {'notificationIds': ids});
  Future<dynamic> notifyUser(String userId, String text) =>
      post('/notifications', {'userId': userId, 'notificationText': text});
  Future<dynamic> notifyAllUsers(String text) =>
      post('/notifications/all', {'notificationText': text});
}
