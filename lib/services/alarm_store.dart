import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shabbat_alarm.dart';

const String _kAlarmsKey = 'shabbat_alarms_v1';

/// Persists the preset Shabbat alarm list.
class AlarmStore {
  const AlarmStore._();

  static Future<List<ShabbatAlarm>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kAlarmsKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShabbatAlarm.fromJson)
          .toList();
    } catch (e) {
      debugPrint('AlarmStore: failed to load alarms: $e');
      return [];
    }
  }

  static Future<void> save(List<ShabbatAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kAlarmsKey, jsonEncode([for (final a in alarms) a.toJson()]));
  }
}
