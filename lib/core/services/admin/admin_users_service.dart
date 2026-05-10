import 'package:dio/dio.dart';

import '../../constants/app_strings.dart';
import '../../models/models.dart';
import '../api_client.dart';
import '../api_error_handler.dart';

class AdminUsersService {
  final _client = ApiClient.instance;

  Future<ApiResponse<List<UserModel>>> getAllUsers() async {
    try {
      final response = await _client.dio.get(ApiConstants.adminUsersIndex);
      final rawData = _extractDataList(response.data);
      final items = rawData.map((e) => UserModel.fromJson(e)).toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> lockUnlockUser(String userId) async {
    try {
      await _client.dio.post('${ApiConstants.adminUsersLockUnlock}$userId');
      return const ApiResponse.success('User lock status updated successfully');
    } on DioException catch (e) {
      return ApiResponse.failure(_parseDioError(e));
    }
  }

  Future<ApiResponse<String>> updateUserRole(String userId, String newRole) async {
    try {
      await _client.dio.post(
        '${ApiConstants.adminUsersUpdateRole}$userId',
        data: {'role': newRole},
        queryParameters: {'role': newRole},
      );
      return const ApiResponse.success('User role updated successfully');
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
