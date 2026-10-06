import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../providers/app_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/image_picker_widget.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/symptom_chip.dart';
import '../payment/buy_scans_screen.dart';
import '../result/result_screen.dart';
import 'navigation_container.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final _descriptionController = TextEditingController();

  String? _selectedPetType;
  String? _selectedBodyPart;
  List<String> _selectedSymptoms = [];
  List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (provider.isDemoMode) {
        setState(() {
          _selectedPetType = 'Dog';
          _selectedBodyPart = 'Skin';
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

  void _navigateToPayment() {
    Navigator.push(context, AppRoutes.sharedAxis(const BuyScansScreen()));
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
    debugPrint('[ScanTab] Start New Scan tapped');
    debugPrint('[ScanTab]   petType      = $_selectedPetType');
    debugPrint('[ScanTab]   bodyPart     = $_selectedBodyPart');
    debugPrint('[ScanTab]   symptoms     = $_selectedSymptoms');
    debugPrint(
      '[ScanTab]   description  = "${_descriptionController.text.trim()}"',
    );
    debugPrint('[ScanTab]   images       = $_selectedImages');

    if (_selectedPetType == null || _selectedBodyPart == null) {
      debugPrint('[ScanTab] Blocked: pet type or body part missing');
      _warn('Please select both Pet Type and Body Part.');
      return;
    }

    final descriptionError = Validators.validateDescription(
      _descriptionController.text,
    );
    if (descriptionError != null) {
      debugPrint('[ScanTab] Blocked: $descriptionError');
      _warn(descriptionError);
      return;
    }

    if (_selectedImages.isEmpty) {
      debugPrint('[ScanTab] Blocked: no photos added');
      _warn('Please add at least one photo of the symptoms');
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    final balance = provider.currentUser?.remainingScans ?? 0;
    debugPrint(
      '[ScanTab] Scan balance = $balance, demoMode = '
      '${provider.isDemoMode}',
    );
    if (balance <= 0) {
      debugPrint('[ScanTab] Blocked: no scans left');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No scans left. Top up to keep scanning.'),
          backgroundColor: AppColors.criticalityHigh,
          action: SnackBarAction(
            label: 'BUY NOW',
            textColor: Colors.white,
            onPressed: _navigateToPayment,
          ),
        ),
      );
      return;
    }

    debugPrint('[ScanTab] Validation passed — calling scanPet()');
    LoadingDialog.show(context, imagePath: _selectedImages.first);

    final response = await provider.scanPet(
      petType: _selectedPetType!,
      bodyPart: _selectedBodyPart!,
      description: _descriptionController.text,
      symptoms: _selectedSymptoms,
      imagePaths: _selectedImages,
    );

    debugPrint(
      '[ScanTab] scanPet() returned: success=${response?.success}, '
      'hasData=${response?.data != null}, '
      'remainingScans=${response?.remainingScans}',
    );

    if (!mounted) {
      debugPrint('[ScanTab] Widget unmounted before the response arrived');
      return;
    }
    LoadingDialog.hide(context);

    if (response != null && response.success && response.data != null) {
      debugPrint('[ScanTab] Scan succeeded — opening result screen');
      // Clear fields upon success (restore demo pre-populations in demo mode)
      setState(() {
        if (provider.isDemoMode) {
          _selectedPetType = 'Dog';
          _selectedBodyPart = 'Skin';
          _selectedSymptoms = ['Itching', 'Redness'];
          _selectedImages = ['demo_placeholder.jpg'];
          _descriptionController.text =
              'The dog has been scratching the neck area frequently and it looks red.';
        } else {
          _selectedPetType = null;
          _selectedBodyPart = null;
          _selectedSymptoms = [];
          _selectedImages = [];
          _descriptionController.clear();
        }
      });

      Navigator.push(
        context,
        AppRoutes.sharedAxis(
          ResultScreen(
            resultData: response.data!,
            remainingScans: response.remainingScans,
          ),
        ),
      );
    } else {
      debugPrint('[ScanTab] Scan failed: ${provider.errorMessage}');
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            kFloatingNavHeight + AppSpacing.lg,
          ),
          children: [
            _GreetingHeader(
              name: user?.name ?? 'Pet Owner',
              profileImage: user?.profileImage ?? '',
              remainingScans: user?.remainingScans ?? 0,
              onScansTap: _navigateToPayment,
            ),

            const SizedBox(height: AppSpacing.xl),

            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.brLg,
                border: Border.all(
                  color: AppColors.alpha(AppColors.border, 0.7),
                ),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  // Hero: copy on the left, the pets peeking in on the right.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New health scan',
                                style: theme.textTheme.headlineLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Our AI will analyze and help you understand '
                                'your pet’s condition.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 4,
                          child: Image.asset(
                            'assets/dog_cat.png',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (context, error, stack) =>
                                    const SizedBox(height: 120),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Steps: each row opens its own picker sheet.
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brLg,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        _StepRow(
                          step: 1,
                          icon: Icons.pets_rounded,
                          title: 'Pet type',
                          hint: 'Select your pet',
                          value: _selectedPetType,
                          onTap: _pickPetType,
                        ),
                        const _StepDivider(),
                        _StepRow(
                          step: 2,
                          icon: Icons.my_location_rounded,
                          title: 'Body part',
                          hint: 'Choose affected area',
                          value: _selectedBodyPart,
                          onTap: _pickBodyPart,
                        ),
                        const _StepDivider(),
                        _StepRow(
                          step: 3,
                          icon: Icons.monitor_heart_rounded,
                          title: 'Symptoms',
                          hint: 'Select visible symptoms',
                          value:
                              _selectedSymptoms.isEmpty
                                  ? null
                                  : _selectedSymptoms.join(', '),
                          onTap: _pickSymptoms,
                        ),
                        const _StepDivider(),
                        _StepRow(
                          step: 4,
                          icon: Icons.chat_rounded,
                          title: 'Describe',
                          hint: 'Add more details',
                          value: description.isEmpty ? null : description,
                          onTap: _editDescription,
                        ),
                        const _StepDivider(),
                        _StepRow(
                          step: 5,
                          icon: Icons.photo_camera_rounded,
                          title: 'Photos',
                          hint: 'Add clear photos',
                          value:
                              _selectedImages.isEmpty
                                  ? null
                                  : '${_selectedImages.length} of '
                                      '${ImagePickerWidget.maxImages} added',
                          onTap: _pickPhotos,
                        ),

                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: PrimaryButton(
                            text: 'Start New Scan',
                            icon: Icons.auto_awesome_rounded,
                            onPressed: _handleAnalyze,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar + greeting on the left, scan balance pill on the right.
class _GreetingHeader extends StatelessWidget {
  final String name;
  final String profileImage;
  final int remainingScans;
  final VoidCallback onScansTap;

  const _GreetingHeader({
    required this.name,
    required this.profileImage,
    required this.remainingScans,
    required this.onScansTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The header greets by first name only, as in the design.
    final firstName = name.trim().split(' ').first;

    return Row(
      children: [
        _Avatar(image: profileImage),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello,', style: theme.textTheme.bodyMedium),
              Text(
                firstName.isEmpty ? 'there' : firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ScanBalancePill(scans: remainingScans, onTap: onScansTap),
      ],
    );
  }
}

class _ScanBalancePill extends StatelessWidget {
  final int scans;
  final VoidCallback onTap;

  const _ScanBalancePill({required this.scans, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, AppSpacing.md, 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scans left', style: theme.textTheme.bodySmall),
                  Text('$scans', style: theme.textTheme.titleLarge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String image;

  const _Avatar({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
        child:
            image.isEmpty
                ? const Icon(
                  Icons.pets_rounded,
                  color: AppColors.primaryDark,
                  size: 24,
                )
                : null,
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
