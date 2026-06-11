import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shabbat_alarm.dart';
import '../../services/alarm_store.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import 'shabbat_mode_screen.dart';

/// Kosher Shabbat alarm setup. Everything is configured BEFORE Shabbat.
///
/// Two layers make the alarm a certainty:
/// 1. Real OS alarms — exact, full-screen notifications on the alarm channel
///    that loop their sound and cancel themselves (Android; scheduled for
///    every Shabbat/Yom Tov in the coming days).
/// 2. In-app Shabbat mode — a dimmed clock that rings and stops by itself;
///    the reliable path on iOS and a belt-and-suspenders backup on Android.
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  List<ShabbatAlarm> _alarms = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final alarms = await AlarmStore.load();
    if (!mounted) return;
    setState(() {
      _alarms = alarms;
      _loaded = true;
    });
  }

  /// Persists the list and re-schedules the OS alarms to match.
  Future<void> _saveAndReschedule(List<ShabbatAlarm> next) async {
    setState(() => _alarms = next);
    await AlarmStore.save(next);
    if (!mounted) return;
    final notifications = context.read<NotificationService>();
    final profile = context.read<SettingsService>().profile;
    await notifications.requestPermissions();
    await notifications.rescheduleAll(profile);
  }

  Future<void> _addAlarm() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: 'שעון מעורר לשבת בבוקר',
    );
    if (picked == null) return;
    final next = [
      ..._alarms,
      ShabbatAlarm(hour: picked.hour, minute: picked.minute),
    ]..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    await _saveAndReschedule(next);
  }

  Future<void> _removeAlarm(int index) async {
    final next = [..._alarms]..removeAt(index);
    await _saveAndReschedule(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('שעון מעורר לשבת')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        tooltip: 'הוספת התראה',
        child: const Icon(Icons.add_alarm),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: scheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'איך זה עובד: מגדירים שעות עכשיו, לפני שבת. ההתראות '
                      'מתוזמנות מראש לכל שבת ויום טוב בימים הקרובים, '
                      'מצלצלות ונכבות מעצמן — בלי לגעת במכשיר. מומלץ '
                      'בנוסף להפעיל את מצב שבת עם הטלפון מחובר לחשמל. '
                      'יש מנהגים שונים לגבי שעון מעורר בשבת — התייעצו '
                      'עם רב.',
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSecondaryContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_alarms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'אין עדיין התראות — הוסיפו אחת בכפתור +',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline),
                    ),
                  ),
                for (final (i, alarm) in _alarms.indexed)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(alarm.label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'מצלצל ${alarm.ringMinutes} דקות ונכבה מעצמו, '
                          'בכל שבת ויום טוב'),
                      trailing: IconButton(
                        tooltip: 'מחיקה',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeAlarm(i),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _alarms.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ShabbatModeScreen(alarms: _alarms),
                            ),
                          ),
                  icon: const Icon(Icons.nightlight_round),
                  label: const Text('כניסה למצב שבת'),
                ),
                const SizedBox(height: 8),
                Text(
                  'מצב שבת משאיר את האפליקציה פתוחה עם שעון מעומעם — '
                  'הדרך האמינה ביותר, וחובה במכשירי אייפון (iOS לא מאפשר '
                  'צלצול ממושך ברקע ללא מגע). השאירו את הטלפון מחובר '
                  'לחשמל.',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              ],
            ),
    );
  }
}
