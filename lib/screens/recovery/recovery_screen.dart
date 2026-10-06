import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/history_model.dart';
import '../../providers/app_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/primary_button.dart';
import '../home/navigation_container.dart';
import '../reminders/notification_primer.dart';
import '../reminders/reminders_screen.dart';
import '../result/result_screen.dart';

/// Photo timeline and risk trend for one health issue, from the first scan
/// through each follow-up.
class RecoveryScreen extends StatefulWidget {
  /// Id of the first scan in the series.
  final String seriesId;

  const RecoveryScreen({super.key, required this.seriesId});

  /// Risk level as a 0–4 score, for the trend (lower is better).
  static int riskScore(String criticality) {
    switch (criticality.toLowerCase()) {
      case 'low':
        return 1;
      case 'moderate':
        return 2;
      case 'high':
        return 3;
      case 'emergency':
        return 4;
      default:
        return 0;
    }
  }

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.recoverySeries(widget.seriesId).isEmpty) provider.fetchHistory();
    });
  }

  String _trend(List<HistoryItem> series) {
    if (series.length < 2) return 'Rescan in a few days to see how it is changing.';
    final first = RecoveryScreen.riskScore(series.first.criticality);
    final last = RecoveryScreen.riskScore(series.last.criticality);
    if (last == 0 || first == 0) return 'Compare the photos below to see how it is changing.';
    if (last < first) return 'Improving: keep up the home care routine.';
    if (last > first) return 'Getting worse: please contact your vet.';
    return 'About the same: keep monitoring, and see a vet if it does not improve.';
  }

  Future<void> _remind(BuildContext context, HistoryItem first) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await NotificationPrimer.ensure(context);
    final now = DateTime.now();
    final pet = provider.pets.where((p) => p.id == first.petId).firstOrNull;
    final title = first.possibleConditions.isEmpty
        ? 'Recovery check'
        : first.possibleConditions.first.name;
    await provider.addReminder(
      title: title,
      dueAt: DateTime(now.year, now.month, now.day + 3, 9),
      pet: pet,
      recoveryScanId: widget.seriesId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final series = provider.recoverySeries(widget.seriesId);
    final first = series.isEmpty ? null : series.first;
    final reminder = provider.recoveryReminderFor(widget.seriesId);
    final pet = first == null ? null : provider.pets.where((p) => p.id == first.petId).firstOrNull;
    final isPlus = provider.isPlus;

    final title = first == null
        ? 'Recovery tracker'
        : first.possibleConditions.isEmpty
            ? '${first.bodyPart} recovery'
            : first.possibleConditions.first.name;

    return Scaffold(
      appBar: AppBar(title: Text(title, style: theme.textTheme.titleLarge)),
      body: first == null
          ? Center(
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'This scan is no longer in your history.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  '${pet?.name ?? first.petType} · ${first.bodyPart} · started ${Helpers.formatDate(first.createdAt)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),

                Material(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.brMd,
                  child: InkWell(
                    borderRadius: AppRadius.brMd,
                    onTap: reminder == null
                        ? () => _remind(context, first)
                        : () => Navigator.push(context, AppRoutes.sharedAxis(const RemindersScreen())),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AppColors.primaryDark),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              reminder == null
                                  ? 'Remind me to rescan in 3 days'
                                  : 'Next check: ${RemindersScreen.formatDue(reminder.dueAt)}',
                              style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                          Text(
                            reminder == null ? 'Set' : 'Edit',
                            style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                _Card(
                  title: 'PHOTO TIMELINE',
                  child: SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: series.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final item = series[i];
                        final date = item.createdAtDate;
                        final day = date == null
                            ? ''
                            : 'Day ${date.difference(first.createdAtDate ?? date).inDays + 1}';
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            AppRoutes.sharedAxis(
                              ResultScreen(
                                resultData: item.toAiResponseData(),
                                remainingScans: provider.currentUser?.remainingScans ?? 0,
                                imageUrls: item.imageUrls,
                                scanId: item.id,
                                seriesId: widget.seriesId,
                                pet: pet,
                                isFollowUp: i > 0,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: AppRadius.brSm,
                                child: SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: item.imageUrls.isEmpty
                                      ? Container(color: AppColors.surfaceSunken)
                                      : CachedNetworkImage(
                                          imageUrl: item.imageUrls.first,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) =>
                                              Container(color: AppColors.surfaceSunken),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(day, style: theme.textTheme.labelMedium),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                _Card(
                  title: 'RISK TREND',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (final item in series)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(item.criticality, style: theme.textTheme.labelSmall),
                                      const SizedBox(height: 4),
                                      Container(
                                        height: 18.0 + 22 * RecoveryScreen.riskScore(item.criticality),
                                        decoration: BoxDecoration(
                                          color: _riskColor(item.criticality),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(_trend(series), style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: first == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      text: isPlus ? 'Rescan now' : 'Rescan now · uses 1 scan',
                      icon: Icons.photo_camera_rounded,
                      onPressed: () {
                        if (pet != null) provider.selectPet(pet.id);
                        openScan(context, recoveryOf: widget.seriesId);
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _riskColor(String criticality) {
    switch (criticality.toLowerCase()) {
      case 'low':
        return AppColors.criticalityLow;
      case 'moderate':
        return AppColors.criticalityModerate;
      case 'high':
        return AppColors.criticalityHigh;
      case 'emergency':
        return AppColors.criticalityEmergency;
      default:
        return AppColors.border;
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
