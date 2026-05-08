import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/admin/admin_users_service.dart';

abstract class AdminUsersState extends Equatable {
  const AdminUsersState();
  @override
  List<Object?> get props => [];
}

class AdminUsersInitial extends AdminUsersState {
  const AdminUsersInitial();
}

class AdminUsersLoading extends AdminUsersState {
  final List<UserModel>? previousUsers;
  const AdminUsersLoading({this.previousUsers});

  @override
  List<Object?> get props => [previousUsers];
}

class AdminUsersLoaded extends AdminUsersState {
  final List<UserModel> users;
  const AdminUsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class AdminUsersError extends AdminUsersState {
  final String message;
  const AdminUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminUserOperationSuccess extends AdminUsersState {
  final String message;
  const AdminUserOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final AdminUsersService _service;

  AdminUsersCubit(this._service) : super(const AdminUsersInitial());

  Future<void> loadUsers() async {
    final currentUsers = state is AdminUsersLoaded ? (state as AdminUsersLoaded).users : null;
    emit(AdminUsersLoading(previousUsers: currentUsers));

    final res = await _service.getAllUsers();
    if (res.isSuccess) {
      emit(AdminUsersLoaded(res.data!));
    } else {
      emit(AdminUsersError(res.error!));
    }
  }

  Future<void> lockUnlockUser(String id) async {
    final res = await _service.lockUnlockUser(id);
    if (res.isSuccess) {
      emit(AdminUserOperationSuccess(res.data!));
      await loadUsers();
    } else {
      emit(AdminUsersError(res.error!));
    }
  }

  Future<void> updateUserRole(String id, String role) async {
    final res = await _service.updateUserRole(id, role);
    if (res.isSuccess) {
      emit(AdminUserOperationSuccess(res.data!));
      await loadUsers();
    } else {
      emit(AdminUsersError(res.error!));
    }
  }
}
