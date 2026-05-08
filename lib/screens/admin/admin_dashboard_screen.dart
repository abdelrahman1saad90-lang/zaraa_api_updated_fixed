import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
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
      body: SingleChildScrollView(
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
            
            // Overview Cards
            LayoutBuilder(
              builder: (context, constraints) {
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
                        String value = '...';
                        if (state is AdminOrdersLoaded) {
                          final total = state.orders.fold<double>(0, (sum, item) => sum + item.totalPrice);
                          value = 'EGP ${total.toStringAsFixed(0)}';
                        }
                        return _StatCard(title: 'Total Sales', value: value, icon: Icons.attach_money, color: Colors.green);
                      },
                    ),
                    BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                      builder: (context, state) {
                        String value = '...';
                        if (state is AdminOrdersLoaded) value = state.orders.length.toString();
                        return _StatCard(title: 'Total Orders', value: value, icon: Icons.shopping_bag_rounded, color: Colors.blue);
                      },
                    ),
                    BlocBuilder<AdminProductsCubit, AdminProductsState>(
                      builder: (context, state) {
                        String value = '...';
                        if (state is AdminProductsLoaded) value = state.products.length.toString();
                        return _StatCard(title: 'Products', value: value, icon: Icons.inventory_2_rounded, color: Colors.orange);
                      },
                    ),
                    BlocBuilder<AdminUsersCubit, AdminUsersState>(
                      builder: (context, state) {
                        String value = '...';
                        if (state is AdminUsersLoaded) value = state.users.length.toString();
                        return _StatCard(title: 'Users', value: value, icon: Icons.people_rounded, color: Colors.purple);
                      },
                    ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Placeholder for charts or recent orders list
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Activity charts will be displayed here.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
