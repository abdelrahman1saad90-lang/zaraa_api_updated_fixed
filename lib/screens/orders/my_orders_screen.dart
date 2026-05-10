import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/orders/user_orders_cubit.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  OrderStatus? _selectedFilter;

  @override
  void initState() {
    super.initState();
    context.read<UserOrdersCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          AppStrings.myOrders,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textPrimary),
            onPressed: () => context.read<UserOrdersCubit>().loadOrders(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                ...OrderStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: status.label,
                        isSelected: _selectedFilter == status,
                        onTap: () =>
                            setState(() => _selectedFilter = status),
                        color: _getStatusColor(status),
                      ),
                    )),
              ],
            ),
          ),

          // ── Orders List ─────────────────────────────
          Expanded(
            child: BlocBuilder<UserOrdersCubit, UserOrdersState>(
              builder: (context, state) {
                if (state is UserOrdersLoading &&
                    state.previousOrders == null) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                if (state is UserOrdersError) {
                  return _buildErrorState(state.message);
                }

                final cubit = context.read<UserOrdersCubit>();
                var orders = cubit.orders;

                if (_selectedFilter != null) {
                  orders = orders
                      .where((o) => o.status == _selectedFilter)
                      .toList();
                }

                if (orders.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => cubit.loadOrders(),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _OrderCard(
                        order: orders[index],
                        onTap: () {
                          context.push(
                            AppRoutes.myOrderDetail,
                            extra: orders[index],
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 56, color: AppColors.primary.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedFilter == null
                ? AppStrings.noOrdersYet
                : 'No ${_selectedFilter!.label.toLowerCase()} orders',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your orders will appear here once you make a purchase.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.shop),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text(AppStrings.startShopping,
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppColors.infected),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<UserOrdersCubit>().loadOrders(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
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
// FILTER CHIP
// ═══════════════════════════════════════════════════════════════

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.surfaceBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORDER CARD
// ═══════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  Color _getStatusColor(OrderStatus status) {
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

  Color _getPaymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.healthy;
      case PaymentStatus.pending:
        return const Color(0xFFF39C12);
      case PaymentStatus.failed:
        return AppColors.infected;
      case PaymentStatus.refunded:
        return const Color(0xFF3498DB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final paymentStatus = order.effectivePaymentStatus;
    final paymentColor = _getPaymentColor(paymentStatus);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Items Preview ───────────────────
              if (order.items.isNotEmpty)
                Text(
                  order.items
                      .take(2)
                      .map((i) => '${i.productName} (×${i.quantity})')
                      .join(', ') +
                      (order.items.length > 2
                          ? ' +${order.items.length - 2} more'
                          : ''),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // ── Footer ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: paymentColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        paymentStatus.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: paymentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        order.formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'EGP ${order.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
