import 'package:shared_preferences/shared_preferences.dart';

const String _kCountedKey = 'omer_counted_days_v1';
const String _kYearKey = 'omer_counted_year_v1';

/// Tracks which omer days the user marked as counted this season.
/// Keyed by Jewish year so the set resets automatically each season.
class OmerStore {
  const OmerStore._();

  static Future<Set<int>> loadCounted(int jewishYear) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_kYearKey) != jewishYear) return {};
    final list = prefs.getStringList(_kCountedKey) ?? [];
    return list.map(int.parse).toSet();
  }

  static Future<void> saveCounted(int jewishYear, Set<int> days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kYearKey, jewishYear);
    await prefs.setStringList(
        _kCountedKey, days.map((d) => d.toString()).toList());
  }

  /// Current streak: consecutive days counted, ending at [upToDay].
  static int streak(Set<int> counted, int upToDay) {
    var s = 0;
    for (var d = upToDay; d >= 1; d--) {
      if (counted.contains(d)) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  /// Whether a full day was ever skipped before [day] — per most opinions
  /// one then continues counting without a bracha.
  static bool missedADay(Set<int> counted, int day) {
    for (var d = 1; d < day; d++) {
      if (!counted.contains(d)) return true;
    }
    return false;
  }
}
