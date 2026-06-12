import 'package:kosher_dart/kosher_dart.dart';

/// Pure halachic suppression rules for smart reminders.
///
/// The "smart" in smart reminders: a tefillin reminder that fires on Shabbat
/// is worse than no reminder at all. These rules are pure functions over a
/// date so they can be unit-tested without any notification plumbing.
class ReminderRules {
  const ReminderRules._();

  /// Whether a tefillin reminder should fire on [date].
  ///
  /// Suppressed on:
  /// - Shabbat
  /// - Yom Tov on which melacha is forbidden
  /// - Chol HaMoed (most communities don't wear tefillin; those who do
  ///   know their custom — a future setting)
  /// - Tisha B'Av (tefillin are worn at Mincha, not in the morning when a
  ///   morning reminder would fire)
  static bool tefillinFiresOn(DateTime date, {required bool inIsrael}) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = inIsrael;
    if (jc.getDayOfWeek() == 7) return false;
    if (jc.isYomTovAssurBemelacha()) return false;
    if (jc.isCholHamoed()) return false;
    if (_isTishaBav(jc)) return false;
    return true;
  }

  static bool _isTishaBav(JewishCalendar jc) {
    // Av is month 5 counting from Nissan. Tisha B'Av is the 9th, observed
    // on the 10th when the 9th falls on Shabbat.
    if (jc.getJewishMonth() != JewishDate.AV) return false;
    final day = jc.getJewishDayOfMonth();
    if (day == 9 && jc.getDayOfWeek() != 7) return true;
    if (day == 10 && jc.getDayOfWeek() == 1) {
      // Sunday the 10th: observed fast (9th was Shabbat).
      return true;
    }
    return false;
  }

  /// Whether melacha is restricted on [date] — Shabbat or a Yom Tov on
  /// which work is forbidden. Used to pick the days a Shabbat alarm fires.
  static bool isRestrictedDay(DateTime date, {required bool inIsrael}) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = inIsrael;
    return jc.getDayOfWeek() == 7 || jc.isYomTovAssurBemelacha();
  }

  /// Whether an eruv tavshilin is made on [date]: it is erev Yom Tov, and
  /// the Yom Tov run starting tomorrow flows directly into Shabbat (Yom Tov
  /// on Friday, or Thursday–Friday) — so Shabbat cooking must be "started"
  /// today. E.g. Shavuot 5786 falls on Friday: eruv on Thursday 21.5.2026.
  static bool needsEruvTavshilin(DateTime date, {required bool inIsrael}) {
    bool isYomTov(DateTime d) {
      final jc = JewishCalendar.fromDateTime(d)..inIsrael = inIsrael;
      return jc.getDayOfWeek() != 7 && jc.isYomTovAssurBemelacha();
    }

    final tomorrow = DateTime(date.year, date.month, date.day + 1);
    if (!isYomTov(tomorrow)) return false;

    // Walk forward through the Yom Tov run; eruv is needed iff the run
    // reaches Friday (so Shabbat follows immediately). This is complete:
    // if the run ends on Thursday, Friday is an ordinary cooking day and
    // no eruv is required — Shabbat after a weekday gap never needs one.
    var day = tomorrow;
    for (var i = 0; i < 3 && isYomTov(day); i++) {
      if (day.weekday == DateTime.friday) return true;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return false;
  }

  /// Whether [date] is a candle-lighting eve (erev Shabbat or erev Yom Tov
  /// with standard before-sunset lighting).
  static bool isCandleLightingEve(DateTime date, {required bool inIsrael}) {
    final jc = JewishCalendar.fromDateTime(date)..inIsrael = inIsrael;
    final isRestrictedToday =
        jc.getDayOfWeek() == 7 || jc.isYomTovAssurBemelacha();
    if (isRestrictedToday) return false; // lighting after dark — no alert
    final tomorrow = JewishCalendar.fromDateTime(
        DateTime(date.year, date.month, date.day + 1))
      ..inIsrael = inIsrael;
    return tomorrow.getDayOfWeek() == 7 || tomorrow.isYomTovAssurBemelacha();
  }
}
