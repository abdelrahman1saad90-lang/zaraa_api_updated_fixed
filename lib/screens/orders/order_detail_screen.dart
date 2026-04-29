import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/orders/orders_cubit.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel initialOrder;
  const OrderDetailScreen({super.key, required this.initialOrder});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load full details for this order to ensure fresh data
    context.read<OrdersCubit>().loadOrderDetail(widget.initialOrder.id);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFF39C12);
      case OrderStatus.processing:
        return const Color(0xFF3498DB);
      case OrderStatus.shipped:
        return const Color(0xFF9B59B6);
      case OrderStatus.completed:
        return AppColors.healthy;
      case OrderStatus.canceled:
        return AppColors.infected;
    }
  }

  void _showSnackBar(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.infected : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrdersCubit, OrdersState>(
      listener: (context, state) {
        if (state is OrderActionSuccess) {
          _showSnackBar(state.message, false);
        } else if (state is OrderActionError) {
          _showSnackBar(state.message, true);
        }
      },
      builder: (context, state) {
        // Find the current order to display
        OrderModel currentOrder = widget.initialOrder;
        bool isLoadingAction = state is OrderActionLoading;

        if (state is OrderDetailLoaded && state.order.id == currentOrder.id) {
          currentOrder = state.order;
        }

        final statusColor = _getStatusColor(currentOrder.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF2F7F4),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text(
              'Order #${currentOrder.id}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Header
                    _buildStatusHeader(currentOrder, statusColor),
                    const SizedBox(height: 20),

                    // Customer Info
                    _buildSectionTitle('Customer Information'),
                    _buildCustomerCard(currentOrder),
                    const SizedBox(height: 20),

                    // Items List
                    _buildSectionTitle('Order Items (${currentOrder.items.length})'),
                    _buildItemsList(currentOrder.items),
                    const SizedBox(height: 20),

                    // Order Summary
                    _buildSummaryCard(currentOrder),
                    const SizedBox(height: 30),

                    // Actions
                    _buildActionButtons(context, currentOrder),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Loading Overlay
              if (isLoadingAction)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(OrderModel order, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.8), statusColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Placed on ${order.formattedDate}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_rounded, 'Name', order.customerName ?? 'N/A'),
          const Divider(height: 24, color: AppColors.surfaceBorder),
          _buildInfoRow(Icons.email_rounded, 'Email', order.customerEmail ?? 'N/A'),
          const Divider(height: 24, color: AppColors.surfaceBorder),
          _buildInfoRow(Icons.phone_rounded, 'Phone', order.customerPhone ?? 'N/A'),
          const Divider(height: 24, color: AppColors.surfaceBorder),
          _buildInfoRow(Icons.location_on_rounded, 'Address', order.address ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryLight),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList(List<OrderItemModel> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Center(
          child: Text(
            'No items found in this order.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.surfaceBorder),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.image_not_supported, color: AppColors.primaryLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EGP ${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${item.price.toStringAsFixed(2)} each',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'EGP ${order.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel order) {
    final cubit = context.read<OrdersCubit>();
    
    // Only show buttons based on valid state transitions
    final canShip = order.status == OrderStatus.pending || order.status == OrderStatus.processing;
    final canComplete = order.status == OrderStatus.shipped;
    final canCancel = order.status == OrderStatus.pending || order.status == OrderStatus.processing;

    if (!canShip && !canComplete && !canCancel) {
      return Center(
        child: Text(
          'Order is ${order.status.label.toLowerCase()}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canShip)
          ElevatedButton.icon(
            onPressed: () => cubit.markShipped(order.id),
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('Mark as Shipped'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (canComplete)
          ElevatedButton.icon(
            onPressed: () => cubit.markCompleted(order.id),
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.healthy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showCancelDialog(context, cubit, order.id),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Cancel Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.infected,
              side: const BorderSide(color: AppColors.infected),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]
      ],
    );
  }

  void _showCancelDialog(BuildContext context, OrdersCubit cubit, int orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.cancelOrder(orderId);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.infected, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
