import 'package:flutter/material.dart';
import 'theme_controller.dart';

class AppColorScheme {
  final Color primary;
  final Color primarySoft;
  final Color black;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color border;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;

  const AppColorScheme({
    required this.primary,
    required this.primarySoft,
    required this.black,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.border,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
  });
}

class AppColors {
  static const light = AppColorScheme(
    primary: Color(0xFFF9D649),
    primarySoft: Color(0xFFFFF4B8),
    black: Color(0xFF111111),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B7280),
    textMuted: Color(0xFF9CA3AF),
    background: Color(0xFFF9F9F9),
    surface: Color(0xFFFFFFFF),
    surfaceSoft: Color(0xFFF3F4F6),
    border: Color(0xFFE5E7EB),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    shadow: Color(0x11000000),
  );

  static const dark = AppColorScheme(
    primary: Color(0xFFF9D649),
    primarySoft: Color(0xFF3A330B),
    black: Color(0xFF111111),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFFC7CBD1),
    textMuted: Color(0xFF9AA0A6),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceSoft: Color(0xFF2A2A2A),
    border: Color(0xFF2F2F2F),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFEF4444),
    shadow: Color(0x00000000),
  );

  static bool get _isDark => ThemeController.instance.isDark;
  static AppColorScheme get _scheme => _isDark ? dark : light;

  static Color get primary => _scheme.primary;
  static Color get primarySoft => _scheme.primarySoft;
  static Color get black => _scheme.black;
  static Color get textPrimary => _scheme.textPrimary;
  static Color get textSecondary => _scheme.textSecondary;
  static Color get textMuted => _scheme.textMuted;
  static Color get background => _scheme.background;
  static Color get surface => _scheme.surface;
  static Color get surfaceSoft => _scheme.surfaceSoft;
  static Color get border => _scheme.border;
  static Color get success => _scheme.success;
  static Color get warning => _scheme.warning;
  static Color get danger => _scheme.danger;
  static Color get shadow => _scheme.shadow;
}
