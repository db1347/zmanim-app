import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/shabbat_alarm.dart';
import '../models/user_profile.dart';
import 'reminder_rules.dart';

const String _kScheduledIdsKey = 'ios_alarmkit_ids_v1';

/// Real iOS alarms via AlarmKit (iOS 26+).
///
/// AlarmKit alarms behave like the system Clock app: they ring through
/// Silent mode, Do Not Disturb, and Focus, full-screen on the Lock Screen,
/// even if the app was terminated. One behavioral difference from the
/// Android path: ring duration is system-managed — the alarm stops at the
/// system's own timeout rather than after the user's configured minutes
/// (still zero interaction required).
///
/// On iOS < 26 every call throws; [isAvailable] gates all use.
class IosAlarmService {
  const IosAlarmService._();

  static final FlutterAlarmkit _kit = FlutterAlarmkit();
  static bool? _available;

  /// True only on iOS 26+ where AlarmKit responds.
  static Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    if (_available != null) return _available!;
    try {
      await _kit.getAuthorizationState();
      _available = true;
    } catch (_) {
      // iOS < 26 (PlatformException) or non-iOS host (MissingPlugin).
      _available = false;
    }
    return _available!;
  }

  /// Requests AlarmKit authorization if not yet determined.
  /// Returns true when authorized.
  static Future<bool> ensureAuthorized() async {
    try {
      final state = await _kit.getAuthorizationState();
      if (state == 3) return true; // authorized
      if (state == 0) return await _kit.requestAuthorization();
      return false; // restricted / denied
    } catch (e) {
      debugPrint('IosAlarmService: authorization check failed: $e');
      return false;
    }
  }

  /// Cancels previously scheduled AlarmKit alarms and schedules each preset
  /// alarm on every restricted day (Shabbat / Yom Tov) in the window —
  /// mirroring the Android scheduler.
  static Future<void> reschedule(
    UserProfile p,
    List<ShabbatAlarm> alarms,
    DateTime now,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cancel our previous batch (alarm list/profile may have changed).
      for (final id in prefs.getStringList(_kScheduledIdsKey) ?? []) {
        try {
          await _kit.cancelAlarm(alarmId: id);
        } catch (_) {
          // Already fired or removed by the user from the system UI.
        }
      }

      final ids = <String>[];
      if (alarms.isNotEmpty && await ensureAuthorized()) {
        for (int i = 0; i < kAlarmScheduleWindowDays; i++) {
          final day = DateTime(now.year, now.month, now.day + i);
          if (!ReminderRules.isRestrictedDay(day, inIsrael: p.inIsrael)) {
            continue;
          }
          for (final alarm in alarms.take(10)) {
            final fireAt = DateTime(
                day.year, day.month, day.day, alarm.hour, alarm.minute);
            if (!fireAt.isAfter(now)) continue;

            final id = await _kit.scheduleOneShotAlarm(
              timestamp: fireAt.millisecondsSinceEpoch.toDouble(),
              label: 'שעון מעורר לשבת',
              tintColor: '#0C447C',
              soundPath: 'assets/sounds/alarm.wav',
            );
            ids.add(id);
          }
        }
      }
      await prefs.setStringList(_kScheduledIdsKey, ids);
    } catch (e) {
      debugPrint('IosAlarmService: reschedule failed: $e');
    }
  }
}

/// Fire times for the iOS < 26 fallback: a chain of standard notifications
/// approximating a ringing alarm — one chime every [interval], stopping by
/// itself when the chain ends (no interaction, kosher-compatible).
///
/// Pure and testable. [maxChain] caps the chain so the scheduling stays
/// well inside iOS's 64-pending-notification budget.
List<DateTime> chainFireTimes(
  DateTime start,
  int ringMinutes, {
  Duration interval = const Duration(seconds: 30),
  int maxChain = 6,
}) {
  final wanted = (ringMinutes * 60 / interval.inSeconds).ceil();
  final count = wanted.clamp(1, maxChain);
  return [for (var i = 0; i < count; i++) start.add(interval * i)];
}
