import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/services/reminder_rules.dart';

void main() {
  group('ReminderRules.tefillinFiresOn', () {
    test('fires on a regular weekday', () {
      // Wed 10 June 2026 — ordinary day.
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 6, 10), inIsrael: false),
        isTrue,
      );
    });

    test('suppressed on Shabbat', () {
      // 13 June 2026 is a Saturday.
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 6, 13), inIsrael: false),
        isFalse,
      );
    });

    test('suppressed on Shavuot (Yom Tov)', () {
      // Shavuot 5786: 22 May 2026 (6 Sivan).
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 5, 22), inIsrael: true),
        isFalse,
      );
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 5, 22), inIsrael: false),
        isFalse,
      );
    });

    test('suppressed on Pesach and on Chol HaMoed', () {
      // 2 April 2026 = 15 Nissan, first day Pesach — suppressed everywhere.
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 4, 2), inIsrael: false),
        isFalse,
      );
      // 3 April 2026 = 16 Nissan: chag sheni abroad, Chol HaMoed in Israel —
      // suppressed in both (no tefillin per prevailing custom).
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 4, 3), inIsrael: false),
        isFalse,
      );
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 4, 3), inIsrael: true),
        isFalse,
      );
    });

    test('suppressed on Tisha B\'Av', () {
      // Tisha B\'Av 5786: 23 July 2026 (9 Av, Thursday).
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2026, 7, 23), inIsrael: false),
        isFalse,
      );
    });

    test('fires on Chanukah (no suppression on minor holidays)', () {
      // 15 December 2025 was during Chanukah 5786 (Monday).
      expect(
        ReminderRules.tefillinFiresOn(DateTime(2025, 12, 15), inIsrael: false),
        isTrue,
      );
    });
  });

  group('ReminderRules.isRestrictedDay', () {
    test('true on Shabbat, false on weekday', () {
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 6, 13), inIsrael: true),
        isTrue,
      );
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 6, 10), inIsrael: true),
        isFalse,
      );
    });

    test('true on Shavuot in Israel and Diaspora', () {
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 5, 22), inIsrael: true),
        isTrue,
      );
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 5, 22), inIsrael: false),
        isTrue,
      );
    });

    test('second day Yom Tov restricted only in Diaspora', () {
      // 16 Nissan 5786 = 3 April 2026: chag sheni abroad, Chol HaMoed in IL.
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 4, 3), inIsrael: false),
        isTrue,
      );
      expect(
        ReminderRules.isRestrictedDay(DateTime(2026, 4, 3), inIsrael: true),
        isFalse,
      );
    });
  });

  group('ReminderRules.isCandleLightingEve', () {
    test('true on a regular Friday', () {
      // 12 June 2026 is a Friday.
      expect(
        ReminderRules.isCandleLightingEve(DateTime(2026, 6, 12),
            inIsrael: false),
        isTrue,
      );
    });

    test('false on a regular Tuesday', () {
      expect(
        ReminderRules.isCandleLightingEve(DateTime(2026, 6, 9),
            inIsrael: false),
        isFalse,
      );
    });

    test('true on erev Shavuot', () {
      // 21 May 2026 (Thursday) — erev Shavuot.
      expect(
        ReminderRules.isCandleLightingEve(DateTime(2026, 5, 21),
            inIsrael: true),
        isTrue,
      );
    });

    test('false on Shabbat itself even before a Yom Tov', () {
      // Lighting after dark from existing flame — no pre-sunset alert.
      expect(
        ReminderRules.isCandleLightingEve(DateTime(2026, 6, 13),
            inIsrael: false),
        isFalse,
      );
    });
  });
}
