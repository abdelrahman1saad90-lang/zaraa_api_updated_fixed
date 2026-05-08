import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';

class AdminMainScreen extends StatefulWidget {
  final Widget child;
  const AdminMainScreen({super.key, required this.child});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onNavigate(String route) {
    if (Scaffold.of(context).hasDrawer && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Close drawer
    }
    context.go(route);
  }

  void _logout() {
    context.read<AuthCubit>().logout().then((_) {
      context.go(AppRoutes.landing);
    });
  }

  Widget _buildSidebar() {
    final location = GoRouterState.of(context).matchedLocation;
    
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            color: AppColors.primary,
            width: double.infinity,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zaraa Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Management Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == AppRoutes.adminDashboard,
                  onTap: () => _onNavigate(AppRoutes.adminDashboard),
                ),
                _SidebarItem(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Orders',
                  isSelected: location == AppRoutes.adminOrders,
                  onTap: () => _onNavigate(AppRoutes.adminOrders),
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  isSelected: location == AppRoutes.adminProducts,
                  onTap: () => _onNavigate(AppRoutes.adminProducts),
                ),
                _SidebarItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == AppRoutes.adminCategories,
                  onTap: () => _onNavigate(AppRoutes.adminCategories),
                ),
                _SidebarItem(
                  icon: Icons.people_rounded,
                  label: 'Users',
                  isSelected: location == AppRoutes.adminUsers,
                  onTap: () => _onNavigate(AppRoutes.adminUsers),
                ),
                _SidebarItem(
                  icon: Icons.inventory_rounded,
                  label: 'Inventory',
                  isSelected: location == AppRoutes.adminInventory,
                  onTap: () => _onNavigate(AppRoutes.adminInventory),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.infected),
            title: const Text(
              'Logout',
              style: TextStyle(color: AppColors.infected, fontWeight: FontWeight.bold),
            ),
            onTap: _logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Admin Panel'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            Material(
              elevation: 4,
              child: _buildSidebar(),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
