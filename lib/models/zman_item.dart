/// A single halachic time for display.
class ZmanItem {
  final String name;
  final String explanation;
  final DateTime? time;

  const ZmanItem({
    required this.name,
    required this.explanation,
    required this.time,
  });
}

/// All zmanim for one civil day, sorted by time.
class DayZmanim {
  final DateTime date;
  final List<ZmanItem> items;

  const DayZmanim({required this.date, required this.items});

  /// The first zman strictly after [now], or null if the day is over.
  ZmanItem? nextAfter(DateTime now) {
    for (final item in items) {
      final t = item.time;
      if (t != null && t.isAfter(now)) return item;
    }
    return null;
  }

  /// The latest zman at or before [now] (for interval progress display).
  ZmanItem? previousBefore(DateTime now) {
    ZmanItem? prev;
    for (final item in items) {
      final t = item.time;
      if (t != null && !t.isAfter(now)) prev = item;
    }
    return prev;
  }
}

/// Candle lighting / havdalah for the next Shabbat or Yom Tov.
class ShabbatTimes {
  final String eventName;
  final DateTime candleLightingDay;
  final DateTime? candleLighting;

  /// True when lighting is after dark from a pre-existing flame
  /// (second night of Yom Tov, or Yom Tov following Shabbat).
  final bool lightingAfterDark;
  final DateTime? havdalah;
  final DateTime? havdalahDay;

  const ShabbatTimes({
    required this.eventName,
    required this.candleLightingDay,
    required this.candleLighting,
    required this.lightingAfterDark,
    required this.havdalah,
    required this.havdalahDay,
  });
}
