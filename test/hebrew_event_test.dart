import 'package:flutter_test/flutter_test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:yeadut/models/hebrew_event.dart';
import 'package:yeadut/services/hebrew_event_service.dart';
import 'package:yeadut/services/learning_store.dart';

HebrewEvent _event(int month, int day) => HebrewEvent(
      id: 't',
      name: 'בדיקה',
      type: HebrewEventType.yahrzeit,
      jewishMonth: month,
      jewishDay: day,
    );

void main() {
  group('HebrewEventService.nextOccurrence', () {
    test('upcoming date this Jewish year resolves correctly', () {
      // 20 Sivan 5786 = 5 June 2026. From 1 June it's days away.
      final next = HebrewEventService.nextOccurrence(
          _event(JewishDate.SIVAN, 20), DateTime(2026, 6, 1));
      expect(next, DateTime(2026, 6, 5));
    });

    test('a passed date rolls to next Jewish year', () {
      // From 10 June 2026 (24 Sivan), 20 Sivan already passed → 5787.
      final next = HebrewEventService.nextOccurrence(
          _event(JewishDate.SIVAN, 20), DateTime(2026, 6, 10));
      final jd = JewishDate.fromDateTime(next);
      expect(jd.getJewishYear(), 5787);
      expect(jd.getJewishMonth(), JewishDate.SIVAN);
      expect(jd.getJewishDayOfMonth(), 20);
    });

    test('event on today returns today (inclusive)', () {
      final next = HebrewEventService.nextOccurrence(
          _event(JewishDate.SIVAN, 20), DateTime(2026, 6, 5));
      expect(next, DateTime(2026, 6, 5));
    });

    test('Adar II event falls back to Adar in a non-leap year', () {
      // 5786 is not a leap year.
      final (month, _) =
          HebrewEventService.resolveFor(_event(JewishDate.ADAR_II, 10), 5786);
      expect(month, JewishDate.ADAR);
    });

    test('30 Cheshvan clamps to 29 in a short-Cheshvan year', () {
      final (_, day) =
          HebrewEventService.resolveFor(_event(JewishDate.CHESHVAN, 30), 5786);
      final probe = JewishDate.initDate(
          jewishYear: 5786,
          jewishMonth: JewishDate.CHESHVAN,
          jewishDayOfMonth: 1);
      expect(day, probe.getDaysInJewishMonth());
      expect(day, inInclusiveRange(29, 30));
    });
  });

  group('LearningStore.streak', () {
    test('counts back from today when today is done', () {
      final today = DateTime(2026, 6, 12);
      final done = {'2026-06-12', '2026-06-11', '2026-06-10'};
      expect(LearningStore.streak(done, today), 3);
    });

    test('falls back to yesterday when today not yet done', () {
      final today = DateTime(2026, 6, 12);
      final done = {'2026-06-11', '2026-06-10'};
      expect(LearningStore.streak(done, today), 2);
    });

    test('zero when nothing recent', () {
      expect(LearningStore.streak({'2026-01-01'}, DateTime(2026, 6, 12)), 0);
    });
  });
}
