import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_shadows.dart';
import '../config/theme/app_spacing.dart';

/// The signature elevated surface of the new visual language.
///
/// Two flavours share one widget so the gradient identity stays consistent
/// wherever it appears — balance card, report hero, onboarding pages:
///  * [GradientCard] — filled with a gradient, white content on top.
///  * [GradientCard.plain] — white surface with the standard card elevation.
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  /// Draws the soft decorative circles that give the gradient surfaces depth.
  final bool showOrbs;

  const GradientCard({
    super.key,
    required this.child,
    this.gradient = AppColors.gradientPrimary,
    this.color,
    this.padding = AppSpacing.card,
    this.radius = AppRadius.lg,
    this.shadow,
    this.onTap,
    this.showOrbs = true,
  });

  const GradientCard.plain({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.radius = AppRadius.lg,
    this.shadow,
    this.onTap,
    this.color = AppColors.surfaceElevated,
  }) : gradient = null,
       showOrbs = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    final Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.surfaceElevated) : null,
        borderRadius: borderRadius,
        border: gradient == null
            ? Border.all(color: AppColors.alpha(AppColors.border, 0.7))
            : null,

      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            if (showOrbs && gradient != null) ..._orbs(),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: content,
      ),
    );
  }

  List<Widget> _orbs() {
    return [
      Positioned(
        top: -50,
        right: -30,
        child: _orb(140, AppColors.alpha(Colors.white, 0.13)),
      ),
      Positioned(
        bottom: -60,
        left: -40,
        child: _orb(150, AppColors.alpha(Colors.white, 0.07)),
      ),
    ];
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
