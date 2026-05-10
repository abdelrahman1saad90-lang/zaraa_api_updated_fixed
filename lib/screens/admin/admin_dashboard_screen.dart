import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_orders_cubit.dart';
import '../../cubits/admin/admin_products_cubit.dart';
import '../../cubits/admin/admin_users_cubit.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminOrdersCubit>().loadOrders();
    context.read<AdminProductsCubit>().loadProducts();
    context.read<AdminUsersCubit>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminOrdersCubit>().loadOrders();
          context.read<AdminProductsCubit>().loadProducts();
          context.read<AdminUsersCubit>().loadUsers();
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Overview Cards ────────────────────────
              LayoutBuilder(builder: (context, constraints) {
                int crossAxisCount = 2;
                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth > 800) {
                  crossAxisCount = 3;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                      builder: (context, state) {
                        final cubit = context.read<AdminOrdersCubit>();
                        String value = '...';
                        if (state is AdminOrdersLoaded) {
                          value = 'EGP ${cubit.totalRevenue.toStringAsFixed(0)}';
                        }
                        return _StatCard(
                          title: 'Total Revenue',
                          value: value,
                          icon: Icons.attach_money,
                          color: Colors.green,
                        );
                      },
                    ),
                    BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                      builder: (context, state) {
                        final cubit = context.read<AdminOrdersCubit>();
                        String value = '...';
                        if (state is AdminOrdersLoaded) {
                          value = state.orders.length.toString();
                        }
                        return _StatCard(
                          title: 'Total Orders',
                          value: value,
                          icon: Icons.shopping_bag_rounded,
                          color: Colors.blue,
                          subtitle: state is AdminOrdersLoaded
                              ? '${cubit.pendingCount} pending'
                              : null,
                        );
                      },
                    ),
                    BlocBuilder<AdminProductsCubit, AdminProductsState>(
                      builder: (context, state) {
                        String value = '...';
                        if (state is AdminProductsLoaded) {
                          value = state.products.length.toString();
                        }
                        return _StatCard(
                          title: 'Products',
                          value: value,
                          icon: Icons.inventory_2_rounded,
                          color: Colors.orange,
                        );
                      },
                    ),
                    BlocBuilder<AdminUsersCubit, AdminUsersState>(
                      builder: (context, state) {
                        String value = '...';
                        if (state is AdminUsersLoaded) {
                          value = state.users.length.toString();
                        }
                        return _StatCard(
                          title: 'Users',
                          value: value,
                          icon: Icons.people_rounded,
                          color: Colors.purple,
                        );
                      },
                    ),
                  ],
                );
              }),

              const SizedBox(height: 32),

              // ── Order Status Distribution ─────────────
              BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                builder: (context, state) {
                  if (state is! AdminOrdersLoaded) {
                    return const SizedBox.shrink();
                  }
                  final cubit = context.read<AdminOrdersCubit>();
                  final counts = cubit.statusCounts;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Status Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: OrderStatus.values.map((status) {
                            return _StatusCount(
                              label: status.label,
                              count: counts[status] ?? 0,
                              color: _statusColor(status),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Recent Orders ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Orders',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.adminOrders),
                    child: const Text('View All',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                builder: (context, state) {
                  if (state is AdminOrdersLoaded) {
                    final recent = state.orders.take(5).toList();
                    if (recent.isEmpty) {
                      return _buildPlaceholder('No orders yet.');
                    }
                    return Container(
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recent.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.surfaceBorder),
                        itemBuilder: (context, index) {
                          final order = recent[index];
                          return _RecentOrderTile(order: order);
                        },
                      ),
                    );
                  }
                  return _buildPlaceholder('Loading orders...');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
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
// STAT CARD — enhanced with optional subtitle
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATUS COUNT — circular badge for order status overview
// ═══════════════════════════════════════════════════════════════

class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RECENT ORDER TILE
// ═══════════════════════════════════════════════════════════════

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile({required this.order});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF39C12);
      case OrderStatus.processing:
        return const Color(0xFF3498DB);
      case OrderStatus.shipped:
        return const Color(0xFF9B59B6);
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '#${order.id}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      title: Text(
        order.customerName ?? 'Customer',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        order.formattedDate,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'EGP ${order.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              order.status.label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
