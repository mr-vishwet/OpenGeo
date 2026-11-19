import 'package:flutter/material.dart';

/// Design tokens transcribed from the OpenGeo design reference screens.
///
/// One accent (blue), one surface ramp, one radius scale, one type scale.
/// Nothing here is a Flutter default.
class AppColors {
  // ── Accent ────────────────────────────────────────────────────────────
  static const primary = Color(0xFF1A73E8);
  static const primaryPressed = Color(0xFF1557B0);
  static const primarySoft = Color(0xFFE8F0FE);
  static const onPrimary = Color(0xFFFFFFFF);

  // ── Brand (splash / footer) ───────────────────────────────────────────
  static const navyTop = Color(0xFF0A2E55);
  static const navyMid = Color(0xFF06203E);
  static const navyBottom = Color(0xFF03101F);
  static const brandGlow = Color(0xFF2E9BFF);

  // ── Surfaces ──────────────────────────────────────────────────────────
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF5F7FA);
  static const surfaceSunken = Color(0xFFEDF1F6);
  static const outline = Color(0xFFE3E7EC);

  // ── Text ──────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF15181D);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);

  // ── Semantic ──────────────────────────────────────────────────────────
  static const success = Color(0xFF1E9E6A);
  static const warning = Color(0xFFF5A524);
  static const danger = Color(0xFFE5484D);
  static const star = Color(0xFFF5B301);

  // ── Mode accents ──────────────────────────────────────────────────────
  static const modeRealtime = Color(0xFF1E9E6A);
  static const modeEssential = Color(0xFFEA4C5B);
  static const modeIntelligence = Color(0xFF7B4DFF);
  static const modeSpatial = Color(0xFF1D3E8F);
  static const modeCustom = Color(0xFF1A73E8);

  // ── Dark appearance ───────────────────────────────────────────────────
  static const darkSurface = Color(0xFF0E1116);
  static const darkSurfaceAlt = Color(0xFF161A21);
  static const darkSurfaceSunken = Color(0xFF1D222B);
  static const darkOutline = Color(0xFF262C36);
  static const darkTextPrimary = Color(0xFFF2F4F7);
  static const darkTextSecondary = Color(0xFF98A2B3);
  static const darkPrimary = Color(0xFF4C8DFF);
}

/// 4pt spacing rhythm.
class S {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// Radius scale: 8 chips, 12 inputs, 16 cards, 24 sheets, pill.
class R {
  static const chip = 8.0;
  static const input = 12.0;
  static const card = 16.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const float = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 6)),
  ];
}

class AppTheme {
  static TextTheme _text(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(fontSize: 34, height: 1.15, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.6),
      displayMedium: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.4),
      displaySmall: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w600, color: primary),
      titleLarge: TextStyle(fontSize: 17, height: 1.3, fontWeight: FontWeight.w600, color: primary),
      titleMedium: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600, color: primary),
      titleSmall: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w600, color: primary),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w400, color: primary),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w400, color: secondary),
      labelLarge: TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w500, color: secondary),
    );
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        surface: AppColors.surface,
        surfaceAlt: AppColors.surfaceAlt,
        outline: AppColors.outline,
        text: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        surfaceAlt: AppColors.darkSurfaceAlt,
        outline: AppColors.darkOutline,
        text: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        primary: AppColors.darkPrimary,
        onPrimary: const Color(0xFF0B1220),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color surfaceAlt,
    required Color outline,
    required Color text,
    required Color textSecondary,
    required Color primary,
    required Color onPrimary,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: brightness == Brightness.light
          ? AppColors.primarySoft
          : const Color(0xFF12233D),
      onPrimaryContainer: primary,
      secondary: AppColors.success,
      onSecondary: onPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: surfaceAlt,
      onSurfaceVariant: textSecondary,
      outline: outline,
      outlineVariant: outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      textTheme: _text(text, textSecondary),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: _text(text, textSecondary).headlineSmall,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: _text(text, textSecondary).labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.input)),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: _text(text, textSecondary).bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: S.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.input),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.input),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(R.input),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(R.card),
          side: BorderSide(color: outline),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(R.sheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: _text(surface, surface).bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.input)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? primary : textSecondary,
          );
        }),
      ),
    );
  }
}
