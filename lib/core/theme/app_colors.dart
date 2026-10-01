import 'package:flutter/material.dart';

/// Design token constants for the Synapse AI Slate dark theme.
abstract final class AppColors {
  // ── Backgrounds (Deep Obsidian Slate) ────────────────────────────────────
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF243044);

  // ── Accent (High-Contrast Enterprise Cobalt Blue — NOT purple, NOT white) ──
  static const Color accent = Color(0xFF2563EB);         // Deep crisp blue
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF1D4ED8);
  static const Color accentGlow = Color(0x262563EB);      // Subtle 15% blue tint (no glare)

  // ── Semantic Badges ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);         // Emerald
  static const Color warning = Color(0xFFF59E0B);         // Amber
  static const Color danger = Color(0xFFEF4444);          // Red
  static const Color dangerDeep = Color(0xFFDC2626);

  // ── Text Hierarchy ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);     // 98% Crisp White
  static const Color textSecondary = Color(0xFF94A3B8);   // Muted Slate
  static const Color textMuted = Color(0xFF64748B);       // Subdued

  // ── UI Chrome ─────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF2D3B4E);          // Clean 1px card borders

  // ── Shimmer Skeleton ──────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF111827);
  static const Color shimmerHighlight = Color(0xFF1E293B);

  // ── Gradients (Solid Enterprise Depth — High Contrast for White Text) ─────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
