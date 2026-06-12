import 'package:kosher_dart/kosher_dart.dart';

import '../models/user_profile.dart';
import '../models/zman_item.dart';

/// Computes halachic times via kosher_dart, honoring the user's chosen
/// shitot (calculation opinions). Pure & stateless: safe to call anywhere.
///
/// Note: times are computed in the device's local timezone. Viewing zmanim
/// for a saved location in a *different* timezone is a known v2 limitation.
class ZmanimService {
  const ZmanimService._();

  static ComplexZmanimCalendar calendarFor(UserProfile p, DateTime date) {
    final location = GeoLocation.setLocation(
      p.locationName,
      p.latitude,
      p.longitude,
      DateTime(date.year, date.month, date.day, 12),
    );
    final calendar = ComplexZmanimCalendar.intGeoLocation(location);
    calendar.setCandleLightingOffset(p.candleLightingMinutes.toDouble());
    return calendar;
  }

  static DateTime? alos(ComplexZmanimCalendar c, AlosShita shita) {
    return switch (shita) {
      AlosShita.degrees16_1 => c.getAlos16Point1Degrees(),
      AlosShita.minutes72 => c.getAlos72(),
      AlosShita.minutes90 => c.getAlos90(),
    };
  }

  static DateTime? tzeit(ComplexZmanimCalendar c, TzeitShita shita) {
    return switch (shita) {
      TzeitShita.degrees8_5 => c.getTzaisGeonim8Point5Degrees(),
      TzeitShita.minutes42 =>
        c.getElevationAdjustedSunset()?.add(const Duration(minutes: 42)),
      TzeitShita.minutes50 => c.getTzais50(),
      TzeitShita.minutes72 => c.getTzais72(),
    };
  }

  /// All zmanim for [date], per the profile's shitot, sorted by time.
  static DayZmanim dayZmanim(UserProfile p, DateTime date) {
    final c = calendarFor(p, date);
    final mga = p.dayLengthShita == DayLengthShita.magenAvraham;

    final items = <ZmanItem>[
      ZmanItem(
        name: 'עלות השחר',
        explanation: 'תחילת היום ההלכתי (${p.alosShita.label}). הזמן המוקדם '
            'ביותר לחלק מהמצוות; תחילת הצומות.',
        time: alos(c, p.alosShita),
      ),
      ZmanItem(
        name: 'משיכיר',
        explanation: 'הזמן המוקדם ביותר לטלית ותפילין — משיכיר את חברו '
            'ממרחק (11° מתחת לאופק).',
        time: c.getMisheyakir11Degrees(),
      ),
      ZmanItem(
        name: 'הנץ החמה',
        explanation: 'זריחת השמש. הזמן המובחר לתפילת עמידה (ותיקין).',
        time: c.getElevationAdjustedSunrise(),
      ),
      ZmanItem(
        name: mga ? 'סוף זמן ק״ש (מג״א)' : 'סוף זמן ק״ש (גר״א)',
        explanation: 'סוף זמן קריאת שמע של שחרית — שלוש שעות זמניות מתחילת '
            'היום ${mga ? "לשיטת המגן אברהם (היום מעלות השחר עד צאת הכוכבים)" : "לשיטת הגר״א (היום מהנץ עד השקיעה)"}.',
        time: mga ? c.getSofZmanShmaMGA72Minutes() : c.getSofZmanShmaGRA(),
      ),
      ZmanItem(
        name: mga ? 'סוף זמן תפילה (מג״א)' : 'סוף זמן תפילה (גר״א)',
        explanation: 'סוף זמן תפילת שחרית — ארבע שעות זמניות מתחילת היום.',
        time: mga ? c.getSofZmanTfilaMGA72Minutes() : c.getSofZmanTfilaGRA(),
      ),
      ZmanItem(
        name: 'חצות היום',
        explanation: 'אמצע היום ההלכתי — השמש בנקודה הגבוהה ביותר.',
        time: c.getChatzos(),
      ),
      ZmanItem(
        name: 'מנחה גדולה',
        explanation: 'הזמן המוקדם ביותר לתפילת מנחה — חצי שעה זמנית אחרי '
            'חצות.',
        time: c.getMinchaGedola(),
      ),
      ZmanItem(
        name: 'מנחה קטנה',
        explanation: 'זמן מנחה המועדף לחלק מהדעות — תשע וחצי שעות זמניות '
            'מתחילת היום.',
        time: c.getMinchaKetana(),
      ),
      ZmanItem(
        name: 'פלג המנחה',
        explanation: 'שעה ורבע זמנית לפני סוף היום. הזמן המוקדם ביותר '
            'לקבלת שבת ולתפילת ערבית לחלק מהדעות.',
        time: c.getPlagHamincha(),
      ),
      ZmanItem(
        name: 'שקיעה',
        explanation: 'שקיעת החמה. סוף היום ההלכתי לעניינים רבים; יש לסיים '
            'מנחה לפניה.',
        time: c.getElevationAdjustedSunset(),
      ),
      ZmanItem(
        name: 'צאת הכוכבים',
        explanation: 'לילה (${p.tzeitShita.label}) — נראים כוכבים. תחילת '
            'זמן ערבית וסיום הצומות.',
        time: tzeit(c, p.tzeitShita),
      ),
    ];

    final withTimes = items.where((i) => i.time != null).toList()
      ..sort((a, b) => a.time!.compareTo(b.time!));
    final without = items.where((i) => i.time == null).toList();
    return DayZmanim(date: date, items: [...withTimes, ...without]);
  }

  /// Whether [now] is after tzeit — i.e. the *next* Jewish day has begun
  /// even though the civil date hasn't changed yet.
  static bool isAfterTzeit(UserProfile p, DateTime now) {
    final t = tzeit(calendarFor(p, now), p.tzeitShita);
    return t != null && now.isAfter(t);
  }

  /// True when melacha is restricted on [day] (Shabbat or Yom Tov).
  static bool _isRestricted(UserProfile p, DateTime day) {
    final jc = JewishCalendar.fromDateTime(day)..inIsrael = p.inIsrael;
    return jc.getDayOfWeek() == 7 || jc.isYomTovAssurBemelacha();
  }

  /// Finds the current or next Shabbat / Yom Tov within 30 days of [from] and
  /// returns its candle lighting and havdalah times, or null if none found.
  static ShabbatTimes? nextShabbatOrYomTov(UserProfile p, DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    DateTime? candleDay;
    bool lightingAfterDark = false;

    if (_isRestricted(p, today)) {
      // Currently inside Shabbat/Yom Tov — anchor to the day it began.
      // Restricted runs are at most 3 days (Yom Tov + Shabbat); the guard
      // bounds the walk in case of upstream calendar edge cases.
      var day = today;
      var guard = 0;
      while (guard++ < 4 &&
          _isRestricted(p, DateTime(day.year, day.month, day.day - 1))) {
        day = DateTime(day.year, day.month, day.day - 1);
      }
      candleDay = DateTime(day.year, day.month, day.day - 1);
    } else {
      for (int offset = 0; offset < 30; offset++) {
        final day = DateTime(today.year, today.month, today.day + offset);
        if (_isRestricted(p, DateTime(day.year, day.month, day.day + 1))) {
          lightingAfterDark = _isRestricted(p, day);
          candleDay = day;
          break;
        }
      }
    }
    if (candleDay == null) return null;

    final candleCalendar = calendarFor(p, candleDay);
    final candleLighting = lightingAfterDark
        ? tzeit(candleCalendar, p.tzeitShita)
        : candleCalendar.getCandleLighting();

    // Havdalah: the evening after the last consecutive restricted day.
    DateTime? havdalahDay;
    for (int offset = 1; offset < 5; offset++) {
      final day = DateTime(
          candleDay.year, candleDay.month, candleDay.day + offset);
      if (_isRestricted(p, day)) {
        havdalahDay = day;
      } else {
        break;
      }
    }
    final havdalah = havdalahDay == null
        ? null
        : tzeit(calendarFor(p, havdalahDay), p.tzeitShita);

    // Event name from the first restricted day.
    final firstDay = DateTime(
        candleDay.year, candleDay.month, candleDay.day + 1);
    final firstJc = JewishCalendar.fromDateTime(firstDay)
      ..inIsrael = p.inIsrael;
    final formatter = HebrewDateFormatter()..hebrewFormat = true;
    String eventName = firstJc.getDayOfWeek() == 7 ? 'שבת' : 'יום טוב';
    if (firstJc.isYomTovAssurBemelacha()) {
      final yomTov = formatter.formatYomTov(firstJc);
      if (yomTov.isNotEmpty) eventName = yomTov;
    }

    return ShabbatTimes(
      eventName: eventName,
      candleLightingDay: candleDay,
      candleLighting: candleLighting,
      lightingAfterDark: lightingAfterDark,
      havdalah: havdalah,
      havdalahDay: havdalahDay,
    );
  }
}
