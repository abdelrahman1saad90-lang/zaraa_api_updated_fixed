import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_products_cubit.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProductsCubit>().loadProducts();
  }

  Future<void> _quickUpdateStock(ProductModel product, int delta) async {
    final newQty = (product.quantity + delta).clamp(0, 99999);
    if (newQty == product.quantity) return;
    await context.read<AdminProductsCubit>().updateProductQuantity(product, newQty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AdminProductsCubit, AdminProductsState>(
        listener: (context, state) {
          if (state is AdminProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AdminProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory & Stock',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: () => context.read<AdminProductsCubit>().loadProducts(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the +/– buttons to quickly adjust stock levels.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
                  builder: (context, state) {
                    List<ProductModel>? products;
                    bool isLoading = false;

                    if (state is AdminProductsLoading) {
                      products = state.previousProducts;
                      isLoading = true;
                    } else if (state is AdminProductsLoaded) {
                      products = state.products;
                    }

                    if (products == null && isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (products == null || products.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_rounded, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No products found', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    // Sort: low stock first
                    final sorted = [...products]
                      ..sort((a, b) => a.quantity.compareTo(b.quantity));

                    return Stack(
                      children: [
                        ListView.builder(
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final product = sorted[index];
                            final isLowStock = product.quantity <= 5;
                            final isOutOfStock = product.quantity == 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: isLowStock
                                    ? BorderSide(
                                        color: isOutOfStock ? Colors.red.shade400 : Colors.orange.shade400,
                                        width: 1.5,
                                      )
                                    : BorderSide.none,
                              ),
                              elevation: isLowStock ? 0 : 1,
                              color: isOutOfStock
                                  ? Colors.red.shade50
                                  : isLowStock
                                      ? Colors.orange.shade50
                                      : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        product.imageUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.image_rounded, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Product info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (isOutOfStock)
                                                _StatusBadge(label: 'OUT OF STOCK', color: Colors.red)
                                              else if (isLowStock)
                                                _StatusBadge(label: 'LOW STOCK', color: Colors.orange)
                                              else
                                                _StatusBadge(label: 'IN STOCK', color: Colors.green),
                                              const SizedBox(width: 8),
                                              Text(
                                                'EGP ${product.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Stock adjuster
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StockButton(
                                          icon: Icons.remove_rounded,
                                          color: Colors.red,
                                          onTap: product.quantity > 0
                                              ? () => _quickUpdateStock(product, -1)
                                              : null,
                                        ),
                                        Container(
                                          width: 44,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${product.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isOutOfStock
                                                  ? Colors.red
                                                  : isLowStock
                                                      ? Colors.orange
                                                      : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        _StockButton(
                                          icon: Icons.add_rounded,
                                          color: Colors.green,
                                          onTap: () => _quickUpdateStock(product, 1),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        if (isLoading)
                          const Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StockButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null ? color.withOpacity(0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: onTap != null ? color : Colors.grey),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
