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
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/diagnosis/diagnosis_screen.dart';
import 'screens/diagnosis/diagnosis_result_screen.dart';
import 'screens/my_garden/my_garden_screen.dart';
import 'screens/shop/shop_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/orders/orders_list_screen.dart';
import 'screens/orders/order_detail_screen.dart';
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

      // Authenticated user on a public route (except splash) → send to dashboard
      if (authState is AuthAuthenticated &&
          isPublic &&
          path != AppRoutes.splash) {
        return AppRoutes.dashboard;
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
    ],
  );
}
