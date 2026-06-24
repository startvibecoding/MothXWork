import 'package:flutter/material.dart';

/// App color palette, mirroring the Apple-style CSS variables in index.css.
class AppColors {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color elevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent; // accent-blue
  final Color accentGreen;
  final Color accentRed;
  final Color accentOrange;
  final Color accentYellow;
  final Color accentPurple;
  final Color separator;
  final Color fill;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentGreen,
    required this.accentRed,
    required this.accentOrange,
    required this.accentYellow,
    required this.accentPurple,
    required this.separator,
    required this.fill,
  });

  static const dark = AppColors(
    primary: Color(0xFF1C1C1E),
    secondary: Color(0xFF2C2C2E),
    tertiary: Color(0xFF3A3A3C),
    elevated: Color(0xFF48484A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF8E8E93),
    textTertiary: Color(0xFF636366),
    accent: Color(0xFF007AFF),
    accentGreen: Color(0xFF34C759),
    accentRed: Color(0xFFFF3B30),
    accentOrange: Color(0xFFFF9500),
    accentYellow: Color(0xFFFFCC00),
    accentPurple: Color(0xFFAF52DE),
    separator: Color(0xFF38383A),
    fill: Color(0xFF767680),
  );

  static const light = AppColors(
    primary: Color(0xFFFFFFFF),
    secondary: Color(0xFFF5F5F7),
    tertiary: Color(0xFFE8E8ED),
    elevated: Color(0xFFD2D2D7),
    textPrimary: Color(0xFF1D1D1F),
    textSecondary: Color(0xFF86868B),
    textTertiary: Color(0xFFAEAEB2),
    accent: Color(0xFF007AFF),
    accentGreen: Color(0xFF34C759),
    accentRed: Color(0xFFFF3B30),
    accentOrange: Color(0xFFFF9500),
    accentYellow: Color(0xFFFFCC00),
    accentPurple: Color(0xFFAF52DE),
    separator: Color(0xFFD2D2D7),
    fill: Color(0xFFC7C7CC),
  );
}

/// InheritedWidget to expose [AppColors] down the tree.
class AppTheme extends InheritedWidget {
  final AppColors colors;
  final bool isDark;

  const AppTheme({
    super.key,
    required this.colors,
    required this.isDark,
    required super.child,
  });

  static AppColors of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return theme?.colors ?? AppColors.dark;
  }

  static bool isDarkOf(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return theme?.isDark ?? true;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) =>
      oldWidget.isDark != isDark;
}
