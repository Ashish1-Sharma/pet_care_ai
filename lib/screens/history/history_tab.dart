import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../home/navigation_container.dart';
import '../result/result_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    // Lazy-load history data from backend on tab initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchHistory();
    });
  }

  Color _getCriticalityColor(String criticality) {
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
        return AppColors.textMuted;
    }
  }

  Color _getCriticalityBg(String criticality) {
    switch (criticality.toLowerCase()) {
      case 'low':
        return AppColors.criticalityLowBg;
      case 'moderate':
        return AppColors.criticalityModerateBg;
      case 'high':
        return AppColors.criticalityHighBg;
      case 'emergency':
        return AppColors.criticalityEmergencyBg;
      default:
        return AppColors.surfaceSunken;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final history = provider.historyList;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Scan history', style: theme.textTheme.headlineMedium),
        toolbarHeight: 72,
      ),
      body: provider.isLoading && history.isEmpty
          ? const SkeletonList()
          : RefreshIndicator(
              onRefresh: () => provider.fetchHistory(),
              color: AppColors.primary,
              child: history.isEmpty
                  ? ListView(
                      // Keeps pull-to-refresh working on an empty list.
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: const EmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: 'No scans yet',
                            message:
                                'Your health reports will appear here once '
                                'you run your first scan.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        kFloatingNavHeight + AppSpacing.lg,
                      ),
                      itemCount: history.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final dateFormatted = Helpers.formatDate(
                          item.createdAt,
                        );

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(
                              right: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.criticalityEmergency,
                              borderRadius: AppRadius.brLg,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete scan?'),
                                  content: const Text(
                                    'This report will be removed from your '
                                    'history permanently.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          color:
                                              AppColors.criticalityEmergency,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            final success = await provider.deleteHistoryItem(
                              item.id,
                            );
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    provider.errorMessage ??
                                        'Failed to delete scan',
                                  ),
                                  backgroundColor:
                                      AppColors.criticalityEmergency,
                                ),
                              );
                            }
                          },
                          child: _HistoryCard(
                            title: '${item.petType} • ${item.bodyPart}',
                            date: dateFormatted,
                            criticality: item.criticality,
                            criticalityColor: _getCriticalityColor(
                              item.criticality,
                            ),
                            criticalityBg: _getCriticalityBg(item.criticality),
                            onTap: () {
                              Navigator.push(
                                context,
                                AppRoutes.sharedAxis(
                                  ResultScreen(
                                    resultData: item.toAiResponseData(),
                                    remainingScans:
                                        provider.currentUser?.remainingScans ??
                                        0,
                                    // Lazy loaded/passed here only when opening
                                    imageUrls: item.imageUrls,
                                  ),
                                ),
                              );
                            },
                          ).animate(delay: (index * 45).ms).fadeIn(
                            duration: AppDurations.medium,
                          ).moveY(begin: 12, end: 0, curve: Curves.easeOutCubic),
                        );
                      },
                    ),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String date;
  final String criticality;
  final Color criticalityColor;
  final Color criticalityBg;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.title,
    required this.date,
    required this.criticality,
    required this.criticalityColor,
    required this.criticalityBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brLg,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.alpha(AppColors.border, 0.7)),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.alpha(criticalityColor, 0.18),
                      AppColors.alpha(criticalityColor, 0.06),
                    ],
                  ),
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: criticalityColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: criticalityBg,
                  borderRadius: AppRadius.brPill,
                ),
                child: Text(
                  criticality,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: criticalityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
