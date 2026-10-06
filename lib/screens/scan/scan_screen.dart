import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/pet_profile.dart';
import '../../providers/app_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/pet_avatar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/symptom_chip.dart';
import '../payment/out_of_scans_sheet.dart';
import '../payment/paywall_screen.dart';
import '../result/result_screen.dart';

/// A new AI health scan. Opened for the selected [pet]; with [recoveryOf] it
/// is a follow-up photo in an existing recovery series.
class ScanScreen extends StatefulWidget {
  final PetProfile? pet;
  final String? recoveryOf;

  const ScanScreen({super.key, this.pet, this.recoveryOf});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _descriptionController = TextEditingController();

  String? _selectedPetType;
  String? _selectedBodyPart;
  List<String> _selectedSymptoms = [];
  List<String> _selectedImages = [];

  bool get _isFollowUp => widget.recoveryOf != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null && AppConstants.petTypes.contains(pet.type)) {
      _selectedPetType = pet.type;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);

      // A follow-up repeats the first scan's pet type and body part.
      if (_isFollowUp) {
        final first = provider.historyItem(widget.recoveryOf!);
        if (first != null) {
          setState(() {
            if (AppConstants.petTypes.contains(first.petType)) {
              _selectedPetType = first.petType;
            }
            if (AppConstants.bodyParts.contains(first.bodyPart)) {
              _selectedBodyPart = first.bodyPart;
            }
          });
        }
      }

      if (provider.isDemoMode) {
        setState(() {
          _selectedPetType ??= 'Dog';
          _selectedBodyPart ??= 'Skin';
          _selectedSymptoms = ['Itching', 'Redness'];
          _descriptionController.text =
              'The dog has been scratching the neck area frequently and it looks red.';
          _selectedImages = ['demo_placeholder.jpg'];
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _warn(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? AppColors.criticalityEmergency,
        ),
      );
  }

  // --- Step pickers -------------------------------------------------------

  Future<void> _pickPetType() async {
    final value = await _showSheet<String>(
      title: 'Pet type',
      subtitle: 'Which animal are we looking at?',
      builder:
          (context) => _OptionGrid(
            options: AppConstants.petTypes,
            selected: _selectedPetType,
            onSelected: (value) => Navigator.pop(context, value),
          ),
    );
    if (value != null) setState(() => _selectedPetType = value);
  }

  Future<void> _pickBodyPart() async {
    final value = await _showSheet<String>(
      title: 'Body part',
      subtitle: 'Where is the problem?',
      builder:
          (context) => _OptionGrid(
            options: AppConstants.bodyParts,
            selected: _selectedBodyPart,
            onSelected: (value) => Navigator.pop(context, value),
          ),
    );
    if (value != null) setState(() => _selectedBodyPart = value);
  }

  Future<void> _pickSymptoms() async {
    var draft = List<String>.from(_selectedSymptoms);

    final value = await _showSheet<List<String>>(
      title: 'Symptoms',
      subtitle: 'Tap everything you have noticed',
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Column(
                  children: [
                    SymptomChipsWidget(
                      availableSymptoms: AppConstants.symptomsList,
                      selectedSymptoms: draft,
                      onSelectionChanged:
                          (value) => setSheetState(() => draft = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: draft.isEmpty ? 'Done' : 'Done (${draft.length})',
                      onPressed: () => Navigator.pop(context, draft),
                    ),
                  ],
                ),
          ),
    );
    if (value != null) setState(() => _selectedSymptoms = value);
  }

  Future<void> _editDescription() async {
    final value = await _showSheet<String>(
      title: 'Describe it',
      subtitle: 'The more context, the better the report',
      builder:
          (context) =>
              _DescriptionSheet(initialText: _descriptionController.text),
    );

    if (value != null) setState(() => _descriptionController.text = value);
  }

  Future<void> _pickPhotos() async {
    var draft = List<String>.from(_selectedImages);

    final value = await _showSheet<List<String>>(
      title: 'Photos',
      subtitle: 'Clear, well-lit close-ups work best',
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Column(
                  children: [
                    ImagePickerWidget(
                      imagePaths: draft,
                      onImagesChanged:
                          (value) => setSheetState(() => draft = value),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      text: 'Done',
                      onPressed: () => Navigator.pop(context, draft),
                    ),
                  ],
                ),
          ),
    );
    if (value != null) setState(() => _selectedImages = value);
  }

  /// One sheet shape for every step, so the pickers feel like one family.
  Future<T?> _showSheet<T>({
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.gutter,
              right: AppSpacing.gutter,
              top: AppSpacing.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: AppRadius.brPill,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  builder(context),
                ],
              ),
            ),
          ),
    );
  }

  // --- Submit -------------------------------------------------------------

  Future<void> _handleAnalyze() async {
    if (_selectedImages.isEmpty) {
      _warn('Please add at least one photo of the problem area.');
      return;
    }

    if (_selectedPetType == null || _selectedBodyPart == null) {
      _warn('Please select both Pet Type and Body Part.');
      return;
    }

    if (_selectedSymptoms.isEmpty) {
      _warn('Please select at least one symptom you have noticed.');
      return;
    }

    final descriptionError = Validators.validateDescription(
      _descriptionController.text,
    );
    if (descriptionError != null) {
      _warn(descriptionError);
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Out of scans: show the options sheet rather than a dead-end error.
    if (!(provider.currentUser?.canScan ?? false)) {
      await OutOfScansSheet.show(context, petName: widget.pet?.name);
      return;
    }

    LoadingDialog.show(context, imagePath: _selectedImages.first);

    final response = await provider.scanPet(
      petType: _selectedPetType!,
      bodyPart: _selectedBodyPart!,
      description: _descriptionController.text,
      symptoms: _selectedSymptoms,
      imagePaths: _selectedImages,
      petId: widget.pet?.id,
      recoveryOf: widget.recoveryOf,
    );

    if (!mounted) return;
    LoadingDialog.hide(context);

    if (response != null && response.success && response.data != null) {
      Navigator.pushReplacement(
        context,
        AppRoutes.sharedAxis(
          ResultScreen(
            resultData: response.data!,
            remainingScans: response.remainingScans,
            scanId: response.scanId,
            seriesId: response.recoveryOf ?? response.scanId,
            pet: widget.pet,
            isFollowUp: _isFollowUp,
            isNewResult: true,
          ),
        ),
      );
    } else if (provider.errorCode == 'NO_SCANS') {
      await OutOfScansSheet.show(context, petName: widget.pet?.name);
    } else {
      _warn(provider.errorMessage ?? 'Analysis failed');
    }
  }

  // --- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final theme = Theme.of(context);
    final description = _descriptionController.text.trim();
    final pet = widget.pet;
    final isPlus = user?.isPlus == true;

    final String costLine;
    if (isPlus) {
      costLine = 'Included in PetCare Plus';
    } else {
      final left = user?.remainingScans ?? 0;
      costLine = left > 0
          ? 'Uses 1 scan · ${left - 1} left after this'
          : 'You have no scans left';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isFollowUp ? 'Recovery check' : 'New scan',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.lg,
        ),
        children: [
          if (pet != null) ...[
            Row(
              children: [
                PetAvatar(pet: pet, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isFollowUp ? 'Follow-up for ${pet.name}' : 'Scan for ${pet.name}',
                        style: theme.textTheme.titleLarge,
                      ),
                      if (pet.subtitle.isNotEmpty)
                        Text(pet.subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_isFollowUp) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.brMd,
              ),
              child: Text(
                'Take the photo from the same angle and distance as last time, '
                'so the AI can compare them.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.alpha(AppColors.border, 0.7)),
              boxShadow: AppShadows.card,
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                _StepRow(
                  step: 1,
                  icon: Icons.photo_camera_rounded,
                  title: 'Photos',
                  hint: 'Clear, close-up photos of the problem',
                  value: _selectedImages.isEmpty
                      ? null
                      : '${_selectedImages.length} of '
                          '${ImagePickerWidget.maxImages} added',
                  onTap: _pickPhotos,
                ),
                const _StepDivider(),
                _StepRow(
                  step: 2,
                  icon: Icons.pets_rounded,
                  title: 'Pet type',
                  hint: 'Select your pet',
                  value: _selectedPetType,
                  onTap: _pickPetType,
                ),
                const _StepDivider(),
                _StepRow(
                  step: 3,
                  icon: Icons.my_location_rounded,
                  title: 'Body part',
                  hint: 'Where is the problem?',
                  value: _selectedBodyPart,
                  onTap: _pickBodyPart,
                ),
                const _StepDivider(),
                _StepRow(
                  step: 4,
                  icon: Icons.monitor_heart_rounded,
                  title: 'Symptoms',
                  hint: 'What have you noticed?',
                  value: _selectedSymptoms.isEmpty ? null : _selectedSymptoms.join(', '),
                  onTap: _pickSymptoms,
                ),
                const _StepDivider(),
                _StepRow(
                  step: 5,
                  icon: Icons.chat_rounded,
                  title: 'Describe (optional)',
                  hint: 'When it started, what makes it worse…',
                  value: description.isEmpty ? null : description,
                  onTap: _editDescription,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
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
                PrimaryButton(
                  text: 'Analyze with AI',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _handleAnalyze,
                ),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: isPlus
                      ? null
                      : () => PaywallScreen.open(context, source: 'scan_cost_line'),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text.rich(
                      TextSpan(
                        text: costLine,
                        children: [
                          if (!isPlus)
                            const TextSpan(
                              text: '  ·  Get more',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: AppSpacing.md,
      color: AppColors.alpha(AppColors.border, 0.9),
    );
  }
}

/// One numbered step. Shows its selected value once the user has filled it in,
/// so the whole scan reads as a checklist.
class _StepRow extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String hint;
  final String? value;
  final VoidCallback onTap;

  const _StepRow({
    required this.step,
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = value != null && value!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? AppColors.primaryDark : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child:
                    filled
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                          '$step',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.brSm,
                ),
                child: Icon(icon, size: 21, color: AppColors.primaryDark),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      filled ? value! : hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            filled
                                ? AppColors.primaryDark
                                : AppColors.textMuted,
                        fontWeight: filled ? FontWeight.w600 : null,
                      ),
                    ),
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

/// The description sheet owns its controller: disposing it from the caller
/// would tear it down while the sheet is still animating out.
class _DescriptionSheet extends StatefulWidget {
  final String initialText;

  const _DescriptionSheet({required this.initialText});

  @override
  State<_DescriptionSheet> createState() => _DescriptionSheetState();
}

class _DescriptionSheetState extends State<_DescriptionSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 5,
          maxLength: 300,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText:
                'e.g. has been scratching this spot for three days and it '
                'looks redder each morning…',
            fillColor: AppColors.surfaceSunken,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          text: 'Save',
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}

/// Single-choice option pills, used by the pet type and body part sheets.
class _OptionGrid extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm + 2,
      children:
          options.map((option) {
            final isSelected = option == selected;

            return Material(
              color: isSelected ? AppColors.primary : AppColors.surfaceSunken,
              borderRadius: AppRadius.brPill,
              child: InkWell(
                borderRadius: AppRadius.brPill,
                onTap: () => onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + 2,
                    vertical: 12,
                  ),
                  child: Text(
                    option,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
