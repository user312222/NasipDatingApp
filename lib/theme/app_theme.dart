import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'wizard_widgets.dart';

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
      // Transparent so each screen's backdrop glows run on behind the bar;
      // the back arrow is the same round chip as the other bar controls.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (context) =>
            const ChromeChip(icon: Icons.arrow_back_rounded, size: 38),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: AppTextStyles.displayHeadline.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: colors.plumStrong,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: colors.plumFill.withValues(alpha: 0.22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.plum,
          foregroundColor: colors.bg,
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.lerp(colors.surface, colors.plumTint, 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.plum, width: 1.5),
        ),
        labelStyle: AppTextStyles.labelCaption.copyWith(color: colors.inkSoft),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.line),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.plumStrong,
        contentTextStyle: AppTextStyles.bodyDefault.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        backgroundColor: colors.surface,
        selectedColor: colors.plumFill,
        side: BorderSide(color: colors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: AppTextStyles.bodyDefault.copyWith(
          color: colors.plumStrong,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: AppTextStyles.bodyDefault.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.plum,
        inactiveTrackColor: colors.line,
        thumbColor: colors.plum,
        overlayColor: colors.plum.withValues(alpha: 0.12),
        rangeThumbShape: const RoundRangeSliderThumbShape(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: AppTextStyles.displayHeadline.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colors.plumStrong,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
