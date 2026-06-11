import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../models/shabbat_alarm.dart';
import '../models/user_profile.dart';
import 'alarm_store.dart';
import 'reminder_rules.dart';
import 'zmanim_service.dart';

/// Schedules zman-aware local notifications with halachic suppression, and
/// real OS-level Shabbat alarms.
///
/// Reminders are scheduled day-by-day over a rolling window (rather than as
/// a blind daily repeat) so that Shabbat/Yom Tov suppression and per-day
/// candle-lighting times are honored. Shabbat alarms are scheduled as exact,
/// full-screen, alarm-channel notifications that loop their sound and cancel
/// themselves after the configured ring time — no interaction needed.
/// Re-run [rescheduleAll] whenever the profile or alarm list changes and on
/// every app launch to keep the window topped up.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _tefillinIdBase = 100;
  static const _candleIdBase = 200;
  static const _alarmIdBase = 300;

  /// FLAG_INSISTENT — Android repeats the notification sound until the
  /// notification is cancelled (here: by its own timeout).
  static const int _flagInsistent = 4;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('NotificationService: timezone init failed, using UTC: $e');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: init failed: $e');
    }
  }

  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true) ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      // Exact alarms need their own grant on Android 12+. Best effort —
      // inexact scheduling still works if the user declines.
      try {
        await android.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('NotificationService: exact-alarm permission: $e');
      }
      return granted;
    }
    return false;
  }

  static const NotificationDetails _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'yeadut_reminders',
      'תזכורות',
      channelDescription: 'תזכורות תפילין והדלקת נרות',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Alarm-channel details: plays on the alarm audio stream, shows over the
  /// lock screen, loops its sound (insistent), and cancels itself after
  /// [ringMinutes] — which also stops the sound. Zero interaction required.
  static NotificationDetails _alarmDetails(int ringMinutes) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'yeadut_shabbat_alarm',
        'שעון מעורר לשבת',
        channelDescription: 'שעון מעורר כשר לשבת — נכבה מעצמו',
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(const [_flagInsistent]),
        timeoutAfter: ringMinutes * 60 * 1000,
        autoCancel: false,
        ongoing: true,
      ),
      iOS: const DarwinNotificationDetails(
        sound: 'alarm.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  bool _rescheduling = false;

  /// Cancels everything and re-schedules reminders + Shabbat alarms from the
  /// current profile and saved alarm list. Serialized: concurrent calls are
  /// dropped so a second cancelAll cannot race freshly scheduled entries.
  Future<void> rescheduleAll(UserProfile p) async {
    if (!_initialized || _rescheduling) return;
    _rescheduling = true;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      if (p.tefillinReminderEnabled) await _scheduleTefillin(p, now);
      if (p.candleReminderEnabled) await _scheduleCandleLighting(p, now);
      await _scheduleShabbatAlarms(p, await AlarmStore.load(), now);
    } catch (e) {
      debugPrint('NotificationService: reschedule failed: $e');
    } finally {
      _rescheduling = false;
    }
  }

  Future<void> _scheduleTefillin(UserProfile p, DateTime now) async {
    for (int i = 0; i < kReminderScheduleWindowDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.tefillinFiresOn(day, inIsrael: p.inIsrael)) continue;

      final fireAt = DateTime(day.year, day.month, day.day,
          p.tefillinReminderHour, p.tefillinReminderMinute);
      if (!fireAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _tefillinIdBase + i,
        title: 'תפילין',
        body: 'הגיע הזמן להניח תפילין.',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _scheduleCandleLighting(UserProfile p, DateTime now) async {
    for (int i = 0; i < 28; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.isCandleLightingEve(day, inIsrael: p.inIsrael)) {
        continue;
      }

      final candles =
          ZmanimService.calendarFor(p, day).getCandleLighting();
      if (candles == null) continue;
      final fireAt =
          candles.subtract(Duration(minutes: p.candleReminderLeadMinutes));
      if (!fireAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _candleIdBase + i,
        title: 'הדלקת נרות בקרוב',
        body: 'הדלקת נרות בעוד ${p.candleReminderLeadMinutes} דקות '
            '(${_fmt(candles)}).',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Schedules each preset alarm on every restricted day (Shabbat / Yom Tov)
  /// within the next [kAlarmScheduleWindowDays]. Exact scheduling so the
  /// alarm fires even in Doze, with the device untouched the whole time.
  Future<void> _scheduleShabbatAlarms(
    UserProfile p,
    List<ShabbatAlarm> alarms,
    DateTime now,
  ) async {
    if (alarms.isEmpty) return;
    var id = _alarmIdBase;
    for (int i = 0; i < kAlarmScheduleWindowDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.isRestrictedDay(day, inIsrael: p.inIsrael)) continue;

      for (final alarm in alarms) {
        final fireAt = DateTime(
            day.year, day.month, day.day, alarm.hour, alarm.minute);
        if (!fireAt.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          id: id++,
          title: 'שעון מעורר לשבת',
          body: 'ההתראה תיכבה מעצמה בעוד ${alarm.ringMinutes} דקות — '
              'אין צורך לגעת במכשיר.',
          scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
          notificationDetails: _alarmDetails(alarm.ringMinutes),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    }
  }

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
