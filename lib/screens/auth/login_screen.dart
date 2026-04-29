import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

// ─── Colour tokens (scoped to login screen) ───────────────────────────────────
class _C {
  static const primary = AppColors.primary;
  static const pageBg = AppColors.background;
  static const cardBg = Colors.white;
  static const fieldBg = AppColors.background;
  static const border = AppColors.surfaceBorder;
  static const labelClr = AppColors.textMuted;
  static const textH = AppColors.textPrimary;
  static const textSub = AppColors.textSecondary;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _errorBanner;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorBanner = null);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          emailOrUsername: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthError) {
          setState(() => _errorBanner = state.message);
        }
      },
      child: Scaffold(
        backgroundColor: _C.pageBg,
        body: Stack(
          children: [
            const _BackgroundBlobs(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: _LoginCard(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    obscurePass: _obscurePass,
                    onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                    errorBanner: _errorBanner,
                    onSubmit: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Decorative background blobs ─────────────────────────────────────────────

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          top: size.height * 0.4,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryAccent.withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Login card ───────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscurePass;
  final VoidCallback onTogglePass;
  final String? errorBanner;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscurePass,
    required this.onTogglePass,
    required this.errorBanner,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthCubit>().state is AuthLoading;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _C.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLighter, width: 2),
                  color: AppColors.surfaceAlt,
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/zaraa_logo.png', fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ────────────────────────────────────────────────────
            const _ScreenHeader(),
            const SizedBox(height: 26),

            // ── Error banner ──────────────────────────────────────────────
            if (errorBanner != null) ...[
              _ErrorBanner(message: errorBanner!),
              const SizedBox(height: 16),
            ],

            // ── Email / Username field ────────────────────────────────────
            _AppField(
              controller: emailCtrl,
              label: 'Email or Username',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email or username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Password field ────────────────────────────────────────────
            _PasswordField(
              controller: passCtrl,
              label: 'Password',
              obscure: obscurePass,
              onToggle: onTogglePass,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 4) return 'At least 4 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ── Submit ────────────────────────────────────────────────────
            _GradientButton(
              label: 'SIGN IN',
              loading: isLoading,
              onPressed: isLoading ? null : onSubmit,
            ),
            const SizedBox(height: 18),

            // ── Hint ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💡 ', style: TextStyle(fontSize: 13)),
                  Flexible(
                    // ✅ الإصلاح هنا
                    child: Text(
                      'You can sign in with email or username',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: _C.labelClr,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Register link ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: _C.textSub, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.register),
                  child: const Text(
                    'Sign up here',
                    style: TextStyle(
                      color: _C.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen header ────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Welcome Back!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.primary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Sign in to your account to continue.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _C.textSub,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Colors.red.shade400, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade500, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
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

// ─── Input decoration helper ──────────────────────────────────────────────────

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _C.labelClr, fontSize: 13),
    prefixIcon: Icon(icon, color: _C.labelClr, size: 18),
    suffixIcon: suffix,
    filled: true,
    fillColor: _C.fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.primary, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade500, width: 1.8),
    ),
  );
}

// ─── Text field ───────────────────────────────────────────────────────────────

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _AppField({
    required this.controller,
    required this.label,
    required this.icon,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _C.textH),
      decoration: _fieldDecoration(label: label, icon: icon),
      validator: validator,
    );
  }
}

// ─── Password field ───────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontSize: 14, color: _C.textH),
      decoration: _fieldDecoration(
        label: label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: _C.labelClr,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Gradient CTA button ──────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: onPressed == null
                  ? null
                  : const LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              color: onPressed == null ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
