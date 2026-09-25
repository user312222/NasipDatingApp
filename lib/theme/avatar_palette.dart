import 'package:flutter/material.dart';

/// Vivid two-color pairs (rather than one color darkened toward black) so
/// a person's illustration reads as energetic/contemporary. Keyed by the
/// `avatarColorSeed` every feature already carries, so the same person gets
/// the same colors on the discovery card, the match celebration, the
/// matches list and in chat — without those features importing each other.
abstract final class AvatarPalette {
  static const _pairs = [
    [Color(0xFF8A3F80), Color(0xFFD9A15C)], // plum -> warm brass-rose
    [Color(0xFFDDA646), Color(0xFF8A3F80)], // brass -> plum
    [Color(0xFFD2897D), Color(0xFF9C4590)], // rose -> plum-pink
    [Color(0xFF9C4590), Color(0xFFD9A15C)], // plum-pink -> brass
  ];

  static List<Color> forSeed(int seed) => _pairs[seed % _pairs.length];
}
