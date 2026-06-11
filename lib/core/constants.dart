/// App-wide constants.
library;

/// Coordinates of the Temple Mount, Jerusalem — the halachic prayer direction.
const double kJerusalemLat = 31.7780;
const double kJerusalemLng = 35.2354;

/// Degrees of tolerance within which the compass counts as "facing Jerusalem".
const double kCompassAlignedToleranceDeg = 5.0;

/// Default location used before the user grants GPS or picks a city
/// (Jerusalem — a sensible default for a Jewish lifestyle app).
const String kDefaultLocationName = 'ירושלים';
const double kDefaultLat = 31.7780;
const double kDefaultLng = 35.2354;

/// How many days ahead reminder notifications are scheduled in one pass.
const int kReminderScheduleWindowDays = 14;

/// How many days ahead Shabbat-alarm notifications are scheduled. Covers the
/// next Shabbat plus multi-day Yom Tov runs.
const int kAlarmScheduleWindowDays = 10;

/// How long the Shabbat alarm rings before dismissing itself.
const Duration kAlarmAutoDismissDefault = Duration(minutes: 2);

/// Anthropic API defaults for the AI features.
const String kAnthropicApiUrl = 'https://api.anthropic.com/v1/messages';
const String kAnthropicApiVersion = '2023-06-01';
const String kDefaultAiModel = 'claude-sonnet-4-6';
const int kAiMaxTokens = 1024;
