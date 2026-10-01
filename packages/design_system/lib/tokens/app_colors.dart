import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent Brand Colors
  static const Color primary = Color(0xFF2563EB); // Vibrant Electric Indigo
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySubtle = Color(0xFFEFF6FF);

  // Status Colors
  static const Color liveGreen = Color(0xFF10B981); // Emerald Live Status
  static const Color liveGreenDark = Color(0xFF047857);
  static const Color liveGreenSubtle = Color(0xFFECFDF5);

  static const Color recentAmber = Color(0xFFF59E0B); // Amber Recent Status
  static const Color recentAmberSubtle = Color(0xFFFFFBEB);

  static const Color staleOrange = Color(0xFFF97316); // Stale Status
  static const Color staleOrangeSubtle = Color(0xFFFFF7ED);

  static const Color offlineRose = Color(0xFFEF4444); // Red/Rose Offline
  static const Color offlineRoseSubtle = Color(0xFFFEF2F2);

  // Light Theme Surfaces & Grays (Slate scale)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Dark Theme Surfaces & Grays
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF131B2E);
  static const Color surfaceElevatedDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF243048);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Glassmorphism Tint Colors
  static const Color glassWhite = Color(0x99FFFFFF);
  static const Color glassBorderWhite = Color(0x66FFFFFF);
  static const Color glassDark = Color(0x99131B2E);
  static const Color glassBorderDark = Color(0x3338BDF8);

  // Card Glow / Shadow Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF2563EB),
    Color(0xFF1D4ED8),
  ];

  static const List<Color> liveGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> dutyGradient = [
    Color(0xFF3B82F6),
    Color(0xFF1E40AF),
  ];
}
