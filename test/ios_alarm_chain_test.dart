import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/services/ios_alarm_service.dart';

void main() {
  group('chainFireTimes (iOS < 26 fallback)', () {
    test('2-minute ring chains 4 chimes 30s apart', () {
      final start = DateTime(2026, 6, 13, 8, 0);
      final chain = chainFireTimes(start, 2);
      expect(chain, [
        DateTime(2026, 6, 13, 8, 0, 0),
        DateTime(2026, 6, 13, 8, 0, 30),
        DateTime(2026, 6, 13, 8, 1, 0),
        DateTime(2026, 6, 13, 8, 1, 30),
      ]);
    });

    test('long ring is capped at maxChain (notification budget)', () {
      final chain = chainFireTimes(DateTime(2026, 6, 13, 8, 0), 10);
      expect(chain.length, 6, reason: 'default cap');
      expect(
          chainFireTimes(DateTime(2026, 6, 13, 8, 0), 10, maxChain: 3).length,
          3);
    });

    test('always fires at least once, starting exactly at the alarm time',
        () {
      final start = DateTime(2026, 6, 13, 8, 0);
      final chain = chainFireTimes(start, 0);
      expect(chain.length, 1);
      expect(chain.first, start);
    });
  });
}
