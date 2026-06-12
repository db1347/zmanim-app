import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';

import '../../models/hebrew_event.dart';
import '../../services/event_store.dart';
import '../../services/hebrew_event_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';

/// Yahrzeits and Hebrew-date events: list with next occurrence + countdown,
/// add/delete, and automatic reminders (eve + morning of).
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<HebrewEvent> _events = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await EventStore.load();
    if (!mounted) return;
    setState(() {
      _events = events;
      _loaded = true;
    });
  }

  Future<void> _saveAndReschedule(List<HebrewEvent> next) async {
    setState(() => _events = next);
    await EventStore.save(next);
    if (!mounted) return;
    final notifications = context.read<NotificationService>();
    final profile = context.read<SettingsService>().profile;
    await notifications.requestPermissions();
    await notifications.rescheduleAll(profile);
  }

  Future<void> _addEvent() async {
    final created = await showDialog<HebrewEvent>(
      context: context,
      builder: (_) => const _AddEventDialog(),
    );
    if (created == null) return;
    await _saveAndReschedule([..._events, created]);
  }

  Future<void> _delete(HebrewEvent e) async {
    await _saveAndReschedule(
        _events.where((x) => x.id != e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final sorted = [..._events]..sort((a, b) =>
        HebrewEventService.nextOccurrence(a, now)
            .compareTo(HebrewEventService.nextOccurrence(b, now)));

    return Scaffold(
      appBar: AppBar(title: const Text('תאריכים עבריים')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        tooltip: 'הוספת תאריך',
        child: const Icon(Icons.add),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : sorted.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note,
                            size: 56, color: scheme.outline),
                        const SizedBox(height: 12),
                        Text(
                          'יארצייטים, ימי הולדת עבריים וימי נישואין —\n'
                          'נזכיר לכם לפי התאריך העברי, כולל נר נשמה '
                          'בערב שלפני.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final e in sorted) _eventCard(context, e, now),
                    const SizedBox(height: 72),
                  ],
                ),
    );
  }

  Widget _eventCard(BuildContext context, HebrewEvent e, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final next = HebrewEventService.nextOccurrence(e, now);
    final daysUntil =
        next.difference(DateTime(now.year, now.month, now.day)).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Text(e.type.emoji, style: const TextStyle(fontSize: 26)),
          title: Text(e.name,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${e.type.label} · ${HebrewEventService.dateLabel(e)}\n'
            '${DateFormat.yMMMMEEEEd().format(next)}',
            style: const TextStyle(height: 1.4),
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                daysUntil == 0 ? 'היום' : 'בעוד $daysUntil ימים',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: daysUntil <= 7 ? scheme.tertiary : scheme.outline,
                ),
              ),
              IconButton(
                tooltip: 'מחיקה',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _delete(e),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  const _AddEventDialog();

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _name = TextEditingController();
  HebrewEventType _type = HebrewEventType.yahrzeit;
  int _month = JewishDate.NISSAN;
  int _day = 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('תאריך עברי חדש'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'שם (למשל: סבא יוסף ז״ל)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<HebrewEventType>(
              initialValue: _type,
              decoration: const InputDecoration(
                  labelText: 'סוג', border: OutlineInputBorder()),
              items: [
                for (final t in HebrewEventType.values)
                  DropdownMenuItem(
                      value: t, child: Text('${t.emoji} ${t.label}')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(
                        labelText: 'חודש', border: OutlineInputBorder()),
                    items: [
                      for (final m in kJewishMonthNames.entries)
                        DropdownMenuItem(
                            value: m.key, child: Text(m.value)),
                    ],
                    onChanged: (v) => setState(() => _month = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _day,
                    decoration: const InputDecoration(
                        labelText: 'יום', border: OutlineInputBorder()),
                    items: [
                      for (var d = 1; d <= 30; d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'אדר בשנה מעוברת: נהוג לציין באדר א׳ (יש הנוהגים אחרת — '
              'שאלו רב). ל׳ בחודש חסר יידחה ליום האחרון בחודש.',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(HebrewEvent(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              type: _type,
              jewishMonth: _month,
              jewishDay: _day,
            ));
          },
          child: const Text('שמירה'),
        ),
      ],
    );
  }
}
