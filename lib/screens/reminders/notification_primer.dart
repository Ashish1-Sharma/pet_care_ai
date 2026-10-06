import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../widgets/primary_button.dart';

/// Explains reminders before Android's permission prompt appears, so people
/// know why they are being asked. Shown once.
class NotificationPrimer extends StatelessWidget {
  const NotificationPrimer({super.key});

  /// Shows the primer if it has not been shown before. Safe to call any time
  /// a reminder is about to be scheduled.
  static Future<void> ensure(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (await provider.notificationsPrimed()) return;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => const NotificationPrimer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget bullet(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: AppRadius.brPill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.primaryDark),
                const SizedBox(width: AppSpacing.sm),
                Text('Get reminders that matter', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            bullet('Recovery check-ins, so you know if it is healing'),
            bullet('Flea, tick and deworming doses'),
            bullet('Vaccine due dates'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No marketing spam. You can turn them off anytime.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              text: 'Turn on reminders',
              onPressed: () async {
                await Provider.of<AppProvider>(context, listen: false).enableNotifications();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Not now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
