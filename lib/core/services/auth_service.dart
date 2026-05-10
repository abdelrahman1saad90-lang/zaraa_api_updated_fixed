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

      final accessToken = response.data['accessToken'] as String?;
      final refreshToken = response.data['refreshToken'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        return const ApiResponse.failure('Login failed: no token received.');
      }

      await _client.saveTokens(accessToken, refreshToken ?? '');

      // Decode JWT to extract role and userId (Profile endpoint doesn't return roles)
      final jwtPayload = _decodeJwtPayload(accessToken);
      final jwtRole = jwtPayload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      final jwtUserId = jwtPayload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? '';
      final jwtEmail = jwtPayload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ?? '';
      final jwtUserName = jwtPayload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? '';

      List<String> roles = [];
      if (jwtRole is String) {
        roles = [jwtRole];
      } else if (jwtRole is List) {
        roles = List<String>.from(jwtRole);
      }

      // Get profile for additional user details
      UserModel user;
      try {
        final profileRes = await _client.dio.get(ApiConstants.profile);
        final profileData = profileRes.data as Map<String, dynamic>;

        user = UserModel(
          id: jwtUserId.toString(),
          fullName: '${profileData['firstName'] ?? ''} ${profileData['lastName'] ?? ''}'.trim(),
          userName: profileData['userName'] ?? jwtUserName,
          email: profileData['email'] ?? jwtEmail,
          phoneNumber: profileData['phoneNumber'],
          address: profileData['address'],
          token: accessToken,
          refreshToken: refreshToken,
          roles: roles,
        );
      } catch (_) {
        // Profile fetch failed — build user from JWT claims only
        user = UserModel(
          id: jwtUserId.toString(),
          fullName: jwtUserName,
          userName: jwtUserName,
          email: jwtEmail,
          token: accessToken,
          refreshToken: refreshToken,
          roles: roles,
        );
      }

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

  // ================= JWT DECODE HELPER =================
  /// Decodes a JWT token payload without external dependencies.
  /// Only decodes — does NOT verify signature.
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};

      final payload = parts[1];
      // JWT uses base64url encoding, add padding if needed
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
