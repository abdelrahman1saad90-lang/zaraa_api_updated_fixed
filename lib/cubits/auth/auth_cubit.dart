import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../core/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(const AuthInitial());

  Future<void> checkSession() async {
    emit(const AuthLoading());

    final user = await _authService.restoreSession();

    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({
    required String emailOrUsername,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _authService.login(
      emailOrUserName: emailOrUsername.trim(),
      password: password,
    );

    if (result.isSuccess) {
      emit(AuthAuthenticated(result.data!));
    } else {
      final msg = result.error ?? AppStrings.genericError;
      if (msg.toLowerCase().contains('too many attempts')) {
        // default wait time 5 minutes; can be adjusted later
        emit(const AuthRateLimited(Duration(minutes: 5)));
      } else {
        emit(AuthError(msg));
      }
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String userName,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _authService.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      userName: userName.trim(),
      email: email.trim(),
      password: password,
    );

    if (result.isSuccess) {
      emit(AuthNeedsEmailConfirmation(result.data!));
    } else {
      emit(AuthError(result.error!));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(const AuthUnauthenticated());
  }

  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) return currentState.user;
    return null;
  }
}
