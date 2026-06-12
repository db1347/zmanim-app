import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/services/omer_service.dart';
import 'package:yeadut/services/omer_store.dart';

void main() {
  group('OmerService.countText', () {
    test('day 1 — single day, no weeks clause', () {
      expect(OmerService.countText(1), 'הַיּוֹם יוֹם אֶחָד לָעוֹמֶר.');
    });

    test('day 2 — dual form', () {
      expect(OmerService.countText(2), 'הַיּוֹם שְׁנֵי יָמִים לָעוֹמֶר.');
    });

    test('day 7 — exactly one week', () {
      expect(OmerService.countText(7),
          'הַיּוֹם שִׁבְעָה יָמִים, שֶׁהֵם שָׁבוּעַ אֶחָד לָעוֹמֶר.');
    });

    test('day 8 — one week and one day', () {
      expect(
          OmerService.countText(8),
          'הַיּוֹם שְׁמוֹנָה יָמִים, שֶׁהֵם שָׁבוּעַ אֶחָד וְיוֹם אֶחָד '
          'לָעוֹמֶר.');
    });

    test('day 14 — two weeks, teen number', () {
      expect(
          OmerService.countText(14),
          'הַיּוֹם אַרְבָּעָה עָשָׂר יוֹם, שֶׁהֵם שְׁנֵי שָׁבוּעוֹת '
          'לָעוֹמֶר.');
    });

    test('day 33 — Lag BaOmer composite number', () {
      expect(
          OmerService.countText(33),
          'הַיּוֹם שְׁלוֹשָׁה וּשְׁלוֹשִׁים יוֹם, שֶׁהֵם אַרְבָּעָה '
          'שָׁבוּעוֹת וַחֲמִשָּׁה יָמִים לָעוֹמֶר.');
    });

    test('day 49 — final day, seven full weeks', () {
      expect(
          OmerService.countText(49),
          'הַיּוֹם תִּשְׁעָה וְאַרְבָּעִים יוֹם, שֶׁהֵם שִׁבְעָה '
          'שָׁבוּעוֹת לָעוֹמֶר.');
    });

    test('all 49 days generate without error and end with לָעוֹמֶר.', () {
      for (var d = 1; d <= 49; d++) {
        final text = OmerService.countText(d);
        expect(text, startsWith('הַיּוֹם'));
        expect(text, endsWith('לָעוֹמֶר.'));
        if (d >= 7) expect(text, contains('שֶׁהֵם'));
      }
    });
  });

  group('OmerService.sefirahOfDay', () {
    test('day 1 is chesed shebechesed', () {
      expect(OmerService.sefirahOfDay(1), 'חֶסֶד שֶׁבְּחֶסֶד');
    });

    test('day 33 is hod shebehod (Lag BaOmer)', () {
      expect(OmerService.sefirahOfDay(33), 'הוֹד שֶׁבְּהוֹד');
    });

    test('day 49 is malchut shebemalchut', () {
      expect(OmerService.sefirahOfDay(49), 'מַלְכוּת שֶׁבְּמַלְכוּת');
    });
  });

  group('OmerStore logic', () {
    test('streak counts consecutive days back from current', () {
      expect(OmerStore.streak({1, 2, 3}, 3), 3);
      expect(OmerStore.streak({1, 3}, 3), 1);
      expect(OmerStore.streak({}, 5), 0);
    });

    test('missedADay detects a gap before the current day', () {
      expect(OmerStore.missedADay({1, 2, 3}, 4), isFalse);
      expect(OmerStore.missedADay({1, 3}, 4), isTrue);
      expect(OmerStore.missedADay({}, 1), isFalse); // day 1: nothing before
    });
  });
}
