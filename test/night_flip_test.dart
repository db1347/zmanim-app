import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/user_profile.dart';
import 'package:yeadut/services/zmanim_service.dart';

void main() {
  const jerusalem = UserProfile(
    locationName: 'ירושלים',
    latitude: 31.7780,
    longitude: 35.2354,
    inIsrael: true,
  );

  group('ZmanimService.isAfterTzeit', () {
    test('mid-morning is before tzeit', () {
      expect(
        ZmanimService.isAfterTzeit(jerusalem, DateTime(2026, 6, 10, 10, 0)),
        isFalse,
      );
    });

    test('23:00 is after tzeit — the Jewish day has flipped', () {
      expect(
        ZmanimService.isAfterTzeit(jerusalem, DateTime(2026, 6, 10, 23, 0)),
        isTrue,
      );
    });

    test('just before sunset is still before tzeit', () {
      // Sunset in Jerusalem in June ≈ 19:45; tzeit (8.5°) ≈ 20:25.
      expect(
        ZmanimService.isAfterTzeit(jerusalem, DateTime(2026, 6, 10, 19, 30)),
        isFalse,
      );
    });

    test('winter evening flips earlier', () {
      // January: tzeit ≈ 17:30 in Jerusalem; 18:30 is well past it.
      expect(
        ZmanimService.isAfterTzeit(jerusalem, DateTime(2026, 1, 15, 18, 30)),
        isTrue,
      );
    });
  });
}
