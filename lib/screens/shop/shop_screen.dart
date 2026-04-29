import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/category/category_cubit.dart';
import '../../cubits/shop/shop_cubit.dart';

/// Shop screen — mirrors /users/shop.
/// Displays products with category filter chips and individual product cards.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Expandable hero header ───────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 60, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Certified Organic & Professional Tools',
                            style: TextStyle(
                              color: AppColors.primaryLighter,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          AppStrings.greenShop,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          AppStrings.shopSubtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Category chips (loaded from API) ──────────────────
          BlocBuilder<CategoryCubit, CategoryState>(
            builder: (context, catState) {
              // Build the chip list: "All Categories" + API categories
              final List<String> categoryNames = [AppStrings.allCategories];

              if (catState is CategoryLoaded) {
                categoryNames.addAll(
                  catState.categories
                      .where((c) => c.status)
                      .map((c) => c.name),
                );
              }

              return BlocBuilder<ShopCubit, ShopState>(
                builder: (context, shopState) {
                  final selectedCat = shopState is ShopLoaded
                      ? shopState.selectedCategory
                      : AppStrings.allCategories;

                  return SliverToBoxAdapter(
                    child: Container(
                      color: AppColors.surface,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: categoryNames.map((cat) {
                            final isActive = cat == selectedCat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isActive,
                                onSelected: (_) => context
                                    .read<ShopCubit>()
                                    .loadProducts(category: cat),
                                backgroundColor: AppColors.surfaceAlt,
                                selectedColor: AppColors.primary,
                                checkmarkColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                side: BorderSide(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.surfaceBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ── Divider ───────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Divider(
              color: AppColors.surfaceBorder,
              height: 1,
            ),
          ),

          // ── Product list ──────────────────────────────────────
          BlocBuilder<ShopCubit, ShopState>(
            builder: (context, state) {
              if (state is ShopLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  ),
                );
              }

              if (state is ShopError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_outlined,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.message,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ShopCubit>().loadProducts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ShopLoaded) {
                if (state.products.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No products in this category.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _ProductCard(product: state.products[i]),
                      childCount: state.products.length,
                    ),
                  ),
                );
              }

              return const SliverToBoxAdapter();
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PRODUCT CARD
// ══════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isSoldOut
              ? AppColors.infected.withOpacity(0.25)
              : AppColors.surfaceBorder,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Product image ──────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.network(
                product.imageUrl,
                width: 115,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 115,
                  color: AppColors.surfaceAlt,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
            // ── Product info ───────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (product.isOrganic)
                          _Badge(
                            label: AppStrings.organic,
                            color: AppColors.healthy,
                          ),
                        if (product.isSoldOut)
                          _Badge(
                            label: AppStrings.soldOut,
                            color: AppColors.infected,
                          ),
                        _Badge(
                          label: product.category,
                          color: AppColors.primaryLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stars + reviews
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final full = i < product.rating.floor();
                          return Icon(
                            full ? Icons.star : Icons.star_border,
                            color: AppColors.accentYellow,
                            size: 12,
                          );
                        }),
                        const SizedBox(width: 5),
                        Text(
                          '${product.rating}  (${product.reviewCount})',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    // Price + add to cart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Price',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              product.displayPrice,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (!product.isSoldOut)
                          ElevatedButton(
                            onPressed: () => _showAddedSnack(context),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text(AppStrings.addToCart),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.infected.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.infected.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              AppStrings.soldOut,
                              style: TextStyle(
                                color: AppColors.infected,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddedSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${product.name.split(',').first} added to cart',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
