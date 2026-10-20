import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A); // Deep black (KRIVA brand)
  static const Color surface = Color(0xFF141414);    // Card surface
  static const Color surfaceLight = Color(0xFF1E1E1E); // Light surface accent
  static const Color border = Color(0xFF2A2A2A);     // Border outline

  // ── Brand / Accents (KRIVA Red + Black) ─────────────────────────────────
  static const Color primary = Color(0xFFE53935);    // KRIVA Red
  static const Color primaryDark = Color(0xFFB71C1C); // Deep red
  static const Color primaryLight = Color(0xFFFF6659); // Light red
  static const Color secondary = Color(0xFFFF8A80);  // Soft coral
  static const Color accent = Color(0xFFFF6D00);     // Orange-red accent (streaks)

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);    // Neon green
  static const Color error = Color(0xFFFF1744);      // Error red
  static const Color info = Color(0xFF40C4FF);       // Bright blue

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);   // Off-white
  static const Color textSecondary = Color(0xFFAAAAAA); // Muted grey
  static const Color textMuted = Color(0xFF666666);     // Disabled grey

  // ── Gradients ─────────────────────────────────────────────────────────────

  /// Main KRIVA brand gradient — deep black to KRIVA red
  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Radial glow effect behind logo / hero areas
  static const Gradient heroGradient = LinearGradient(
    colors: [Color(0xFF2D0000), Color(0xFF0A0A0A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Card glass shimmer
  static const Gradient glassGradient = LinearGradient(
    colors: [Color(0x22FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Red to dark diagonal — for stat cards
  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A0000), Color(0xFF141414)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent orange gradient — for streak / fire
  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Progress / domain cyan gradient
  static const Gradient cyanGradient = LinearGradient(
    colors: [Color(0xFF40C4FF), Color(0xFF00B0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bottom nav bar background gradient
  static const Gradient navGradient = LinearGradient(
    colors: [Color(0xFF0F0F0F), Color(0xFF1A0000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
