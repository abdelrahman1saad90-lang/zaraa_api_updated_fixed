import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zaraa_flutter/core/theme/app_theme.dart';
import 'app_router.dart';

import 'core/services/api_client.dart';
import 'core/services/auth_service.dart';
import 'core/services/cart_service.dart';
import 'core/services/category_service.dart';
import 'core/services/checkout_service.dart';
import 'core/services/diagnosis_service.dart';
import 'core/services/shop_service.dart';
import 'core/services/weather_service.dart';
import 'core/services/order_service.dart';
import 'core/services/admin/admin_orders_service.dart';
import 'core/services/admin/admin_products_service.dart';
import 'core/services/admin/admin_users_service.dart';

import 'cubits/auth/auth_cubit.dart';
import 'cubits/cart/cart_cubit.dart';
import 'cubits/category/category_cubit.dart';
import 'cubits/diagnosis/diagnosis_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'cubits/weather/weather_cubit.dart';
import 'cubits/orders/orders_cubit.dart';
import 'cubits/orders/user_orders_cubit.dart';
import 'cubits/checkout/checkout_cubit.dart';
import 'cubits/admin/admin_orders_cubit.dart';
import 'cubits/admin/admin_products_cubit.dart';
import 'cubits/admin/admin_users_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();

  // Lock to portrait for a clean mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar: transparent with dark icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ZaraaApp());
}

class ZaraaApp extends StatelessWidget {
  const ZaraaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth cubit — session check is triggered by SplashScreen
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(AuthService()),
        ),
        // Diagnosis cubit — manages the 3-step scan wizard
        BlocProvider<DiagnosisCubit>(
          create: (_) => DiagnosisCubit(DiagnosisService()),
        ),
        // Category cubit — loads categories from API
        BlocProvider<CategoryCubit>(
          create: (_) => CategoryCubit(CategoryService())..loadCategories(),
        ),
        // Weather cubit — fetches live weather on startup
        BlocProvider<WeatherCubit>(
          create: (_) => WeatherCubit(WeatherService())..loadWeather(),
        ),
        // Shop cubit — loads products immediately
        BlocProvider<ShopCubit>(
          create: (_) => ShopCubit(ShopService())..loadProducts(),
        ),
        // Cart cubit — lazy loaded when user opens cart
        BlocProvider<CartCubit>(
          create: (_) => CartCubit(CartService()),
        ),
        // Checkout cubit — manages checkout & payment lifecycle
        BlocProvider<CheckoutCubit>(
          create: (_) => CheckoutCubit(
            checkoutService: CheckoutService(),
            cartService: CartService(),
          ),
        ),
        // Orders cubit — Admin orders
        BlocProvider<OrdersCubit>(
          create: (_) => OrdersCubit(OrderService()),
        ),
        // User orders cubit — customer order history
        BlocProvider<UserOrdersCubit>(
          create: (_) => UserOrdersCubit(CheckoutService()),
        ),
        BlocProvider<AdminOrdersCubit>(
          create: (_) => AdminOrdersCubit(AdminOrdersService()),
        ),
        BlocProvider<AdminProductsCubit>(
          create: (_) => AdminProductsCubit(AdminProductsService()),
        ),
        BlocProvider<AdminUsersCubit>(
          create: (_) => AdminUsersCubit(AdminUsersService()),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zaraa',
        theme: AppTheme.theme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
