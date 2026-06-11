import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/shabbat_alarm.dart';

void main() {
  group('ShabbatAlarm', () {
    test('round-trips through JSON', () {
      const alarm = ShabbatAlarm(hour: 8, minute: 30, ringMinutes: 3);
      final restored = ShabbatAlarm.fromJson(alarm.toJson());
      expect(restored.hour, 8);
      expect(restored.minute, 30);
      expect(restored.ringMinutes, 3);
    });

    test('label is zero-padded 24-hour format', () {
      expect(const ShabbatAlarm(hour: 8, minute: 5).label, '08:05');
      expect(const ShabbatAlarm(hour: 0, minute: 0).label, '00:00');
      expect(const ShabbatAlarm(hour: 23, minute: 59).label, '23:59');
    });

    test('fromJson falls back on malformed input', () {
      final alarm = ShabbatAlarm.fromJson(const {});
      expect(alarm.hour, 8);
      expect(alarm.minute, 0);
      expect(alarm.ringMinutes, 2);
    });
  });
}
