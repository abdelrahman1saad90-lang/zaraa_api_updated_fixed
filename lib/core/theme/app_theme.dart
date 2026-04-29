import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppTheme  —  Unified forest-green theme for Zaraa
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  /// The single brand-green seed colour — derived from the logo.
  static const Color _seed = Color(0xFF2D7A50);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
          primary: _seed,
          onPrimary: Colors.white,
          secondary: const Color(0xFF52B788),
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: const Color(0xFF1A3C28),
          surfaceContainerHighest: const Color(0xFFEDF7F1),
          outline: const Color(0xFFD0EBD9),
          outlineVariant: const Color(0xFFE3F2E8),
          error: const Color(0xFFE53935),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4FAF6),

        // ── AppBar ─────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D7A50),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),

        // ── Navigation Bar ─────────────────────────────────────────────────
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2D7A50).withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF2D7A50),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF8AB89A),
              fontSize: 11,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF2D7A50), size: 24);
            }
            return const IconThemeData(color: Color(0xFF8AB89A), size: 24);
          }),
        ),

        // ── Elevated Button ────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D7A50),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // ── Text Button ────────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2D7A50),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        // ── Outlined Button ────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2D7A50),
            side: const BorderSide(color: Color(0xFF2D7A50), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        // ── Input Fields ───────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4FAF6),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          labelStyle:
              const TextStyle(color: Color(0xFF8AB89A), fontSize: 13),
          hintStyle: TextStyle(
              color: const Color(0xFF8AB89A).withOpacity(0.7), fontSize: 13),
          prefixIconColor: const Color(0xFF8AB89A),
          suffixIconColor: const Color(0xFF8AB89A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0EBD9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD0EBD9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF2D7A50), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFE53935), width: 1.8),
          ),
          errorStyle: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),

        // ── Card ───────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE3F2E8)),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Chip ───────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFEDF7F1),
          selectedColor: const Color(0xFF2D7A50),
          labelStyle: const TextStyle(fontSize: 13),
          side: const BorderSide(color: Color(0xFFD0EBD9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // ── Divider ────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE3F2E8),
          thickness: 1,
        ),

        fontFamily: 'Poppins',
      );
}
