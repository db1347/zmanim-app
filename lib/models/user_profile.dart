import 'dart:convert';

import '../core/constants.dart';

enum Gender { male, female, unspecified }

enum Nusach { ashkenaz, sefard, edotHamizrach, ari, temani }

/// How sha'ot zmaniyot (proportional hours) are computed.
enum DayLengthShita { gra, magenAvraham }

/// Opinion used for tzeit hakochavim / end of Shabbat.
enum TzeitShita { degrees8_5, minutes42, minutes50, minutes72 }

/// Opinion used for alos hashachar.
enum AlosShita { degrees16_1, minutes72, minutes90 }

extension NusachLabel on Nusach {
  String get label => switch (this) {
        Nusach.ashkenaz => 'אשכנז',
        Nusach.sefard => 'ספרד',
        Nusach.edotHamizrach => 'עדות המזרח',
        Nusach.ari => 'נוסח האר״י',
        Nusach.temani => 'תימני',
      };
}

extension TzeitShitaLabel on TzeitShita {
  String get label => switch (this) {
        TzeitShita.degrees8_5 => 'ג׳ כוכבים (8.5°)',
        TzeitShita.minutes42 => '42 דקות',
        TzeitShita.minutes50 => '50 דקות',
        TzeitShita.minutes72 => '72 דקות (רבנו תם)',
      };
}

extension AlosShitaLabel on AlosShita {
  String get label => switch (this) {
        AlosShita.degrees16_1 => '16.1° מתחת לאופק',
        AlosShita.minutes72 => '72 דקות',
        AlosShita.minutes90 => '90 דקות',
      };
}

/// Immutable user profile. Use [copyWith] to derive modified copies.
class UserProfile {
  final bool onboardingComplete;
  final Gender gender;
  final Nusach nusach;
  final DayLengthShita dayLengthShita;
  final AlosShita alosShita;
  final TzeitShita tzeitShita;
  final int candleLightingMinutes; // 18 standard, 40 Jerusalem custom
  final bool inIsrael;
  final String locationName;
  final double latitude;
  final double longitude;
  final bool useGreatCircleBearing;

  // Reminders
  final bool tefillinReminderEnabled;
  final int tefillinReminderHour;
  final int tefillinReminderMinute;
  final bool candleReminderEnabled;
  final int candleReminderLeadMinutes;

  // AI (key stored locally on device only)
  final String anthropicApiKey;
  final String aiModel;

  const UserProfile({
    this.onboardingComplete = false,
    this.gender = Gender.unspecified,
    this.nusach = Nusach.ashkenaz,
    this.dayLengthShita = DayLengthShita.gra,
    this.alosShita = AlosShita.degrees16_1,
    this.tzeitShita = TzeitShita.degrees8_5,
    this.candleLightingMinutes = 18,
    this.inIsrael = false,
    this.locationName = kDefaultLocationName,
    this.latitude = kDefaultLat,
    this.longitude = kDefaultLng,
    this.useGreatCircleBearing = true,
    this.tefillinReminderEnabled = false,
    this.tefillinReminderHour = 7,
    this.tefillinReminderMinute = 0,
    this.candleReminderEnabled = false,
    this.candleReminderLeadMinutes = 30,
    this.anthropicApiKey = '',
    this.aiModel = kDefaultAiModel,
  });

  UserProfile copyWith({
    bool? onboardingComplete,
    Gender? gender,
    Nusach? nusach,
    DayLengthShita? dayLengthShita,
    AlosShita? alosShita,
    TzeitShita? tzeitShita,
    int? candleLightingMinutes,
    bool? inIsrael,
    String? locationName,
    double? latitude,
    double? longitude,
    bool? useGreatCircleBearing,
    bool? tefillinReminderEnabled,
    int? tefillinReminderHour,
    int? tefillinReminderMinute,
    bool? candleReminderEnabled,
    int? candleReminderLeadMinutes,
    String? anthropicApiKey,
    String? aiModel,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      gender: gender ?? this.gender,
      nusach: nusach ?? this.nusach,
      dayLengthShita: dayLengthShita ?? this.dayLengthShita,
      alosShita: alosShita ?? this.alosShita,
      tzeitShita: tzeitShita ?? this.tzeitShita,
      candleLightingMinutes:
          candleLightingMinutes ?? this.candleLightingMinutes,
      inIsrael: inIsrael ?? this.inIsrael,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      useGreatCircleBearing:
          useGreatCircleBearing ?? this.useGreatCircleBearing,
      tefillinReminderEnabled:
          tefillinReminderEnabled ?? this.tefillinReminderEnabled,
      tefillinReminderHour: tefillinReminderHour ?? this.tefillinReminderHour,
      tefillinReminderMinute:
          tefillinReminderMinute ?? this.tefillinReminderMinute,
      candleReminderEnabled:
          candleReminderEnabled ?? this.candleReminderEnabled,
      candleReminderLeadMinutes:
          candleReminderLeadMinutes ?? this.candleReminderLeadMinutes,
      anthropicApiKey: anthropicApiKey ?? this.anthropicApiKey,
      aiModel: aiModel ?? this.aiModel,
    );
  }

  /// NOTE: deliberately excludes [anthropicApiKey] — the key is persisted
  /// under its own storage entry by SettingsService so it never appears in
  /// profile dumps or logs.
  Map<String, dynamic> toJson() => {
        'onboardingComplete': onboardingComplete,
        'gender': gender.name,
        'nusach': nusach.name,
        'dayLengthShita': dayLengthShita.name,
        'alosShita': alosShita.name,
        'tzeitShita': tzeitShita.name,
        'candleLightingMinutes': candleLightingMinutes,
        'inIsrael': inIsrael,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'useGreatCircleBearing': useGreatCircleBearing,
        'tefillinReminderEnabled': tefillinReminderEnabled,
        'tefillinReminderHour': tefillinReminderHour,
        'tefillinReminderMinute': tefillinReminderMinute,
        'candleReminderEnabled': candleReminderEnabled,
        'candleReminderLeadMinutes': candleReminderLeadMinutes,
        'aiModel': aiModel,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    T enumFrom<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.asNameMap()[name] ?? fallback;
    const def = UserProfile();
    return UserProfile(
      onboardingComplete:
          json['onboardingComplete'] as bool? ?? def.onboardingComplete,
      gender: enumFrom(Gender.values, json['gender'], def.gender),
      nusach: enumFrom(Nusach.values, json['nusach'], def.nusach),
      dayLengthShita: enumFrom(
          DayLengthShita.values, json['dayLengthShita'], def.dayLengthShita),
      alosShita: enumFrom(AlosShita.values, json['alosShita'], def.alosShita),
      tzeitShita:
          enumFrom(TzeitShita.values, json['tzeitShita'], def.tzeitShita),
      candleLightingMinutes: json['candleLightingMinutes'] as int? ??
          def.candleLightingMinutes,
      inIsrael: json['inIsrael'] as bool? ?? def.inIsrael,
      locationName: json['locationName'] as String? ?? def.locationName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? def.latitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? def.longitude,
      useGreatCircleBearing: json['useGreatCircleBearing'] as bool? ??
          def.useGreatCircleBearing,
      tefillinReminderEnabled: json['tefillinReminderEnabled'] as bool? ??
          def.tefillinReminderEnabled,
      tefillinReminderHour:
          json['tefillinReminderHour'] as int? ?? def.tefillinReminderHour,
      tefillinReminderMinute:
          json['tefillinReminderMinute'] as int? ?? def.tefillinReminderMinute,
      candleReminderEnabled:
          json['candleReminderEnabled'] as bool? ?? def.candleReminderEnabled,
      candleReminderLeadMinutes: json['candleReminderLeadMinutes'] as int? ??
          def.candleReminderLeadMinutes,
      // Legacy profiles stored the key in the blob; read it for migration.
      anthropicApiKey:
          json['anthropicApiKey'] as String? ?? def.anthropicApiKey,
      aiModel: json['aiModel'] as String? ?? def.aiModel,
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserProfile.decode(String raw) =>
      UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
