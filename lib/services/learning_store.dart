import 'package:shared_preferences/shared_preferences.dart';

const String _kDoneDaysKey = 'daf_yomi_done_days_v1';

/// Tracks which civil days the user finished their daf, for streaks.
class LearningStore {
  const LearningStore._();

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<Set<String>> loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kDoneDaysKey) ?? []).toSet();
  }

  static Future<void> saveDone(Set<String> days) async {
    final prefs = await SharedPreferences.getInstance();
    // Cap storage: keep the most recent 400 entries.
    final sorted = days.toList()..sort();
    await prefs.setStringList(
        _kDoneDaysKey,
        sorted.length > 400 ? sorted.sublist(sorted.length - 400) : sorted);
  }

  static bool isDone(Set<String> done, DateTime day) =>
      done.contains(_key(day));

  static Set<String> toggle(Set<String> done, DateTime day) {
    final next = {...done};
    final k = _key(day);
    if (!next.add(k)) next.remove(k);
    return next;
  }

  /// Consecutive finished days ending today (or yesterday if today isn't
  /// done yet — an evening learner shouldn't see a broken streak at noon).
  static int streak(Set<String> done, DateTime today) {
    var day = DateTime(today.year, today.month, today.day);
    if (!done.contains(_key(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var s = 0;
    while (done.contains(_key(day))) {
      s++;
      day = day.subtract(const Duration(days: 1));
    }
    return s;
  }
}
