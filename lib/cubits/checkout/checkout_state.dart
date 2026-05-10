import 'package:equatable/equatable.dart';

import '../../core/models/models.dart';

// ══════════════════════════════════════════════════════════════
// CHECKOUT STATES — full payment lifecycle state machine
// ══════════════════════════════════════════════════════════════

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

/// Initial idle state — no checkout in progress
class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

/// Cart data loaded, ready for checkout form
class CheckoutReady extends CheckoutState {
  final CartModel cart;
  final ShippingDetailsModel? lastShipping;
  const CheckoutReady({required this.cart, this.lastShipping});

  @override
  List<Object?> get props => [cart, lastShipping];
}

/// Creating Stripe checkout session on backend
class CheckoutProcessing extends CheckoutState {
  final String message;
  const CheckoutProcessing({this.message = 'Creating payment session...'});

  @override
  List<Object?> get props => [message];
}

/// Stripe session created — URL ready to launch
class CheckoutPaymentReady extends CheckoutState {
  final String paymentUrl;
  final CheckoutSessionResult session;
  const CheckoutPaymentReady({
    required this.paymentUrl,
    required this.session,
  });

  @override
  List<Object?> get props => [paymentUrl];
}

/// Stripe URL launched in browser — waiting for return
class CheckoutLaunchingStripe extends CheckoutState {
  const CheckoutLaunchingStripe();
}

/// Returned from Stripe — verifying payment status
class CheckoutVerifying extends CheckoutState {
  final String message;
  final int attempt;
  const CheckoutVerifying({
    this.message = 'Verifying your payment...',
    this.attempt = 1,
  });

  @override
  List<Object?> get props => [message, attempt];
}

/// Payment verified successfully
class CheckoutSuccess extends CheckoutState {
  final OrderModel order;
  final ShippingDetailsModel? shipping;
  const CheckoutSuccess({required this.order, this.shipping});

  @override
  List<Object?> get props => [order];
}

/// Payment failed
class CheckoutFailed extends CheckoutState {
  final String message;
  final bool canRetry;
  const CheckoutFailed({required this.message, this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

/// Payment cancelled by user
class CheckoutCanceled extends CheckoutState {
  final String message;
  const CheckoutCanceled({this.message = 'Payment was cancelled.'});

  @override
  List<Object?> get props => [message];
}

/// Verification timed out — order may still be processing
class CheckoutTimeout extends CheckoutState {
  final String message;
  const CheckoutTimeout({
    this.message = 'Payment verification timed out. Check your orders for status.',
  });

  @override
  List<Object?> get props => [message];
}

/// General error
class CheckoutError extends CheckoutState {
  final String message;
  final bool canRetry;
  const CheckoutError({required this.message, this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}
