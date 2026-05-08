import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../cubits/admin/admin_orders_cubit.dart';
import '../../widgets/common_widgets.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load orders on init
    context.read<AdminOrdersCubit>().loadOrders();
  }

  void _updateStatus(OrderModel order, OrderStatus newStatus) {
    context.read<AdminOrdersCubit>().updateOrderStatus(order.id, newStatus);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.canceled:
        return Colors.red;
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Customer: ${order.customerName ?? 'N/A'}'),
              Text('Email: ${order.customerEmail ?? 'N/A'}'),
              Text('Phone: ${order.customerPhone ?? 'N/A'}'),
              Text('Address: ${order.address ?? 'N/A'}'),
              const Divider(),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(item.imageUrl),
                  onBackgroundImageError: (_, __) => const Icon(Icons.image),
                ),
                title: Text(item.productName),
                subtitle: Text('Qty: ${item.quantity} x EGP ${item.price}'),
                trailing: Text('EGP ${item.totalPrice}'),
              )),
              const Divider(),
              Text(
                'Total: EGP ${order.totalPrice}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Orders Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<AdminOrdersCubit>().loadOrders(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
                builder: (context, state) {
                  List<OrderModel>? orders;
                  bool isLoading = false;

                  if (state is AdminOrdersLoading) {
                    orders = state.previousOrders;
                    isLoading = true;
                  } else if (state is AdminOrdersLoaded) {
                    orders = state.orders;
                  } else if (state is AdminOrdersError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  }

                  if (orders == null) {
                    return const ShimmerLoader(count: 6);
                  }

                  if (orders.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Orders Yet',
                      subtitle: 'Orders placed by customers will appear here.',
                      onRetry: () => context.read<AdminOrdersCubit>().loadOrders(),
                    );
                  }

                  return Stack(
                    children: [
                      ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders![index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              title: Row(
                                children: [
                                  Text(
                                    'Order #${order.id}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      order.status.label,
                                      style: TextStyle(
                                        color: _getStatusColor(order.status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Customer: ${order.customerName ?? 'Unknown'}'),
                                    Text('Date: ${order.formattedDate}'),
                                    Text('Total: EGP ${order.totalPrice}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              trailing: PopupMenuButton<OrderStatus>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (status) => _updateStatus(order, status),
                                itemBuilder: (context) => [
                                  if (order.status != OrderStatus.shipped)
                                    const PopupMenuItem(
                                      value: OrderStatus.shipped,
                                      child: Text('Mark as Shipped'),
                                    ),
                                  if (order.status != OrderStatus.completed)
                                    const PopupMenuItem(
                                      value: OrderStatus.completed,
                                      child: Text('Mark as Completed'),
                                    ),
                                  if (order.status != OrderStatus.canceled)
                                    const PopupMenuItem(
                                      value: OrderStatus.canceled,
                                      child: Text('Mark as Canceled'),
                                    ),
                                ],
                              ),
                              onTap: () => _showOrderDetails(order),
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
    );
  }
}
