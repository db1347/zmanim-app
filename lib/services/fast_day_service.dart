import 'package:kosher_dart/kosher_dart.dart';

import '../models/user_profile.dart';
import 'zmanim_service.dart';

/// Times for a fast day: when it begins and ends.
class FastInfo {
  final String name;

  /// True for Yom Kippur and Tisha B'Av, which begin at sunset the evening
  /// before; the minor fasts begin at dawn.
  final bool startsAtNight;
  final DateTime? start;
  final DateTime? end;

  const FastInfo({
    required this.name,
    required this.startsAtNight,
    required this.start,
    required this.end,
  });
}

/// Fast-day detection and timing, per the user's zmanim shitot.
class FastDayService {
  const FastDayService._();

  static const Map<int, String> _fastNames = {
    JewishCalendar.SEVENTEEN_OF_TAMMUZ: 'צום שבעה עשר בתמוז',
    JewishCalendar.TISHA_BEAV: 'תשעה באב',
    JewishCalendar.FAST_OF_GEDALYAH: 'צום גדליה',
    JewishCalendar.YOM_KIPPUR: 'יום הכיפורים',
    JewishCalendar.TENTH_OF_TEVES: 'צום עשרה בטבת',
    JewishCalendar.FAST_OF_ESTHER: 'תענית אסתר',
  };

  /// Fast info for [date], or null if it isn't a fast day.
  static FastInfo? fastInfo(UserProfile p, DateTime date) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = p.inIsrael;
    if (!jc.isTaanis()) return null;

    final index = jc.getYomTovIndex();
    final name = _fastNames[index] ?? 'יום תענית';
    final startsAtNight = index == JewishCalendar.YOM_KIPPUR ||
        index == JewishCalendar.TISHA_BEAV;

    DateTime? start;
    if (startsAtNight) {
      final yesterday = DateTime(date.year, date.month, date.day - 1);
      start =
          ZmanimService.calendarFor(p, yesterday).getElevationAdjustedSunset();
    } else {
      start = ZmanimService.alos(
          ZmanimService.calendarFor(p, date), p.alosShita);
    }

    final end =
        ZmanimService.tzeit(ZmanimService.calendarFor(p, date), p.tzeitShita);

    return FastInfo(
      name: name,
      startsAtNight: startsAtNight,
      start: start,
      end: end,
    );
  }
}
