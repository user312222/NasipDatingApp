import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the app's light and dark [ThemeData] from the Bi Nasip design
/// tokens ("Gece Moru" palette + Fraunces/Sora type scale — see
/// `docs/REQUIREMENTS.md` §6 and the `binasip` Figma file's
/// "🎨 Foundations" page).
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.plum,
      onPrimary: colors.bg,
      primaryContainer: colors.plumTint,
      onPrimaryContainer: colors.plumStrong,
      secondary: colors.brass,
      onSecondary: colors.plumStrong,
      secondaryContainer: colors.brassTint,
      onSecondaryContainer: colors.plumStrong,
      tertiary: colors.rose,
      onTertiary: colors.surface,
      tertiaryContainer: colors.roseSoft,
      onTertiaryContainer: colors.plumStrong,
      error: isLight ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
      onError: isLight ? Colors.white : const Color(0xFF601410),
      errorContainer: isLight
          ? const Color(0xFFF9DEDC)
          : const Color(0xFF8C1D18),
      onErrorContainer: isLight
          ? const Color(0xFF410E0B)
          : const Color(0xFFF9DEDC),
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.plumTint,
      onSurfaceVariant: colors.inkSoft,
      outline: colors.inkSoft,
      outlineVariant: colors.line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: colors.plumStrong,
      onInverseSurface: colors.bg,
      inversePrimary: colors.plumTint,
    );

    final baseTextTheme = GoogleFonts.soraTextTheme(
      isLight
          ? Typography.material2021().black
          : Typography.material2021().white,
    );

    final textTheme = baseTextTheme
        .copyWith(
          displayLarge: AppTextStyles.displayLarge,
          displayMedium: AppTextStyles.displayHeadline,
          headlineLarge: AppTextStyles.displayHeadline,
          headlineMedium: AppTextStyles.displayHeadline,
          titleLarge: AppTextStyles.titleLarge,
          titleMedium: AppTextStyles.titleSmall,
          titleSmall: AppTextStyles.titleSmall,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyDefault,
          labelLarge: AppTextStyles.button,
          labelSmall: AppTextStyles.labelCaption,
        )
        .apply(bodyColor: colors.ink, displayColor: colors.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.bg,
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.ink,
        elevation: 0,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: colors.ink),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.plum,
          foregroundColor: colors.bg,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: colors.brass),
        ),
        labelStyle: AppTextStyles.labelCaption.copyWith(color: colors.inkSoft),
      ),
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
