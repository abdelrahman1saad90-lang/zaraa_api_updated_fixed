import 'package:equatable/equatable.dart';
import '../../core/models/models.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state — app just launched, haven't checked session yet
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Waiting for login/register/session-check API call
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is logged in and has a valid session
class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not logged in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Registration succeeded — user must confirm email before logging in
class AuthNeedsEmailConfirmation extends AuthState {
  final String message;
  const AuthNeedsEmailConfirmation(this.message);

  @override
  List<Object?> get props => [message];
}

/// Login or register attempt failed
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Too many login attempts – user must wait before retrying
class AuthRateLimited extends AuthState {
  final Duration waitTime;
  const AuthRateLimited(this.waitTime);

  @override
  List<Object?> get props => [waitTime];
}
