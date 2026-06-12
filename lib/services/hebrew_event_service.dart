import 'package:kosher_dart/kosher_dart.dart';

import '../models/hebrew_event.dart';

/// Hebrew month names for pickers, in calendar-constant order
/// (NISSAN=1 … ADAR=12, ADAR_II=13).
const Map<int, String> kJewishMonthNames = {
  JewishDate.NISSAN: 'ניסן',
  JewishDate.IYAR: 'אייר',
  JewishDate.SIVAN: 'סיון',
  JewishDate.TAMMUZ: 'תמוז',
  JewishDate.AV: 'אב',
  JewishDate.ELUL: 'אלול',
  JewishDate.TISHREI: 'תשרי',
  JewishDate.CHESHVAN: 'חשון',
  JewishDate.KISLEV: 'כסלו',
  JewishDate.TEVES: 'טבת',
  JewishDate.SHEVAT: 'שבט',
  JewishDate.ADAR: 'אדר',
  JewishDate.ADAR_II: 'אדר ב׳',
};

/// Date math for recurring Hebrew events. Pure & testable.
///
/// Edge cases handled:
/// - Adar in a leap year: an Adar event is observed in Adar I (common
///   Ashkenazi custom; the UI notes customs differ). An Adar II event in a
///   non-leap year falls back to Adar.
/// - 30th of Cheshvan/Kislev in a short year: observed on the month's
///   last day (29th).
class HebrewEventService {
  const HebrewEventService._();

  /// Resolves the event's (month, day) for a given target Jewish year.
  static (int month, int day) resolveFor(HebrewEvent e, int jewishYear) {
    final leap = JewishDate.initDate(
            jewishYear: jewishYear, jewishMonth: JewishDate.TISHREI,
            jewishDayOfMonth: 1)
        .isJewishLeapYear();

    var month = e.jewishMonth;
    if (month == JewishDate.ADAR_II && !leap) month = JewishDate.ADAR;
    // In a leap year, plain-Adar events stay in month 12 (= Adar I).

    var day = e.jewishDay;
    final probe = JewishDate.initDate(
        jewishYear: jewishYear, jewishMonth: month, jewishDayOfMonth: 1);
    final daysInMonth = probe.getDaysInJewishMonth();
    if (day > daysInMonth) day = daysInMonth;

    return (month, day);
  }

  /// Next Gregorian occurrence on or after [from] (date-only comparison).
  static DateTime nextOccurrence(HebrewEvent e, DateTime from) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final currentJewishYear =
        (JewishDate.fromDateTime(fromDate)).getJewishYear();

    for (var year = currentJewishYear; year <= currentJewishYear + 1; year++) {
      final (month, day) = resolveFor(e, year);
      final jd = JewishDate.initDate(
          jewishYear: year, jewishMonth: month, jewishDayOfMonth: day);
      final greg = jd.getGregorianCalendar();
      final gregDate = DateTime(greg.year, greg.month, greg.day);
      if (!gregDate.isBefore(fromDate)) return gregDate;
    }
    // Unreachable: the next Jewish year always contains the date.
    throw StateError('no occurrence found for ${e.name}');
  }

  /// Hebrew label like "כ׳ אדר".
  static String dateLabel(HebrewEvent e) {
    final fmt = HebrewDateFormatter()..hebrewFormat = true;
    return '${fmt.formatHebrewNumber(e.jewishDay)} '
        '${kJewishMonthNames[e.jewishMonth] ?? ''}';
  }
}
