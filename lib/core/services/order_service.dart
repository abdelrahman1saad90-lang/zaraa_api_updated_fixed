import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles Admin Orders operations.
class OrderService {
  final _client = ApiClient.instance;

  /// GET /api/Admin/Orders/GetAll
  Future<ApiResponse<List<OrderModel>>> getAllOrders() async {
    try {
      final response = await _client.dio.get(ApiConstants.ordersGetAll);
      
      final rawList = response.data as List<dynamic>? ?? [];
      final orders = rawList
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(orders);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// GET /api/Admin/Orders/Get/{id}
  Future<ApiResponse<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _client.dio.get('${ApiConstants.ordersGet}$id');
      
      final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(order);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// PATCH /api/Admin/Orders/Shipped/{id}
  Future<ApiResponse<bool>> markOrderShipped(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersShipped}$id');
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// PATCH /api/Admin/Orders/Complete/{id}
  Future<ApiResponse<bool>> markOrderCompleted(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersComplete}$id');
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  /// PATCH /api/Admin/Orders/Canceled/{id}
  Future<ApiResponse<bool>> cancelOrder(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersCanceled}$id');
      return const ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }
}
