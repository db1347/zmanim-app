import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/zman_item.dart';

/// Hero card: countdown to the next halachic time of the day.
class NextZmanCard extends StatelessWidget {
  const NextZmanCard({super.key, required this.next, required this.now});

  final ZmanItem? next;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = next;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: item == null
            ? Text(
                'כל זמני היום עברו.\nנתראה בעלות השחר.',
                style: TextStyle(
                  fontSize: 16,
                  color: scheme.onPrimaryContainer,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'הזמן הבא',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _countdown(item.time!, now),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'בשעה ${DateFormat.Hm().format(item.time!)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: scheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  static String _countdown(DateTime target, DateTime now) {
    final d = target.difference(now);
    if (d.isNegative) return '0:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')} שע׳';
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')} דק׳';
    return '$s שנ׳';
  }
}
