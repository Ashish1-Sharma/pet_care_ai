import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/iap_service.dart';
import '../login/login_screen.dart';
import '../payment/paywall_screen.dart';
import '../pets/my_pets_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reminders/notification_primer.dart';
import 'referral_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text(
          'Are you sure you want to log out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: AppColors.criticalityEmergency,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          AppRoutes.fadeThrough(const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: 'Version ${AppConfig.appVersion}',
      applicationIcon: const Icon(
        Icons.pets_rounded,
        color: AppColors.primaryDark,
      ),
      children: const [
        Text('AI guidance for pet owners. Not a substitute for a licensed veterinarian.'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final theme = Theme.of(context);
    final name = user?.name ?? 'Pet Owner';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFA03CBF),
                  backgroundImage: user != null && user.profileImage.isNotEmpty
                      ? NetworkImage(user.profileImage)
                      : null,
                  child: user != null && user.profileImage.isNotEmpty
                      ? null
                      : Text(
                          name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${provider.pets.length} pet${provider.pets.length == 1 ? '' : 's'} · ${user?.email ?? ''}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _PlanCard(user: user),
            const SizedBox(height: AppSpacing.md),

            const ReferralCard(),
            const SizedBox(height: AppSpacing.md),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.brLg,
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.pets_rounded,
                    label: 'My pets',
                    onTap: () => Navigator.push(context, AppRoutes.sharedAxis(const MyPetsScreen())),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.notifications_rounded,
                    label: 'Reminders & notifications',
                    onTap: () async {
                      await NotificationPrimer.ensure(context);
                      if (context.mounted) {
                        Navigator.push(context, AppRoutes.sharedAxis(const RemindersScreen()));
                      }
                    },
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.restore_rounded,
                    label: 'Restore purchases',
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (!provider.iapAvailable) await provider.initIap();
                      if (!provider.iapAvailable) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Google Play is not available on this device.')),
                        );
                        return;
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Checking Google Play for your purchases…')),
                      );
                      await provider.restorePurchases(silent: true);
                      // Give restored purchases a moment to reach the server.
                      await Future.delayed(const Duration(seconds: 3));
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.isPlus
                                  ? 'PetCare Plus is active on this account.'
                                  : 'No active subscription found. Scan packs are already in your balance.',
                            ),
                          ),
                        );
                    },
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & feedback',
                    onTap: () => launchUrl(
                      Uri(
                        scheme: 'mailto',
                        path: AppConfig.supportEmail,
                        query: 'subject=PetCareAI feedback (account ${user?.id ?? '-'})',
                      ),
                    ),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.verified_user_rounded,
                    label: 'Privacy policy',
                    onTap: () => launchUrl(
                      Uri.parse(AppConfig.privacyPolicyUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const _RowDivider(),
                  _ProfileRow(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Material(
              color: AppColors.criticalityEmergencyBg,
              borderRadius: AppRadius.brMd,
              child: InkWell(
                borderRadius: AppRadius.brMd,
                onTap: () => _handleLogout(context),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.criticalityEmergency),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Log out',
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.criticalityEmergency),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final UserModel? user;

  const _PlanCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = user?.plan;
    final isPlus = user?.isPlus ?? false;
    final white90 = AppColors.alpha(Colors.white, 0.9);

    String title;
    String subtitle;
    String? chip;
    if (isPlus && plan != null) {
      title = 'PetCare Plus · ${plan.isYearly ? 'Yearly' : 'Weekly'}';
      final date = plan.expiresAt;
      final dateText = date == null ? '' : '${date.day}/${date.month}/${date.year}';
      if (plan.isTrial && date != null) {
        final daysLeft = date.difference(DateTime.now()).inDays;
        chip = 'Free trial · ${daysLeft < 1 ? 'ends today' : '$daysLeft days left'}';
        subtitle = 'Your plan starts on $dateText. Unlimited scans and AI Vet chat.';
      } else {
        subtitle = plan.autoRenewing
            ? 'Renews on $dateText. Unlimited scans and AI Vet chat.'
            : 'Ends on $dateText. Renew anytime in Google Play.';
      }
    } else {
      final scans = user?.remainingScans ?? 0;
      title = '$scans scan${scans == 1 ? '' : 's'} left';
      subtitle = 'Free plan · ${user?.freeWeeklyScans ?? 1} free scan every Monday · '
          '${user?.chatDailyLimit ?? 5} AI Vet messages a day';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('YOUR PLAN', style: theme.textTheme.labelSmall?.copyWith(color: white90)),
              const Spacer(),
              if (chip != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(Colors.white, 0.18),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Text(chip, style: theme.textTheme.labelMedium?.copyWith(color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: white90)),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.brPill),
            ),
            onPressed: () {
              if (isPlus) {
                launchUrl(
                  Uri.parse(AppConfig.manageSubscriptionUrl(plan?.productId ?? IapService.plans.first.productId)),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                PaywallScreen.open(context, source: 'profile_plan');
              }
            },
            child: Text(isPlus ? 'Manage in Google Play' : 'Get more scans or Plus'),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: AppColors.alpha(AppColors.border, 0.8),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
