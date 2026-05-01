import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles product and shop API calls.
class ShopService {
  final _client = ApiClient.instance;

  Future<ApiResponse<List<ProductModel>>> getProducts({
    String? productName,
    double? minPrice,
    double? maxPrice,
    int? categoryId,
    bool isHot = false,
    int page = 1,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{
        if (productName != null && productName.isNotEmpty)
          'productName': productName,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (categoryId != null && categoryId > 0) 'categoryId': categoryId,
        'isHot': isHot,
      };

      final response = await _client.dio.get(
        ApiConstants.products,
        queryParameters: {
          'page': page,
          ...body,
        },
      );

      final returned = response.data['returned'] as Map<String, dynamic>?;
      final rawList = returned?['products'] as List<dynamic>? ?? [];

      var products = rawList
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (category != null && category != AppStrings.allCategories) {
        products = products
            .where((product) =>
                product.category.toLowerCase() == category.toLowerCase())
            .toList();
      }

      return ApiResponse.success(products);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getProductDetails(int id) async {
    try {
      final response = await _client.dio.get('${ApiConstants.productDetails}$id');
      return ApiResponse.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    }
  }
}
