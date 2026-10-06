/// How often a care reminder repeats.
enum ReminderRepeat { none, weekly, monthly, quarterly, yearly }

extension ReminderRepeatLabel on ReminderRepeat {
  String get label {
    switch (this) {
      case ReminderRepeat.none:
        return 'Once';
      case ReminderRepeat.weekly:
        return 'Weekly';
      case ReminderRepeat.monthly:
        return 'Monthly';
      case ReminderRepeat.quarterly:
        return 'Every 3 months';
      case ReminderRepeat.yearly:
        return 'Yearly';
    }
  }

  /// The next due date after [from] for a repeating reminder.
  DateTime next(DateTime from) {
    switch (this) {
      case ReminderRepeat.none:
        return from;
      case ReminderRepeat.weekly:
        return from.add(const Duration(days: 7));
      case ReminderRepeat.monthly:
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      case ReminderRepeat.quarterly:
        return DateTime(from.year, from.month + 3, from.day, from.hour, from.minute);
      case ReminderRepeat.yearly:
        return DateTime(from.year + 1, from.month, from.day, from.hour, from.minute);
    }
  }
}

/// A care reminder (flea dose, vaccine, recovery check). Stored on the device
/// and delivered as a local notification.
class Reminder {
  final int id;
  final String title;
  final String? petId;
  final String petName;
  final DateTime dueAt;
  final ReminderRepeat repeat;

  /// Set for recovery check-ins: the scan being followed up.
  final String? recoveryScanId;

  const Reminder({
    required this.id,
    required this.title,
    required this.petName,
    required this.dueAt,
    this.petId,
    this.repeat = ReminderRepeat.none,
    this.recoveryScanId,
  });

  bool get isRecovery => recoveryScanId != null;

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as int,
      title: json['title'] ?? '',
      petId: json['petId'],
      petName: json['petName'] ?? '',
      dueAt: DateTime.parse(json['dueAt']),
      repeat: ReminderRepeat.values.firstWhere(
        (r) => r.name == json['repeat'],
        orElse: () => ReminderRepeat.none,
      ),
      recoveryScanId: json['recoveryScanId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'petId': petId,
    'petName': petName,
    'dueAt': dueAt.toIso8601String(),
    'repeat': repeat.name,
    'recoveryScanId': recoveryScanId,
  };

  Reminder copyWith({DateTime? dueAt}) => Reminder(
    id: id,
    title: title,
    petId: petId,
    petName: petName,
    dueAt: dueAt ?? this.dueAt,
    repeat: repeat,
    recoveryScanId: recoveryScanId,
  );
}
