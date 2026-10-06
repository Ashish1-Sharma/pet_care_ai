import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';

/// Shimmering placeholder blocks, used instead of bare spinners while
/// history and report content loads.
class Skeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  const Skeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 999;

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceSunken,
      highlightColor: AppColors.alpha(Colors.white, 0.85),
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Placeholder for a row in the scan history list.
class HistoryCardSkeleton extends StatelessWidget {
  const HistoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.alpha(AppColors.border, 0.7)),
      ),
      child: Row(
        children: [
          const Skeleton(width: 56, height: 56, radius: AppRadius.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 130, height: 14),
                SizedBox(height: AppSpacing.sm),
                Skeleton(width: 90, height: 11),
                SizedBox(height: AppSpacing.sm),
                Skeleton(width: 60, height: 20, radius: AppRadius.pill),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A short stack of [HistoryCardSkeleton]s.
class SkeletonList extends StatelessWidget {
  final int count;

  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.md,
      ),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const HistoryCardSkeleton(),
    );
  }
}
