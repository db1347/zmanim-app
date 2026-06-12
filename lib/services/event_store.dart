import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hebrew_event.dart';

const String _kEventsKey = 'hebrew_events_v1';

/// Persists the user's Hebrew-date events (yahrzeits, birthdays…).
class EventStore {
  const EventStore._();

  static Future<List<HebrewEvent>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kEventsKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(HebrewEvent.fromJson)
          .toList();
    } catch (e) {
      debugPrint('EventStore: failed to load: $e');
      return [];
    }
  }

  static Future<void> save(List<HebrewEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kEventsKey, jsonEncode([for (final e in events) e.toJson()]));
  }
}
