import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

/// Hand-built animated marks used as the default artwork across the app —
/// and as the fallback whenever a Lottie asset is absent.
///
/// Everything here is painted with `CustomPainter`, so it costs no assets and
/// picks up the palette automatically.

/// Concentric rings pulsing outward from a centred icon. Splash logo mark and
/// the onboarding "scan" page.
class PulseMark extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const PulseMark({
    super.key,
    this.icon = Icons.pets_rounded,
    this.color = Colors.white,
    this.size = 120,
  });

  @override
  State<PulseMark> createState() => _PulseMarkState();
}

class _PulseMarkState extends State<PulseMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulsePainter(
              progress: _controller.value,
              color: widget.color,
            ),
            child: child,
          );
        },
        child: Center(
          child: Icon(
            widget.icon,
            size: widget.size * 0.36,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;

    // Three rings, evenly offset in phase, fading as they expand.
    for (var i = 0; i < 3; i++) {
      final t = (progress + i / 3) % 1.0;
      final radius = maxRadius * (0.42 + 0.58 * t);
      final opacity = (1.0 - t) * 0.45;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.alpha(color, opacity),
      );
    }

    // Solid core disc.
    canvas.drawCircle(
      center,
      maxRadius * 0.34,
      Paint()..color = AppColors.alpha(color, 0.18),
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}

/// A rotating arc ring. Used for the report's severity dial and as a
/// determinate-looking progress accent.
class ArcRing extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final Widget? child;

  const ArcRing({
    super.key,
    this.size = 96,
    this.color = Colors.white,
    this.strokeWidth = 4,
    this.child,
  });

  @override
  State<ArcRing> createState() => _ArcRingState();
}

class _ArcRingState extends State<ArcRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ArcRingPainter(
              progress: _controller.value,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
            child: child,
          );
        },
        child: widget.child == null
            ? null
            : Center(child: widget.child),
      ),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);

    canvas.drawCircle(
      size.center(Offset.zero),
      inset.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.alpha(color, 0.2),
    );

    canvas.drawArc(
      inset,
      progress * 2 * math.pi,
      math.pi * 0.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.progress != progress;
}

/// A dashed rounded-rectangle border. Used for the "add photo" tile.
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  DashedBorderPainter({
    required this.color,
    this.radius = 20,
    this.dashLength = 6,
    this.gapLength = 5,
    this.strokeWidth = 1.6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
