import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../constants/app_strings.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles cart API calls.
/// All endpoints require a valid bearer token.
class CartService {
  final _client = ApiClient.instance;

  // ── Get Cart ─────────────────────────────────────────────
  Future<ApiResponse<CartModel>> getCart() async {
    try {
      final response = await _client.dio.get(ApiConstants.cartIndex);
      
      dynamic rawData = response.data;
      if (rawData is Map && (rawData.containsKey('returned') || rawData.containsKey('data'))) {
        rawData = rawData['returned'] ?? rawData['data'];
      }
      
      final cart = CartModel.fromJson(rawData as Map<String, dynamic>);
      return ApiResponse.success(cart);
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Add To Cart ──────────────────────────────────────────
  /// Matches Angular: POST with query params + empty body + text response
  Future<ApiResponse<String>> addToCart({
    required int productId,
    int count = 1,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('┌── ADD TO CART ─────────────────────────');
        debugPrint('│ productId: $productId, count: $count');
      }
      await _client.dio.post(
        ApiConstants.cartAddToCart,
        data: {},  // empty body — required by ASP.NET
        queryParameters: {
          'productId': productId,
          'count': count,
        },
        options: Options(responseType: ResponseType.plain),
      );
      if (kDebugMode) debugPrint('└── ADD TO CART SUCCESS ─────────────────');
      return const ApiResponse.success('Product added to cart.');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('│ ADD TO CART ERROR: ${e.response?.statusCode} ${e.response?.data}');
        debugPrint('└────────────────────────────────────────');
      }
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Increment Count ──────────────────────────────────────
  Future<ApiResponse<String>> incrementCount(int productId) async {
    try {
      await _client.dio.patch(
        '${ApiConstants.cartIncrementCount}/$productId',
        data: {},  // empty body — required by ASP.NET
      );
      return const ApiResponse.success('Count incremented.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Decrement Count ──────────────────────────────────────
  Future<ApiResponse<String>> decrementCount(int productId) async {
    try {
      await _client.dio.patch(
        '${ApiConstants.cartDecrementCount}/$productId',
        data: {},  // empty body — required by ASP.NET
      );
      return const ApiResponse.success('Count decremented.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Remove From Cart ─────────────────────────────────────
  Future<ApiResponse<String>> removeFromCart(int productId) async {
    try {
      await _client.dio.patch(
        '${ApiConstants.cartDeleteProduct}/$productId',
        data: {},  // empty body — required by ASP.NET
      );
      return const ApiResponse.success('Product removed from cart.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Pay (Stripe) ─────────────────────────────────────────
  /// Calls backend to create a Stripe checkout session.
  /// Returns the payment URL on success.
  Future<ApiResponse<String>> pay() async {
    try {
      if (kDebugMode) debugPrint('┌── CART PAY ────────────────────────────');
      final response = await _client.dio.post(
        ApiConstants.cartPay,
        data: {},  // empty body — required by ASP.NET
      );
      if (kDebugMode) {
        debugPrint('│ Status: ${response.statusCode}');
        debugPrint('│ Response: ${response.data}');
        debugPrint('└────────────────────────────────────────');
      }

      // Extract URL from response — handle wrapped and unwrapped shapes
      String? url;
      final data = response.data;
      if (data is Map) {
        url = data['url'] as String?;
        // Also check wrapped shape: {returned: {url: "..."}}
        if (url == null && data['returned'] is Map) {
          url = data['returned']['url'] as String?;
        }
        // Also try 'data' wrapper
        if (url == null && data['data'] is Map) {
          url = data['data']['url'] as String?;
        }
      } else if (data is String && data.startsWith('http')) {
        url = data;
      }

      if (url == null || url.isEmpty) {
        return const ApiResponse.failure('No payment URL received from server.');
      }

      return ApiResponse.success(url);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('│ PAY ERROR: ${e.response?.statusCode} ${e.response?.data}');
        debugPrint('└────────────────────────────────────────');
      }
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
