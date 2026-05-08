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
      dynamic rawData = response.data;
      if (rawData is Map && (rawData.containsKey('returned') || rawData.containsKey('data'))) {
        rawData = rawData['returned'] ?? rawData['data'];
      }
      
      final items = (rawData as List).map((e) => UserModel.fromJson(e)).toList();
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
      // Assuming it expects a JSON body or query param
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

  String _parseDioError(DioException exception) {
    return ApiErrorHandler.message(exception);
  }
}
