import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_colors.dart';
import '../cubits/cart/cart_cubit.dart';

class CartBadgeIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;

  const CartBadgeIcon({
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        int itemCount = 0;
        if (state is CartLoaded) {
          itemCount = state.cart.items.length;
        } else if (state is CartLoading && state.previousCart != null) {
          itemCount = state.previousCart!.items.length;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            if (itemCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
