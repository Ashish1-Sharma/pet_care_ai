import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/animated_marks.dart';
import '../../widgets/google_logo.dart';
import '../../widgets/mint_backdrop.dart';
import '../../widgets/primary_button.dart';
import '../home/navigation_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoggingIn = false;

  /// Name of the pet entered during onboarding, if any.
  String? _petName;

  @override
  void initState() {
    super.initState();
    StorageService().getPendingPet().then((pet) {
      if (mounted && pet != null) setState(() => _petName = pet.name);
    });
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoggingIn = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    final success = await provider.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        AppRoutes.fadeThrough(const NavigationContainer()),
      );
    } else {
      final error = provider.errorMessage ?? 'Google Sign-In failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.criticalityEmergency,
        ),
      );
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() => _isLoggingIn = true);

    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.loginAsDemo();

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    Navigator.pushReplacement(
      context,
      AppRoutes.fadeThrough(const NavigationContainer()),
    );
  }

  void _showDemoLoginSheet() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final theme = Theme.of(sheetCtx);
        return StatefulBuilder(
          builder:
              (sheetCtx, setSheetState) => Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom:
                      MediaQuery.of(sheetCtx).viewInsets.bottom + AppSpacing.xl,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.brSm,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: AppColors.primaryDark,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Reviewer demo login',
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Enter the reviewer credentials from your submission notes '
                        'to access offline demo mode.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                            ),
                            onPressed:
                                () => setSheetState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      PrimaryButton(
                        text: 'Log in',
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            // Hardcoded Reviewer Credentials
                            if (email == 'reviewer@example.com' &&
                                password == 'reviewerpassword123') {
                              Navigator.pop(sheetCtx); // Close sheet
                              await _handleDemoSignIn();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invalid reviewer credentials.',
                                  ),
                                  backgroundColor:
                                      AppColors.criticalityEmergency,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  /// The legal documents have no in-app destination yet.
  void _showLegal(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light backdrop, so the status bar icons must be dark.
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: MintBackdrop.top,
        body: MintBackdrop(
          hillLift: 300,
          child: Column(
            children: [
              // Brand half, on the mint stage.
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                              'assets/logo.png',
                              width: 170,
                              height: 170,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stack) =>
                                      const PulseMark(size: 140),
                            )
                            .animate()
                            .fadeIn(duration: AppDurations.slow)
                            .scale(
                              duration: AppDurations.slow,
                              curve: Curves.easeOutBack,
                              begin: const Offset(0.85, 0.85),
                            ),

                        const SizedBox(height: AppSpacing.lg),

                        // Two-tone wordmark: dark "PetCare", brand-green "AI".
                        Text.rich(
                              TextSpan(
                                style: theme.textTheme.displayMedium,
                                children: const [
                                  TextSpan(text: 'PetCare'),
                                  TextSpan(
                                    text: 'AI',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(delay: 150.ms)
                            .fadeIn(duration: 500.ms)
                            .moveY(
                              begin: 16,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),

                        const SizedBox(height: AppSpacing.sm),

                        Text(
                          _petName == null
                              ? 'Know what your pet needs.'
                              : "Save $_petName's health profile",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textDark,
                          ),
                        ).animate(delay: 250.ms).fadeIn(duration: 500.ms),

                        const SizedBox(height: AppSpacing.md),

                        Text(
                              _petName == null
                                  ? 'AI-powered symptom scanning, with a report you can '
                                      'take straight to the vet.'
                                  : 'Sign in so scans, photos and reminders are kept '
                                      'safe and sync across phones.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            )
                            .animate(delay: 350.ms)
                            .fadeIn(duration: 500.ms)
                            .moveY(
                              begin: 12,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action sheet rising over the mint stage.
              Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.sheet,
                      boxShadow: AppShadows.floating,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xl,
                          AppSpacing.lg,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoggingIn)
                              const SizedBox(
                                height: 62,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: AppRadius.brMd,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.card_giftcard_rounded,
                                      color: AppColors.primaryDark,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        'Welcome gift: 3 free scans, plus 5 AI Vet '
                                        'messages a day. No card needed.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.ink,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _GoogleSignInButton(
                                onPressed: _handleGoogleSignIn,
                              ),
                              // const SizedBox(height: AppSpacing.lg),
                              // TextButton(
                              //   onPressed: _showDemoLoginSheet,
                              //   child: Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              //       Text(
                              //         'Explore in demo mode',
                              //         style: theme.textTheme.labelLarge
                              //             ?.copyWith(
                              //               color: AppColors.primaryDark,
                              //             ),
                              //       ),
                              //       const SizedBox(width: AppSpacing.sm),
                              //       const Icon(
                              //         Icons.chevron_right_rounded,
                              //         color: AppColors.primaryDark,
                              //         size: 22,
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'By signing in, you agree to our',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LegalLink(
                                  label: 'Terms and Conditions',
                                  onTap:
                                      () => _showLegal('Terms and Conditions'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: Text(
                                    'and',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                _LegalLink(
                                  label: 'Privacy Policy',
                                  onTap: () => _showLegal('Privacy Policy'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .moveY(
                    begin: 40,
                    end: 0,
                    duration: AppDurations.slow,
                    curve: Curves.easeOutCubic,
                  )
                  .fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient CTA carrying the real Google mark on a white disc.
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.brMd,
        child: Container(
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            borderRadius: AppRadius.brMd,
            boxShadow: AppShadows.glow(AppColors.teal, opacity: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const GoogleLogo(size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Continue with Google',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LegalLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
