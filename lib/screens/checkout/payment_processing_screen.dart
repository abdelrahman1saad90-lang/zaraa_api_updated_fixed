import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../cubits/cart/cart_cubit.dart';
import '../../cubits/checkout/checkout_cubit.dart';

/// Shown when user returns from Stripe browser.
/// Automatically verifies payment and navigates to success/cancel/fail.
class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});

  @override
  State<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Start payment verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutCubit>().verifyPayment();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleState(BuildContext context, CheckoutState state) {
    if (state is CheckoutSuccess) {
      context.read<CartCubit>().clearCart();
      context.go(AppRoutes.paymentSuccess, extra: state.order);
    } else if (state is CheckoutCanceled) {
      context.go(AppRoutes.paymentCancel);
    } else if (state is CheckoutFailed) {
      context.go(AppRoutes.paymentFailed);
    } else if (state is CheckoutTimeout) {
      // Timeout — show message and let user navigate
      _showTimeoutDialog();
    }
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verification Timed Out'),
        content: const Text(
          'We couldn\'t confirm your payment yet. It may still be processing.\n\n'
          'Please check "My Orders" to see your order status.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.myOrders);
            },
            child: const Text('View My Orders',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.dashboard);
            },
            child: const Text('Go to Dashboard',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: _handleState,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F7F4),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated Pulse Icon ────────────────
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, child) {
                      final scale = 1.0 + (_pulseController.value * 0.1);
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Title ─────────────────────────────
                  const Text(
                    AppStrings.verifyingPayment,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // ── Status ────────────────────────────
                  BlocBuilder<CheckoutCubit, CheckoutState>(
                    builder: (context, state) {
                      String message = 'Checking payment status...';
                      if (state is CheckoutVerifying) {
                        message = state.message;
                      }
                      return Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Progress ──────────────────────────
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Skip Button ───────────────────────
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.myOrders),
                    icon: const Icon(Icons.skip_next_rounded,
                        size: 20, color: AppColors.textMuted),
                    label: const Text(
                      'Skip — check orders later',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
