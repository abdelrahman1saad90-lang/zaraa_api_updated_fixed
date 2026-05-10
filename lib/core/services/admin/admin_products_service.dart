import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants/app_strings.dart';
import '../../models/models.dart';
import '../../models/admin/product_request_model.dart';
import '../api_client.dart';
import '../api_error_handler.dart';

class AdminProductsService {
  final _client = ApiClient.instance;

  Future<ApiResponse<List<ProductModel>>> getAllProducts() async {
    try {
      final response = await _client.dio.get(ApiConstants.adminProductsIndex);
      if (kDebugMode) {
        debugPrint('┌── GET ALL PRODUCTS ────────────────────');
        debugPrint('│ Status: ${response.statusCode}');
        debugPrint('│ Response type: ${response.data.runtimeType}');
        debugPrint('│ Response: ${response.data.toString().length > 500 ? response.data.toString().substring(0, 500) + "..." : response.data}');
        debugPrint('└────────────────────────────────────────');
      }
      final rawData = _extractDataList(response.data);
      if (kDebugMode) {
        debugPrint('│ Parsed ${rawData.length} products');
      }
      try {
        final items = rawData.map((e) => ProductModel.fromJson(e)).toList();
        return ApiResponse.success(items);
      } catch (e, stack) {
        if (kDebugMode) debugPrint('│ Parsing Error: $e\n$stack');
        return const ApiResponse.failure('Data format error: failed to parse products.');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('┌── GET ALL PRODUCTS ERROR ──────────────');
        debugPrint('│ Status: ${e.response?.statusCode}');
        debugPrint('│ Response: ${e.response?.data}');
        debugPrint('│ Message: ${e.message}');
        debugPrint('└────────────────────────────────────────');
      }
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<ProductModel>> getProductDetails(int productId) async {
    try {
      final response = await _client.dio.get('${ApiConstants.adminProductsDetails}$productId');
      return ApiResponse.success(ProductModel.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> createProduct(ProductRequestModel productData) async {
    try {
      final formData = await productData.toFormData();
      if (kDebugMode) {
        debugPrint('┌── CREATE PRODUCT ──────────────────────');
        debugPrint('│ URL: ${ApiConstants.adminProductsCreate}');
        debugPrint('│ Fields: ${formData.fields}');
        debugPrint('│ Files: ${formData.files.map((f) => '${f.key}: ${f.value.filename}').toList()}');
      }
      final response = await _client.dio.post(
        ApiConstants.adminProductsCreate,
        data: formData,
      );
      if (kDebugMode) {
        debugPrint('│ Status: ${response.statusCode}');
        debugPrint('│ Response: ${response.data}');
        debugPrint('└────────────────────────────────────────');
      }
      return const ApiResponse.success('Product created successfully');
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('┌── CREATE PRODUCT ERROR ────────────────');
        debugPrint('│ Status: ${e.response?.statusCode}');
        debugPrint('│ Response: ${e.response?.data}');
        debugPrint('│ Message: ${e.message}');
        debugPrint('└────────────────────────────────────────');
      }
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> updateProduct(int id, ProductRequestModel productData) async {
    try {
      final formData = await productData.toFormData();
      await _client.dio.put(
        '${ApiConstants.adminProductsEdit}$id',
        data: formData,
      );
      return const ApiResponse.success('Product updated successfully');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> deleteProduct(int id) async {
    try {
      await _client.dio.delete('${ApiConstants.adminProductsDelete}$id');
      return const ApiResponse.success('Product deleted successfully');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  /// Extracts the list from API response wrapper.
  /// Supports multiple shapes:
  ///   - Raw list: [...]
  ///   - {data: [...]} or {returned: [...]}
  ///   - {returned: {products: [...]}}  ← Customer/HomeData/Index shape
  ///   - {items:[...]}, {products:[...]}, {result:[...]}, {value:[...]}
  ///   - Any first-found list value in the map
  List<Map<String, dynamic>> _extractDataList(dynamic responseData) {
    if (responseData is List) {
      return responseData.cast<Map<String, dynamic>>();
    }
    if (responseData is Map) {
      // Handle Customer/HomeData/Index shape: {returned: {products: [...]}}
      final returned = responseData['returned'];
      if (returned is Map) {
        final innerProducts = returned['products'];
        if (innerProducts is List) return innerProducts.cast<Map<String, dynamic>>();
        // also check other inner keys
        for (final key in ['data', 'items', 'result', 'value']) {
          final candidate = returned[key];
          if (candidate is List) return candidate.cast<Map<String, dynamic>>();
        }
      }
      if (returned is List) return returned.cast<Map<String, dynamic>>();

      // Try well-known top-level wrapper keys
      for (final key in ['data', 'items', 'products', 'result', 'value']) {
        final candidate = responseData[key];
        if (candidate is List) return candidate.cast<Map<String, dynamic>>();
      }

      // Fall back: return the first List value found in the map
      for (final value in responseData.values) {
        if (value is List && value.isNotEmpty) {
          try {
            return value.cast<Map<String, dynamic>>();
          } catch (_) {}
        }
      }
    }
    return [];
  }

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
