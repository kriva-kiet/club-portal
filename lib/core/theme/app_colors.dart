import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0B0F19); // Obsidian Blue-Grey
  static const Color surface = Color(0xFF161F30); // Card Surface
  static const Color surfaceLight = Color(0xFF222F47); // Light Surface Accent
  static const Color border = Color(0xFF1F2E47); // Border Outline

  // Brand / Accents
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color secondary = Color(0xFF06B6D4); // Glowing Cyan
  static const Color accent = Color(0xFFF59E0B); // Warm Amber (for Streaks)

  // Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color error = Color(0xFFEF4444); // Soft Coral Red
  static const Color info = Color(0xFF3B82F6); // Bright Blue

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Off-white
  static const Color textSecondary = Color(0xFF94A3B8); // Cool Grey
  static const Color textMuted = Color(0xFF64748B); // Muted/Disabled Grey

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cyanGradient = LinearGradient(
    colors: [secondary, Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
