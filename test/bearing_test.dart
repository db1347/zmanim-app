import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/core/constants.dart';
import 'package:yeadut/services/bearing.dart';

void main() {
  group('greatCircleBearing', () {
    test('NYC to Jerusalem points northeast (~54°)', () {
      final bearing = greatCircleBearing(
          40.7128, -74.0060, kJerusalemLat, kJerusalemLng);
      expect(bearing, closeTo(54, 3));
    });

    test('Tel Aviv to Jerusalem points roughly east-southeast', () {
      final bearing = greatCircleBearing(
          32.0853, 34.7818, kJerusalemLat, kJerusalemLng);
      expect(bearing, inInclusiveRange(120, 145));
    });

    test('due north when directly south of target on same meridian', () {
      final bearing = greatCircleBearing(20.0, 35.2354, 31.0, 35.2354);
      expect(bearing, closeTo(0, 0.01));
    });

    test('result is always in [0, 360)', () {
      for (final (lat, lng) in [(-60.0, -150.0), (75.0, 170.0), (0.0, 0.0)]) {
        final b = greatCircleBearing(lat, lng, kJerusalemLat, kJerusalemLng);
        expect(b, inInclusiveRange(0, 359.9999));
      }
    });
  });

  group('rhumbLineBearing', () {
    test('NYC rhumb line differs substantially from great circle', () {
      final gc = greatCircleBearing(
          40.7128, -74.0060, kJerusalemLat, kJerusalemLng);
      final rl =
          rhumbLineBearing(40.7128, -74.0060, kJerusalemLat, kJerusalemLng);
      // The classic ~40-70° split between the two opinions from the US east coast.
      expect((rl - gc).abs(), greaterThan(30));
      expect(rl, inInclusiveRange(90, 130)); // roughly east-southeast
    });

    test('identical longitudes give due north/south', () {
      expect(rhumbLineBearing(20.0, 35.0, 30.0, 35.0), closeTo(0, 0.01));
      expect(rhumbLineBearing(30.0, 35.0, 20.0, 35.0), closeTo(180, 0.01));
    });
  });

  group('greatCircleDistanceKm', () {
    test('NYC to Jerusalem is about 9,200 km', () {
      final d = greatCircleDistanceKm(
          40.7128, -74.0060, kJerusalemLat, kJerusalemLng);
      expect(d, closeTo(9200, 200));
    });

    test('zero distance to self', () {
      expect(
          greatCircleDistanceKm(
              kJerusalemLat, kJerusalemLng, kJerusalemLat, kJerusalemLng),
          closeTo(0, 0.001));
    });
  });

  group('angleDelta', () {
    test('wraps across 0/360 correctly', () {
      expect(angleDelta(350, 10), closeTo(20, 0.001));
      expect(angleDelta(10, 350), closeTo(-20, 0.001));
      expect(angleDelta(0, 180), closeTo(180, 0.001));
      expect(angleDelta(90, 90), closeTo(0, 0.001));
    });
  });
}
