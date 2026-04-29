import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles plant diagnosis API calls.
class DiagnosisService {
  final _client = ApiClient.instance;

  Future<ApiResponse<DiagnosisModel>> diagnose({
    required File imageFile,
    required String plantId,
    required String plantName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'plant': plantId,
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'plant_image.jpg',
        ),
      });

      final response = await _client.dio.post(
        ApiConstants.diagnose,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final result = DiagnosisModel.fromJson(response.data);
      return ApiResponse.success(result);
    } on DioException catch (e) {
      return ApiResponse.failure(_handleDioError(e));
    } on Exception catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  Future<ApiResponse<List<DiagnosisModel>>> getHistory() async {
    try {
      final response = await _client.dio.get(ApiConstants.diagnosisHistory);
      final list = (response.data as List)
          .map((item) => DiagnosisModel.fromJson(item))
          .toList();
      return ApiResponse.success(list);
    } on DioException catch (e) {
      return ApiResponse.failure(_handleDioError(e));
    } on Exception catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  String _handleDioError(DioException exception) {
    if (exception.response?.statusCode == 422) {
      return 'Could not process the image. Please use a clearer photo.';
    }

    return ApiErrorHandler.message(exception);
  }
}
