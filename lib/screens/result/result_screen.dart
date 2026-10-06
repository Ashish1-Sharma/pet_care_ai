import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/ai_response_model.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_loader.dart';

class ResultScreen extends StatelessWidget {
  final AiResponseData resultData;
  final int remainingScans;
  final List<String>? imageUrls;

  const ResultScreen({
    super.key,
    required this.resultData,
    required this.remainingScans,
    this.imageUrls,
  });

  Color _getCriticalityColor() {
    switch (resultData.criticality.toLowerCase()) {
      case 'low':
        return AppColors.criticalityLow;
      case 'moderate':
        return AppColors.criticalityModerate;
      case 'high':
        return AppColors.criticalityHigh;
      case 'emergency':
        return AppColors.criticalityEmergency;
      default:
        return AppColors.textDark;
    }
  }

  // Note: the old `_getCriticalityBg` tint helper is gone — the hero now
  // derives its gradient from the severity colour via
  // `AppColors.gradientForCriticality`, and the vet banner keeps using the
  // `criticality*Bg` tokens directly.

  IconData _getCriticalityIcon() {
    switch (resultData.criticality.toLowerCase()) {
      case 'low':
        return Icons.check_circle_outline_rounded;
      case 'moderate':
        return Icons.info_outline_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'emergency':
        return Icons.dangerous_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  /// Severity as a 0–1 fraction, driving the hero dial.
  double _criticalityFraction() {
    switch (resultData.criticality.toLowerCase()) {
      case 'low':
        return 0.25;
      case 'moderate':
        return 0.5;
      case 'high':
        return 0.75;
      case 'emergency':
        return 1.0;
      default:
        return 0.5;
    }
  }

  String _criticalityBlurb() {
    switch (resultData.criticality.toLowerCase()) {
      case 'low':
        return 'Nothing alarming — keep an eye on it.';
      case 'moderate':
        return 'Worth watching closely over the next few days.';
      case 'high':
        return 'This needs professional attention soon.';
      case 'emergency':
        return 'Seek veterinary care immediately.';
      default:
        return 'Review the details below.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final criticalityColor = _getCriticalityColor();
    final hasImages = imageUrls != null && imageUrls!.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CriticalityHero(
            label: resultData.criticality,
            blurb: _criticalityBlurb(),
            icon: _getCriticalityIcon(),
            color: criticalityColor,
            fraction: _criticalityFraction(),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.lg,
              AppSpacing.gutter,
              AppSpacing.xl,
            ),
            sliver: SliverList.list(
              children: [
                if (hasImages) ...[
                  const SectionHeader(
                    title: 'Uploaded photos',
                    icon: Icons.photo_library_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _PhotoGallery(urls: imageUrls!),
                  const SizedBox(height: AppSpacing.xl),
                ],

                const SectionHeader(
                  title: 'Possible conditions',
                  subtitle: 'Ranked by likelihood',
                  icon: Icons.biotech_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                _ConditionsCard(conditions: resultData.possibleConditions),

                const SizedBox(height: AppSpacing.xl),

                const SectionHeader(
                  title: 'What to do next',
                  icon: Icons.flag_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionCard(text: resultData.whatOwnerShouldDo),

                const SizedBox(height: AppSpacing.md),
                _VetBanner(
                  needVet: resultData.needVet,
                  visitWithin: resultData.visitWithin,
                ),

                const SizedBox(height: AppSpacing.xl),

                _ExpandableCard(
                  title: 'Reasoning & symptom analysis',
                  icon: Icons.psychology_rounded,
                  body: resultData.reason,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _ExpandableCard(
                  title: 'Home care instructions',
                  icon: Icons.home_rounded,
                  items: resultData.homeCare,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _ExpandableCard(
                  title: 'Emergency signs to watch',
                  icon: Icons.error_rounded,
                  accent: AppColors.criticalityEmergency,
                  items: resultData.emergencySigns,
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _ExpandableCard(
                  title: 'Medical disclaimer',
                  icon: Icons.gavel_rounded,
                  accent: AppColors.textMuted,
                  body: resultData.disclaimer,
                ),
              ],
            ),
          ),
        ],
      ),

      // Sticky action bar.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.sheet,
          boxShadow: AppShadows.floating,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$remainingScans scan${remainingScans == 1 ? '' : 's'} left',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                PrimaryButton(
                  text: 'Scan another pet',
                  icon: Icons.refresh_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed gradient hero tinted by severity, with an animated dial.
class _CriticalityHero extends StatelessWidget {
  final String label;
  final String blurb;
  final IconData icon;
  final Color color;
  final double fraction;

  const _CriticalityHero({
    required this.label,
    required this.blurb,
    required this.icon,
    required this.color,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      backgroundColor: color,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Assessment report',
        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors.gradientForCriticality(color),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SeverityDial(
                    fraction: fraction,
                    icon: icon,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Text(
                      blurb,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.alpha(Colors.white, 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring that sweeps to the severity level on entry.
class _SeverityDial extends StatelessWidget {
  final double fraction;
  final IconData icon;

  const _SeverityDial({required this.fraction, required this.icon});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 108,
          height: 108,
          child: CustomPaint(
            painter: _DialPainter(value: value),
            child: Center(child: child),
          ),
        );
      },
      child: Icon(icon, color: Colors.white, size: 42),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;

  _DialPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    const start = -3.14159 / 2;

    canvas.drawCircle(
      size.center(Offset.zero),
      rect.width / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.alpha(Colors.white, 0.22),
    );

    canvas.drawArc(
      rect,
      start,
      value * 2 * 3.14159,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.value != value;
}

/// Snap-scrolling gallery with shimmer placeholders.
class _PhotoGallery extends StatelessWidget {
  final List<String> urls;

  const _PhotoGallery({required this.urls});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const PageScrollPhysics(),
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: AppRadius.brMd,
            child: CachedNetworkImage(
              imageUrl: urls[index],
              width: 190,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Skeleton(width: 190, height: 150, radius: AppRadius.md),
              errorWidget: (context, url, error) => Container(
                width: 190,
                color: AppColors.surfaceSunken,
                child: const Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textLight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Ranked probability bars. The top condition is emphasised.
class _ConditionsCard extends StatelessWidget {
  final List<PossibleCondition> conditions;

  const _ConditionsCard({required this.conditions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sorted here for display only; the source list is left untouched.
    final ranked = [...conditions]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.alpha(AppColors.border, 0.7)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: List.generate(ranked.length, (i) {
          final condition = ranked[i];
          final isTop = i == 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: i == ranked.length - 1 ? 0 : AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        condition.name,
                        style: isTop
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${condition.probability}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isTop
                            ? AppColors.primaryDark
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                _ProbabilityBar(
                  value: condition.probability / 100.0,
                  emphasised: isTop,
                  delayMs: i * 90,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ProbabilityBar extends StatelessWidget {
  final double value;
  final bool emphasised;
  final int delayMs;

  const _ProbabilityBar({
    required this.value,
    required this.emphasised,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 900 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, animated, child) {
        return ClipRRect(
          borderRadius: AppRadius.brPill,
          child: Stack(
            children: [
              Container(height: 10, color: AppColors.surfaceSunken),
              FractionallySizedBox(
                widthFactor: animated,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: emphasised
                        ? AppColors.gradientPrimary
                        : null,
                    color: emphasised
                        ? null
                        : AppColors.alpha(AppColors.primary, 0.35),
                    borderRadius: AppRadius.brPill,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String text;

  const _ActionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accentLight, AppColors.alpha(AppColors.accent, 0.3)],
        ),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.alpha(AppColors.accentDark, 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              gradient: AppColors.gradientAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VetBanner extends StatelessWidget {
  final bool needVet;
  final String visitWithin;

  const _VetBanner({required this.needVet, required this.visitWithin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = needVet
        ? AppColors.criticalityHigh
        : AppColors.criticalityLow;
    final bg = needVet
        ? AppColors.criticalityHighBg
        : AppColors.criticalityLowBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.alpha(color, 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            needVet
                ? Icons.local_hospital_rounded
                : Icons.home_repair_service_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needVet ? 'See a vet' : 'No vet visit needed',
                  style: theme.textTheme.titleLarge?.copyWith(color: color),
                ),
                if (needVet && visitWithin.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Within $visitWithin',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom expandable card replacing the stock `ExpansionTile`: icon chip,
/// rotating chevron, smooth height animation.
///
/// Accepts either a [body] paragraph or a bulleted [items] list.
class _ExpandableCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? body;
  final List<String>? items;
  final Color accent;

  const _ExpandableCard({
    required this.title,
    required this.icon,
    this.body,
    this.items,
    this.accent = AppColors.primary,
  });

  @override
  State<_ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<_ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: _open
              ? AppColors.alpha(widget.accent, 0.4)
              : AppColors.alpha(AppColors.border, 0.7),
        ),
        boxShadow: _open ? AppShadows.card : AppShadows.soft,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: AppRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.alpha(widget.accent, 0.12),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Icon(widget.icon, size: 18, color: widget.accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleLarge),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: AppDurations.medium,
                    curve: Curves.easeOutCubic,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDurations.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _content(theme),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _content(ThemeData theme) {
    final items = widget.items;

    if (items != null) {
      if (items.isEmpty) {
        return Text('None reported.', style: theme.textTheme.bodySmall);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: AppSpacing.sm + 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(item, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Text(widget.body ?? '', style: theme.textTheme.bodyMedium);
  }
}
