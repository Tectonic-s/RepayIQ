import 'package:flutter/material.dart';

/// Theme-aware text colour helpers.
/// Use these instead of hardcoded AppColors.textPrimary/Secondary/Hint
/// so colours automatically adapt to light and dark mode.
extension ThemeText on BuildContext {
  /// Primary text — white in dark, near-black in light
  Color get textPrimary => Theme.of(this).colorScheme.onSurface;

  /// Secondary / label text — 55% opacity of onSurface
  Color get textSecondary =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.55);

  /// Hint / muted text — 38% opacity of onSurface
  Color get textHint =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.38);

  /// Card background
  Color get cardColor =>
      Theme.of(this).cardTheme.color ?? Theme.of(this).colorScheme.surface;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
