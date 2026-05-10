import 'package:dio/dio.dart';

import '../../constants/app_strings.dart';
import '../../models/models.dart';
import '../api_client.dart';
import '../api_error_handler.dart';

class AdminOrdersService {
  final _client = ApiClient.instance;

  Future<ApiResponse<List<OrderModel>>> getAllOrders() async {
    try {
      final response = await _client.dio.get(ApiConstants.ordersGetAll);
      final rawData = _extractDataList(response.data);
      final items = rawData.map((e) => OrderModel.fromJson(e)).toList();
      // Sort by date descending
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _client.dio.get('${ApiConstants.ordersGet}$id');
      final data = response.data;
      return ApiResponse.success(OrderModel.fromJson(data));
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> markAsShipped(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersShipped}$id');
      return const ApiResponse.success('Order marked as Shipped');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> markAsCompleted(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersComplete}$id');
      return const ApiResponse.success('Order marked as Completed');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> markAsCanceled(int id) async {
    try {
      await _client.dio.patch('${ApiConstants.ordersCanceled}$id');
      return const ApiResponse.success('Order marked as Canceled');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  /// Extracts the list from API response wrapper `{data: [...]}` or raw list.
  List<Map<String, dynamic>> _extractDataList(dynamic responseData) {
    if (responseData is List) {
      return responseData.cast<Map<String, dynamic>>();
    }
    if (responseData is Map) {
      final list = responseData['data'] ?? responseData['returned'];
      if (list is List) return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
