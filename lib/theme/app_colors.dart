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
    required this.accent,
    required this.teal,
    required this.tealTint,
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

  /// The warm end of the brand gradient (plumFill -> accent) and the
  /// one "look here" color: unread dots, live highlights. Carries white
  /// text only at button weight/size.
  final Color accent;

  /// The teal of the logo's heart - the second brand color, used where
  /// plum would be too heavy: secondary links, location pins, one of the
  /// backdrop glows. [brass] is the logo's copper.
  final Color teal;
  final Color tealTint;
  final Color brass;
  final Color brassTint;
  final Color rose;
  final Color roseSoft;
  final Color line;

  static const light = AppColors(
    bg: Color(0xFFFBF6F1),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF24122B),
    inkSoft: Color(0xFF6B5670),
    plum: Color(0xFF7A2C8F),
    plumStrong: Color(0xFF2E1238),
    plumTint: Color(0xFFF4E6F7),
    plumFill: Color(0xFF7A2C8F),
    accent: Color(0xFFE84A70),
    teal: Color(0xFF257A8F),
    tealTint: Color(0xFFDDF0F4),
    brass: Color(0xFFB4703A),
    brassTint: Color(0xFFF8E7D6),
    rose: Color(0xFFD9506B),
    roseSoft: Color(0xFFFBE1E6),
    line: Color(0xFFEBDFEA),
  );

  static const dark = AppColors(
    bg: Color(0xFF1A0F1C),
    surface: Color(0xFF241530),
    ink: Color(0xFFF3EAE7),
    inkSoft: Color(0xFFB9A4B1),
    plum: Color(0xFFC495BC),
    plumStrong: Color(0xFFE3C3DC),
    plumTint: Color(0xFF2E1B33),
    plumFill: Color(0xFF8A3BA0),
    accent: Color(0xFFF0668A),
    teal: Color(0xFF74C4D6),
    tealTint: Color(0xFF16313A),
    brass: Color(0xFFE2A873),
    brassTint: Color(0xFF3A2616),
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
    Color? accent,
    Color? teal,
    Color? tealTint,
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
      accent: accent ?? this.accent,
      teal: teal ?? this.teal,
      tealTint: tealTint ?? this.tealTint,
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
      accent: Color.lerp(accent, other.accent, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealTint: Color.lerp(tealTint, other.tealTint, t)!,
      brass: Color.lerp(brass, other.brass, t)!,
      brassTint: Color.lerp(brassTint, other.brassTint, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      roseSoft: Color.lerp(roseSoft, other.roseSoft, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

/// The brand gradient every primary surface shares (buttons, own chat
/// bubbles, badges): `colors.brandGradient`.
extension AppColorsGradients on AppColors {
  List<Color> get brandGradient => [plumFill, accent];
}

/// Shorthand: `context.colors.plum`.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
