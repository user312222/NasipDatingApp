import 'package:flutter/material.dart';

/// Vivid two-color pairs so a person's illustration reads as energetic and
/// two people next to each other in a list look clearly different. Keyed by
/// the `avatarColorSeed` every feature already carries, so the same person
/// gets the same colors on the discovery card, the match celebration, the
/// matches list and in chat - without those features importing each other.
/// No green on purpose (see docs/REQUIREMENTS.md section 6).
abstract final class AvatarPalette {
  static const _pairs = [
    [Color(0xFF7A2C8F), Color(0xFFE84A70)], // plum -> coral
    [Color(0xFFF0567A), Color(0xFFF5A742)], // coral -> amber
    [Color(0xFF4B45B5), Color(0xFFB455CC)], // indigo -> orchid
    [Color(0xFFE0457B), Color(0xFF8B3FD1)], // magenta -> violet
    [Color(0xFFF28A5B), Color(0xFFE84A70)], // peach -> coral
    [Color(0xFF3F6BD8), Color(0xFF8C5CF0)], // blue -> lavender
  ];

  static int get count => _pairs.length;

  static List<Color> forSeed(int seed) => _pairs[seed % _pairs.length];
}
