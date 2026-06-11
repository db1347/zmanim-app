import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile.dart';
import '../../../services/notification_service.dart';

/// Reminder manager: per-reminder toggles and timing rules, with the
/// suppression behavior stated up front (trust-building).
class RemindersSection extends StatelessWidget {
  const RemindersSection({
    super.key,
    required this.profile,
    required this.onUpdate,
  });

  final UserProfile profile;
  final Future<void> Function(UserProfile) onUpdate;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Text(
            'תזכורות',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            'תזכורות לעולם לא יישלחו בשבת וביום טוב.',
            style: TextStyle(
                fontSize: 13, color: Theme.of(context).colorScheme.outline),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.self_improvement),
          title: const Text('תפילין'),
          subtitle: Text(
              'מדי יום ב־${_fmtTime(p.tefillinReminderHour, p.tefillinReminderMinute)}'
              ' · מדלג על שבת, יו״ט, חול המועד ותשעה באב'),
          value: p.tefillinReminderEnabled,
          onChanged: (v) async {
            final granted = !v ||
                await context.read<NotificationService>().requestPermissions();
            await onUpdate(
                p.copyWith(tefillinReminderEnabled: v && granted));
          },
        ),
        if (p.tefillinReminderEnabled)
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('שעת תזכורת התפילין'),
            trailing: TextButton(
              child: Text(
                  _fmtTime(p.tefillinReminderHour, p.tefillinReminderMinute)),
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: p.tefillinReminderHour,
                    minute: p.tefillinReminderMinute,
                  ),
                );
                if (picked != null) {
                  await onUpdate(p.copyWith(
                    tefillinReminderHour: picked.hour,
                    tefillinReminderMinute: picked.minute,
                  ));
                }
              },
            ),
          ),
        SwitchListTile(
          secondary: const Icon(Icons.local_fire_department_outlined),
          title: const Text('הדלקת נרות'),
          subtitle: Text(
              '${p.candleReminderLeadMinutes} דקות לפני, בכל ערב שבת '
              'וערב יום טוב'),
          value: p.candleReminderEnabled,
          onChanged: (v) async {
            final granted = !v ||
                await context.read<NotificationService>().requestPermissions();
            await onUpdate(p.copyWith(candleReminderEnabled: v && granted));
          },
        ),
        if (p.candleReminderEnabled)
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('זמן התראה מראש'),
            trailing: DropdownButton<int>(
              value: p.candleReminderLeadMinutes,
              underline: const SizedBox.shrink(),
              onChanged: (v) async {
                if (v != null) {
                  await onUpdate(p.copyWith(candleReminderLeadMinutes: v));
                }
              },
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 דק׳')),
                DropdownMenuItem(value: 30, child: Text('30 דק׳')),
                DropdownMenuItem(value: 45, child: Text('45 דק׳')),
                DropdownMenuItem(value: 60, child: Text('60 דק׳')),
              ],
            ),
          ),
      ],
    );
  }

  static String _fmtTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
