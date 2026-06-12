import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/omer_service.dart';
import '../../services/omer_store.dart';
import '../../services/settings_service.dart';

/// Sefirat HaOmer: tonight's count with bracha, sefirah of the day,
/// "counted" tracking with a streak, and the missed-day halacha note.
class OmerScreen extends StatefulWidget {
  const OmerScreen({super.key});

  @override
  State<OmerScreen> createState() => _OmerScreenState();
}

class _OmerScreenState extends State<OmerScreen> {
  Set<int> _counted = {};
  int _jewishYear = 0;
  bool _loaded = false;

  /// Refreshes the screen across tzeit, so a screen left open at dusk
  /// flips to the new evening's count by itself.
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(
        const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final jc = JewishCalendar.fromDateTime(DateTime.now());
    final year = jc.getJewishYear();
    final counted = await OmerStore.loadCounted(year);
    if (!mounted) return;
    setState(() {
      _jewishYear = year;
      _counted = counted;
      _loaded = true;
    });
  }

  Future<void> _toggleCounted(int day) async {
    final next = {..._counted};
    if (!next.add(day)) next.remove(day);
    setState(() => _counted = next);
    await OmerStore.saveCounted(_jewishYear, next);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsService>().profile;
    final scheme = Theme.of(context).colorScheme;
    final count = OmerService.currentCount(profile, DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('ספירת העומר')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : count == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'אנחנו לא בימי ספירת העומר כעת.\nהספירה מתחילה '
                      'בליל ט״ז בניסן ונמשכת 49 יום עד חג השבועות.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.outline, fontSize: 15),
                    ),
                  ),
                )
              : _buildCount(context, count),
    );
  }

  Widget _buildCount(BuildContext context, OmerCount count) {
    final scheme = Theme.of(context).colorScheme;
    final day = count.day;
    final counted = _counted.contains(day);
    final missed = OmerStore.missedADay(_counted, day);
    final streak = OmerStore.streak(_counted, day);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Day hero
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  count.isEveningCount ? 'הספירה של הערב' : 'הספירה של היום',
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: YeadutTheme.displayFont,
                    fontSize: 88,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
                Text('מתוך 49',
                    style: TextStyle(fontSize: 13, color: scheme.outline)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LinearProgressIndicator(
                    value: day / 49,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (missed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'סומן שהוחסר יום שלם — לרוב הדעות ממשיכים לספור '
                  'בלי ברכה. שאלו רב לגבי המקרה שלכם.',
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSecondaryContainer),
                ),
              ),
            ),
          )
        else ...[
          Text('הברכה', style: _sectionStyle(scheme)),
          const SizedBox(height: 6),
          SelectableText(
            OmerService.bracha,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 18, height: 1.8),
          ),
          const SizedBox(height: 16),
        ],
        Text('הספירה', style: _sectionStyle(scheme)),
        const SizedBox(height: 6),
        SelectableText(
          OmerService.countText(day),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: YeadutTheme.displayFont,
            fontSize: 24,
            height: 1.7,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(
          OmerService.harachaman,
          textDirection: TextDirection.rtl,
          style: TextStyle(
              fontSize: 15, height: 1.7, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: scheme.tertiary),
            const SizedBox(width: 6),
            Text(
              'מידת היום: ${OmerService.sefirahOfDay(day)}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.tertiary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _toggleCounted(day),
          style: counted
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer)
              : null,
          icon: Icon(counted ? Icons.check_circle : Icons.check),
          label: Text(counted ? 'נספר ✓' : 'ספרתי'),
        ),
        if (streak > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '🔥 רצף של $streak ימים',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: scheme.tertiary),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'סופרים בעמידה, אחרי צאת הכוכבים. מי ששכח בלילה — סופר ביום '
          'בלי ברכה וממשיך בברכה בלילות הבאים.',
          style: TextStyle(fontSize: 12.5, color: scheme.outline),
        ),
      ],
    );
  }

  TextStyle _sectionStyle(ColorScheme scheme) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: scheme.primary,
      );
}
