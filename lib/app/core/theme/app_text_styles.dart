// ─────────────────────────────────────────────────────────────────────────────
// app/core/theme/app_text_styles.dart
// Typography – Plus Jakarta Sans (display/headline) + Inter (body/label)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Display (Plus Jakarta Sans) ────────────────────────────────────────────
  static TextStyle displayLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 40, fontWeight: FontWeight.w800,
        color: color, letterSpacing: -0.5,
      );

  static TextStyle displayMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: color, letterSpacing: -0.3,
      );

  // ── Headline (Plus Jakarta Sans) ───────────────────────────────────────────
  static TextStyle headlineLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: color, letterSpacing: -0.2,
      );

  static TextStyle headlineMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: color,
      );

  // ── Title (Inter) ──────────────────────────────────────────────────────────
  static TextStyle titleLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: color,
      );

  static TextStyle titleMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: color,
      );

  static TextStyle titleSm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: color,
      );

  // ── Body (Inter) ───────────────────────────────────────────────────────────
  static TextStyle bodyLg({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: color);

  static TextStyle bodyMd({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  static TextStyle bodySm({Color color = AppColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  // ── Label (Inter) ──────────────────────────────────────────────────────────
  static TextStyle labelMd({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: color, letterSpacing: 0.08,
      );

  static TextStyle labelSm({Color color = AppColors.onSurfaceVariant}) =>
      GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: color, letterSpacing: 0.1,
      );
}
