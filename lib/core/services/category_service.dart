import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles Category CRUD API calls (Admin endpoints).
class CategoryService {
  final _client = ApiClient.instance;

  /// GET /api/Admin/Categories/Index
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    try {
      final response = await _client.dio.get(ApiConstants.categoriesIndex);

      dynamic rawData = response.data;
      if (rawData is Map) {
        rawData = rawData['returned'] ?? rawData['data'] ?? rawData;
      }

      final rawList = rawData as List<dynamic>? ?? [];

      final categories = rawList
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(categories);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// POST /api/Admin/Categories/Create
  Future<ApiResponse<bool>> createCategory({
    required String name,
    String? description,
    bool status = true,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.categoriesCreate,
        data: {
          'name': name,
          'description': description,
          'status': status,
        },
      );
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// PUT /api/Admin/Categories/Edit/{id}
  Future<ApiResponse<bool>> editCategory({
    required int id,
    required String name,
    String? description,
    bool status = true,
  }) async {
    try {
      await _client.dio.put(
        '${ApiConstants.categoriesEdit}$id',
        data: {
          'name': name,
          'description': description,
          'status': status,
        },
      );
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// DELETE /api/Admin/Categories/Delete/{id}
  Future<ApiResponse<bool>> deleteCategory(int id) async {
    try {
      await _client.dio.delete('${ApiConstants.categoriesDelete}$id');
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }
}
