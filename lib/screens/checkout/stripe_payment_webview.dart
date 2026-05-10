import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../cubits/checkout/checkout_cubit.dart';

class StripePaymentWebView extends StatefulWidget {
  final String url;
  const StripePaymentWebView({super.key, required this.url});

  @override
  State<StripePaymentWebView> createState() => _StripePaymentWebViewState();
}

class _StripePaymentWebViewState extends State<StripePaymentWebView> {
  double _progress = 0;
  InAppWebViewController? _webViewController;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        // Close WebView when state transitions to success/fail/cancel
        if (state is CheckoutSuccess ||
            state is CheckoutFailed ||
            state is CheckoutCanceled ||
            state is CheckoutTimeout) {
          if (!_isFinished && mounted) {
            _isFinished = true;
            context.pop(); // Close WebView
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.healthy, size: 18),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure Checkout',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Powered by Stripe',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {
              context.read<CheckoutCubit>().markCanceled();
              context.pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
              onPressed: () => _webViewController?.reload(),
            ),
          ],
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                isFraudulentWebsiteWarningEnabled: true,
                safeBrowsingEnabled: true,
                allowsBackForwardNavigationGestures: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString();
                if (url != null) {
                  final handled = await context
                      .read<CheckoutCubit>()
                      .handleStripeRedirect(url);
                  
                  if (handled) {
                    return NavigationActionPolicy.CANCEL; // Intercepted
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                if (url != null) {
                  await context
                      .read<CheckoutCubit>()
                      .handleStripeRedirect(url.toString());
                }
              },
            ),

            // ── Loading Progress Bar ──────────────────
            if (_progress < 1.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
