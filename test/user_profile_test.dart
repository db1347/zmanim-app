import 'package:flutter_test/flutter_test.dart';
import 'package:yeadut/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('round-trips through JSON', () {
      const original = UserProfile(
        onboardingComplete: true,
        gender: Gender.female,
        nusach: Nusach.edotHamizrach,
        dayLengthShita: DayLengthShita.magenAvraham,
        alosShita: AlosShita.minutes90,
        tzeitShita: TzeitShita.minutes72,
        candleLightingMinutes: 40,
        inIsrael: true,
        locationName: 'חיפה',
        latitude: 32.794,
        longitude: 34.9896,
        useGreatCircleBearing: false,
        tefillinReminderEnabled: true,
        tefillinReminderHour: 6,
        tefillinReminderMinute: 45,
        candleReminderEnabled: true,
        candleReminderLeadMinutes: 45,
      );

      final restored = UserProfile.decode(original.encode());
      expect(restored.toJson(), original.toJson());
      expect(restored.locationName, 'חיפה');
    });

    test('API key is never serialized into the profile blob', () {
      const profile = UserProfile(anthropicApiKey: 'sk-super-secret');
      expect(profile.encode(), isNot(contains('sk-super-secret')));
      expect(profile.toJson().containsKey('anthropicApiKey'), isFalse);
      // But legacy blobs that contain a key are still read (migration).
      final legacy = UserProfile.fromJson({'anthropicApiKey': 'sk-old'});
      expect(legacy.anthropicApiKey, 'sk-old');
    });

    test('decodes gracefully from partial/unknown JSON', () {
      final restored = UserProfile.fromJson({
        'nusach': 'doesNotExist',
        'latitude': 1,
        'unknownField': true,
      });
      expect(restored.nusach, Nusach.ashkenaz); // fallback
      expect(restored.latitude, 1.0); // int → double
      expect(restored.onboardingComplete, isFalse);
    });

    test('copyWith creates a new object without mutating the original', () {
      const original = UserProfile();
      final changed = original.copyWith(locationName: 'תל אביב');
      expect(original.locationName, isNot('תל אביב'));
      expect(changed.locationName, 'תל אביב');
      expect(changed.nusach, original.nusach);
    });
  });
}
