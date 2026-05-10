import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_orders_cubit.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  String _searchQuery = '';
  OrderStatus? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminOrdersCubit>().loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = orders;
    if (_statusFilter != null) {
      filtered = filtered.where((o) => o.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((o) {
        return o.id.toString().contains(q) ||
            (o.customerName?.toLowerCase().contains(q) ?? false) ||
            (o.customerEmail?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header with Search & Revenue ─────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Orders Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.primary),
                      onPressed: () =>
                          context.read<AdminOrdersCubit>().loadOrders(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Revenue Summary ─────────────────
                BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                  builder: (context, state) {
                    if (state is! AdminOrdersLoaded) {
                      return const SizedBox.shrink();
                    }
                    final cubit = context.read<AdminOrdersCubit>();
                    return Row(
                      children: [
                        _MiniStat(
                          label: 'Revenue',
                          value: 'EGP ${cubit.totalRevenue.toStringAsFixed(0)}',
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label: 'Pending',
                          value: cubit.pendingCount.toString(),
                          color: const Color(0xFFF39C12),
                        ),
                        const SizedBox(width: 12),
                        _MiniStat(
                          label: 'Today',
                          value: cubit.todayOrdersCount.toString(),
                          color: Colors.blue,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── Search Bar ──────────────────────
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by order ID, customer name or email...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceAlt.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Status Filter Chips ─────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      ...OrderStatus.values.map(
                          (s) => _buildFilterChip(s.label, s)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Orders List ───────────────────────────────
          Expanded(
            child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
              builder: (context, state) {
                if (state is AdminOrdersLoading &&
                    state.previousOrders == null) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (state is AdminOrdersError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.infected),
                        const SizedBox(height: 12),
                        Text(state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<AdminOrdersCubit>().loadOrders(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state is AdminOrdersLoaded) {
                  final filtered = _filterOrders(state.orders);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56,
                              color: AppColors.primary.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          const Text('No matching orders found',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<AdminOrdersCubit>().loadOrders(),
                    color: AppColors.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _AdminOrderCard(
                          order: filtered[index],
                          onStatusChange: (status) {
                            context
                                .read<AdminOrdersCubit>()
                                .updateOrderStatus(filtered[index].id, status);
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status) {
    final isSelected = _statusFilter == status;
    final color = status != null ? _statusColor(status) : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _statusFilter = status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF39C12);
      case OrderStatus.processing:
        return const Color(0xFF3498DB);
      case OrderStatus.shipped:
        return const Color(0xFF9B59B6);
      case OrderStatus.completed:
        return AppColors.healthy;
      case OrderStatus.canceled:
        return AppColors.infected;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI STAT — compact revenue/count indicator
// ═══════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN ORDER CARD — enhanced with search, status update menu
// ═══════════════════════════════════════════════════════════════

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final Function(OrderStatus) onStatusChange;

  const _AdminOrderCard({
    required this.order,
    required this.onStatusChange,
  });

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF39C12);
      case OrderStatus.processing:
        return const Color(0xFF3498DB);
      case OrderStatus.shipped:
        return const Color(0xFF9B59B6);
      case OrderStatus.completed:
        return AppColors.healthy;
      case OrderStatus.canceled:
        return AppColors.infected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final paymentStatus = order.effectivePaymentStatus;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.label,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<OrderStatus>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textMuted, size: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: onStatusChange,
                  itemBuilder: (_) => [
                    if (order.status == OrderStatus.pending) ...[
                      _menuItem(OrderStatus.shipped, 'Mark as Shipped',
                          Icons.local_shipping_rounded),
                      _menuItem(OrderStatus.canceled, 'Cancel Order',
                          Icons.cancel_outlined),
                    ],
                    if (order.status == OrderStatus.shipped)
                      _menuItem(OrderStatus.completed, 'Mark as Completed',
                          Icons.check_circle_outline),
                    if (order.status == OrderStatus.processing) ...[
                      _menuItem(OrderStatus.shipped, 'Mark as Shipped',
                          Icons.local_shipping_rounded),
                      _menuItem(OrderStatus.canceled, 'Cancel Order',
                          Icons.cancel_outlined),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Customer Info ───────────────────
            if (order.customerName != null &&
                order.customerName!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName!,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.customerEmail != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        order.customerEmail!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
            ],

            // ── Items Count & Payment ───────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${order.items.length} items',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: paymentStatus == PaymentStatus.paid
                            ? AppColors.healthy
                            : const Color(0xFFF39C12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentStatus.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: paymentStatus == PaymentStatus.paid
                            ? AppColors.healthy
                            : const Color(0xFFF39C12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      order.formattedDate,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  'EGP ${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<OrderStatus> _menuItem(
      OrderStatus status, String label, IconData icon) {
    return PopupMenuItem(
      value: status,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _statusColor(status)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
