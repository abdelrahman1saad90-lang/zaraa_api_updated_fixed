import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

/// Welcome / splash screen — always shown on app launch.
///
/// Flow:
///   1. Play entrance animation (~1.5s)
///   2. Wait for AuthCubit to resolve
///   3. If authenticated → auto-navigate to Dashboard after brief pause
///   4. If unauthenticated → reveal CTA buttons
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _contentCtrl;
  late AnimationController _networkCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _buttonRevealCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoSlide;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonFade;
  late Animation<Offset> _buttonSlide;

  bool _hasNavigated = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Background animations ────────────────────────────────
    _networkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // ── Content entrance animation ───────────────────────────
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    ));

    // ── Button reveal — separate controller (stays hidden until needed)
    _buttonRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonRevealCtrl, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonRevealCtrl,
      curve: Curves.easeOut,
    ));

    // Start the entrance animation
    _contentCtrl.forward();

    // Trigger session check AFTER the first frame (context is fully ready)
    // This guarantees the splash screen is visible before any auth navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthCubit>().checkSession();
    });

    // After entrance animation finishes, decide what to do
    _contentCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handlePostAnimation();
      }
    });
  }

  /// Called after the entrance animation (~1.5s) completes.
  /// Checks auth state — if still loading, waits for the result.
  void _handlePostAnimation() {
    if (!mounted || _hasNavigated) return;

    final authState = context.read<AuthCubit>().state;

    if (authState is AuthAuthenticated) {
      // Authenticated: show splash briefly then auto-navigate
      _autoNavigate();
    } else if (authState is AuthUnauthenticated || authState is AuthError) {
      // Not authenticated: show the CTA buttons
      _showButtons();
    } else {
      // Still checking (AuthLoading / AuthInitial) — wait for result
      _authSub = context.read<AuthCubit>().stream.listen((state) {
        if (!mounted || _hasNavigated) return;
        if (state is AuthAuthenticated) {
          _autoNavigate();
        } else if (state is AuthUnauthenticated || state is AuthError) {
          _showButtons();
        }
      });
    }
  }

  /// Auto-navigate to dashboard after a short branding pause.
  void _autoNavigate() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _authSub?.cancel();

    // Brief pause so the user sees the full splash
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) context.go(AppRoutes.dashboard);
    });
  }

  /// Fade in the CTA buttons for unauthenticated users.
  void _showButtons() {
    _authSub?.cancel();
    if (mounted) _buttonRevealCtrl.forward();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _contentCtrl.dispose();
    _networkCtrl.dispose();
    _pulseCtrl.dispose();
    _buttonRevealCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A4D2E),
      body: Stack(
        children: [
          _buildBackground(),
          AnimatedBuilder(
            animation: _networkCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConstellationPainter(_networkCtrl.value),
              size: Size.infinite,
            ),
          ),
          SafeArea(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D3B22),
            Color(0xFF1A5C34),
            Color(0xFF22703F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Logo + wordmark
        FadeTransition(
          opacity: _logoFade,
          child: SlideTransition(
            position: _logoSlide,
            child: ScaleTransition(
              scale: _logoScale,
              child: _buildLogoSection(),
            ),
          ),
        ),
        const SizedBox(height: 40),
        // Welcome text
        FadeTransition(
          opacity: _textFade,
          child: SlideTransition(
            position: _textSlide,
            child: _buildWelcomeText(),
          ),
        ),
        const Spacer(flex: 3),
        // CTA buttons — hidden initially, revealed for unauthenticated users
        FadeTransition(
          opacity: _buttonFade,
          child: SlideTransition(
            position: _buttonSlide,
            child: _buildButtons(),
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  // ── Logo section ──────────────────────────────────────────────
  Widget _buildLogoSection() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            final glow = 0.25 + (_pulseCtrl.value * 0.3);
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CD68A).withValues(alpha: glow),
                    blurRadius: 55,
                    spreadRadius: 15,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A5C34),
              border: Border.all(
                color: const Color(0xFF52D68A).withValues(alpha: 0.35),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/big_zaraa.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        _buildWordmark(),
        const SizedBox(height: 8),
        const Text(
          'PLANT CARE AI PROJECT',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF90D4A4),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildWordmark() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD4EDD4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Zara',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 46,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Icon(
            Icons.eco,
            color: Color(0xFF52D68A),
            size: 18,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD4EDD4), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'a',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 46,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  // ── Welcome text ──────────────────────────────────────────────
  Widget _buildWelcomeText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          Text(
            "Welcome to Zara'a",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF4C842),
              height: 1.3,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Cultivating Health, Powered\nby Intelligence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA buttons ───────────────────────────────────────────────
  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DBE6E),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF2A9958),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: () => context.go(AppRoutes.login),
              child: const Text(
                'START YOUR JOURNEY',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.go(AppRoutes.landing),
            child: const Text(
              'Skip for Now',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF90D4A4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Constellation network painter
// ═══════════════════════════════════════════════════════════════════

class _ConstellationPainter extends CustomPainter {
  final double progress;

  static final List<Offset> _seeds = List.generate(22, (i) {
    final rng = math.Random(i * 7 + 3);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  const _ConstellationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF52D68A).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final List<Offset> pts = _seeds.map((p) {
      final angle = progress * 2 * math.pi + p.dx * 6;
      final driftX = math.sin(angle) * 0.016;
      final driftY = math.cos(angle * 0.7) * 0.016;
      return Offset(
        (p.dx + driftX).clamp(0.0, 1.0) * size.width,
        (p.dy + driftY).clamp(0.0, 1.0) * size.height,
      );
    }).toList();

    for (int i = 0; i < pts.length; i++) {
      for (int j = i + 1; j < pts.length; j++) {
        final dist = (pts[i] - pts[j]).distance;
        final maxDist = size.width * 0.34;
        if (dist < maxDist) {
          final opacity = (1 - dist / maxDist) * 0.22;
          canvas.drawLine(
            pts[i],
            pts[j],
            Paint()
              ..color = const Color(0xFF52D68A).withValues(alpha: opacity)
              ..strokeWidth = 0.8,
          );
        }
      }
    }

    for (final pt in pts) {
      canvas.drawCircle(
        pt,
        5,
        Paint()
          ..color = const Color(0xFF52D68A).withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawCircle(pt, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => old.progress != progress;
}
