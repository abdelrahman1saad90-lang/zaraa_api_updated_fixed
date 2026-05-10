import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/cart/cart_cubit.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure cart is loaded when entering screen
    context.read<CartCubit>().loadCart();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          AppStrings.cart,
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (state is CartError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          }
          if (state is CartLoaded) {
            if (state.cart.items.isEmpty) {
              return const Center(child: Text('Your cart is empty.', style: TextStyle(fontSize: 16)));
            }
            final total = state.cart.totalPrice;
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.cart.items[index];
                      return _CartItemTile(item: item);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                      Text('EGP ${total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 20)),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to checkout screen for shipping details & payment
                      context.push(AppRoutes.checkout);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemModel item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        leading: Image.network(item.product.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
        title: Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('EGP ${item.product.discountedPrice.toStringAsFixed(2)} each'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => cartCubit.decrement(item.productId)),
            Text(item.count.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => cartCubit.increment(item.productId)),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.infected), onPressed: () => cartCubit.removeItem(item.productId)),
          ],
        ),
      ),
    );
  }
}
