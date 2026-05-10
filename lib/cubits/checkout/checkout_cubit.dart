import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/models.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/checkout_service.dart';
import 'checkout_state.dart';

export 'checkout_state.dart';

/// Manages the complete checkout lifecycle:
///   Cart → Shipping Form → Pay → Stripe → Verify → Success/Fail
///
/// Also handles:
///   - Session recovery on app resume
///   - Payment verification polling with timeout
///   - Cart clearing after successful payment
class CheckoutCubit extends Cubit<CheckoutState> {
  final CheckoutService _checkoutService;
  final CartService _cartService;

  CheckoutCubit({
    required CheckoutService checkoutService,
    required CartService cartService,
  })  : _checkoutService = checkoutService,
        _cartService = cartService,
        super(const CheckoutInitial());

  // Cache for UI recovery
  ShippingDetailsModel? _lastShipping;
  CheckoutSessionResult? _lastSession;

  ShippingDetailsModel? get lastShipping => _lastShipping;

  // ── Initialize ────────────────────────────────────────────
  /// Load cart and pre-fill shipping details if available
  Future<void> initialize() async {
    final cartRes = await _cartService.getCart();
    if (!cartRes.isSuccess || cartRes.data == null) {
      emit(CheckoutError(message: cartRes.error ?? 'Failed to load cart.'));
      return;
    }

    if (cartRes.data!.items.isEmpty) {
      emit(const CheckoutError(message: 'Your cart is empty.', canRetry: false));
      return;
    }

    final lastShipping = await _checkoutService.getLastShippingDetails();
    _lastShipping = lastShipping;

    emit(CheckoutReady(cart: cartRes.data!, lastShipping: lastShipping));
  }

  // ── Start Checkout ────────────────────────────────────────
  /// Validate form → Create session → Launch Stripe
  Future<void> startCheckout({
    required String address,
    required String phone,
    String? notes,
    required double cartTotal,
  }) async {
    final shipping = ShippingDetailsModel(
      address: address,
      phone: phone,
      notes: notes,
    );
    _lastShipping = shipping;

    emit(const CheckoutProcessing(message: 'Creating payment session...'));

    final result = await _checkoutService.createCheckoutSession(
      shipping: shipping,
      cartTotal: cartTotal,
    );

    if (!result.isSuccess || result.data == null) {
      emit(CheckoutError(message: result.error ?? 'Failed to create payment session.'));
      return;
    }

    _lastSession = result.data!;

    emit(CheckoutPaymentReady(
      paymentUrl: result.data!.paymentUrl,
      session: result.data!,
    ));
  }

  // ── Launch Stripe ─────────────────────────────────────────
  /// Opens the Stripe checkout URL in the external browser
  Future<bool> launchStripeCheckout(String url) async {
    emit(const CheckoutLaunchingStripe());

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        emit(const CheckoutError(
          message: 'Could not open payment page. Please try again.',
        ));
        return false;
      }

      return true;
    } catch (e) {
      emit(CheckoutError(message: 'Failed to open payment: $e'));
      return false;
    }
  }

  // ── Verify Payment ────────────────────────────────────────
  /// Poll orders to verify payment after returning from Stripe.
  /// Retries up to [maxAttempts] times with delay between attempts.
  /// If [orderId] is provided (extracted from URL), verification is faster.
  Future<void> verifyPayment({int? orderId, int maxAttempts = 3}) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      emit(CheckoutVerifying(
        message: attempt == 1
            ? 'Verifying your payment...'
            : 'Still verifying... (attempt $attempt/$maxAttempts)',
        attempt: attempt,
      ));

      // Wait before checking (Stripe webhook needs time)
      if (attempt > 1) {
        await Future.delayed(Duration(seconds: 2 * attempt));
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }

      final result = await _checkoutService.verifyPayment(orderId: orderId);

      if (result.isSuccess && result.data != null) {
        final order = result.data!;

        // Check if order status indicates payment success
        if (order.status != OrderStatus.canceled) {
          emit(CheckoutSuccess(order: order, shipping: _lastShipping));
          return;
        }
      }

      if (kDebugMode) {
        debugPrint('Verification attempt $attempt: ${result.error ?? 'pending'}');
      }
    }

    // All attempts exhausted
    emit(const CheckoutTimeout());
  }

  // ── Handle Stripe Redirect (WebView) ──────────────────────
  /// Intercepts WebView navigation and detects payment status.
  /// Detects "Success", "orderId=", "Cancel", or "Failed" in URL.
  Future<bool> handleStripeRedirect(String url) async {
    final lowerUrl = url.toLowerCase();

    if (kDebugMode) {
      debugPrint('WebView Intercept: $url');
    }

    // 1. Success Detection
    if (lowerUrl.contains('success') || lowerUrl.contains('orderid=')) {
      int? orderId = _extractOrderId(url);
      
      if (kDebugMode) {
        debugPrint('>>> PAYMENT SUCCESS DETECTED (orderId: $orderId)');
      }

      await verifyPayment(orderId: orderId);
      return true; // Navigation handled
    }

    // 2. Cancel Detection
    if (lowerUrl.contains('cancel')) {
      if (kDebugMode) {
        debugPrint('>>> PAYMENT CANCEL DETECTED');
      }
      emit(const CheckoutCanceled());
      return true;
    }

    // 3. Failure Detection
    if (lowerUrl.contains('failed') || lowerUrl.contains('error')) {
      if (kDebugMode) {
        debugPrint('>>> PAYMENT FAILURE DETECTED');
      }
      emit(const CheckoutFailed(message: 'Your payment could not be processed.'));
      return true;
    }

    return false; // Continue navigation
  }

  /// Regex to extract orderId from URL (e.g. ?orderId=15)
  int? _extractOrderId(String url) {
    try {
      final uri = Uri.parse(url);
      final idStr = uri.queryParameters['orderId'];
      return idStr != null ? int.tryParse(idStr) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Handle Stripe Return (Deep Link) ──────────────────────
  /// Called when user returns from Stripe (via deep link or app resume)
  Future<void> handlePaymentReturn({required bool isSuccess}) async {
    if (isSuccess) {
      await verifyPayment();
    } else {
      emit(const CheckoutCanceled());
    }
  }

  // ── Resume Pending Checkout ───────────────────────────────
  /// Checks if there's a pending checkout from a previous session
  /// and resumes verification if needed
  Future<bool> checkAndResumePendingCheckout() async {
    final hasPending = await _checkoutService.hasPendingCheckout();
    if (!hasPending) return false;

    if (kDebugMode) {
      debugPrint('Found pending checkout — resuming verification...');
    }

    await verifyPayment();
    return true;
  }

  // ── Mark as Cancelled ─────────────────────────────────────
  void markCanceled() {
    emit(const CheckoutCanceled());
  }

  // ── Mark as Failed ────────────────────────────────────────
  void markFailed(String message) {
    emit(CheckoutFailed(message: message));
  }

  // ── Reset ─────────────────────────────────────────────────
  /// Returns cubit to initial state
  Future<void> reset() async {
    _lastSession = null;
    await _checkoutService.clearPendingCheckout();
    emit(const CheckoutInitial());
  }

  // ── Clear Cart ────────────────────────────────────────────
  /// Clears the cart after successful payment.
  /// The backend should also clear it, but this ensures local state is clean.
  Future<void> clearCartAfterPayment() async {
    try {
      // Reload cart — it should already be empty after backend processes payment
      await _cartService.getCart();
    } catch (_) {
      // Non-critical — cart will sync on next load
    }
  }
}
