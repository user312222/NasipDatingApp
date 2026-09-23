import 'package:flutter/material.dart';

/// A soft crescent (hilal) motif — unmistakably Turkish/Islamic visual
/// vocabulary (REQUIREMENTS.md's icon notes: "yıldız/hilal/kemer/fener")
/// without any resemblance to an unrelated religious symbol. Drawn as one
/// filled circle with a second, offset circle cut out of it (even-odd fill).
/// Kept intentionally simple and low-opacity: it's a texture, not a focal
/// illustration — a real candidate photo (once photo upload exists) would
/// need this to stay out of the way rather than compete with it.
class CrescentMotifPainter extends CustomPainter {
  const CrescentMotifPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final bite = Offset(center.dx + radius * 0.5, center.dy - radius * 0.22);

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..addOval(Rect.fromCircle(center: bite, radius: radius * 0.86));

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CrescentMotifPainter oldDelegate) =>
      oldDelegate.color != color;
}
