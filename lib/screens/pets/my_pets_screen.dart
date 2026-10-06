import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/pet_profile.dart';
import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/primary_button.dart';
import 'add_pet_screen.dart';

class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  Future<void> _delete(BuildContext context, PetProfile pet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${pet.name}?'),
        content: const Text('Past scans stay in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.criticalityEmergency)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await Provider.of<AppProvider>(context, listen: false).deletePet(pet.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('My pets', style: theme.textTheme.titleLarge)),
      body: provider.pets.isEmpty
          ? const EmptyState(
              icon: Icons.pets_rounded,
              title: 'No pets yet',
              message: 'Add your pet to personalise scans and reminders.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: provider.pets.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final pet = provider.pets[i];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: AppRadius.brMd,
                    boxShadow: AppShadows.soft,
                  ),
                  child: ListTile(
                    leading: PetAvatar(pet: pet, size: 44),
                    title: Text(pet.name, style: theme.textTheme.titleLarge),
                    subtitle: pet.subtitle.isEmpty ? null : Text(pet.subtitle),
                    onTap: () => Navigator.push(
                      context,
                      AppRoutes.sharedAxis(AddPetScreen(mode: AddPetMode.edit, pet: pet)),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _delete(context, pet),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: PrimaryButton(
            text: 'Add a pet',
            icon: Icons.add_rounded,
            onPressed: () => Navigator.push(
              context,
              AppRoutes.sharedAxis(const AddPetScreen(mode: AddPetMode.add)),
            ),
          ),
        ),
      ),
    );
  }
}
