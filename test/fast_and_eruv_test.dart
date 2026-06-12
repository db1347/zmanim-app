import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/user_profile.dart';
import 'package:yeadut/services/fast_day_service.dart';
import 'package:yeadut/services/reminder_rules.dart';

void main() {
  const jerusalem = UserProfile(
    locationName: 'ירושלים',
    latitude: 31.7780,
    longitude: 35.2354,
    inIsrael: true,
  );

  group('FastDayService.fastInfo', () {
    test('regular day returns null', () {
      expect(FastDayService.fastInfo(jerusalem, DateTime(2026, 6, 10)),
          isNull);
    });

    test('Tisha B\'Av starts the night before', () {
      // 9 Av 5786 = 23 July 2026.
      final fast = FastDayService.fastInfo(jerusalem, DateTime(2026, 7, 23));
      expect(fast, isNotNull);
      expect(fast!.name, 'תשעה באב');
      expect(fast.startsAtNight, isTrue);
      expect(fast.start!.day, 22, reason: 'starts at sunset on 22 July');
      expect(fast.end!.day, 23);
      expect(fast.start!.isBefore(fast.end!), isTrue);
    });

    test('17 Tammuz starts at dawn the same day', () {
      // 17 Tammuz 5786 = 2 July 2026 (Thursday).
      final fast = FastDayService.fastInfo(jerusalem, DateTime(2026, 7, 2));
      expect(fast, isNotNull);
      expect(fast!.name, 'צום שבעה עשר בתמוז');
      expect(fast.startsAtNight, isFalse);
      expect(fast.start!.day, 2);
      expect(fast.start!.hour, lessThan(6), reason: 'alos is before 6 am');
    });

    test('Yom Kippur is detected with night start', () {
      // 10 Tishrei 5787 = 21 September 2026.
      final fast = FastDayService.fastInfo(jerusalem, DateTime(2026, 9, 21));
      expect(fast, isNotNull);
      expect(fast!.name, 'יום הכיפורים');
      expect(fast.startsAtNight, isTrue);
    });
  });

  group('ReminderRules.needsEruvTavshilin', () {
    test('erev Shavuot 5786 — Yom Tov falls on Friday → eruv needed', () {
      // Shavuot 5786 = Friday 22 May 2026; erev = Thursday 21 May.
      expect(
        ReminderRules.needsEruvTavshilin(DateTime(2026, 5, 21),
            inIsrael: true),
        isTrue,
      );
    });

    test('no eruv on a regular Thursday', () {
      expect(
        ReminderRules.needsEruvTavshilin(DateTime(2026, 6, 11),
            inIsrael: true),
        isFalse,
      );
    });

    test('no eruv on erev Shabbat itself', () {
      // Friday before a plain Shabbat: nothing to cook *from* Yom Tov.
      expect(
        ReminderRules.needsEruvTavshilin(DateTime(2026, 6, 12),
            inIsrael: true),
        isFalse,
      );
    });

    test('no eruv when Yom Tov does not touch Shabbat', () {
      // First day Pesach 5786 = Thursday 2 April 2026 (single day in IL,
      // followed by Chol HaMoed Friday) → no eruv needed in Israel.
      expect(
        ReminderRules.needsEruvTavshilin(DateTime(2026, 4, 1),
            inIsrael: true),
        isFalse,
      );
    });

    test('Diaspora two-day Yom Tov reaching Friday → eruv needed', () {
      // Abroad, Pesach 5786 = Thu 2 + Fri 3 April → second day is Friday,
      // so eruv is made on Wednesday 1 April.
      expect(
        ReminderRules.needsEruvTavshilin(DateTime(2026, 4, 1),
            inIsrael: false),
        isTrue,
      );
    });
  });
}
