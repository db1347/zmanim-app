import 'package:flutter/material.dart';

import '../../models/bracha_entry.dart';

/// Shows a matched food with its bracha rishona (full Hebrew text) and
/// bracha acharona.
class BrachaResultCard extends StatelessWidget {
  const BrachaResultCard({super.key, required this.entry});

  final BrachaEntry entry;

  static const String _opening = 'בָּרוּךְ אַתָּה ה׳ אֱלֹקֵינוּ מֶלֶךְ הָעוֹלָם';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('לפני האכילה — ${entry.rishona.label}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary)),
            const SizedBox(height: 4),
            Text(
              '$_opening ${entry.rishona.hebrewEnding}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 18, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text('אחרי האכילה — ${entry.acharona.label}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.tertiary)),
            const SizedBox(height: 2),
            Text(entry.acharona.description,
                style: const TextStyle(fontSize: 13.5)),
            if (entry.note != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(entry.note!,
                    style: TextStyle(
                        fontSize: 12.5, color: scheme.onSecondaryContainer)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
