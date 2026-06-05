// ─────────────────────────────────────────────────────────────────────────────
// app/core/theme/app_colors.dart
// Extracted from Stitch Project 1654352290469224973
// Design System: "The Reassurance Framework" / "The Digital Guardian"
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand / Primary ────────────────────────────────────────────────────────
  static const Color primary             = Color(0xFF003D9B);
  static const Color primaryContainer    = Color(0xFF0052CC);
  static const Color onPrimary           = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer  = Color(0xFFC4D2FF);
  static const Color primaryFixed        = Color(0xFFDAE2FF);
  static const Color primaryFixedDim     = Color(0xFFB2C5FF);
  static const Color onPrimaryFixed      = Color(0xFF001848);
  static const Color onPrimaryFixedVar   = Color(0xFF0040A2);

  // ── Secondary ──────────────────────────────────────────────────────────────
  static const Color secondary           = Color(0xFF4C5D8D);
  static const Color secondaryContainer  = Color(0xFFB6C8FE);
  static const Color onSecondary         = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer= Color(0xFF415382);
  static const Color secondaryFixed      = Color(0xFFDAE2FF);
  static const Color secondaryFixedDim   = Color(0xFFB4C5FB);
  static const Color onSecondaryFixed    = Color(0xFF021945);
  static const Color onSecondaryFixedVar = Color(0xFF344573);

  // ── Tertiary (Green = Safe) ────────────────────────────────────────────────
  static const Color tertiary            = Color(0xFF004E32);
  static const Color tertiaryContainer   = Color(0xFF006844);
  static const Color onTertiary          = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF72E9AF);
  static const Color tertiaryFixed       = Color(0xFF82F9BE);
  static const Color tertiaryFixedDim    = Color(0xFF65DCA4);
  static const Color onTertiaryFixed     = Color(0xFF002113);
  static const Color onTertiaryFixedVar  = Color(0xFF005235);

  // ── Surface / Background ───────────────────────────────────────────────────
  static const Color background          = Color(0xFFF8F9FB);
  static const Color surface            = Color(0xFFF8F9FB);
  static const Color surfaceDim         = Color(0xFFD9DADC);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFF3F4F6);
  static const Color surfaceContainer        = Color(0xFFEDEEF0);
  static const Color surfaceContainerHigh    = Color(0xFFE7E8EA);
  static const Color surfaceContainerHighest = Color(0xFFE1E2E4);
  static const Color surfaceVariant          = Color(0xFFE1E2E4);
  static const Color surfaceTint             = Color(0xFF0C56D0);

  // ── On-Surface ─────────────────────────────────────────────────────────────
  static const Color onBackground        = Color(0xFF191C1E);
  static const Color onSurface          = Color(0xFF191C1E);
  static const Color onSurfaceVariant   = Color(0xFF434654);
  static const Color inverseSurface     = Color(0xFF2E3132);
  static const Color inverseOnSurface   = Color(0xFFF0F1F3);
  static const Color inversePrimary     = Color(0xFFB2C5FF);

  // ── Utility ────────────────────────────────────────────────────────────────
  static const Color outline            = Color(0xFF737685);
  static const Color outlineVariant     = Color(0xFFC3C6D6);
  static const Color error              = Color(0xFFBA1A1A);
  static const Color errorContainer     = Color(0xFFFFDAD6);
  static const Color onError            = Color(0xFFFFFFFF);
  static const Color onErrorContainer   = Color(0xFF93000A);

  // ── Gradient helpers ───────────────────────────────────────────────────────
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  static const LinearGradient gradientHero = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF001848), Color(0xFF003D9B), Color(0xFF0052CC)],
    stops: [0.0, 0.45, 1.0],
  );
}
