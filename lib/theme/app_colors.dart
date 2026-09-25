import 'package:flutter/material.dart';

/// Brand color tokens that don't map cleanly onto Material's [ColorScheme]
/// slots. Mirrors the "Gece Moru" palette defined in the `binasip` Figma
/// file (page "🎨 Foundations", collections `Color / Light` and
/// `Color / Dark`) and the Bi Nasip landing page CSS custom properties.
///
/// Access via `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.plum,
    required this.plumStrong,
    required this.plumTint,
    required this.plumFill,
    required this.brass,
    required this.brassTint,
    required this.rose,
    required this.roseSoft,
    required this.line,
  });

  final Color bg;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color plum;
  final Color plumStrong;
  final Color plumTint;

  /// A plum that stays dark enough to carry white text in both themes
  /// (`plum` itself turns light pink in dark mode) — use for filled
  /// buttons, badges and gradients with white content on top.
  final Color plumFill;
  final Color brass;
  final Color brassTint;
  final Color rose;
  final Color roseSoft;
  final Color line;

  static const light = AppColors(
    bg: Color(0xFFF6F1EA),
    surface: Color(0xFFFCF9F5),
    ink: Color(0xFF2A1B2A),
    inkSoft: Color(0xFF6E5B6C),
    plum: Color(0xFF5B2C55),
    plumStrong: Color(0xFF331A38),
    plumTint: Color(0xFFEFE1EA),
    plumFill: Color(0xFF5B2C55),
    brass: Color(0xFFB8863F),
    brassTint: Color(0xFFF1E3C4),
    rose: Color(0xFFA9726B),
    roseSoft: Color(0xFFEAD7D2),
    line: Color(0xFFE4D9DD),
  );

  static const dark = AppColors(
    bg: Color(0xFF1A0F1C),
    surface: Color(0xFF241530),
    ink: Color(0xFFF3EAE7),
    inkSoft: Color(0xFFB9A4B1),
    plum: Color(0xFFC495BC),
    plumStrong: Color(0xFFE3C3DC),
    plumTint: Color(0xFF2E1B33),
    plumFill: Color(0xFF7A3B71),
    brass: Color(0xFFE0BD7A),
    brassTint: Color(0xFF372A18),
    rose: Color(0xFFD9AFA8),
    roseSoft: Color(0xFF3B2422),
    line: Color(0xFF3D2E3B),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? inkSoft,
    Color? plum,
    Color? plumStrong,
    Color? plumTint,
    Color? plumFill,
    Color? brass,
    Color? brassTint,
    Color? rose,
    Color? roseSoft,
    Color? line,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      plum: plum ?? this.plum,
      plumStrong: plumStrong ?? this.plumStrong,
      plumTint: plumTint ?? this.plumTint,
      plumFill: plumFill ?? this.plumFill,
      brass: brass ?? this.brass,
      brassTint: brassTint ?? this.brassTint,
      rose: rose ?? this.rose,
      roseSoft: roseSoft ?? this.roseSoft,
      line: line ?? this.line,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
      plumStrong: Color.lerp(plumStrong, other.plumStrong, t)!,
      plumTint: Color.lerp(plumTint, other.plumTint, t)!,
      plumFill: Color.lerp(plumFill, other.plumFill, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      brassTint: Color.lerp(brassTint, other.brassTint, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

/// Shorthand: `context.colors.plum`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
