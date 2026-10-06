import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_config.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';

/// "Give 2 scans, get 2 scans": the user's invite code, plus entry of a
/// friend's code for new accounts.
class ReferralCard extends StatelessWidget {
  const ReferralCard({super.key});

  static Future<void> share(BuildContext context, String code) async {
    track('referral_share');
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Try PetCareAI',
        text: 'I use PetCareAI to check on my pet\'s health with AI. '
            'Sign up with my code $code and we both get 2 free scans: '
            '${AppConfig.playStoreUrl}',
      ),
    );
  }

  static Future<void> enterCode(BuildContext context) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter invite code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'e.g. ALEX-B2K9C1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty || !context.mounted) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final ok = await provider.redeemReferral(code);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '2 free scans added. Enjoy!' : provider.errorMessage ?? 'Could not redeem code'),
        backgroundColor: ok ? AppColors.criticalityLow : AppColors.criticalityEmergency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final code = user?.referralCode;
    if (code == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    const ink = Color(0xFF5C3A1C);
    const button = Color(0xFF9A4A10);

    final joinedRecently = user?.createdAt == null ||
        DateTime.now().difference(user!.createdAt!).inDays <= 14;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: AppRadius.brMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: button),
              const SizedBox(width: AppSpacing.sm),
              Text('Give 2 scans, get 2 scans', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'When a friend signs up with your code, you both get 2 free scans.',
            style: theme.textTheme.bodyMedium?.copyWith(color: ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: AppRadius.brSm,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  child: Container(
                    height: 46,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.brSm,
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: Text(
                      code,
                      style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: button,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.brSm),
                  ),
                  onPressed: () => share(context, code),
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
          if (user?.referralRedeemed == false && joinedRecently)
            TextButton(
              onPressed: () => enterCode(context),
              child: const Text('Have a friend\'s code?'),
            ),
        ],
      ),
    );
  }
}
