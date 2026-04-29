import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

class AuthService {
  static const _userKey = 'user_data';

  final ApiClient _client = ApiClient.instance;

  // ================= LOGIN =================
  Future<ApiResponse<UserModel>> login({
    required String emailOrUserName,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {
          "emailORUserName": emailOrUserName,
          "password": password,
          "rememberMe": true,
        },
      );

      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];

      if (accessToken == null || accessToken.isEmpty) {
        return const ApiResponse.failure('Login failed: no token received.');
      }

      await _client.saveTokens(accessToken, refreshToken ?? '');

      // get profile
      final profileRes = await _client.dio.get(ApiConstants.profile);

      final user = UserModel.fromProfileJson(
        profileRes.data,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.failure(
        ApiErrorHandler.message(
          e,
          authRequest: true,
          notFoundMessage: 'User not found.',
        ),
      );
    } catch (_) {
      return const ApiResponse.failure(AppStrings.genericError);
    }
  }

  // ================= REGISTER =================
  Future<ApiResponse<String>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String userName,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.register,
        data: {
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "userName": userName,
          "password": password,
          "confirmPassword": password,
        },
      );

      return ApiResponse.success(
        response.data?.toString() ?? 'Registration successful. Please confirm your email.',
      );
    } on DioException catch (e) {
      return ApiResponse.failure(
        ApiErrorHandler.message(
          e,
          conflictMessage: 'Email or username already exists.',
        ),
      );
    }
  }

  // ================= RESEND EMAIL =================
  Future<ApiResponse<String>> resendConfirmation({
    required String emailOrUsername,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.resendConfirmation,
        data: {
          "emailORUserName": emailOrUsername,
        },
      );

      return const ApiResponse.success('Confirmation email resent.');
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    }
  }

  // ================= FORGOT PASSWORD =================
  Future<ApiResponse<String>> forgotPassword({
    required String emailOrUsername,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.forgotPassword,
        data: {
          "emailORUserName": emailOrUsername,
        },
      );

      return const ApiResponse.success('OTP sent.');
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    }
  }

  // ================= RESET PASSWORD =================
  Future<ApiResponse<String>> resetPassword({
    required String userId,
    required String otp,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.resetPassword,
        data: {
          "code": otp,
          "userId": userId,
        },
      );

      return const ApiResponse.success('OTP verified.');
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    }
  }

  // ================= CHANGE PASSWORD =================
  Future<ApiResponse<String>> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await _client.dio.post(
        ApiConstants.changePassword,
        data: {
          "password": newPassword,
          "confirmPassword": newPassword,
          "userId": userId,
        },
      );

      return const ApiResponse.success('Password changed successfully.');
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    try {
      await _client.dio.post(ApiConstants.logout);
    } catch (_) {}

    await _client.clearTokens();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ================= RESTORE SESSION =================
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null) return null;

    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }
}
