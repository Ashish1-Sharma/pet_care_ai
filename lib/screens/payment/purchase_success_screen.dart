import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../widgets/primary_button.dart';
import '../reminders/reminders_screen.dart';

/// After a PetCare Plus purchase: confirmation, trial end date, and the
/// reminders opt-in (the moment people are most willing to say yes).
class PurchaseSuccessScreen extends StatefulWidget {
  const PurchaseSuccessScreen({super.key});

  @override
  State<PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends State<PurchaseSuccessScreen> {
  bool _primed = true;

  @override
  void initState() {
    super.initState();
    Provider.of<AppProvider>(context, listen: false)
        .notificationsPrimed()
        .then((primed) => mounted ? setState(() => _primed = primed) : null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final plan = provider.currentUser?.plan;
    final pets = provider.pets.map((p) => p.name).toList();
    final who = pets.isEmpty ? 'your pets' : pets.take(2).join(' and ');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.glow(AppColors.teal),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Welcome to PetCare Plus', style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Unlimited scans and AI Vet chat are on for $who.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (plan?.isTrial == true && plan?.expiresAt != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.brMd,
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppColors.primaryDark),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Free trial ends ${RemindersScreen.formatDue(plan!.expiresAt!)}. '
                          'We will remind you the day before.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (!_primed) ...[
                PrimaryButton(
                  text: 'Turn on reminders',
                  icon: Icons.notifications_active_rounded,
                  onPressed: () async {
                    await provider.enableNotifications();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
              ] else
                PrimaryButton(text: 'Continue', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
