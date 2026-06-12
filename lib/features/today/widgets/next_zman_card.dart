import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/zman_item.dart';

/// Hero card: countdown to the next halachic time, with a progress bar
/// showing how far through the interval since the previous zman we are.
class NextZmanCard extends StatelessWidget {
  const NextZmanCard({
    super.key,
    required this.next,
    required this.previous,
    required this.now,
  });

  final ZmanItem? next;
  final ZmanItem? previous;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final item = next;

    double? progress;
    if (item?.time != null && previous?.time != null) {
      final total =
          item!.time!.difference(previous!.time!).inSeconds.toDouble();
      if (total > 0) {
        progress =
            (now.difference(previous!.time!).inSeconds / total).clamp(0, 1);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [YeadutTheme.midBlue, YeadutTheme.deepBlue],
        ),
        boxShadow: [
          BoxShadow(
            color: YeadutTheme.deepBlue.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: item == null
          ? const Text(
              'כל זמני היום עברו.\nנתראה בעלות השחר.',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 15, color: YeadutTheme.goldBright),
                    const SizedBox(width: 6),
                    Text(
                      'הזמן הבא',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _countdown(item.time!, now),
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                        color: YeadutTheme.goldBright,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'בשעה ${DateFormat.Hm().format(item.time!)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation(
                          YeadutTheme.goldBright),
                    ),
                  ),
                ],
              ],
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
