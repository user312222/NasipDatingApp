import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Named type-scale styles matching the text styles defined in the
/// `binasip` Figma file (page "🎨 Foundations", styles prefixed
/// `Bi Nasip/...`). Colorless on purpose — [AppTheme] applies ink colors
/// per-brightness when it builds each [TextTheme].
abstract final class AppTextStyles {
  static TextStyle get displayLarge =>
      GoogleFonts.fraunces(fontSize: 34, fontWeight: FontWeight.w600, height: 1.16);

  static TextStyle get displayHeadline =>
      GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get titleLarge =>
      GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w600, height: 1.28);

  static TextStyle get titleSmall =>
      GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get bodyLarge =>
      GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6);

  static TextStyle get bodyDefault =>
      GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55);

  static TextStyle get labelCaption => GoogleFonts.sora(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 12 * 0.04,
  );

  static TextStyle get button =>
      GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);

  /// Decorative Arabic accent face — brand moments only (e.g. a splash
  /// screen mark), never for functional/UI text.
  static TextStyle get accentArabic =>
      GoogleFonts.arefRuqaa(fontSize: 22, fontWeight: FontWeight.w400, height: 1.3);
}
