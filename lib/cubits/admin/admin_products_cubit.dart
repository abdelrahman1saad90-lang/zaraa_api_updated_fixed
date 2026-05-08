import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/models/admin/product_request_model.dart';
import '../../core/services/admin/admin_products_service.dart';

// ── States ────────────────────────────────────────────────────────
abstract class AdminProductsState extends Equatable {
  const AdminProductsState();
  @override
  List<Object?> get props => [];
}

class AdminProductsInitial extends AdminProductsState {
  const AdminProductsInitial();
}

class AdminProductsLoading extends AdminProductsState {
  final List<ProductModel>? previousProducts;
  const AdminProductsLoading({this.previousProducts});
  @override
  List<Object?> get props => [previousProducts];
}

class AdminProductsLoaded extends AdminProductsState {
  final List<ProductModel> products;
  const AdminProductsLoaded(this.products);
  @override
  List<Object?> get props => [products];
}

class AdminProductsError extends AdminProductsState {
  final String message;
  const AdminProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

class AdminProductOperationSuccess extends AdminProductsState {
  final String message;
  const AdminProductOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ────────────────────────────────────────────────────────
class AdminProductsCubit extends Cubit<AdminProductsState> {
  final AdminProductsService _service;

  AdminProductsCubit(this._service) : super(const AdminProductsInitial());

  Future<void> loadProducts() async {
    final currentProducts =
        state is AdminProductsLoaded ? (state as AdminProductsLoaded).products : null;
    emit(AdminProductsLoading(previousProducts: currentProducts));

    final res = await _service.getAllProducts();
    if (res.isSuccess) {
      emit(AdminProductsLoaded(res.data!));
    } else {
      emit(AdminProductsError(res.error!));
    }
  }

  /// Creates a new product and refreshes the list. Returns true on success.
  Future<bool> createProduct(ProductRequestModel data) async {
    final res = await _service.createProduct(data);
    if (res.isSuccess) {
      emit(AdminProductOperationSuccess(res.data!));
      await loadProducts();
      return true;
    } else {
      emit(AdminProductsError(res.error!));
      return false;
    }
  }

  /// Updates an existing product and refreshes the list. Returns true on success.
  Future<bool> updateProduct(int id, ProductRequestModel data) async {
    final res = await _service.updateProduct(id, data);
    if (res.isSuccess) {
      emit(AdminProductOperationSuccess(res.data!));
      await loadProducts();
      return true;
    } else {
      emit(AdminProductsError(res.error!));
      return false;
    }
  }

  Future<void> deleteProduct(int id) async {
    final res = await _service.deleteProduct(id);
    if (res.isSuccess) {
      emit(AdminProductOperationSuccess(res.data!));
      await loadProducts();
    } else {
      emit(AdminProductsError(res.error!));
    }
  }

  /// Updates the quantity of a product by sending a full update.
  /// Used by InventoryManagementScreen for quick stock adjustments.
  Future<bool> updateProductQuantity(ProductModel product, int newQuantity) async {
    final data = ProductRequestModel(
      name: product.name,
      description: product.description,
      status: !product.isSoldOut,
      price: product.price,
      quantity: newQuantity.clamp(0, 99999),
      discount: product.discount,
      categoryId: product.categoryId ?? 1,
      brandId: 1,
    );
    return updateProduct(int.parse(product.id), data);
  }
}
