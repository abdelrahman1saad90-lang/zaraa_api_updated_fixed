import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/models.dart';
import '../../core/services/cart_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLoading extends CartState {
  final CartModel? previousCart;
  const CartLoading({this.previousCart});

  @override
  List<Object?> get props => [previousCart];
}

class CartLoaded extends CartState {
  final CartModel cart;
  const CartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

class CartError extends CartState {
  final String message;
  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT — Cart management (no payment logic — see CheckoutCubit)
// ══════════════════════════════════════════════════════════════

class CartCubit extends Cubit<CartState> {
  final CartService _service;

  CartCubit(this._service) : super(const CartInitial());

  // ── Load Cart ─────────────────────────────────────────────
  Future<void> loadCart() async {
    final currentCart = state is CartLoaded ? (state as CartLoaded).cart : null;
    emit(CartLoading(previousCart: currentCart));
    
    final res = await _service.getCart();
    if (res.isSuccess) {
      emit(CartLoaded(res.data!));
    } else {
      emit(CartError(res.error!));
    }
  }

  // ── Add To Cart ───────────────────────────────────────────
  Future<void> addToCart(int productId, {int count = 1}) async {
    final res = await _service.addToCart(
      productId: productId,
      count: count,
    );
    if (res.isSuccess) {
      await loadCart();
    } else {
      emit(CartError(res.error!));
    }
  }

  // ── Increment ─────────────────────────────────────────────
  Future<void> increment(int productId) async {
    final res = await _service.incrementCount(productId);
    if (res.isSuccess) {
      await loadCart();
    } else {
      emit(CartError(res.error!));
    }
  }

  // ── Decrement ─────────────────────────────────────────────
  Future<void> decrement(int productId) async {
    final res = await _service.decrementCount(productId);
    if (res.isSuccess) {
      await loadCart();
    } else {
      emit(CartError(res.error!));
    }
  }

  // ── Remove Item ───────────────────────────────────────────
  Future<void> removeItem(int productId) async {
    final res = await _service.removeFromCart(productId);
    if (res.isSuccess) {
      await loadCart();
    } else {
      emit(CartError(res.error!));
    }
  }

  // ── Clear Cart (post-payment) ─────────────────────────────
  /// Reloads cart — after successful payment, backend should have
  /// already cleared it. This just refreshes local state.
  Future<void> clearCart() async {
    await loadCart();
  }

  /// Access current cart total (convenience getter)
  double get currentTotal {
    if (state is CartLoaded) {
      return (state as CartLoaded).cart.totalPrice;
    }
    return 0;
  }
}

