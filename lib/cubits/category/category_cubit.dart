import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/category_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class CategoryState extends Equatable {
  const CategoryState();
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  const CategoryLoaded(this.categories);

  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  const CategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryActionSuccess extends CategoryState {
  final String message;
  const CategoryActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT
// ══════════════════════════════════════════════════════════════

/// Manages category CRUD operations via Admin API.
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryService _service;

  CategoryCubit(this._service) : super(const CategoryInitial());

  /// Cached categories for access from other cubits/screens.
  List<CategoryModel> _cachedCategories = [];
  List<CategoryModel> get categories => _cachedCategories;

  /// Fetch all categories from the API.
  Future<void> loadCategories() async {
    emit(const CategoryLoading());

    final res = await _service.getCategories();

    if (res.isSuccess) {
      _cachedCategories = res.data!;
      emit(CategoryLoaded(res.data!));
    } else {
      emit(CategoryError(res.error ?? 'Failed to load categories'));
    }
  }

  /// Create a new category.
  Future<void> createCategory({
    required String name,
    String? description,
    bool status = true,
  }) async {
    emit(const CategoryLoading());

    final res = await _service.createCategory(
      name: name,
      description: description,
      status: status,
    );

    if (res.isSuccess) {
      emit(const CategoryActionSuccess('Category created successfully'));
      await loadCategories(); // Refresh the list
    } else {
      emit(CategoryError(res.error ?? 'Failed to create category'));
    }
  }

  /// Edit an existing category.
  Future<void> editCategory({
    required int id,
    required String name,
    String? description,
    bool status = true,
  }) async {
    emit(const CategoryLoading());

    final res = await _service.editCategory(
      id: id,
      name: name,
      description: description,
      status: status,
    );

    if (res.isSuccess) {
      emit(const CategoryActionSuccess('Category updated successfully'));
      await loadCategories(); // Refresh the list
    } else {
      emit(CategoryError(res.error ?? 'Failed to update category'));
    }
  }

  /// Delete a category by ID.
  Future<void> deleteCategory(int id) async {
    emit(const CategoryLoading());

    final res = await _service.deleteCategory(id);

    if (res.isSuccess) {
      emit(const CategoryActionSuccess('Category deleted successfully'));
      await loadCategories(); // Refresh the list
    } else {
      emit(CategoryError(res.error ?? 'Failed to delete category'));
    }
  }
}
