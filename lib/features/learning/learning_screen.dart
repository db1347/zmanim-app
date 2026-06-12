import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';

import '../../core/theme.dart';
import '../../services/learning_store.dart';

/// Daily learning: today's Daf Yomi with a done-toggle and streak.
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  Set<String> _done = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final done = await LearningStore.loadDone();
    if (!mounted) return;
    setState(() {
      _done = done;
      _loaded = true;
    });
  }

  Future<void> _toggleToday() async {
    final next = LearningStore.toggle(_done, DateTime.now());
    setState(() => _done = next);
    await LearningStore.saveDone(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final jc = JewishCalendar.fromDateTime(now);
    final hebrew = HebrewDateFormatter()..hebrewFormat = true;

    String dafLabel = '';
    try {
      dafLabel = hebrew.formatDafYomiBavli(YomiCalculator.getDafYomiBavli(jc));
    } catch (_) {}

    final doneToday = LearningStore.isDone(_done, now);
    final streak = LearningStore.streak(_done, now);

    return Scaffold(
      appBar: AppBar(title: const Text('הדף היומי')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Text('הדף של היום',
                            style: TextStyle(
                                fontSize: 13, color: scheme.outline)),
                        const SizedBox(height: 8),
                        Text(
                          dafLabel.isEmpty ? '—' : dafLabel,
                          style: TextStyle(
                            fontFamily: YeadutTheme.displayFont,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'מחזור הש״ס בבלי · דף ליום',
                          style: TextStyle(
                              fontSize: 13, color: scheme.outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _toggleToday,
                  style: doneToday
                      ? FilledButton.styleFrom(
                          backgroundColor: scheme.secondaryContainer,
                          foregroundColor: scheme.onSecondaryContainer)
                      : null,
                  icon: Icon(
                      doneToday ? Icons.check_circle : Icons.menu_book),
                  label: Text(doneToday ? 'סיימתי את הדף ✓' : 'סיימתי את הדף'),
                ),
                if (streak > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '🔥 רצף לימוד של $streak ימים',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: scheme.tertiary),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'טיפ: שיעורי דף יומי זמינים בכל קהילה וברשת — '
                  'כ־45 דקות ביום, ובסוף מסיימים את כל הש״ס.',
                  style: TextStyle(fontSize: 12.5, color: scheme.outline),
                ),
              ],
            ),
    );
  }
}
