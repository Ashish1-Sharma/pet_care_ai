import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

/// Local (on-device) notifications: recovery check-ins, care reminders, the
/// weekly free scan and a trial-ending heads-up. No Firebase needed — every
/// notification is scheduled by the app itself.
///
/// Tapping a notification emits its payload on [taps]:
///   `recovery:<scanId>` · `reminders` · `scan` · `paywall`
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Fixed ids for the app's own notifications; user reminders use their own
  // ids, which start at 1000 (see StorageService.nextReminderId).
  static const int weeklyFreeScanId = 1;
  static const int reengagementId = 2;
  static const int trialEndingId = 3;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _ready = false;

  /// Payload of the notification that launched the app, consumed once.
  String? launchPayload;

  Stream<String> get taps => _taps.stream;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'care_reminders',
      'Care reminders',
      channelDescription: 'Recovery check-ins, medication doses and vaccine dates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        launchPayload = launch?.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('[notifications] init failed: $e');
    }
  }

  /// Shows the Android 13+ permission prompt. Returns whether it was granted.
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  Future<bool> areEnabled() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
    DateTimeComponents? repeat,
  }) async {
    await init();
    if (!_ready) return;
    var at = tz.TZDateTime.from(when, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!at.isAfter(now)) {
      if (repeat == null) return; // a one-off in the past has nothing to do
      at = now.add(const Duration(minutes: 1));
    }
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: at,
        notificationDetails: _details,
        // Inexact: no exact-alarm permission needed; a few minutes' drift is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
        matchDateTimeComponents: repeat,
      );
    } catch (e) {
      debugPrint('[notifications] schedule $id failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    await init();
    if (_ready) await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await init();
    if (_ready) await _plugin.cancelAll();
  }

  // --- App notifications ------------------------------------------------------

  Future<void> scheduleReminder(Reminder reminder) {
    final String body;
    final String payload;
    if (reminder.isRecovery) {
      body = "A quick rescan shows whether it's healing or needs a vet.";
      payload = 'recovery:${reminder.recoveryScanId}';
    } else {
      body = '${reminder.title} is due today. Tap to mark it done.';
      payload = 'reminders';
    }
    final title = reminder.isRecovery
        ? 'How is ${reminder.petName}\'s ${reminder.title.toLowerCase()}?'
        : '${reminder.petName}: ${reminder.title}';
    return _schedule(
      id: reminder.id,
      when: reminder.dueAt,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Monday 10:00 local, every week, for free users.
  Future<void> scheduleWeeklyFreeScan() {
    final now = DateTime.now();
    final daysToMonday = (DateTime.monday - now.weekday) % 7;
    var next = DateTime(now.year, now.month, now.day + daysToMonday, 10);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 7));
    return _schedule(
      id: weeklyFreeScanId,
      when: next,
      title: 'Your free weekly scan is here',
      body: 'Anything bothering your pet? Your scan is ready.',
      payload: 'scan',
      repeat: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// A gentle nudge 14 days after the last app open. Rescheduled on every
  /// open, so active users never see it.
  Future<void> scheduleReengagement(String petName) {
    final name = petName.isEmpty ? 'your pet' : petName;
    return _schedule(
      id: reengagementId,
      when: DateTime.now().add(const Duration(days: 14)),
      title: 'Checking in on $name',
      body: "It's been 2 weeks. Any new scratching, lumps or limping?",
      payload: 'scan',
    );
  }

  /// One day before a free trial converts to paid.
  Future<void> scheduleTrialEnding(DateTime trialEndsAt, String price) {
    return _schedule(
      id: trialEndingId,
      when: trialEndsAt.subtract(const Duration(days: 1)),
      title: 'Your free trial ends tomorrow',
      body: 'PetCare Plus then renews at $price. Manage it anytime in Google Play.',
      payload: 'paywall',
    );
  }
}
