import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/admin/admin_orders_service.dart';
import '../../core/services/api_client.dart';

// ── States ────────────────────────────────────────────────────────
abstract class AdminOrdersState extends Equatable {
  const AdminOrdersState();
  @override
  List<Object?> get props => [];
}

class AdminOrdersInitial extends AdminOrdersState {
  const AdminOrdersInitial();
}

class AdminOrdersLoading extends AdminOrdersState {
  final List<OrderModel>? previousOrders;
  const AdminOrdersLoading({this.previousOrders});

  @override
  List<Object?> get props => [previousOrders];
}

class AdminOrdersLoaded extends AdminOrdersState {
  final List<OrderModel> orders;
  const AdminOrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

class AdminOrdersError extends AdminOrdersState {
  final String message;
  const AdminOrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────────
class AdminOrdersCubit extends Cubit<AdminOrdersState> {
  final AdminOrdersService _service;

  AdminOrdersCubit(this._service) : super(const AdminOrdersInitial());

  Future<void> loadOrders() async {
    final currentOrders = state is AdminOrdersLoaded ? (state as AdminOrdersLoaded).orders : null;
    emit(AdminOrdersLoading(previousOrders: currentOrders));

    final res = await _service.getAllOrders();
    if (res.isSuccess) {
      _cachedOrders = res.data!;
      emit(AdminOrdersLoaded(res.data!));
    } else {
      emit(AdminOrdersError(res.error!));
    }
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus newStatus) async {
    final currentOrders = state is AdminOrdersLoaded ? (state as AdminOrdersLoaded).orders : null;
    if (currentOrders == null) return;

    emit(AdminOrdersLoading(previousOrders: currentOrders));
    
    // We optimismally update or wait for API
    ApiResponse<String>? res;

    switch (newStatus) {
      case OrderStatus.shipped:
        res = await _service.markAsShipped(orderId);
        break;
      case OrderStatus.completed:
        res = await _service.markAsCompleted(orderId);
        break;
      case OrderStatus.canceled:
        res = await _service.markAsCanceled(orderId);
        break;
      default:
        emit(AdminOrdersLoaded(currentOrders));
        return;
    }

    if (res.isSuccess) {
      await loadOrders();
    } else {
      // Return to previous loaded state, but could emit error
      emit(AdminOrdersError(res.error!));
      await Future.delayed(const Duration(seconds: 2));
      emit(AdminOrdersLoaded(currentOrders));
    }
  }

  // ── Revenue & Statistics ──────────────────────────────────

  List<OrderModel> _cachedOrders = [];

  List<OrderModel> get allOrders => _cachedOrders;

  /// Total revenue from all completed/processing/shipped orders
  double get totalRevenue => _cachedOrders
      .where((o) => o.status != OrderStatus.canceled)
      .fold(0.0, (sum, o) => sum + o.totalPrice);

  /// Revenue from orders in the last 30 days
  double get monthlyRevenue {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return _cachedOrders
        .where((o) => o.status != OrderStatus.canceled && o.createdAt.isAfter(cutoff))
        .fold(0.0, (sum, o) => sum + o.totalPrice);
  }

  /// Order counts by status
  Map<OrderStatus, int> get statusCounts {
    final counts = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      counts[status] = _cachedOrders.where((o) => o.status == status).length;
    }
    return counts;
  }

  /// Pending orders count (high priority metric)
  int get pendingCount =>
      _cachedOrders.where((o) => o.status == OrderStatus.pending).length;

  /// Orders today
  int get todayOrdersCount {
    final today = DateTime.now();
    return _cachedOrders.where((o) =>
        o.createdAt.year == today.year &&
        o.createdAt.month == today.month &&
        o.createdAt.day == today.day).length;
  }
}

