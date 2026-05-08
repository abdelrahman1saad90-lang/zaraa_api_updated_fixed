import 'package:dio/dio.dart';

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
      dynamic rawData = response.data;
      if (rawData is Map && (rawData.containsKey('returned') || rawData.containsKey('data'))) {
        rawData = rawData['returned'] ?? rawData['data'];
      }
      
      final items = (rawData as List).map((e) => ProductModel.fromJson(e)).toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
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
      await _client.dio.post(
        ApiConstants.adminProductsCreate,
        data: formData,
      );
      return const ApiResponse.success('Product created successfully');
    } on DioException catch (e) {
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

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
