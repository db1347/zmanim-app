import 'package:kosher_dart/kosher_dart.dart';

import '../models/user_profile.dart';

/// Summary of the Jewish-calendar facts for one civil day (Hebrew output).
class JewishDayInfo {
  final String hebrewDate; // e.g. "כ״ו סיון תשפ״ו"
  final String parsha; // upcoming Shabbat's parsha, Hebrew
  final String holiday; // empty if none
  final int omerDay; // -1 if not during the Omer
  final bool isRoshChodesh;
  final bool isFastDay;
  final String dafYomi;

  const JewishDayInfo({
    required this.hebrewDate,
    required this.parsha,
    required this.holiday,
    required this.omerDay,
    required this.isRoshChodesh,
    required this.isFastDay,
    required this.dafYomi,
  });
}

/// Read-only Jewish calendar lookups built on kosher_dart.
class CalendarService {
  const CalendarService._();

  static JewishDayInfo dayInfo(UserProfile p, DateTime date) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = p.inIsrael;
    final hebrew = HebrewDateFormatter()..hebrewFormat = true;

    String holiday = '';
    if (jc.getYomTovIndex() != -1) {
      holiday = hebrew.formatYomTov(jc);
    }

    String dafYomi = '';
    try {
      final daf = YomiCalculator.getDafYomiBavli(jc);
      dafYomi = hebrew.formatDafYomiBavli(daf);
    } catch (_) {
      // Daf Yomi cycle starts in 1923; out-of-range dates are fine to skip.
    }

    return JewishDayInfo(
      hebrewDate: hebrew.format(jc),
      parsha: hebrew.formatWeeklyParsha(jc),
      holiday: holiday,
      omerDay: jc.getDayOfOmer(),
      isRoshChodesh: jc.isRoshChodesh(),
      isFastDay: jc.isTaanis(),
      dafYomi: dafYomi,
    );
  }

  /// Holiday/Shabbat label for a calendar-grid cell, or empty string.
  static String cellLabel(UserProfile p, DateTime date) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = p.inIsrael;
    final hebrew = HebrewDateFormatter()..hebrewFormat = true;
    if (jc.getYomTovIndex() != -1) return hebrew.formatYomTov(jc);
    if (jc.isRoshChodesh()) return 'ראש חודש';
    return '';
  }

  /// Hebrew day-of-month number (e.g. "ט״ו") for calendar-grid cells.
  static String hebrewDayNumber(UserProfile p, DateTime date) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = p.inIsrael;
    final hebrew = HebrewDateFormatter()..hebrewFormat = true;
    return hebrew.formatHebrewNumber(jc.getJewishDayOfMonth());
  }
}
