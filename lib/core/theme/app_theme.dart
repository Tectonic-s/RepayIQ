import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color enabled,
    required Color hint,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: enabled),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.warning, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: hint, fontSize: 14),
      errorStyle: TextStyle(
        color: AppColors.warning.withValues(alpha: 0.85),
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      errorMaxLines: 2,
    );
  }

  // ── Light ──────────────────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFB2DFDB),
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2F1),
      onSecondaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.warning,
      onError: Colors.white,
      outline: Color(0xFFE5E7EB),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.darkSurface,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimary),
      displayMedium: TextStyle(color: AppColors.textPrimary),
      displaySmall: TextStyle(color: AppColors.textPrimary),
      headlineLarge: TextStyle(color: AppColors.textPrimary),
      headlineMedium: TextStyle(color: AppColors.textPrimary),
      headlineSmall: TextStyle(color: AppColors.textPrimary),
      titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: AppColors.textSecondary),
      bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      labelLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: AppColors.textSecondary),
      labelSmall: TextStyle(color: AppColors.textHint, fontSize: 11),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: _inputTheme(
      fill: AppColors.background,
      enabled: const Color(0xFFE5E7EB),
      hint: AppColors.textHint,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB), thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      titleTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
      contentTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontFamily: 'Roboto'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: AppColors.textHint, width: 1.5),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
    ),
    iconTheme: const IconThemeData(color: AppColors.textSecondary),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surface,
      textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
    ),
  );

  // ── Dark ───────────────────────────────────────────────────────────────────

  static const _darkText = Colors.white;
  static const _darkTextSub = Color(0xFFB0B7C3);
  static const _darkTextHint = Color(0xFF6B7280);
  static const _darkBorder = Color(0xFF374151);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF004D40),
      onPrimaryContainer: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1A3A38),
      onSecondaryContainer: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: _darkText,
      error: AppColors.warning,
      onError: Colors.white,
      outline: _darkBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: _darkText),
      displayMedium: TextStyle(color: _darkText),
      displaySmall: TextStyle(color: _darkText),
      headlineLarge: TextStyle(color: _darkText),
      headlineMedium: TextStyle(color: _darkText),
      headlineSmall: TextStyle(color: _darkText),
      titleLarge: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _darkText, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: _darkTextSub),
      bodyLarge: TextStyle(color: _darkText, fontSize: 15),
      bodyMedium: TextStyle(color: _darkText, fontSize: 14),
      bodySmall: TextStyle(color: _darkTextSub, fontSize: 12),
      labelLarge: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: _darkTextSub),
      labelSmall: TextStyle(color: _darkTextHint, fontSize: 11),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: _darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: _darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(color: _darkText),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: _inputTheme(
      fill: AppColors.darkCard,
      enabled: _darkBorder,
      hint: _darkTextHint,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.primary),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _darkBorder, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      titleTextStyle: const TextStyle(color: _darkText, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Roboto'),
      contentTextStyle: const TextStyle(color: _darkTextSub, fontSize: 14, fontFamily: 'Roboto'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkCard,
      contentTextStyle: const TextStyle(color: _darkText, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: const BorderSide(color: _darkTextHint, width: 1.5),
    ),
    listTileTheme: const ListTileThemeData(
      textColor: _darkText,
      iconColor: _darkTextSub,
    ),
    iconTheme: const IconThemeData(color: _darkTextSub),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.darkCard,
      textStyle: TextStyle(color: _darkText, fontSize: 14),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      textStyle: TextStyle(color: _darkText, fontSize: 14),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: Color(0xFF004D40),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: _darkText, fontSize: 10)),
    ),
  );
}
