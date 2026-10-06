import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The Google "G" mark, painted from arcs.
///
/// The sign-in button previously showed `Icons.g_mobiledata` tinted emerald,
/// which is a Material glyph rather than Google's mark.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  // Arc segments as (startDegrees, sweepDegrees), canvas convention:
  // 0° points east and angles increase clockwise.
  static const _segments = <(double, double, Color)>[
    (-60, 60, _blue), // 1 o'clock → 3 o'clock
    (0, 66, _green), // 3 → 5
    (66, 100, _yellow), // 5 → 8
    (166, 134, _red), // 8 → over the top → 1
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.26;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    for (final (start, sweep, color) in _segments) {
      canvas.drawArc(
        rect,
        start * math.pi / 180,
        sweep * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = color,
      );
    }

    // The horizontal crossbar, running from the centre to the right edge.
    final center = size.center(Offset.zero);
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx - stroke * 0.1,
        center.dy - stroke / 2,
        size.width,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
