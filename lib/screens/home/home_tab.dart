import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/reminder.dart';
import '../../providers/app_provider.dart';
import '../../widgets/pet_avatar.dart';
import '../payment/paywall_screen.dart';
import '../pets/add_pet_screen.dart';
import '../recovery/recovery_screen.dart';
import '../reminders/reminders_screen.dart';
import 'navigation_container.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final theme = Theme.of(context);
    final pet = provider.selectedPet;
    final petName = pet?.name ?? 'your pet';
    final firstName = (user?.name ?? '').trim().split(' ').first;

    final now = DateTime.now();
    final recovery = provider.reminders.where((r) => r.isRecovery).firstOrNull;
    final upcoming = provider.reminders
        .where((r) => !r.isRecovery && r.dueAt.isAfter(now.subtract(const Duration(days: 1))))
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: provider.refreshProfile,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(), style: theme.textTheme.bodyMedium),
                        Text(
                          firstName.isEmpty ? 'Welcome' : firstName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  _BalancePill(
                    isPlus: user?.isPlus ?? false,
                    scans: user?.remainingScans ?? 0,
                    onTap: () => PaywallScreen.open(context, source: 'home_balance'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              _PetSwitcher(),
              const SizedBox(height: AppSpacing.md),

              // Primary action: scan the selected pet.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientHero,
                  borderRadius: AppRadius.brLg,
                  boxShadow: AppShadows.glow(AppColors.teal, opacity: 0.25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI HEALTH SCAN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.85),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Something wrong with $petName?',
                      style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Skin, eyes, ears, paws, wounds. Results in about a minute.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Material(
                      color: Colors.white,
                      borderRadius: AppRadius.brPill,
                      child: InkWell(
                        borderRadius: AppRadius.brPill,
                        onTap: () => openScan(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_rounded, color: AppColors.primaryDark, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Start a scan',
                                style: theme.textTheme.labelLarge?.copyWith(color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (recovery != null) ...[
                const SizedBox(height: AppSpacing.md),
                _RecoveryCard(reminder: recovery),
              ],

              const SizedBox(height: AppSpacing.md),
              _CareCard(upcoming: upcoming),

              const SizedBox(height: AppSpacing.md),
              _TintedRow(
                background: const Color(0xFFEFE7FD),
                iconBackground: kVetFabColor,
                icon: Icons.chat_bubble_rounded,
                title: 'Ask AI Vet',
                subtitle: user?.isPlus == true
                    ? 'Diet, vomiting, behaviour… unlimited with Plus'
                    : 'Diet, vomiting, behaviour… ${user?.chatRemainingToday ?? 5} free today',
                trailingColor: kVetFabColor,
                onTap: () => context
                    .findAncestorStateOfType<NavigationContainerState>()
                    ?.jumpToTab(NavigationContainerState.chatTab),
              ),

              if (user != null && !user.isPlus) ...[
                const SizedBox(height: AppSpacing.md),
                _TintedRow(
                  background: AppColors.accentLight,
                  iconBackground: AppColors.accentDark,
                  icon: Icons.workspace_premium_rounded,
                  title: 'Try PetCare Plus',
                  subtitle: 'Unlimited scans and AI Vet chat for every pet',
                  trailingColor: AppColors.accentDark,
                  onTap: () => PaywallScreen.open(context, source: 'home_banner'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  final bool isPlus;
  final int scans;
  final VoidCallback onTap;

  const _BalancePill({required this.isPlus, required this.scans, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = isPlus ? 'Plus' : '$scans scan${scans == 1 ? '' : 's'}';
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        borderRadius: AppRadius.brPill,
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: Border.all(color: AppColors.alpha(AppColors.border, 0.9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlus ? Icons.workspace_premium_rounded : Icons.center_focus_strong_rounded,
                size: 18,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (!isPlus) ...[
                const SizedBox(width: 4),
                const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryDark),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PetSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selected = provider.selectedPet;

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final pet in provider.pets) ...[
            _PetChip(
              label: pet.name,
              selected: pet.id == selected?.id,
              avatar: PetAvatar(pet: pet, size: 32),
              onTap: () => provider.selectPet(pet.id),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _PetChip(
            label: provider.pets.isEmpty ? 'Add your pet' : 'Add',
            selected: false,
            avatar: const Icon(Icons.add_rounded, color: AppColors.primaryDark),
            dashed: true,
            onTap: () => Navigator.push(
              context,
              AppRoutes.sharedAxis(const AddPetScreen(mode: AddPetMode.add)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Widget avatar;
  final VoidCallback onTap;
  final bool dashed;

  const _PetChip({
    required this.label,
    required this.selected,
    required this.avatar,
    required this.onTap,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.surfaceElevated,
      borderRadius: AppRadius.brPill,
      child: InkWell(
        borderRadius: AppRadius.brPill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brPill,
            border: selected
                ? null
                : Border.all(color: dashed ? AppColors.primary : AppColors.alpha(AppColors.border, 0.9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 32, height: 32, child: Center(child: avatar)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final Reminder reminder;

  const _RecoveryCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = reminder.dueAt.difference(DateTime.now()).inHours / 24;
    final due = days <= 0.5 ? 'due today' : 'due in ${days.ceil()} day${days.ceil() == 1 ? '' : 's'}';

    return Material(
      color: AppColors.criticalityModerateBg,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: () => Navigator.push(
          context,
          AppRoutes.sharedAxis(RecoveryScreen(seriesId: reminder.recoveryScanId!)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.alpha(AppColors.criticalityModerate, 0.35),
                  borderRadius: AppRadius.brSm,
                ),
                child: const Icon(Icons.schedule_rounded, color: Color(0xFF7A4F00)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recovery check $due', style: theme.textTheme.titleMedium),
                    Text(
                      '${reminder.petName} · ${reminder.title}',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Text(
                'Rescan',
                style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF7A4F00)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final Reminder? upcoming;

  const _CareCard({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void openReminders() =>
        Navigator.push(context, AppRoutes.sharedAxis(const RemindersScreen()));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brMd,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('UPCOMING CARE', style: theme.textTheme.labelSmall)),
              TextButton(
                onPressed: openReminders,
                child: Text(upcoming == null ? 'Add' : 'See all'),
              ),
            ],
          ),
          if (upcoming == null)
            Text(
              'Flea & tick, deworming, vaccines: set a reminder and never miss a dose.',
              style: theme.textTheme.bodyMedium,
            )
          else
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: AppRadius.brSm,
                  ),
                  child: const Icon(Icons.vaccines_rounded, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${upcoming!.petName}: ${upcoming!.title}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  RemindersScreen.relativeDue(upcoming!.dueAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TintedRow extends StatelessWidget {
  final Color background;
  final Color iconBackground;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color trailingColor;
  final VoidCallback onTap;

  const _TintedRow({
    required this.background,
    required this.iconBackground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: background,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: trailingColor),
            ],
          ),
        ),
      ),
    );
  }
}
