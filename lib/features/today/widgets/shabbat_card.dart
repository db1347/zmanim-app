import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/zman_item.dart';

/// Candle lighting / havdalah for the upcoming (or current) Shabbat or chag.
/// Within six hours of candle lighting it adds a live countdown — the
/// number that matters most on a Friday afternoon.
class ShabbatCard extends StatelessWidget {
  const ShabbatCard({super.key, required this.times, required this.now});

  final ShabbatTimes times;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dayFmt = DateFormat.EEEE();
    final timeFmt = DateFormat.Hm();

    Duration? untilCandles;
    final lighting = times.candleLighting;
    if (lighting != null) {
      final d = lighting.difference(now);
      if (!d.isNegative && d <= const Duration(hours: 6)) untilCandles = d;
    }

    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department,
                    size: 20, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    times.eventName,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row(
              context,
              label: times.lightingAfterDark
                  ? 'הדלקת נרות (אחרי צאת הכוכבים, מאש קיימת)'
                  : 'הדלקת נרות',
              value: times.candleLighting == null
                  ? '—'
                  : '${dayFmt.format(times.candleLightingDay)} '
                      '${timeFmt.format(times.candleLighting!)}',
            ),
            const SizedBox(height: 6),
            _row(
              context,
              label: 'הבדלה',
              value: times.havdalah == null || times.havdalahDay == null
                  ? '—'
                  : '${dayFmt.format(times.havdalahDay!)} '
                      '${timeFmt.format(times.havdalah!)}',
            ),
            if (untilCandles != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.onTertiaryContainer.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🕯️ עוד ${_fmtDuration(untilCandles)} להדלקת נרות',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')} שעות';
    return '$m דקות';
  }

  Widget _row(BuildContext context,
      {required String label, required String value}) {
    final color = Theme.of(context).colorScheme.onTertiaryContainer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              style: TextStyle(color: color.withValues(alpha: 0.85))),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
