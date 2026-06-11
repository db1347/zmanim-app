import 'package:flutter/material.dart';

/// Bounded kosher decision trees — only well-defined customs, never psak.
/// Anything involving mixtures or accidents routes to a Rav.
class KosherSituationsScreen extends StatelessWidget {
  const KosherSituationsScreen({super.key});

  static const List<({String custom, String wait, String detail})> _waits = [
    (
      custom: 'המנהג הרווח (רוב הקהילות)',
      wait: '6 שעות',
      detail: 'ספרדים ורוב האשכנזים ממתינים שש שעות מלאות אחרי בשר '
          'לפני מאכלי חלב.'
    ),
    (
      custom: 'מנהג יוצאי גרמניה (יקים)',
      wait: '3 שעות',
      detail: 'רבים מיוצאי גרמניה ממתינים שלוש שעות.'
    ),
    (
      custom: 'מנהג הולנד',
      wait: '72 דקות',
      detail: 'מנהג יהדות הולנד — המתנה של שעה ורבע בקירוב.'
    ),
    (
      custom: 'מחלב לבשר',
      wait: 'קינוח והדחה',
      detail: 'אחרי רוב מוצרי החלב די בהדחת הפה ואכילת דבר פרווה; אחרי '
          'גבינה קשה מיושנת רבים ממתינים כמו מבשר לחלב. המנהגים שונים.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('בשר וחלב')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('המתנה בין בשר לחלב',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'לכו לפי מנהג המשפחה או הקהילה שלכם.',
            style: TextStyle(color: scheme.outline, fontSize: 13),
          ),
          const SizedBox(height: 12),
          for (final w in _waits)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(w.custom),
                subtitle: Text(w.detail),
                trailing: Text(
                  w.wait,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: scheme.primary),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'תקלות כשרות — כף חלבית בסיר בשרי, כלים שהתערבבו, מוצר '
                'מפוקפק — אפליקציה אינה יכולה לפסוק בהן. אלו שאלות '
                'התלויות בפרטים שרק רב יכול לשקול. השתמשו בלשונית «שאל» '
                'לרקע, ואז התקשרו לרב.',
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
