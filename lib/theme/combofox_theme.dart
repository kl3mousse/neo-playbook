import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// ComboFox Design System — Arcade OS Theme
// Neon arcade / retro-futuristic with pixel influences
// ═══════════════════════════════════════════════════════════════

class ComboFoxColors {
  ComboFoxColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const surfaceElevated = Color(0xFF1A1A24);

  // ── Neon Palette ─────────────────────────────────────────────
  static const neonPurple = Color(0xFFA855F7);
  static const neonPink = Color(0xFFFF4FD8);
  static const neonBlue = Color(0xFF22D3EE);

  // ── Platform Accent Colors ───────────────────────────────────
  static const cps1 = Color(0xFF3B82F6);
  static const cps2 = Color(0xFFF97316);
  static const neogeo = Color(0xFFEF4444);

  // ── Text ─────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
}

// ── Effects helpers ───────────────────────────────────────────

/// Neon glow BoxShadow with the given color.
BoxShadow neonGlow(Color color) => BoxShadow(
  color: color.withValues(alpha: 0.6),
  blurRadius: 12,
  spreadRadius: 1,
);

/// Neon-bordered BoxDecoration with glow. Use `.copyWith(color: ...)` to add
/// a fill color.
BoxDecoration neonBorder(Color color) => BoxDecoration(
  border: Border.all(color: color, width: 1.5),
  borderRadius: BorderRadius.circular(12),
  boxShadow: [neonGlow(color)],
);
