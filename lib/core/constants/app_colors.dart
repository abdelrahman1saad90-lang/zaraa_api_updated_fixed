import 'package:flutter/material.dart';

/// Zaraa unified brand color palette — forest-green theme matching the logo.
class AppColors {
  AppColors._();

  // ── Primary greens ────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF2D7A50); // Forest green (logo-match)
  static const Color primaryDark    = Color(0xFF1B5235); // Deep forest green
  static const Color primaryLight   = Color(0xFF52B788); // Medium mint green
  static const Color primaryLighter = Color(0xFFA8DFC4); // Soft mint
  static const Color primaryAccent  = Color(0xFF3DBE6E); // Bright action green
  static const Color accentYellow   = Color(0xFFF4D03F); // Warm gold accent

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF4FAF6); // Very light green tint
  static const Color surface       = Color(0xFFFFFFFF); // Card / panel white
  static const Color surfaceAlt    = Color(0xFFEDF7F1); // Slightly tinted surface
  static const Color surfaceBorder = Color(0xFFD0EBD9); // Divider / border

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color healthy    = Color(0xFF52B788);
  static const Color infected   = Color(0xFFE74C3C);
  static const Color recovering = Color(0xFFF39C12);
  static const Color warning    = Color(0xFFF39C12);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A3C28); // Dark green-black
  static const Color textSecondary = Color(0xFF4D7A60); // Mid-tone green-grey
  static const Color textMuted     = Color(0xFF8AB89A); // Muted

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Gradient presets ──────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0D3B22), Color(0xFF2D7A50)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceAlt, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
