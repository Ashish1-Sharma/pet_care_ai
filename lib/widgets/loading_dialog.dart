import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';
import '../providers/app_provider.dart';
import 'animated_marks.dart';
import 'lottie_or_fallback.dart';

/// Progress overlay, in two modes.
///
/// Passing [imagePath] (the scan flow) gives the full-screen scanning
/// experience: the photo behind a sweeping scan line plus a three-step rail
/// driven by the provider's progress messages. Omitting it (the payment flow)
/// gives a compact card, since those steps are meaningless there.
///
/// The static `show`/`hide` API is unchanged, so existing call sites keep
/// working.
class LoadingDialog extends StatelessWidget {
  final String? imagePath;
  final String? message;

  const LoadingDialog({super.key, this.imagePath, this.message});

  /// The provider's progress messages, in the order they are emitted.
  /// Used to light up the step rail.
  static const List<String> steps = [
    'Uploading Images...',
    'Analyzing Images...',
    'Generating Health Report...',
  ];

  static const List<String> _stepLabels = [
    'Uploading photos',
    'Analyzing symptoms',
    'Writing your report',
  ];

  static void show(BuildContext context, {String? imagePath, String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlayScrim,
      useSafeArea: false,
      builder: (context) =>
          LoadingDialog(imagePath: imagePath, message: message),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Maps the provider's free-text message onto a step index.
  static int _indexFor(String message) {
    final index = steps.indexOf(message);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath == null) {
      return PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ArcRing(size: 48, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message ?? 'Just a moment…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHero),
          child: SafeArea(
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                final message = provider.scanProgressMessage;
                final current = _indexFor(message);

                return Column(
                  children: [
                    const Spacer(flex: 2),

                    _ScanViewport(imagePath: imagePath),

                    const SizedBox(height: AppSpacing.xxl),

                    Text(
                      _stepLabels[current],
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hang tight — this usually takes a few seconds.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.75),
                      ),
                    ),

                    const Spacer(flex: 2),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: _StepRail(
                        labels: _stepLabels,
                        currentIndex: current,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's photo behind a sweeping scan line, framed by corner brackets.
class _ScanViewport extends StatefulWidget {
  final String? imagePath;

  const _ScanViewport({this.imagePath});

  @override
  State<_ScanViewport> createState() => _ScanViewportState();
}

class _ScanViewportState extends State<_ScanViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Demo mode uses a placeholder path that is not a real file.
  bool get _hasRealImage {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    const size = 220.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: AppRadius.brLg,
            child: SizedBox(
              width: size,
              height: size,
              child: _hasRealImage
                  ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                  : Container(
                      color: AppColors.alpha(Colors.white, 0.08),
                      child: const LottieOrFallback(
                        asset: 'assets/animations/scanning.json',
                        fallback: PulseMark(size: size),
                      ),
                    ),
            ),
          ),

          // Sweeping scan line.
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(size, size),
                painter: _ScanLinePainter(progress: _controller.value),
              );
            },
          ),

          // Corner brackets.
          CustomPaint(
            size: const Size(size, size),
            painter: _BracketPainter(),
          ),
        ],
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double progress;

  _ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Glow trailing the line.
    canvas.drawRect(
      Rect.fromLTRB(0, y - 44, size.width, y),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.alpha(AppColors.primary, 0.42),
          ],
        ).createShader(Rect.fromLTRB(0, y - 44, size.width, y)),
    );

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 2.2
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const arm = 26.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    // Top-left, top-right, bottom-left, bottom-right.
    final corners = <List<Offset>>[
      [const Offset(0, arm), Offset.zero, const Offset(arm, 0)],
      [
        Offset(size.width - arm, 0),
        Offset(size.width, 0),
        Offset(size.width, arm),
      ],
      [
        Offset(0, size.height - arm),
        Offset(0, size.height),
        Offset(arm, size.height),
      ],
      [
        Offset(size.width - arm, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - arm),
      ],
    ];

    for (final points in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(points[0].dx, points[0].dy)
          ..lineTo(points[1].dx, points[1].dy)
          ..lineTo(points[2].dx, points[2].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BracketPainter oldDelegate) => false;
}

/// Three-stage progress rail: completed steps show a tick, the active step
/// pulses, upcoming steps stay dim.
class _StepRail extends StatelessWidget {
  final List<String> labels;
  final int currentIndex;

  const _StepRail({required this.labels, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: List.generate(labels.length, (i) {
        final done = i < currentIndex;
        final active = i == currentIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: active
                    ? const ArcRing(size: 26, strokeWidth: 2.5)
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? Colors.white
                              : AppColors.alpha(Colors.white, 0.16),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: AppColors.primaryDark,
                              )
                            : null,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                labels[i],
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.alpha(
                    Colors.white,
                    active ? 1.0 : (done ? 0.75 : 0.4),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
