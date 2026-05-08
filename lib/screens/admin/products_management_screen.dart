import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_products_cubit.dart';
import '../../widgets/common_widgets.dart';

class ProductsManagementScreen extends StatefulWidget {
  const ProductsManagementScreen({super.key});

  @override
  State<ProductsManagementScreen> createState() => _ProductsManagementScreenState();
}

class _ProductsManagementScreenState extends State<ProductsManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProductsCubit>().loadProducts();
  }

  void _deleteProduct(int productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AdminProductsCubit>().deleteProduct(productId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          context.push('${AppRoutes.adminProducts}/create');
        },
      ),
      body: BlocListener<AdminProductsCubit, AdminProductsState>(
        listener: (context, state) {
          if (state is AdminProductOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is AdminProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
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
                    'Products Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<AdminProductsCubit>().loadProducts(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                      return const ShimmerLoader(count: 6);
                    }

                    if (products == null || products.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.inventory_2_rounded,
                        title: 'No Products Found',
                        subtitle: 'Tap the + button below to add your first product.',
                        onRetry: () => context.read<AdminProductsCubit>().loadProducts(),
                      );
                    }

                    return Stack(
                      children: [
                        ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products![index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.image, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Category: ${product.category} | Stock: ${product.quantity}\nPrice: EGP ${product.price}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        context.push('${AppRoutes.adminProducts}/edit', extra: product);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Delete requires int parsing
                                        _deleteProduct(int.parse(product.id));
                                      },
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
