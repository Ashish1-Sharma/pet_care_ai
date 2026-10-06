import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';

/// Selectable symptom pills.
///
/// Selection now fills with the brand gradient and grows a soft glow, so the
/// chosen set reads at a glance instead of as a subtle tint change.
class SymptomChipsWidget extends StatelessWidget {
  final List<String> availableSymptoms;
  final List<String> selectedSymptoms;
  final Function(List<String>) onSelectionChanged;

  const SymptomChipsWidget({
    super.key,
    required this.availableSymptoms,
    required this.selectedSymptoms,
    required this.onSelectionChanged,
  });

  void _toggleSymptom(String symptom) {
    final updatedList = List<String>.from(selectedSymptoms);
    if (updatedList.contains(symptom)) {
      updatedList.remove(symptom);
    } else {
      updatedList.add(symptom);
    }
    onSelectionChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm + 2,
      children: availableSymptoms.map((symptom) {
        final isSelected = selectedSymptoms.contains(symptom);
        return _SymptomChip(
          label: symptom,
          selected: isSelected,
          onTap: () => _toggleSymptom(symptom),
        );
      }).toList(),
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.gradientPrimary : null,
          color: selected ? null : AppColors.surfaceElevated,
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1.4,
          ),
          borderRadius: AppRadius.brPill,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.alpha(AppColors.teal, 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: AppDurations.fast,
              curve: Curves.easeOut,
              child: selected
                  ? const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
