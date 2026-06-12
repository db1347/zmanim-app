import 'dart:convert';

import '../models/hebrew_event.dart';
import '../models/shabbat_alarm.dart';
import '../models/user_profile.dart';
import 'alarm_store.dart';
import 'event_store.dart';

/// Settings/data portability: everything except the API key (which never
/// leaves the device) round-trips through one JSON blob the user can copy
/// between devices.
class BackupService {
  const BackupService._();

  static const int _version = 1;

  static Future<String> export(UserProfile profile) async {
    final events = await EventStore.load();
    final alarms = await AlarmStore.load();
    return jsonEncode({
      'app': 'yeadut',
      'version': _version,
      'profile': profile.toJson(), // API key deliberately excluded
      'events': [for (final e in events) e.toJson()],
      'alarms': [for (final a in alarms) a.toJson()],
    });
  }

  /// Parses [raw]; returns the restored pieces, or null if it isn't a
  /// Yeadut backup. Throws nothing — malformed inner items are skipped.
  static Future<
      ({
        UserProfile profile,
        List<HebrewEvent> events,
        List<ShabbatAlarm> alarms
      })?> parse(String raw, {required UserProfile current}) async {
    try {
      final json = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (json['app'] != 'yeadut') return null;

      var profile = current;
      if (json['profile'] is Map<String, dynamic>) {
        // Imported profile, but keep this device's API key.
        profile = UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
            .copyWith(anthropicApiKey: current.anthropicApiKey);
      }
      final events = (json['events'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(HebrewEvent.fromJson)
          .where((e) => e.name.isNotEmpty)
          .toList();
      final alarms = (json['alarms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ShabbatAlarm.fromJson)
          .toList();
      return (profile: profile, events: events, alarms: alarms);
    } catch (_) {
      return null;
    }
  }
}
