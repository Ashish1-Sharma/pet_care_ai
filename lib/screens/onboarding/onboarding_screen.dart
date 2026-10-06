import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/primary_button.dart';
import '../home/navigation_container.dart';
import '../login/login_screen.dart';
import '../pets/add_pet_screen.dart';

/// First-run welcome: shows the value before asking for anything, then
/// Welcome → Add your pet → Sign in.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _haveAccount(BuildContext context) async {
    await StorageService().setOnboardingSeen();
    if (!context.mounted) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    Navigator.pushReplacement(
      context,
      AppRoutes.fadeThrough(
        provider.isAuthenticated ? const NavigationContainer() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget benefit(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.brSm),
            child: Icon(icon, size: 18, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.md, AppSpacing.gutter, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.brSm,
                    child: Image.asset('assets/logo.png', width: 36, height: 36),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('PetCareAI', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientHero,
                    borderRadius: AppRadius.brLg,
                    boxShadow: AppShadows.glow(AppColors.teal, opacity: 0.25),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/dog_cat.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(Icons.pets_rounded, color: Colors.white, size: 96),
                        ).animate().fadeIn(duration: AppDurations.slow).scale(
                          begin: const Offset(0.92, 0.92),
                          curve: Curves.easeOutBack,
                          duration: AppDurations.slow,
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AppRadius.brSm,
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.criticalityLow,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Low risk · safe to monitor', style: theme.textTheme.labelMedium),
                            ],
                          ),
                        ).animate(delay: 400.ms).fadeIn().moveY(begin: 10, end: 0),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Is it serious?\nKnow in 60 seconds.', style: theme.textTheme.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Snap a photo of your dog or cat's skin, eye, ear or paw. AI tells you "
                'whether to watch at home or see a vet today.',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              benefit(Icons.shield_rounded, 'Low / Moderate / Emergency risk level'),
              benefit(Icons.trending_up_rounded, 'Track healing photo by photo'),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: AppRadius.brPill),
                  child: Text(
                    '3 free scans · no card needed',
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                text: 'Get started',
                onPressed: () {
                  track('onboarding_start');
                  Navigator.push(
                    context,
                    AppRoutes.sharedAxis(const AddPetScreen(mode: AddPetMode.onboarding)),
                  );
                },
              ),
              TextButton(
                onPressed: () => _haveAccount(context),
                child: const Text('I already have an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
