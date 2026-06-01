import 'package:flutter/material.dart';

/// 레지오 활동보고 — 따뜻한 크림·테라코타 톤
abstract final class AppColors {
  // Base surfaces
  static const background = Color(0xFFFAF6F0);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceElevated = Color(0xFFF5EFE6);
  static const inputBackground = Color(0xFFF3EDE4);

  // Brand accent — 테라코타·코랄
  static const accent = Color(0xFFD4694A);
  static const accentMuted = Color(0xFFB85A42);
  static const accentSoft = Color(0xFFFCEEE8);
  static const onAccent = Color(0xFFFFFCF8);

  // Typography
  static const textPrimary = Color(0xFF3A2F26);
  static const textSecondary = Color(0xFF6D5F52);
  static const textMuted = Color(0xFFA09082);

  // Lines & states
  static const border = Color(0xFFE5DACE);
  static const borderSubtle = Color(0xFFEDE6DC);
  static const destructive = Color(0xFFD95547);

  // Highlight cards (활동상세 요약 등)
  static const headerSurface = Color(0xFFF0E6D8);
  static const headerTextMuted = Color(0xFF7D6B58);
  static const headerHighlight = Color(0xFFC75B3B);

  // Charts
  static const chartPrayer = Color(0xFFD4694A);
  static const chartService = Color(0xFF5F9170);
  static const chartVisit = Color(0xFFE09B5A);
  static const chartMeeting = Color(0xFF7A8BB5);
  static const chartOther = Color(0xFFA89888);

  // Calendar
  static const burgundy = Color(0xFF9B4D3A);
  static const burgundyDark = Color(0xFF7A3D2E);
  static const gold = Color(0xFFD4694A);
  static const goldMuted = Color(0xFFF0D4C4);
  static const cream = Color(0xFFFAF6F0);
  static const parchment = Color(0xFFFFFCF8);
  static const ink = Color(0xFF3A2F26);
  static const inkMuted = Color(0xFF6D5F52);
  static const divider = Color(0xFFE8DFD4);
  static const cardBorder = Color(0xFFE5DACE);

  static Color get shadow => const Color(0xFF3A2F26).withValues(alpha: 0.08);
}
