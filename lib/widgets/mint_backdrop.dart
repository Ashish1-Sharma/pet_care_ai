import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';

/// The pale mint stage the splash and login screens sit on: a soft wash,
/// scattered paw watermarks and two overlapping hills off the bottom edge.
class MintBackdrop extends StatelessWidget {
  final Widget child;

  /// How far up from the bottom the hills reach. Screens with a white action
  /// sheet at the foot push them higher so they stay visible.
  final double hillLift;

  const MintBackdrop({super.key, required this.child, this.hillLift = 0});

  static const Color top = Color(0xFFF2F9F5);
  static const Color bottom = Color(0xFFE4F1EA);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
          ),
        ),

        const _Paw(top: 150, left: 40, size: 96, angle: -0.25),
        const _Paw(top: 120, right: 30, size: 120, angle: 0.18),
        const _Paw(top: 700, right: 55, size: 78, angle: -0.12),
        const _Paw(top: 760, left: 60, size: 66, angle: 0.3),

        _Hill(
          bottom: hillLift - 110,
          left: -80,
          right: 90,
          height: 300,
          color: AppColors.alpha(AppColors.primary, 0.06),
        ),
        _Hill(
          bottom: hillLift - 140,
          left: 70,
          right: -90,
          height: 300,
          color: AppColors.alpha(AppColors.teal, 0.06),
        ),

        child,
      ],
    );
  }
}

/// A soft rounded mound anchored off the bottom edge.
class _Hill extends StatelessWidget {
  final double bottom;
  final double left;
  final double right;
  final double height;
  final Color color;

  const _Hill({
    required this.bottom,
    required this.left,
    required this.right,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

/// A single faint paw watermark in the backdrop.
class _Paw extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double size;
  final double angle;

  const _Paw({
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          Icons.pets_rounded,
          size: size,
          color: AppColors.alpha(AppColors.primary, 0.07),
        ),
      ),
    );
  }
}
