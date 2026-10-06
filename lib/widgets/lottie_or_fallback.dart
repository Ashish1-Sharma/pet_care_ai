import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

/// Renders a Lottie animation when the asset exists, and a built-in Flutter
/// animation when it does not.
///
/// The repo ships no `.json` files — dropping one into `assets/animations/`
/// upgrades the visual with no code change. See that folder's README for the
/// filenames each screen looks for.
class LottieOrFallback extends StatefulWidget {
  /// Asset path, e.g. `assets/animations/scanning.json`.
  final String asset;

  /// Shown while the asset is being probed, and permanently if it's absent.
  final Widget fallback;

  final double? width;
  final double? height;
  final bool repeat;

  const LottieOrFallback({
    super.key,
    required this.asset,
    required this.fallback,
    this.width,
    this.height,
    this.repeat = true,
  });

  @override
  State<LottieOrFallback> createState() => _LottieOrFallbackState();
}

class _LottieOrFallbackState extends State<LottieOrFallback> {
  /// Cached across instances so each asset is probed only once per run.
  static final Map<String, bool> _existsCache = {};

  bool? _exists;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    final cached = _existsCache[widget.asset];
    if (cached != null) {
      setState(() => _exists = cached);
      return;
    }

    bool found;
    try {
      await rootBundle.load(widget.asset);
      found = true;
    } catch (_) {
      found = false;
    }

    _existsCache[widget.asset] = found;
    if (mounted) setState(() => _exists = found);
  }

  @override
  Widget build(BuildContext context) {
    if (_exists != true) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.fallback,
      );
    }

    return Lottie.asset(
      widget.asset,
      width: widget.width,
      height: widget.height,
      repeat: widget.repeat,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.fallback,
      ),
    );
  }
}
