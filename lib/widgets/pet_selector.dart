import 'package:flutter/material.dart';
import '../config/theme/app_colors.dart';
import '../config/theme/app_spacing.dart';

/// Labelled dropdown for pet type / breed.
///
/// The four-border-state `InputDecoration` this used to declare inline now
/// comes from `inputDecorationTheme` in `AppTheme`.
class PetSelectorWidget extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final String placeholder;
  final Function(String?) onChanged;
  final IconData? icon;

  const PetSelectorWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.placeholder,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: AppColors.textMuted,
          ),
          hint: Text(placeholder, style: theme.textTheme.bodyMedium),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: AppColors.textMuted),
            fillColor: AppColors.surfaceSunken,
          ),
          dropdownColor: Colors.white,
          borderRadius: AppRadius.brMd,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}
