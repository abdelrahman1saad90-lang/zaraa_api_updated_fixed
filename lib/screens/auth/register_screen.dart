import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';

// ─── Main Screen ─────────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorBanner;

  // ── Password strength ──────────────────────────────────────────────────────
  double _passStrength = 0.0;
  String _passStrengthLabel = 'Password Strength';
  Color _passStrengthColor = _RegisterColors.primary;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password strength logic ────────────────────────────────────────────────
  void _onPasswordChanged() {
    final p = _passCtrl.text;
    if (p.isEmpty) {
      setState(() {
        _passStrength = 0;
        _passStrengthLabel = 'Password Strength';
        _passStrengthColor = _RegisterColors.primary;
      });
      return;
    }
    double s = 0;
    if (p.length >= 6) s += 0.25;
    if (p.length >= 10) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(p)) s += 0.25;

    late String label;
    late Color color;
    if (s <= 0.25) {
      label = 'Weak Password';
      color = Colors.red;
    } else if (s <= 0.50) {
      label = 'Fair Password';
      color = Colors.orange;
    } else if (s <= 0.75) {
      label = 'Good Password';
      color = Colors.blue;
    } else {
      label = 'Strong Password';
      color = _RegisterColors.success;
    }

    setState(() {
      _passStrength = s;
      _passStrengthLabel = label;
      _passStrengthColor = color;
    });
  }

  // ── Auto-generate username ─────────────────────────────────────────────────
  void _autoUsername() {
    final f = _firstNameCtrl.text.trim().toLowerCase();
    final l = _lastNameCtrl.text.trim().toLowerCase();
    final suffix = DateTime.now().millisecondsSinceEpoch % 1000;
    _usernameCtrl.text = '$f$l$suffix';
  }

  // ── Form submit ────────────────────────────────────────────────────────────
  void _submit() {
    setState(() => _errorBanner = null);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          userName: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthNeedsEmailConfirmation) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Color(0xFF4CAF50)),
                  SizedBox(width: 10),
                  Text('Account Created!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Text(
                state.message,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        } else if (state is AuthError) {
          setState(() => _errorBanner = state.message);
        }
      },
      child: Scaffold(
        backgroundColor: _RegisterColors.pageBg,
        body: Stack(
          children: [
            // ── Decorative blobs ──────────────────────────────────────────────
            const _BackgroundBlobs(),

            // ── Main content ──────────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: _FormCard(
                    formKey: _formKey,
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    usernameCtrl: _usernameCtrl,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    confirmCtrl: _confirmCtrl,
                    obscurePass: _obscurePass,
                    obscureConfirm: _obscureConfirm,
                    onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
                    onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    passStrength: _passStrength,
                    passStrengthLabel: _passStrengthLabel,
                    passStrengthColor: _passStrengthColor,
                    errorBanner: _errorBanner,
                    onAuto: _autoUsername,
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

// ─── Color palette ────────────────────────────────────────────────────────────

class _RegisterColors {
  static const pageBg  = AppColors.background;
  static const primary = AppColors.primary;
  static const darkBtn = AppColors.primaryDark;
  static const success = AppColors.primaryAccent;
  static const fieldBg = AppColors.background;
  static const border  = AppColors.surfaceBorder;
  static const labelClr= AppColors.textMuted;
  static const textH   = AppColors.textPrimary;
  static const textSub = AppColors.textSecondary;
}

// ─── Background blobs ─────────────────────────────────────────────────────────

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withOpacity(0.45),
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEDD9A3).withOpacity(0.45),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Form card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameCtrl, lastNameCtrl, usernameCtrl, emailCtrl, passCtrl, confirmCtrl;
  final bool obscurePass, obscureConfirm;
  final VoidCallback onTogglePass, onToggleConfirm, onAuto, onSubmit;
  final double passStrength;
  final String passStrengthLabel;
  final Color passStrengthColor;
  final String? errorBanner;

  const _FormCard({
    required this.formKey,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.onAuto,
    required this.onSubmit,
    required this.passStrength,
    required this.passStrengthLabel,
    required this.passStrengthColor,
    required this.errorBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ───────────────────────────────────────────────────────
            const _ScreenHeader(),
            const SizedBox(height: 20),

            // ── Error banner ────────────────────────────────────────────────
            if (errorBanner != null) ...[
              _ErrorBanner(message: errorBanner!),
              const SizedBox(height: 16),
            ],

            // ── First + Last name ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _AppField(
                    controller: firstNameCtrl,
                    label: 'First Name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AppField(
                    controller: lastNameCtrl,
                    label: 'Last Name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Username ────────────────────────────────────────────────────
            _UsernameField(controller: usernameCtrl, onAuto: onAuto),
            const SizedBox(height: 14),

            // ── Email ───────────────────────────────────────────────────────
            _AppField(
              controller: emailCtrl,
              label: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Password ────────────────────────────────────────────────────
            _PasswordField(
              controller: passCtrl,
              label: 'Password',
              obscure: obscurePass,
              onToggle: onTogglePass,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            // ── Strength bar ────────────────────────────────────────────────
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: passStrength,
                minHeight: 3,
                backgroundColor: const Color(0xFFE8EAF6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  passStrength == 0 ? _RegisterColors.primary.withOpacity(0.2) : passStrengthColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              passStrengthLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: passStrength == 0 ? _RegisterColors.primary : passStrengthColor,
              ),
            ),
            const SizedBox(height: 14),

            // ── Confirm password ────────────────────────────────────────────
            _PasswordField(
              controller: confirmCtrl,
              label: 'Confirm Password',
              obscure: obscureConfirm,
              onToggle: onToggleConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 6),

            // ── Forgot password ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: _RegisterColors.primary,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Submit button ───────────────────────────────────────────────
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final loading = state is AuthLoading;
                return _GradientButton(
                  label: 'CREATE ACCOUNT',
                  loading: loading,
                  onPressed: loading ? null : onSubmit,
                );
              },
            ),
            const SizedBox(height: 18),

            // ── Login link ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: _RegisterColors.textSub, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text(
                    'Log in here',
                    style: TextStyle(
                      color: _RegisterColors.primary,
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
    return Column(
      children: const [
        Text(
          'Create an Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RegisterColors.primary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Join us today! Please enter your details.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _RegisterColors.textSub,
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

// ─── Shared input decoration helper ──────────────────────────────────────────

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: _RegisterColors.labelClr, fontSize: 13),
    prefixIcon: Icon(icon, color: _RegisterColors.labelClr, size: 18),
    suffixIcon: suffix,
    filled: true,
    fillColor: _RegisterColors.fieldBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RegisterColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RegisterColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _RegisterColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade400),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.red.shade500, width: 1.6),
    ),
    // Highlight valid (non-error) filled fields in teal
    // Flutter doesn't have a "valid" border natively — handled via
    // errorBorder path; teal shown when focused + valid.
  );
}

// ─── Generic text field ───────────────────────────────────────────────────────

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AppField({
    required this.controller,
    required this.label,
    required this.icon,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, color: _RegisterColors.textH),
      decoration: _fieldDecoration(label: label, icon: icon),
      validator: validator,
    );
  }
}

// ─── Username field with Auto button ─────────────────────────────────────────

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAuto;

  const _UsernameField({required this.controller, required this.onAuto});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: _RegisterColors.textH),
      decoration: _fieldDecoration(
        label: 'Username',
        icon: Icons.alternate_email_rounded,
        suffix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            onPressed: onAuto,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 13),
            label: const Text(
              'Auto',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _RegisterColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Username is required';
        }
        if (v.trim().length < 3) return 'Username too short';
        return null;
      },
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
      style: const TextStyle(fontSize: 14, color: _RegisterColors.textH),
      decoration: _fieldDecoration(
        label: label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: _RegisterColors.labelClr,
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
              color: onPressed == null ? Colors.grey.shade400 : null,
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
