import 'package:flutter/material.dart';

/// Vivid two-color pairs so a person's illustration reads as energetic and
/// two people next to each other in a list look clearly different. Keyed by
/// the `avatarColorSeed` every feature already carries, so the same person
/// gets the same colors on the discovery card, the match celebration, the
/// matches list and in chat - without those features importing each other.
/// Teal and copper come from the logo; no plain green (see
/// docs/REQUIREMENTS.md section 6).
abstract final class AvatarPalette {
  static const _pairs = [
    [Color(0xFF7A2C8F), Color(0xFFE84A70)], // plum -> coral
    [Color(0xFFC27A3E), Color(0xFFF5A742)], // copper -> amber
    [Color(0xFF2F8399), Color(0xFF4B45B5)], // teal -> indigo
    [Color(0xFFE0457B), Color(0xFF8B3FD1)], // magenta -> violet
    [Color(0xFF3B93A8), Color(0xFF7A2C8F)], // teal -> plum
    [Color(0xFFE84A70), Color(0xFFC27A3E)], // coral -> copper
  ];

  static int get count => _pairs.length;

  static List<Color> forSeed(int seed) => _pairs[seed % _pairs.length];
}
