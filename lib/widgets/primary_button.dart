import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_shadows.dart';
import '../config/theme/app_spacing.dart';

enum ButtonVariant {
  /// Gradient fill with a coloured glow — the app's main CTA.
  filled,

  /// Soft tinted fill, no glow. For secondary actions on light surfaces.
  tonal,

  /// Transparent with a border. For actions on gradient backdrops.
  outline,
}

/// The app's primary call-to-action.
///
/// The public API is unchanged from the previous implementation so every
/// existing call site keeps working; [variant] and [height] are additive.
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final ButtonVariant variant;
  final double height;

  /// Set false to size to content rather than filling the width.
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.variant = ButtonVariant.filled,
    this.height = 58,
    this.expand = true,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _disabled => widget.isLoading || widget.onPressed == null;

  /// Custom colours opt out of the gradient so callers that pass a specific
  /// [backgroundColor] (e.g. the emergency-red variants) still get it.
  bool get _useGradient =>
      widget.variant == ButtonVariant.filled &&
      widget.backgroundColor == AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
      onTap: _disabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: widget.expand ? double.infinity : null,
          height: widget.height,
          padding: widget.expand
              ? null
              : const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: _decoration(),
          child: Center(child: _child()),
        ),
      ),
    );
  }

  BoxDecoration _decoration() {
    final radius = AppRadius.brMd;

    if (_disabled) {
      return BoxDecoration(
        color: widget.variant == ButtonVariant.outline
            ? Colors.transparent
            : AppColors.alpha(AppColors.primary, 0.18),
        borderRadius: radius,
        border: widget.variant == ButtonVariant.outline
            ? Border.all(color: AppColors.alpha(Colors.white, 0.25), width: 1.5)
            : null,
      );
    }

    switch (widget.variant) {
      case ButtonVariant.filled:
        return BoxDecoration(
          gradient: _useGradient ? AppColors.gradientPrimary : null,
          color: _useGradient ? null : widget.backgroundColor,
          borderRadius: radius,
          boxShadow: AppShadows.glow(
            _useGradient ? AppColors.teal : widget.backgroundColor,
            opacity: _pressed ? 0.18 : 0.34,
          ),
        );
      case ButtonVariant.tonal:
        return BoxDecoration(
          color: AppColors.alpha(widget.backgroundColor, 0.12),
          borderRadius: radius,
        );
      case ButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: radius,
          border: Border.all(color: widget.textColor, width: 1.5),
        );
    }
  }

  Color get _foreground {
    if (_disabled) {
      return widget.variant == ButtonVariant.outline
          ? AppColors.alpha(widget.textColor, 0.5)
          : AppColors.alpha(AppColors.primary, 0.6);
    }
    switch (widget.variant) {
      case ButtonVariant.filled:
        return widget.textColor;
      case ButtonVariant.tonal:
        return widget.backgroundColor;
      case ButtonVariant.outline:
        return widget.textColor;
    }
  }

  Widget _child() {
    if (widget.isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(_foreground),
        ),
      );
    }

    final label = Text(
      widget.text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: _foreground),
    );

    if (widget.icon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: 20, color: _foreground),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: label),
      ],
    );
  }
}
