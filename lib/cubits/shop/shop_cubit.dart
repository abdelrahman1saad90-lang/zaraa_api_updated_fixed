import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/shop_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopLoaded extends ShopState {
  final List<ProductModel> products;
  final String selectedCategory;

  const ShopLoaded(this.products, this.selectedCategory);

  @override
  List<Object?> get props => [products, selectedCategory];
}

class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT
// ══════════════════════════════════════════════════════════════

/// Manages the product shop — loading and filtering by category.
/// Mirrors Angular's ShopComponent + product filtering logic.
class ShopCubit extends Cubit<ShopState> {
  final ShopService _service;

  ShopCubit(this._service) : super(const ShopInitial());

  Future<void> loadProducts({String category = 'All Categories'}) async {
    emit(const ShopLoading());

    final res = await _service.getProducts(
      category: category == 'All Categories' ? null : category,
    );

    if (res.isSuccess) {
      emit(ShopLoaded(res.data!, category));
    } else {
      emit(ShopError(res.error ?? 'Failed to load products'));
    }
  }

  /// Filter products by category name without re-fetching from API
  Future<void> filterByCategory(String category) async {
    await loadProducts(category: category);
  }
}
