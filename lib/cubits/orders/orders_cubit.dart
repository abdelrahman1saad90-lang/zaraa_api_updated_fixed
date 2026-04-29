import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/order_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderDetailLoading extends OrdersState {
  const OrderDetailLoading();
}

class OrderDetailLoaded extends OrdersState {
  final OrderModel order;
  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

class OrderActionLoading extends OrdersState {
  const OrderActionLoading();
}

class OrderActionSuccess extends OrdersState {
  final String message;
  const OrderActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderActionError extends OrdersState {
  final String message;
  const OrderActionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT
// ══════════════════════════════════════════════════════════════

class OrdersCubit extends Cubit<OrdersState> {
  final OrderService _service;

  OrdersCubit(this._service) : super(const OrdersInitial());

  List<OrderModel> _cachedOrders = [];
  OrderModel? _currentOrder;

  List<OrderModel> get orders => _cachedOrders;
  OrderModel? get currentOrder => _currentOrder;

  Future<void> loadOrders() async {
    emit(const OrdersLoading());

    final res = await _service.getAllOrders();

    if (res.isSuccess) {
      // Sort orders descending by createdAt 
      final sortedList = res.data!
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _cachedOrders = sortedList;
      emit(OrdersLoaded(sortedList));
    } else {
      emit(OrdersError(res.error ?? 'Failed to load orders'));
    }
  }

  Future<void> loadOrderDetail(int id) async {
    emit(const OrderDetailLoading());

    final res = await _service.getOrderById(id);

    if (res.isSuccess) {
      _currentOrder = res.data!;
      emit(OrderDetailLoaded(res.data!));
    } else {
      emit(OrdersError(res.error ?? 'Failed to load order details'));
    }
  }

  Future<void> markShipped(int id) async {
    emit(const OrderActionLoading());

    final res = await _service.markOrderShipped(id);

    if (res.isSuccess) {
      emit(const OrderActionSuccess('Order marked as shipped'));
      await loadOrderDetail(id); 
    } else {
      emit(OrderActionError(res.error ?? 'Failed to update order status'));
      if (_currentOrder != null) {
        emit(OrderDetailLoaded(_currentOrder!));
      } else {
        await loadOrderDetail(id);
      }
    }
  }

  Future<void> markCompleted(int id) async {
    emit(const OrderActionLoading());

    final res = await _service.markOrderCompleted(id);

    if (res.isSuccess) {
      emit(const OrderActionSuccess('Order marked as completed'));
      await loadOrderDetail(id);
    } else {
      emit(OrderActionError(res.error ?? 'Failed to update order status'));
      if (_currentOrder != null) {
        emit(OrderDetailLoaded(_currentOrder!));
      } else {
        await loadOrderDetail(id);
      }
    }
  }

  Future<void> cancelOrder(int id) async {
    emit(const OrderActionLoading());

    final res = await _service.cancelOrder(id);

    if (res.isSuccess) {
      emit(const OrderActionSuccess('Order canceled successfully'));
      await loadOrderDetail(id);
    } else {
      emit(OrderActionError(res.error ?? 'Failed to cancel order'));
      if (_currentOrder != null) {
        emit(OrderDetailLoaded(_currentOrder!));
      } else {
        await loadOrderDetail(id);
      }
    }
  }
}
