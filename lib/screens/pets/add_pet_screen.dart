import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/pet_profile.dart';
import '../../providers/app_provider.dart';
import '../../services/analytics_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/primary_button.dart';
import '../login/login_screen.dart';

enum AddPetMode {
  /// First-run: the pet is kept on the device and saved after sign-in.
  onboarding,
  add,
  edit,
}

class AddPetScreen extends StatefulWidget {
  final AddPetMode mode;
  final PetProfile? pet;

  const AddPetScreen({super.key, required this.mode, this.pet});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.pet?.name ?? '');
  late final TextEditingController _breed = TextEditingController(text: widget.pet?.breed ?? '');
  late final TextEditingController _age = TextEditingController(text: widget.pet?.age ?? '');
  late final TextEditingController _weight = TextEditingController(text: widget.pet?.weight ?? '');
  late String _type = widget.pet?.type ?? 'Dog';
  bool _saving = false;

  bool get _onboarding => widget.mode == AddPetMode.onboarding;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  PetProfile _buildPet() => PetProfile(
    id: widget.pet?.id ?? '',
    name: _name.text.trim(),
    type: _type,
    breed: _breed.text.trim(),
    age: _age.text.trim(),
    weight: _weight.text.trim(),
  );

  Future<void> _continueToLogin() async {
    await StorageService().setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(context, AppRoutes.fadeThrough(const LoginScreen()));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final pet = _buildPet();

    try {
      if (_onboarding) {
        await StorageService().savePendingPet(pet);
        track('onboarding_pet_added', {'type': pet.type});
        await _continueToLogin();
        return;
      }
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (widget.mode == AddPetMode.edit) {
        await provider.updatePet(pet);
      } else {
        await provider.addPet(pet);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.criticalityEmergency),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = AppConstants.petTypes;

    return Scaffold(
      appBar: AppBar(
        title: _onboarding ? const Text('1 of 2') : null,
        actions: [
          if (_onboarding)
            TextButton(
              onPressed: () {
                track('onboarding_pet_skipped');
                _continueToLogin();
              },
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.lg),
          children: [
            Text(
              widget.mode == AddPetMode.edit ? 'Edit ${widget.pet?.name ?? 'pet'}' : 'Who are we caring for?',
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We tailor every scan and reminder to your pet.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('PET TYPE', style: theme.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final type in types)
                  ChoiceChip(
                    label: Text(type),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Buddy'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _breed,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Breed (optional)', hintText: 'e.g. Golden Retriever'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: 'Age (optional)', hintText: '3 years'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: 'Weight (optional)', hintText: '30 kg'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.md),
          child: PrimaryButton(
            text: _onboarding ? 'Continue' : 'Save',
            isLoading: _saving,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
