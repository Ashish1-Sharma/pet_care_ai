import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../widgets/gradient_card.dart';
import '../home/navigation_container.dart';
import '../login/login_screen.dart';
import '../payment/buy_scans_screen.dart';

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

  /// The settings rows have no destinations yet; say so rather than
  /// silently doing nothing.
  void _notReady(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is coming soon')));
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final theme = Theme.of(context);

    final name = user?.name ?? 'Pet Owner';
    final scans = user?.remainingScans ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('', style: theme.textTheme.headlineMedium),
        toolbarHeight: 10,

      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          kFloatingNavHeight + AppSpacing.lg,
        ),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.glow(AppColors.teal, opacity: 0.28),
                    image: user != null && user.profileImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(user.profileImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: user != null && user.profileImage.isNotEmpty
                      ? null
                      : Text(
                          name.trim().isEmpty
                              ? '?'
                              : name.trim()[0].toUpperCase(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(name, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center,),
                const SizedBox(height: 2),
                // Text(
                //   provider.isDemoMode ? 'Demo account' : 'Google account',
                //   style: theme.textTheme.bodyLarge?.copyWith(
                //     color: AppColors.textMuted,
                //   ),
                // ),
                Text(
                  user?.email ?? 'owner@example.com',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          GradientCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.alpha(Colors.white, 0.2),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCAN BALANCE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.alpha(Colors.white, 0.75),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$scans',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            scans == 1 ? 'scan left' : 'scans left',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.alpha(Colors.white, 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Material(
                  color: Colors.white,
                  borderRadius: AppRadius.brPill,
                  child: InkWell(
                    borderRadius: AppRadius.brPill,
                    onTap: () => Navigator.push(
                      context,
                      AppRoutes.sharedAxis(const BuyScansScreen()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 12,
                      ),
                      child: Text(
                        'Buy scans',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          GradientCard.plain(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                // _ProfileRow(
                //   icon: Icons.person_rounded,
                //   label: 'Account',
                //   subtitle: 'Manage your account details',
                //   onTap: () => _notReady(context, 'Account'),
                // ),
                // const _RowDivider(),
                // _ProfileRow(
                //   icon: Icons.verified_user_rounded,
                //   label: 'Privacy',
                //   subtitle: 'Privacy policy and data settings',
                //   onTap: () => _notReady(context, 'Privacy'),
                // ),
                // const _RowDivider(),
                // _ProfileRow(
                //   icon: Icons.notifications_rounded,
                //   label: 'Notifications',
                //   subtitle: 'Manage your notification preferences',
                //   onTap: () => _notReady(context, 'Notifications'),
                // ),
                // const _RowDivider(),
                // _ProfileRow(
                //   icon: Icons.help_outline_rounded,
                //   label: 'Help & Support',
                //   subtitle: 'Get help and support',
                //   onTap: () => _notReady(context, 'Help & Support'),
                // ),
                // const _RowDivider(),
                _ProfileRow(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  subtitle: 'App version and information',
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Material(
            color: AppColors.criticalityEmergencyBg,
            borderRadius: AppRadius.brLg,
            child: InkWell(
              borderRadius: AppRadius.brLg,
              onTap: () => _handleLogout(context),
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.criticalityEmergency,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Log out',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.criticalityEmergency,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.subtitle,
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
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
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
