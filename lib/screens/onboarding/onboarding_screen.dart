import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/primary_button.dart';
import '../home/navigation_container.dart';
import '../login/login_screen.dart';
import 'onboarding_page.dart';

/// Three-slide intro shown once on first launch.
///
/// The backdrop gradient interpolates continuously between each slide's
/// colours as the user swipes, so the whole screen — not just the content —
/// responds to the gesture.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final List<OnboardingContent> _pages = OnboardingContent.pages;

  /// Continuous scroll position in pages (e.g. 1.4 mid-swipe).
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.hasClients && _controller.position.haveDimensions
          ? _controller.page ?? 0
          : 0.0;
      if (page != _page) setState(() => _page = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _index => _page.round();

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    await StorageService().setOnboardingSeen();
    if (!mounted) return;

    // A user could already be signed in (e.g. app updated into a build that
    // added onboarding), so respect the existing session.
    final provider = Provider.of<AppProvider>(context, listen: false);
    final next = provider.isAuthenticated
        ? const NavigationContainer()
        : const LoginScreen();

    if (!mounted) return;
    Navigator.pushReplacement(context, AppRoutes.fadeThrough(next));
  }

  /// Blends the surrounding slides' gradients by the fractional scroll
  /// position.
  List<Color> get _backdrop {
    final lower = _page.floor().clamp(0, _pages.length - 1);
    final upper = _page.ceil().clamp(0, _pages.length - 1);
    final t = _page - lower;

    return [
      Color.lerp(_pages[lower].gradient[0], _pages[upper].gradient[0], t)!,
      Color.lerp(_pages[lower].gradient[1], _pages[upper].gradient[1], t)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _backdrop,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.85),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => OnboardingPage(
                    content: _pages[index],
                    offset: _page - index,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _DotIndicator(count: _pages.length, position: _page),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: _isLast ? 'Get started' : 'Next',
                      icon: _isLast ? null : Icons.arrow_forward_rounded,
                      onPressed: _next,
                      backgroundColor: Colors.white,
                      textColor: AppColors.ink,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-style indicator: the active dot stretches rather than just brightening.
class _DotIndicator extends StatelessWidget {
  final int count;
  final double position;

  const _DotIndicator({required this.count, required this.position});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        // 1 when this dot is centred, 0 when a full page away.
        final t = (1 - (position - i).abs()).clamp(0.0, 1.0);
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8 + 20 * t,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.alpha(Colors.white, 0.35 + 0.65 * t),
            borderRadius: AppRadius.brPill,
          ),
        );
      }),
    );
  }
}
