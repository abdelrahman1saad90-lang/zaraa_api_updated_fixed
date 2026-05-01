import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/shop/shop_cubit.dart';
import '../../cubits/cart/cart_cubit.dart';

// ══════════════════════════════════════════════════════════════
// SHOP SCREEN — Organic Market redesign
// ══════════════════════════════════════════════════════════════

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // ── Controllers ─────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController(text: '0');
  final TextEditingController _maxPriceController = TextEditingController(text: '10000');

  // ── Filter state ─────────────────────────────────────────────
  CategoryModel? _selectedCategory; // null = All Categories

  @override
  void initState() {
    super.initState();
    // Refresh shop data & sync cart on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryCubit>().loadCategories();
        context.read<ShopCubit>().loadProducts();
        context.read<CartCubit>().loadCart();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  // ── Apply all active filters to ShopCubit ───────────────────
  void _applyFilters() {
    FocusScope.of(context).unfocus();
    context.read<ShopCubit>().loadProducts(
          category: _selectedCategory?.name,
          categoryId: _selectedCategory?.id,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          minPrice: double.tryParse(_minPriceController.text),
          maxPrice: double.tryParse(_maxPriceController.text),
        );
  }

  // ── Increment cart quantity ──────────────────────────────────
  void _increment(ProductModel product) {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId == 0) return;

    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;
    
    int currentQty = 0;
    if (cartState is CartLoaded) {
      final item = cartState.cart.items.where((i) => i.productId == productId).firstOrNull;
      currentQty = item?.count ?? 0;
    }

    if (currentQty == 0) {
      cartCubit.addToCart(productId);
    } else {
      cartCubit.increment(productId);
    }
  }

  // ── Decrement cart quantity ──────────────────────────────────
  void _decrement(ProductModel product) {
    final productId = int.tryParse(product.id) ?? 0;
    if (productId == 0) return;

    final cartCubit = context.read<CartCubit>();
    final cartState = cartCubit.state;

    if (cartState is CartLoaded) {
      final item = cartState.cart.items.where((i) => i.productId == productId).firstOrNull;
      if (item == null) return;

      if (item.count <= 1) {
        cartCubit.removeItem(productId);
      } else {
        cartCubit.decrement(productId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      // ── Top App Bar ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () {},
        ),
        title: const Text(
          AppStrings.greenShop, // Keep logo/title exactly as-is
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          // Cart icon with badge (wire up to your cart cubit)
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              int totalItems = 0;
              if (cartState is CartLoaded) {
                totalItems = cartState.cart.items.fold(0, (sum, item) => sum + item.count);
              } else if (cartState is CartLoading && cartState.previousCart != null) {
                totalItems = cartState.previousCart!.items.fold(0, (sum, item) => sum + item.count);
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF1A1A1A),
                    ),
                    onPressed: () {
                      // TODO: Navigate to cart screen
                    },
                  ),
                  if (totalItems > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$totalItems',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Filter Panel ──────────────────────────────────────
          BlocListener<CartCubit, CartState>(
            listener: (context, state) {
              if (state is CartError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            child: _FilterPanel(
              searchController: _searchController,
              minPriceController: _minPriceController,
              maxPriceController: _maxPriceController,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (val) {
                setState(() => _selectedCategory = val);
                _applyFilters();
              },
              onApplyFilter: _applyFilters,
            ),
          ),

          // ── Product List ──────────────────────────────────────
          BlocListener<ShopCubit, ShopState>(
            listener: (context, state) {
              if (state is ShopLoaded && state.products.isNotEmpty) {
                // Extract unique categories from products
                final categories = state.products
                    .where((p) => p.categoryId != null && p.category.isNotEmpty)
                    .map((p) => CategoryModel(id: p.categoryId!, name: p.category))
                    .toList();
                
                if (categories.isNotEmpty) {
                  context.read<CategoryCubit>().updateCategories(categories);
                }
              }
            },
            child: Expanded(
              child: BlocBuilder<ShopCubit, ShopState>(
                builder: (context, state) {
                  if (state is ShopLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryLight),
                    );
                  }

                  if (state is ShopError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<ShopCubit>().loadProducts(),
                    );
                  }

                  if (state is ShopLoaded) {
                    if (state.products.isEmpty) {
                      return const _EmptyView();
                    }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: state.products.length,
                    itemBuilder: (_, i) {
                      final product = state.products[i];
                      final productId = int.tryParse(product.id) ?? 0;

                      return BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          int qty = 0;
                          if (cartState is CartLoaded) {
                            final item = cartState.cart.items
                                .where((i) => i.productId == productId)
                                .firstOrNull;
                            qty = item?.count ?? 0;
                          } else if (cartState is CartLoading && cartState.previousCart != null) {
                            final item = cartState.previousCart!.items
                                .where((i) => i.productId == productId)
                                .firstOrNull;
                            qty = item?.count ?? 0;
                          }

                          return _ProductCard(
                            product: product,
                            quantity: qty,
                            onAddToCart: () => _increment(product),
                            onIncrement: () => _increment(product),
                            onDecrement: () => _decrement(product),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ══════════════════════════════════════════════════════════════
// FILTER PANEL
// ══════════════════════════════════════════════════════════════

class _FilterPanel extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final CategoryModel? selectedCategory;
  final ValueChanged<CategoryModel?> onCategoryChanged;
  final VoidCallback onApplyFilter;

  const _FilterPanel({
    required this.searchController,
    required this.minPriceController,
    required this.maxPriceController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          _FieldLabel(label: AppStrings.searchProducts),
          const SizedBox(height: 6),
          _StyledTextField(
            controller: searchController,
            hint: AppStrings.searchHint,
            prefixIcon: Icons.search_rounded,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),

          // Category dropdown
          _FieldLabel(label: AppStrings.category),
          const SizedBox(height: 6),
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, catState) {
              final isLoading = catState is CategoryLoading;
              final categories = catState is CategoryLoaded
                  ? catState.categories.where((c) => c.status).toList()
                  : <CategoryModel>[];

              return Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDE0DE)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CategoryModel?>(
                    value: selectedCategory,
                    isExpanded: true,
                    isDense: false, // Ensure it has enough hit area
                    hint: Text(
                      isLoading ? 'Loading...' : AppStrings.allCategories,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF666666),
                          ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                    items: [
                      const DropdownMenuItem<CategoryModel?>(
                        value: null,
                        child: Text(AppStrings.allCategories),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<CategoryModel?>(
                          value: c,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: onCategoryChanged,
                    // Fix: Ensure the menu is always accessible
                    menuMaxHeight: 300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Min / Max price
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: AppStrings.minPrice),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: minPriceController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: AppStrings.maxPrice),
                    const SizedBox(height: 6),
                    _StyledTextField(
                      controller: maxPriceController,
                      hint: '10000',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onApplyFilter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.tune_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: section label ──────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }
}

// ── Helper: styled text field ──────────────────────────────────
class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: const Color(0xFF9E9E9E)) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE0DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDE0DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRODUCT CARD — new vertical layout
// ══════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool inCart = quantity > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: product.isSoldOut ? AppColors.infected.withOpacity(0.2) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product image ────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(
                  product.imageUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: double.infinity,
                    height: 180,
                    color: const Color(0xFFF0F0F0),
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFFBDBDBD),
                      size: 40,
                    ),
                  ),
                ),
              ),

              // Category badge — top right corner of image
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: Text(
                    product.category.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Organic badge — top left
              if (product.isOrganic)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.healthy.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      AppStrings.organic,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Sold out overlay
              if (product.isSoldOut)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.infected,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          AppStrings.soldOut,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ── Product info ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stars + reviews
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < product.rating.floor() ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.accentYellow,
                        size: 14,
                      );
                    }),
                    const SizedBox(width: 5),
                    Text(
                      '${product.rating}  (${product.reviewCount})',
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Product name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                // Price
                Text(
                  product.displayPrice,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // ── CTA: Add to Cart OR Quantity Selector ────────
                if (product.isSoldOut)
                  // Sold-out label button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.infected.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        AppStrings.soldOut,
                        style: TextStyle(
                          color: AppColors.infected,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else if (!inCart)
                  // "Add to Cart" button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
                      icon: const Icon(Icons.shopping_cart_outlined, size: 17),
                      label: const Text(AppStrings.addToCart),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else
                  // Quantity selector (matches Image 2 design)
                  _QuantitySelector(
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// QUANTITY SELECTOR — matches Image 2 (yellow-bordered pill)
// ══════════════════════════════════════════════════════════════

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.accentYellow,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // ── Minus ─────────────────────────────────────────
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(100)),
                onTap: onDecrement,
                child: const Center(
                  child: Icon(
                    Icons.remove_rounded,
                    size: 20,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ),

          // ── Divider ───────────────────────────────────────
          Container(
            width: 1,
            height: 22,
            color: AppColors.accentYellow.withOpacity(0.5),
          ),

          // ── Quantity number ───────────────────────────────
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          // ── Divider ───────────────────────────────────────
          Container(
            width: 1,
            height: 22,
            color: AppColors.accentYellow.withOpacity(0.5),
          ),

          // ── Plus ──────────────────────────────────────────
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(100)),
                onTap: onIncrement,
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SUPPORTING VIEWS
// ══════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            'No products found.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
