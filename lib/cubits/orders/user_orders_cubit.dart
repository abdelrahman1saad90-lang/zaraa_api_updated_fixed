import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/checkout_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class UserOrdersState extends Equatable {
  const UserOrdersState();
  @override
  List<Object?> get props => [];
}

class UserOrdersInitial extends UserOrdersState {
  const UserOrdersInitial();
}

class UserOrdersLoading extends UserOrdersState {
  final List<OrderModel>? previousOrders;
  const UserOrdersLoading({this.previousOrders});

  @override
  List<Object?> get props => [previousOrders];
}

class UserOrdersLoaded extends UserOrdersState {
  final List<OrderModel> orders;
  const UserOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class UserOrdersError extends UserOrdersState {
  final String message;
  const UserOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT — Customer-facing order history
// ══════════════════════════════════════════════════════════════

class UserOrdersCubit extends Cubit<UserOrdersState> {
  final CheckoutService _service;

  UserOrdersCubit(this._service) : super(const UserOrdersInitial());

  List<OrderModel> _cachedOrders = [];

  List<OrderModel> get orders => _cachedOrders;

  Future<void> loadOrders() async {
    final currentOrders = state is UserOrdersLoaded
        ? (state as UserOrdersLoaded).orders
        : null;
    emit(UserOrdersLoading(previousOrders: currentOrders));

    final res = await _service.getUserOrders();
    if (res.isSuccess) {
      _cachedOrders = res.data!;
      emit(UserOrdersLoaded(res.data!));
    } else {
      emit(UserOrdersError(res.error ?? 'Failed to load orders'));
    }
  }

  Future<void> refresh() => loadOrders();

  /// Counts by status for summary cards
  Map<OrderStatus, int> get statusCounts {
    final counts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      counts[status] = _cachedOrders.where((o) => o.status == status).length;
    }
    return counts;
  }

  /// Total revenue
  double get totalRevenue =>
      _cachedOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
}
