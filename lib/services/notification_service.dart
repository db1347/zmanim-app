import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../models/hebrew_event.dart';
import '../models/shabbat_alarm.dart';
import '../models/user_profile.dart';
import 'alarm_store.dart';
import 'event_store.dart';
import 'hebrew_event_service.dart';
import 'ios_alarm_service.dart';
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
  static const _omerIdBase = 400;
  static const _eventIdBase = 500;
  static const _eruvIdBase = 600;

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
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) =>
            onNotificationTap?.call(response.payload),
      );
      _initialized = true;

      // If the app was cold-started by tapping a notification, stash the
      // payload so the UI can route to the right screen once it's up.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch?.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('NotificationService: init failed: $e');
    }
  }

  /// Set by the app layer to deep-link when a notification is tapped while
  /// the app is running.
  void Function(String? payload)? onNotificationTap;

  String? _launchPayload;

  /// One-shot: the payload that cold-started the app, if any.
  String? consumeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
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
      if (p.omerReminderEnabled) await _scheduleOmer(p, now);
      await _scheduleEruvTavshilin(p, now);
      await _scheduleEvents(p, await EventStore.load(), now);
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
        payload: 'today',
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
        payload: 'today',
        title: 'הדלקת נרות בקרוב',
        body: 'הדלקת נרות בעוד ${p.candleReminderLeadMinutes} דקות '
            '(${_fmt(candles)}).',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Nightly Sefirat HaOmer reminder, ~20 min after tzeit (when the new
  /// count begins). The evening of civil day D belongs to Jewish day D+1 —
  /// suppressed when that evening is Shabbat or Yom Tov.
  ///
  /// Note: in the Diaspora this also suppresses night 1 (second Seder) —
  /// deliberately. A push notification on Yom Tov is exactly what an
  /// observant user must not receive; the count is said publicly at the
  /// Seder anyway. Same policy as every Friday-night count.
  Future<void> _scheduleOmer(UserProfile p, DateTime now) async {
    for (int i = 0; i < kReminderScheduleWindowDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final eveningJewishDay = DateTime(day.year, day.month, day.day + 1);
      if (ReminderRules.isRestrictedDay(eveningJewishDay,
          inIsrael: p.inIsrael)) {
        continue;
      }

      // The count said on this evening:
      final omerDay = (JewishCalendar.fromDateTime(eveningJewishDay)
            ..inIsrael = p.inIsrael)
          .getDayOfOmer();
      if (omerDay < 1 || omerDay > 49) continue;

      final tzeit = ZmanimService.tzeit(
          ZmanimService.calendarFor(p, day), p.tzeitShita);
      if (tzeit == null) continue;
      final fireAt = tzeit.add(const Duration(minutes: 20));
      if (!fireAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _omerIdBase + i,
        payload: 'omer',
        title: 'ספירת העומר',
        body: 'הערב סופרים יום $omerDay לעומר 🌙',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Eruv tavshilin alert: when Yom Tov flows into Shabbat, remind at
  /// 10:00 on the erev (always on — this is the reminder people forget).
  Future<void> _scheduleEruvTavshilin(UserProfile p, DateTime now) async {
    for (int i = 0; i < 28; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.needsEruvTavshilin(day, inIsrael: p.inIsrael)) {
        continue;
      }
      final fireAt = DateTime(day.year, day.month, day.day, 10, 0);
      if (!fireAt.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: _eruvIdBase + i,
        payload: 'today',
        title: 'עירוב תבשילין',
        body: 'יום טוב נכנס הערב ונמשך לשבת — מניחים עירוב תבשילין '
            'היום לפני כניסת החג.',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Hebrew-date event reminders: candle-lighting note the afternoon
  /// before (yahrzeit candles are lit at sunset) + morning-of, skipping
  /// mornings of Shabbat/Yom Tov.
  ///
  /// IDs are deterministic — `base + eventIndex*2 (+1)` over the soonest 45
  /// events — keeping the 500–591 range clear of the eruv range at 600.
  Future<void> _scheduleEvents(
      UserProfile p, List<HebrewEvent> events, DateTime now) async {
    final upcoming = [...events]..sort((a, b) =>
        HebrewEventService.nextOccurrence(a, now)
            .compareTo(HebrewEventService.nextOccurrence(b, now)));
    for (final (index, event) in upcoming.take(45).toList().indexed) {
      final occurrence = HebrewEventService.nextOccurrence(event, now);
      final daysAway = occurrence
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (daysAway > 35) continue; // topped up on every launch

      if (event.type == HebrewEventType.yahrzeit) {
        final eve = DateTime(occurrence.year, occurrence.month,
            occurrence.day - 1, 16, 0);
        if (eve.isAfter(now)) {
          await _plugin.zonedSchedule(
            id: _eventIdBase + index * 2,
            payload: 'events',
            title: '🕯️ ${event.name}',
            body: 'היארצייט מתחיל הערב — מדליקים נר נשמה לפני השקיעה.',
            scheduledDate: tz.TZDateTime.from(eve, tz.local),
            notificationDetails: _reminderDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }

      final morning = DateTime(
          occurrence.year, occurrence.month, occurrence.day, 9, 0);
      if (morning.isAfter(now) &&
          !ReminderRules.isRestrictedDay(occurrence, inIsrael: p.inIsrael)) {
        await _plugin.zonedSchedule(
          id: _eventIdBase + index * 2 + 1,
          payload: 'events',
          title: '${event.type.emoji} ${event.name}',
          body: 'היום: ${event.type.label} '
              '(${HebrewEventService.dateLabel(event)}).',
          scheduledDate: tz.TZDateTime.from(morning, tz.local),
          notificationDetails: _reminderDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  /// Schedules each preset alarm on every restricted day (Shabbat / Yom Tov)
  /// within the next [kAlarmScheduleWindowDays].
  ///
  /// Three platform paths:
  /// - iOS 26+: real AlarmKit alarms — ring through Silent/Focus, even with
  ///   the app terminated.
  /// - older iOS: a chain of standard notifications (one chime every 30 s
  ///   for the ring duration) that ends by itself — limited to the next few
  ///   restricted days to respect iOS's 64-pending-notification budget.
  /// - Android: exact full-screen alarm-channel notifications with looping
  ///   sound and self-cancel. IDs are deterministic
  ///   (`base + dayIndex*10 + alarmIndex`, alarms capped at 10/day) so the
  ///   300–399 range can never collide with the other ID ranges.
  Future<void> _scheduleShabbatAlarms(
    UserProfile p,
    List<ShabbatAlarm> alarms,
    DateTime now,
  ) async {
    if (Platform.isIOS) {
      if (await IosAlarmService.isAvailable()) {
        await IosAlarmService.reschedule(p, alarms, now);
      } else {
        await _scheduleIosChainedAlarms(p, alarms, now);
      }
      return;
    }
    if (alarms.isEmpty) return;
    final capped = alarms.take(10).toList();
    for (int i = 0; i < kAlarmScheduleWindowDays; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.isRestrictedDay(day, inIsrael: p.inIsrael)) continue;

      for (final (alarmIndex, alarm) in capped.indexed) {
        final fireAt = DateTime(
            day.year, day.month, day.day, alarm.hour, alarm.minute);
        if (!fireAt.isAfter(now)) continue;

        await _plugin.zonedSchedule(
          id: _alarmIdBase + i * 10 + alarmIndex,
          payload: 'alarm',
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

  /// iOS < 26 fallback: per alarm, a chain of standard notifications each
  /// playing the (4 s) alarm sound — a chime every 30 s for the ring
  /// duration, ending by itself. Cannot pierce Silent mode; the in-app
  /// Shabbat mode remains the primary recommendation on these devices.
  ///
  /// Budget: 3 days × 5 alarms × 6 chain slots fits IDs in 300–389 and
  /// stays well inside iOS's 64-pending-notification limit.
  Future<void> _scheduleIosChainedAlarms(
    UserProfile p,
    List<ShabbatAlarm> alarms,
    DateTime now,
  ) async {
    if (alarms.isEmpty) return;
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        sound: 'alarm.wav',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    var dayIndex = 0;
    for (int i = 0;
        i < kAlarmScheduleWindowDays && dayIndex < 3;
        i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!ReminderRules.isRestrictedDay(day, inIsrael: p.inIsrael)) continue;

      for (final (alarmIndex, alarm) in alarms.take(5).toList().indexed) {
        final fireAt = DateTime(
            day.year, day.month, day.day, alarm.hour, alarm.minute);
        if (!fireAt.isAfter(now)) continue;

        final chain = chainFireTimes(fireAt, alarm.ringMinutes);
        for (final (chainIndex, t) in chain.indexed) {
          await _plugin.zonedSchedule(
            id: _alarmIdBase + dayIndex * 30 + alarmIndex * 6 + chainIndex,
            payload: 'alarm',
            title: 'שעון מעורר לשבת',
            body: 'ההתראות ייפסקו מעצמן — אין צורך לגעת במכשיר.',
            scheduledDate: tz.TZDateTime.from(t, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
      dayIndex++;
    }
  }

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
