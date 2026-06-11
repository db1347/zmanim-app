import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/user_profile.dart';
import 'package:yeadut/services/zmanim_service.dart';

void main() {
  // Jerusalem profile, default shitot (GRA, 8.5°, 18-min candles).
  const jerusalem = UserProfile(
    locationName: 'ירושלים',
    latitude: 31.7780,
    longitude: 35.2354,
    inIsrael: true,
  );

  group('ZmanimService.dayZmanim', () {
    test('produces a full, chronologically ordered day', () {
      final day = ZmanimService.dayZmanim(jerusalem, DateTime(2026, 6, 10));
      final times =
          day.items.map((i) => i.time).whereType<DateTime>().toList();
      expect(times.length, day.items.length,
          reason: 'no zman should be null in Jerusalem in June');
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue,
            reason: 'zmanim must be sorted');
      }
    });

    test('sunrise precedes sunset on the same civil day', () {
      final day = ZmanimService.dayZmanim(jerusalem, DateTime(2026, 1, 15));
      final sunrise =
          day.items.firstWhere((i) => i.name.contains('הנץ')).time!;
      final sunset =
          day.items.firstWhere((i) => i.name.contains('שקיעה')).time!;
      expect(sunrise.isBefore(sunset), isTrue);
      expect(sunrise.day, 15);
      expect(sunset.day, 15);
    });

    test('MGA shema time is earlier than GRA shema time', () {
      const mgaProfile = UserProfile(
        latitude: 31.7780,
        longitude: 35.2354,
        dayLengthShita: DayLengthShita.magenAvraham,
      );
      final gra = ZmanimService.dayZmanim(jerusalem, DateTime(2026, 6, 10));
      final mga = ZmanimService.dayZmanim(mgaProfile, DateTime(2026, 6, 10));
      final graShema =
          gra.items.firstWhere((i) => i.name.contains('ק״ש')).time!;
      final mgaShema =
          mga.items.firstWhere((i) => i.name.contains('ק״ש')).time!;
      expect(mgaShema.isBefore(graShema), isTrue);
    });

    test('nextAfter returns null at end of day', () {
      final day = ZmanimService.dayZmanim(jerusalem, DateTime(2026, 6, 10));
      expect(day.nextAfter(DateTime(2026, 6, 10, 23, 59)), isNull);
      expect(day.nextAfter(DateTime(2026, 6, 10, 0, 1)), isNotNull);
    });
  });

  group('ZmanimService.nextShabbatOrYomTov', () {
    test('finds Friday candle lighting from a midweek day', () {
      // Wed 10 June 2026 → Shabbat begins Fri 12 June.
      final st =
          ZmanimService.nextShabbatOrYomTov(jerusalem, DateTime(2026, 6, 10));
      expect(st, isNotNull);
      expect(st!.candleLightingDay.weekday, DateTime.friday);
      expect(st.candleLightingDay.day, 12);
      expect(st.eventName, 'שבת');
      expect(st.candleLighting, isNotNull);
      expect(st.havdalah, isNotNull);
      // Candle lighting Friday evening, havdalah Saturday night.
      expect(st.candleLighting!.isBefore(st.havdalah!), isTrue);
      expect(st.havdalahDay!.weekday, DateTime.saturday);
    });

    test('anchors to current Shabbat when called on Shabbat', () {
      // Sat 13 June 2026.
      final st =
          ZmanimService.nextShabbatOrYomTov(jerusalem, DateTime(2026, 6, 13));
      expect(st, isNotNull);
      expect(st!.candleLightingDay.day, 12,
          reason: 'should anchor to the Shabbat in progress');
    });

    test('detects Yom Tov (Shavuot 5786) with its Hebrew name', () {
      // Erev Shavuot: Thu 21 May 2026. From Tue 19 May the next restricted
      // day is Shavuot (Friday 22 May), then Shabbat right after.
      final st =
          ZmanimService.nextShabbatOrYomTov(jerusalem, DateTime(2026, 5, 19));
      expect(st, isNotNull);
      expect(st!.candleLightingDay.day, 21);
      expect(st.eventName, contains('שבועות'));
      // Shavuot Friday flows into Shabbat — havdalah is Saturday night.
      expect(st.havdalahDay!.weekday, DateTime.saturday);
    });

    test('candle lighting is ~18 min before sunset', () {
      final st =
          ZmanimService.nextShabbatOrYomTov(jerusalem, DateTime(2026, 6, 10));
      final fridayZmanim =
          ZmanimService.dayZmanim(jerusalem, st!.candleLightingDay);
      final sunset = fridayZmanim.items
          .firstWhere((i) => i.name.contains('שקיעה'))
          .time!;
      final diff = sunset.difference(st.candleLighting!).inMinutes;
      expect(diff, inInclusiveRange(17, 19));
    });
  });
}
