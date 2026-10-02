// Pads assets/images/logo.png onto a square white canvas so the icon
// generator doesn't stretch it. Run from the project root:
//   dart run tools/make_square_logo.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

void main() {
  const source = 'assets/images/logo.png';
  const target = 'assets/branding/logo_square.png';
  const size = 1024;
  const margin = 0.08;

  final logo = img.decodePng(File(source).readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not read $source');
    exit(1);
  }

  final available = (size * (1 - 2 * margin)).round();
  final scale = available / max(logo.width, logo.height);
  final resized = img.copyResize(
    logo,
    width: (logo.width * scale).round(),
    height: (logo.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: size, height: size, numChannels: 3);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(
    canvas,
    resized,
    dstX: (size - resized.width) ~/ 2,
    dstY: (size - resized.height) ~/ 2,
  );

  File(target)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln(
    'Wrote $target (${logo.width}x${logo.height} -> ${size}x$size)',
  );
}
