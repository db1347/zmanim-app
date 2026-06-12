import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeadut/models/hebrew_event.dart';
import 'package:yeadut/models/shabbat_alarm.dart';
import 'package:yeadut/models/user_profile.dart';
import 'package:yeadut/services/alarm_store.dart';
import 'package:yeadut/services/backup_service.dart';
import 'package:yeadut/services/event_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BackupService', () {
    test('exports and re-imports profile, events, and alarms', () async {
      const profile = UserProfile(
        locationName: 'חיפה',
        nusach: Nusach.sefard,
        candleLightingMinutes: 40,
        anthropicApiKey: 'sk-secret-on-device',
      );
      await EventStore.save([
        const HebrewEvent(
            id: '1',
            name: 'סבא יוסף ז״ל',
            type: HebrewEventType.yahrzeit,
            jewishMonth: 12,
            jewishDay: 20),
      ]);
      await AlarmStore.save([const ShabbatAlarm(hour: 8, minute: 30)]);

      final blob = await BackupService.export(profile);
      expect(blob, isNot(contains('sk-secret-on-device')),
          reason: 'the API key must never leave the device');

      // Restore onto a "new device" whose own key should survive.
      const newDevice = UserProfile(anthropicApiKey: 'sk-new-device');
      final parsed = await BackupService.parse(blob, current: newDevice);
      expect(parsed, isNotNull);
      expect(parsed!.profile.locationName, 'חיפה');
      expect(parsed.profile.nusach, Nusach.sefard);
      expect(parsed.profile.candleLightingMinutes, 40);
      expect(parsed.profile.anthropicApiKey, 'sk-new-device');
      expect(parsed.events.single.name, 'סבא יוסף ז״ל');
      expect(parsed.alarms.single.minute, 30);
    });

    test('rejects non-Yeadut JSON and garbage', () async {
      const current = UserProfile();
      expect(await BackupService.parse('{"app":"other"}', current: current),
          isNull);
      expect(await BackupService.parse('not json at all', current: current),
          isNull);
      expect(await BackupService.parse('', current: current), isNull);
    });
  });
}
