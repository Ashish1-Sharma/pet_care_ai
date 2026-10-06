import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';
import '../../models/pet_profile.dart';
import '../../models/reminder.dart';
import '../../providers/app_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/primary_button.dart';
import '../recovery/recovery_screen.dart';
import 'notification_primer.dart';

/// Care reminders: flea & tick, deworming, vaccines, plus recovery check-ins.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// "Today", "Tomorrow", "in 4 days", "Nov 2".
  static String relativeDue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(due.year, due.month, due.day);
    final diff = day.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 7) return 'in $diff days';
    return '${_months[due.month - 1]} ${due.day}';
  }

  /// "Thu Oct 9, 9:00 AM".
  static String formatDue(DateTime due) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = due.hour % 12 == 0 ? 12 : due.hour % 12;
    final minute = due.minute.toString().padLeft(2, '0');
    final ampm = due.hour < 12 ? 'AM' : 'PM';
    return '${days[due.weekday - 1]} ${_months[due.month - 1]} ${due.day}, $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final reminders = provider.reminders;
    final weekEnd = DateTime.now().add(const Duration(days: 7));
    final thisWeek = reminders.where((r) => r.dueAt.isBefore(weekEnd)).toList();
    final later = reminders.where((r) => !r.dueAt.isBefore(weekEnd)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Care reminders', style: theme.textTheme.titleLarge)),
      body: reminders.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No reminders yet',
              message: 'Add flea & tick doses, deworming and vaccines so you never miss one.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (thisWeek.isNotEmpty) ...[
                  Text('THIS WEEK', style: theme.textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _Group(reminders: thisWeek),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (later.isNotEmpty) ...[
                  Text('COMING UP', style: theme.textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _Group(reminders: later),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: PrimaryButton(
            text: 'Add reminder',
            icon: Icons.add_rounded,
            onPressed: () => _AddReminderSheet.show(context),
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Reminder> reminders;

  const _Group({required this.reminders});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.brLg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (final r in reminders)
            Dismissible(
              key: ValueKey(r.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                color: AppColors.criticalityEmergencyBg,
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.criticalityEmergency),
              ),
              onDismissed: (_) => provider.deleteReminder(r),
              child: ListTile(
                onTap: r.isRecovery
                    ? () => Navigator.push(
                          context,
                          AppRoutes.sharedAxis(RecoveryScreen(seriesId: r.recoveryScanId!)),
                        )
                    : null,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: r.isRecovery ? AppColors.criticalityModerateBg : AppColors.primaryLight,
                    borderRadius: AppRadius.brSm,
                  ),
                  child: Icon(
                    r.isRecovery ? Icons.healing_rounded : Icons.vaccines_rounded,
                    color: r.isRecovery ? const Color(0xFF7A4F00) : AppColors.primaryDark,
                    size: 20,
                  ),
                ),
                title: Text(
                  r.isRecovery ? '${r.title} recovery check' : r.title,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${r.petName} · ${RemindersScreen.relativeDue(r.dueAt)}'
                  '${r.repeat == ReminderRepeat.none ? '' : ' · ${r.repeat.label.toLowerCase()}'}',
                ),
                trailing: r.isRecovery
                    ? const Icon(Icons.chevron_right_rounded)
                    : TextButton(
                        onPressed: () => provider.completeReminder(r),
                        child: const Text('Done'),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  static Future<void> show(BuildContext context) async {
    await NotificationPrimer.ensure(context);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (_) => const _AddReminderSheet(),
    );
  }

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  static const _presets = <String, ReminderRepeat>{
    'Flea & tick dose': ReminderRepeat.monthly,
    'Deworming': ReminderRepeat.quarterly,
    'Heartworm pill': ReminderRepeat.monthly,
    'Vaccine booster': ReminderRepeat.yearly,
    'Grooming': ReminderRepeat.monthly,
  };

  final _titleController = TextEditingController(text: 'Flea & tick dose');
  ReminderRepeat _repeat = ReminderRepeat.monthly;
  PetProfile? _pet;
  late DateTime _due;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _due = DateTime(now.year, now.month, now.day + 1, 9);
    _pet = Provider.of<AppProvider>(context, listen: false).selectedPet;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    setState(() {
      _due = DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    await Provider.of<AppProvider>(context, listen: false).addReminder(
      title: title,
      dueAt: _due,
      pet: _pet,
      repeat: _repeat,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pets = Provider.of<AppProvider>(context, listen: false).pets;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New reminder', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in _presets.entries)
                  ChoiceChip(
                    label: Text(entry.key),
                    selected: _titleController.text == entry.key,
                    onSelected: (_) => setState(() {
                      _titleController.text = entry.key;
                      _repeat = entry.value;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'What'),
              onChanged: (_) => setState(() {}),
            ),
            if (pets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _pet?.id,
                decoration: const InputDecoration(labelText: 'For'),
                items: [
                  for (final p in pets) DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (id) => setState(() => _pet = pets.firstWhere((p) => p.id == id)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ReminderRepeat>(
              initialValue: _repeat,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: [
                for (final r in ReminderRepeat.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (r) => setState(() => _repeat = r ?? ReminderRepeat.none),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded, color: AppColors.primaryDark),
              title: const Text('When'),
              subtitle: Text(RemindersScreen.formatDue(_due)),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(text: 'Save reminder', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
