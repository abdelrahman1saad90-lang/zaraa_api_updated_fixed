import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/models/models.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/auth/auth_state.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/landing/landing_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/orders_management_screen.dart';
import 'screens/admin/products_management_screen.dart';
import 'screens/admin/product_form_screen.dart';
import 'screens/admin/categories_management_screen.dart';
import 'screens/admin/category_form_screen.dart';
import 'screens/admin/users_management_screen.dart';
import 'screens/admin/inventory_management_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/diagnosis/diagnosis_screen.dart';
import 'screens/diagnosis/diagnosis_result_screen.dart';
import 'screens/my_garden/my_garden_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/orders/orders_list_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';

/// Smooth fade transition for all admin routes
CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    // ── Always start on the splash screen ──────────────────────
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,

    // ── Auth guard ──────────────────────────────────────────────
    // - AuthInitial  → always show splash (session not checked yet)
    // - Unauthenticated on protected route → go to landing
    // - Authenticated on public route (not splash) → go to dashboard
    redirect: (context, state) {
      final authState = context.read<AuthCubit>().state;
      final path = state.matchedLocation;

      // Session not yet checked → always show splash first
      if (authState is AuthInitial) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final publicRoutes = {
        AppRoutes.splash,
        AppRoutes.landing,
        AppRoutes.login,
        AppRoutes.register,
      };
      final isPublic = publicRoutes.contains(path);

      // Unauthenticated user on a protected route → send to landing
      if ((authState is AuthUnauthenticated || authState is AuthError) &&
          !isPublic) {
        return AppRoutes.landing;
      }

      // Authenticated user on a public route (except splash) → send to dashboard or admin
      if (authState is AuthAuthenticated &&
          isPublic &&
          path != AppRoutes.splash) {
        if (authState.user.roles.contains('Admin') || authState.user.roles.contains('SuperAdmin')) {
          return AppRoutes.adminDashboard;
        }
        return AppRoutes.dashboard;
      }

      // If user goes to /admin directly, redirect to /admin/dashboard
      if (path == AppRoutes.adminMain) {
        return AppRoutes.adminDashboard;
      }

      // ── Security: Non-admin cannot access /admin/* routes ───────
      if (path.startsWith('/admin')) {
        if (authState is AuthAuthenticated) {
          final isAdmin = authState.user.roles.contains('Admin') ||
              authState.user.roles.contains('SuperAdmin');
          if (!isAdmin) return AppRoutes.dashboard;
        } else {
          return AppRoutes.landing;
        }
      }

      return null; // No redirect
    },

    routes: [
      // ── Public routes ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Authenticated shell (bottom nav) ─────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.diagnosis,
            builder: (_, __) => const DiagnosisScreen(),
          ),
          GoRoute(
            path: AppRoutes.myGarden,
            builder: (_, __) => const MyGardenScreen(),
          ),
          GoRoute(
            path: AppRoutes.shop,
            builder: (_, __) => const ShopScreen(),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, __) => const HistoryScreen(),
          ),
        ],
      ),

      // ── Full-screen routes (no bottom nav) ───────────────────
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.diagnosisResult,
        builder: (context, state) {
          final diagnosis = state.extra as DiagnosisModel;
          return DiagnosisResultScreen(diagnosis: diagnosis);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.orders,
        builder: (context, state) => const OrdersListScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderDetailScreen(initialOrder: order);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),

      // ── Admin shell (sidebar nav) ─────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminMainScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (_, state) => _fadePage(const AdminDashboardScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.adminOrders,
            pageBuilder: (_, state) => _fadePage(const OrdersManagementScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.adminProducts,
            pageBuilder: (_, state) => _fadePage(const ProductsManagementScreen(), state),
          ),
          GoRoute(
            path: '${AppRoutes.adminProducts}/create',
            builder: (_, __) => const ProductFormScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminProducts}/edit',
            builder: (context, state) {
              final product = state.extra as ProductModel;
              return ProductFormScreen(existingProduct: product);
            },
          ),
          GoRoute(
            path: AppRoutes.adminCategories,
            pageBuilder: (_, state) => _fadePage(const CategoriesManagementScreen(), state),
          ),
          GoRoute(
            path: '${AppRoutes.adminCategories}/create',
            builder: (_, __) => const CategoryFormScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.adminCategories}/edit',
            builder: (context, state) {
              final category = state.extra as CategoryModel;
              return CategoryFormScreen(existingCategory: category);
            },
          ),
          GoRoute(
            path: AppRoutes.adminUsers,
            pageBuilder: (_, state) => _fadePage(const UsersManagementScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.adminInventory,
            pageBuilder: (_, state) => _fadePage(const InventoryManagementScreen(), state),
          ),
        ],
      ),
    ],
  );
}
