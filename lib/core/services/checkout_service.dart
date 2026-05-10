import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_strings.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'api_error_handler.dart';

/// Handles the complete checkout lifecycle:
/// 1. Create Stripe checkout session (via Cart/Pay)
/// 2. Persist pending checkout state locally
/// 3. Verify payment by polling orders
/// 4. Retrieve user's orders (customer → admin fallback)
class CheckoutService {
  final _client = ApiClient.instance;

  static const _pendingCheckoutKey = 'pending_checkout';
  static const _shippingDetailsKey = 'last_shipping_details';

  // ══════════════════════════════════════════════════════════════
  // 1) CREATE CHECKOUT SESSION
  // ══════════════════════════════════════════════════════════════

  /// Calls Cart/Pay to create a Stripe checkout session.
  /// Stores shipping details & session metadata locally.
  Future<ApiResponse<CheckoutSessionResult>> createCheckoutSession({
    required ShippingDetailsModel shipping,
    required double cartTotal,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('┌── CHECKOUT SESSION ────────────────────');
        debugPrint('│ Address: ${shipping.address}');
        debugPrint('│ Phone: ${shipping.phone}');
        debugPrint('│ Cart Total: $cartTotal');
      }

      final response = await _client.dio.post(
        ApiConstants.cartPay,
        data: {},
      );

      if (kDebugMode) {
        debugPrint('│ Status: ${response.statusCode}');
        debugPrint('│ Response: ${response.data}');
        debugPrint('└────────────────────────────────────────');
      }

      // Extract URL from response — handle wrapped and unwrapped shapes
      String? url;
      int? orderId;
      final data = response.data;
      if (data is Map) {
        url = data['url'] as String?;
        orderId = data['orderId'] as int?;
        if (url == null && data['returned'] is Map) {
          url = data['returned']['url'] as String?;
          orderId ??= data['returned']['orderId'] as int?;
        }
        if (url == null && data['data'] is Map) {
          url = data['data']['url'] as String?;
          orderId ??= data['data']['orderId'] as int?;
        }
      } else if (data is String && data.startsWith('http')) {
        url = data;
      }

      if (url == null || url.isEmpty) {
        return const ApiResponse.failure('No payment URL received from server.');
      }

      final result = CheckoutSessionResult(
        paymentUrl: url,
        inferredOrderId: orderId,
        cartTotal: cartTotal,
        createdAt: DateTime.now(),
      );

      // Persist checkout state & shipping details locally
      await _persistPendingCheckout(result, shipping);

      return ApiResponse.success(result);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('│ CHECKOUT ERROR: ${e.response?.statusCode} ${e.response?.data}');
        debugPrint('└────────────────────────────────────────');
      }
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (e) {
      return ApiResponse.failure('Checkout failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 2) VERIFY PAYMENT
  // ══════════════════════════════════════════════════════════════

  /// Verifies payment by checking the order list.
  /// If [orderId] is provided (e.g. extracted from URL), it checks that specific order.
  /// Otherwise, it looks for the most recent order matching the checkout session.
  Future<ApiResponse<OrderModel>> verifyPayment({int? orderId}) async {
    try {
      final pending = await getPendingCheckout();
      
      // Fetch all orders to find the one matching our checkout
      final ordersResult = await getUserOrders();
      if (!ordersResult.isSuccess || ordersResult.data == null) {
        return ApiResponse.failure(ordersResult.error ?? 'Failed to load orders.');
      }

      final orders = ordersResult.data!;
      if (orders.isEmpty) {
        return const ApiResponse.failure('No orders found. Payment may still be processing.');
      }

      // 1. If we have an orderId (passed from WebView or persisted), use it first
      final targetId = orderId ?? (pending != null ? pending['orderId'] as int? : null);
      if (targetId != null) {
        final match = orders.where((o) => o.id == targetId).firstOrNull;
        if (match != null) {
          await clearPendingCheckout();
          return ApiResponse.success(match);
        }
      }

      // If we don't have a targetId and no pending session, we can't do timestamp matching
      if (pending == null) {
        // Fallback: just return the most recent order if we were explicitly verifying
        return ApiResponse.success(orders.first);
      }

      // Fallback: match by most recent order near our checkout time
      final createdAtStr = pending['createdAt'] as String?;
      final checkoutTime = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
      final cartTotal = (pending['cartTotal'] as num?)?.toDouble() ?? 0.0;


      // Find orders created after our checkout session (within 30min window)
      final candidates = orders.where((o) {
        final timeDiff = o.createdAt.difference(checkoutTime).inMinutes.abs();
        final priceDiff = (o.totalPrice - cartTotal).abs();
        return timeDiff < 30 && priceDiff < 1.0; // within 30min and ~same total
      }).toList();

      if (candidates.isNotEmpty) {
        // Sort by most recent
        candidates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        await clearPendingCheckout();
        return ApiResponse.success(candidates.first);
      }

      // If no exact match, just return the most recent order
      final latest = orders.first; // already sorted desc
      await clearPendingCheckout();
      return ApiResponse.success(latest);
    } on DioException catch (e) {
      return ApiResponse.failure(ApiErrorHandler.message(e));
    } catch (e) {
      return ApiResponse.failure('Payment verification failed: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 3) GET USER ORDERS
  // ══════════════════════════════════════════════════════════════

  /// Fetches user's orders. Tries customer endpoint first,
  /// falls back to admin endpoint for admin-role users.
  Future<ApiResponse<List<OrderModel>>> getUserOrders() async {
    // Strategy: try customer endpoint → fallback to admin endpoint
    try {
      final response = await _client.dio.get(ApiConstants.customerOrdersIndex);
      final orders = _parseOrderList(response.data);
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return ApiResponse.success(orders);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Customer orders endpoint failed (${e.response?.statusCode}), trying admin...');
      }
      // Fallback to admin endpoint
      try {
        final response = await _client.dio.get(ApiConstants.ordersGetAll);
        final orders = _parseOrderList(response.data);
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return ApiResponse.success(orders);
      } on DioException catch (adminError) {
        return ApiResponse.failure(ApiErrorHandler.message(adminError));
      }
    }
  }

  /// Fetches a single order by ID.
  Future<ApiResponse<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _client.dio.get('${ApiConstants.customerOrdersGet}$id');
      return ApiResponse.success(OrderModel.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (_) {
      // Fallback to admin endpoint
      try {
        final response = await _client.dio.get('${ApiConstants.ordersGet}$id');
        return ApiResponse.success(OrderModel.fromJson(response.data as Map<String, dynamic>));
      } on DioException catch (adminError) {
        return ApiResponse.failure(ApiErrorHandler.message(adminError));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // 4) LOCAL PERSISTENCE — pending checkout & shipping
  // ══════════════════════════════════════════════════════════════

  Future<void> _persistPendingCheckout(
    CheckoutSessionResult session,
    ShippingDetailsModel shipping,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_pendingCheckoutKey, jsonEncode({
      'paymentUrl': session.paymentUrl,
      'orderId': session.inferredOrderId,
      'cartTotal': session.cartTotal,
      'createdAt': session.createdAt.toIso8601String(),
    }));

    await prefs.setString(_shippingDetailsKey, jsonEncode(shipping.toJson()));
  }

  Future<Map<String, dynamic>?> getPendingCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pendingCheckoutKey);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<ShippingDetailsModel?> getLastShippingDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_shippingDetailsKey);
    if (json == null) return null;
    try {
      return ShippingDetailsModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCheckoutKey);
  }

  Future<bool> hasPendingCheckout() async {
    final pending = await getPendingCheckout();
    if (pending == null) return false;
    // Check if it's not stale (within 2 hours)
    try {
      final createdAt = DateTime.parse(pending['createdAt'] as String);
      return DateTime.now().difference(createdAt).inHours < 2;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  List<OrderModel> _parseOrderList(dynamic responseData) {
    List<dynamic> rawList;

    if (responseData is List) {
      rawList = responseData;
    } else if (responseData is Map) {
      final data = responseData['data'] ?? responseData['returned'] ?? responseData;
      if (data is List) {
        rawList = data;
      } else {
        rawList = [];
      }
    } else {
      rawList = [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => OrderModel.fromJson(e))
        .toList();
  }
}
