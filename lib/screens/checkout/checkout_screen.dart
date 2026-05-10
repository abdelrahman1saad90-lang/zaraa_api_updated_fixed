import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/cart/cart_cubit.dart';
import '../../cubits/checkout/checkout_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Initialize checkout cubit and prefill shipping if available
    final cubit = context.read<CheckoutCubit>();
    cubit.initialize();
    _prefillShipping(cubit);
  }

  void _prefillShipping(CheckoutCubit cubit) {
    final last = cubit.lastShipping;
    if (last != null) {
      _addressController.text = last.address;
      _phoneController.text = last.phone;
      _notesController.text = last.notes ?? '';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = context.read<CartCubit>().state;
    double total = 0;
    if (cartState is CartLoaded) {
      total = cartState.cart.totalPrice;
    }

    await context.read<CheckoutCubit>().startCheckout(
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          cartTotal: total,
        );
  }

  void _handleCheckoutState(BuildContext context, CheckoutState state) async {
    if (state is CheckoutPaymentReady) {
      // Launch Stripe in In-App WebView
      if (mounted) {
        context.push(AppRoutes.paymentWebview, extra: state.paymentUrl);
      }
    } else if (state is CheckoutSuccess) {
      if (mounted) {
        // Clear cart and navigate to success
        context.read<CartCubit>().clearCart();
        context.go(AppRoutes.paymentSuccess, extra: state.order);
      }
    } else if (state is CheckoutCanceled) {
      if (mounted) context.go(AppRoutes.paymentCancel);
    } else if (state is CheckoutFailed) {
      if (mounted) context.go(AppRoutes.paymentFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: _handleCheckoutState,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F3),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: const Text(
            'Checkout',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.cart);
              }
            },
          ),
        ),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            final isProcessing = checkoutState is CheckoutProcessing ||
                checkoutState is CheckoutLaunchingStripe;

            return Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnim,
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      double total = 0;
                      List<CartItemModel> items = [];
                      if (cartState is CartLoaded) {
                        total = cartState.cart.totalPrice;
                        items = cartState.cart.items;
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Order Summary ─────────────────
                              _buildOrderSummary(items, total),
                              const SizedBox(height: 20),

                              // ── Shipping Details ──────────────
                              _buildSectionHeader(
                                Icons.local_shipping_rounded,
                                AppStrings.shippingDetails,
                              ),
                              const SizedBox(height: 12),
                              _buildShippingForm(),
                              const SizedBox(height: 24),

                              // ── Payment Method ────────────────
                              _buildSectionHeader(
                                Icons.payment_rounded,
                                AppStrings.paymentMethod,
                              ),
                              const SizedBox(height: 12),
                              _buildPaymentMethod(),
                              const SizedBox(height: 24),

                              // ── Price Breakdown ───────────────
                              _buildPriceBreakdown(total),
                              const SizedBox(height: 16),

                              // ── Error Display ─────────────────
                              if (checkoutState is CheckoutError)
                                _buildErrorBanner(checkoutState.message),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Bottom Pay Button ───────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      double total = 0;
                      if (cartState is CartLoaded) {
                        total = cartState.cart.totalPrice;
                      }
                      return _buildPayButton(total, isProcessing);
                    },
                  ),
                ),

                // ── Processing Overlay ──────────────────────
                if (isProcessing) _buildProcessingOverlay(checkoutState),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ORDER SUMMARY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOrderSummary(List<CartItemModel> items, double total) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  '${AppStrings.orderSummary} (${items.length} items)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          ...items.map((item) => _buildOrderItem(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.product.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: AppColors.surfaceAlt,
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.count} × EGP ${item.product.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'EGP ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHIPPING FORM
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShippingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _addressController,
            decoration: _inputDecoration(
              label: AppStrings.deliveryAddress,
              icon: Icons.location_on_outlined,
              hint: 'Enter your full delivery address',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your address';
              if (v.trim().length < 5) return 'Address must be at least 5 characters';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: AppStrings.phoneNumber,
              icon: Icons.phone_outlined,
              hint: 'e.g. 01012345678',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter phone number';
              if (v.trim().length < 8) return 'Enter a valid phone number';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: _inputDecoration(
              label: AppStrings.orderNotes,
              icon: Icons.note_alt_outlined,
              hint: 'Any special instructions...',
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primaryLight, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.infected),
      ),
      filled: true,
      fillColor: AppColors.surfaceAlt.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYMENT METHOD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Online Payment (Stripe)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Secure card payment via Stripe',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRICE BREAKDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPriceBreakdown(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _priceRow('Subtotal', 'EGP ${total.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _priceRow('Shipping', 'Free', isGreen: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.surfaceBorder, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'EGP ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.healthy : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAY BUTTON (bottom floating)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPayButton(double total, bool isProcessing) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isProcessing ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isProcessing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      ),
                      SizedBox(width: 12),
                      Text('Processing...',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  )
                : Text(
                    'Pay EGP ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROCESSING OVERLAY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProcessingOverlay(CheckoutState state) {
    final message = state is CheckoutProcessing
        ? state.message
        : 'Opening payment page...';

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please do not close the app',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ERROR BANNER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infected.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infected.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.infected, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.infected,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
