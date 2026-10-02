import 'package:flutter/material.dart';

/// Design token constants for the Synapse AI Slate dark theme matching Stitch design.
abstract final class AppColors {
  // ── Stitch Base Canvas & Surfaces ───────────────────────────────────────
  static const Color background = Color(0xFF121318);
  static const Color canvasBase = Color(0xFF090A0F);
  static const Color surface = Color(0xFF121318);
  static const Color surfaceContainerLowest = Color(0xFF0D0E13);
  static const Color surfaceContainerLow = Color(0xFF16181F);
  static const Color surfaceContainer = Color(0xFF1E1F25);
  static const Color surfaceContainerHigh = Color(0xFF292A2F);
  static const Color surfaceContainerHighest = Color(0xFF34343A);
  static const Color surfaceBright = Color(0xFF38393F);
  static const Color surfaceVariant = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF243044);

  // ── Accent & Primaries (Electric / Cobalt Blue) ──────────────────────────
  static const Color accent = Color(0xFF2563EB);         // Deep crisp blue
  static const Color primary = Color(0xFF3B82F6);        // Electric blue CTA
  static const Color primaryTint = Color(0xFFADC6FF);    // Soft highlight blue
  static const Color primaryContainer = Color(0xFF4D8EFF);
  static const Color onPrimary = Color(0xFF002E6A);
  static const Color onPrimaryContainer = Color(0xFF00285D);
  static const Color accentLight = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF1D4ED8);
  static const Color accentGlow = Color(0x262563EB);

  // ── Secondary Neutral ────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFC3C6D5);
  static const Color secondaryContainer = Color(0xFF434653);
  static const Color onSecondaryContainer = Color(0xFFB1B4C3);

  // ── Semantic Badges ───────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF4EDEA3);       // Stitch Emerald
  static const Color tertiaryFixedDim = Color(0xFF4EDEA3);
  static const Color success = Color(0xFF10B981);         // Emerald
  static const Color warning = Color(0xFFF59E0B);         // Amber Ochre
  static const Color warningText = Color(0xFFFCD34D);     // Amber 300
  static const Color danger = Color(0xFFEF4444);          // Ruby Crimson
  static const Color dangerDeep = Color(0xFFDC2626);
  static const Color error = Color(0xFFEF4444);
  static const Color errorTint = Color(0xFFFFB4AB);

  // ── Text Hierarchy ────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE3E1E9);     // Crisp chalk
  static const Color textSecondary = Color(0xFFC2C6D6);   // Slate graphite
  static const Color textMuted = Color(0xFF8C909F);       // Deep muted iron / outline
  static const Color outline = Color(0xFF8C909F);
  static const Color outlineVariant = Color(0xFF424754);

  // ── UI Chrome ─────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF1E222D);          // Clean 1px card borders
  static const Color borderSubtle = Color(0x14FFFFFF);    // white/[0.08]

  // ── Shimmer Skeleton ──────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFF111827);
  static const Color shimmerHighlight = Color(0xFF1E293B);

  // ── Gradients ─────────────────────────────────────────────────────────────
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
