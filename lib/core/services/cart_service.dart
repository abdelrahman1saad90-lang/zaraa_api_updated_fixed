import 'package:dio/dio.dart';

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

  // ── Add To Cart (FIXED) ──────────────────────────────────
  Future<ApiResponse<String>> addToCart({
    required int productId,
    int count = 1,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.cartAddToCart,
        data: {
          "productId": productId,
          "quantity": count, // ✅ بدل count
        },
      );
      return const ApiResponse.success('Product added to cart.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Increment Count (FIXED: cartItemId) ──────────────────
  Future<ApiResponse<String>> incrementCount(int productId) async {
    try {
      await _client.dio.post(
        ApiConstants.cartIncrementCount,
        data: {'productId': productId},
      );
      return const ApiResponse.success('Count incremented.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Decrement Count (FIXED: cartItemId) ──────────────────
  Future<ApiResponse<String>> decrementCount(int productId) async {
    try {
      await _client.dio.post(
        ApiConstants.cartDecrementCount,
        data: {'productId': productId},
      );
      return const ApiResponse.success('Count decremented.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Remove From Cart (FIXED: cartItemId) ─────────────────
  Future<ApiResponse<String>> removeFromCart(int productId) async {
    try {
      await _client.dio.post(
        ApiConstants.cartDeleteProduct,
        data: {'productId': productId},
      );
      return const ApiResponse.success('Product removed from cart.');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  // ── Pay ─────────────────────────────────────────────────
  Future<ApiResponse<String>> pay() async {
    try {
      final response = await _client.dio.post(ApiConstants.cartPay);
      final url = response.data['url'] as String?;

      if (url == null || url.isEmpty) {
        return const ApiResponse.failure('No payment URL received.');
      }

      return ApiResponse.success(url);
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
