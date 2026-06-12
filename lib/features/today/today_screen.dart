import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../models/zman_item.dart';
import '../../services/calendar_service.dart';
import '../../services/fast_day_service.dart';
import '../../services/omer_service.dart';
import '../../services/reminder_rules.dart';
import '../../services/settings_service.dart';
import '../../services/zmanim_service.dart';
import '../calendar/calendar_screen.dart';
import '../omer/omer_screen.dart';
import 'widgets/next_zman_card.dart';
import 'widgets/shabbat_card.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  // Day-derived data is valid for the whole civil day — cache it so the
  // 1 Hz countdown tick doesn't recompute the zmanim engine every second.
  DateTime? _cacheDate;
  UserProfile? _cacheProfile;
  DayZmanim? _day;
  JewishDayInfo? _info;
  JewishDayInfo? _tomorrowInfo;
  ShabbatTimes? _shabbat;
  FastInfo? _fast;
  DateTime? _tzeitToday;
  bool _eruvToday = false;
  // Omer day numbers for daytime and after-tzeit, cached so the 1 Hz tick
  // never touches the zmanim engine (-1 = not during the omer).
  int _omerDayCount = -1;
  int _omerEveningCount = -1;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _refreshDayCache(UserProfile profile) {
    final today = DateTime(_now.year, _now.month, _now.day);
    if (_cacheDate == today && identical(_cacheProfile, profile)) return;
    _cacheDate = today;
    _cacheProfile = profile;
    _day = ZmanimService.dayZmanim(profile, _now);
    _info = CalendarService.dayInfo(profile, _now);
    _tomorrowInfo = CalendarService.dayInfo(
        profile, DateTime(today.year, today.month, today.day + 1));
    _shabbat = ZmanimService.nextShabbatOrYomTov(profile, _now);
    _fast = FastDayService.fastInfo(profile, _now);
    _tzeitToday = ZmanimService.tzeit(
        ZmanimService.calendarFor(profile, _now), profile.tzeitShita);
    _eruvToday =
        ReminderRules.needsEruvTavshilin(today, inIsrael: profile.inIsrael);
    _omerDayCount = (JewishCalendar.fromDateTime(today)
          ..inIsrael = profile.inIsrael)
        .getDayOfOmer();
    _omerEveningCount = (JewishCalendar.fromDateTime(
            DateTime(today.year, today.month, today.day + 1))
          ..inIsrael = profile.inIsrael)
        .getDayOfOmer();
  }

  void _copyZmanim(DayZmanim day, JewishDayInfo info, String location) {
    final fmt = DateFormat.Hm();
    final lines = [
      'זמני היום · ${info.hebrewDate} · $location',
      for (final item in day.items)
        if (item.time != null) '${item.name}: ${fmt.format(item.time!)}',
      '— יהדות',
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('זמני היום הועתקו — אפשר להדביק בכל מקום')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsService>().profile;
    _refreshDayCache(profile);
    final day = _day!;
    final info = _info!;
    final shabbat = _shabbat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('היום'),
        actions: [
          IconButton(
            tooltip: 'העתקת זמני היום',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () => _copyZmanim(day, info, profile.locationName),
          ),
          IconButton(
            tooltip: 'לוח שנה עברי',
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _DateHeader(
            info: info,
            now: _now,
            locationName: profile.locationName,
            // After tzeit the Jewish day flips — show tomorrow's date.
            nightDate: _tzeitToday != null && _now.isAfter(_tzeitToday!)
                ? _tomorrowInfo?.hebrewDate
                : null,
          ),
          const SizedBox(height: 12),
          NextZmanCard(
            next: day.nextAfter(_now),
            previous: day.previousBefore(_now),
            now: _now,
          ),
          const SizedBox(height: 12),
          if (_eruvToday) ...[
            const _EruvTavshilinBanner(),
            const SizedBox(height: 12),
          ],
          if (_fast != null) ...[
            _FastCard(fast: _fast!, now: _now),
            const SizedBox(height: 12),
          ],
          if (shabbat != null) ...[
            ShabbatCard(times: shabbat, now: _now),
            const SizedBox(height: 12),
          ],
          _OmerCard(
            count: _omerCountNow(),
          ),
          Card(
            child: Column(
              children: [
                for (final item in day.items)
                  _zmanRow(context, item, isNext: item == day.nextAfter(_now)),
              ],
            ),
          ),
          if (info.dafYomi.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'הדף היומי: ${info.dafYomi}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  /// The omer count relevant right now, from cached day numbers only.
  OmerCount? _omerCountNow() {
    final isEvening = _tzeitToday != null && _now.isAfter(_tzeitToday!);
    final day = isEvening ? _omerEveningCount : _omerDayCount;
    if (day < 1 || day > 49) return null;
    return OmerCount(day: day, isEveningCount: isEvening);
  }

  Widget _zmanRow(BuildContext context, ZmanItem item,
      {required bool isNext}) {
    final scheme = Theme.of(context).colorScheme;
    final passed = item.time != null && item.time!.isBefore(_now);

    return Container(
      decoration: isNext
          ? BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        dense: true,
        leading: isNext
            ? Icon(Icons.play_arrow_rounded, size: 18, color: scheme.primary)
            : null,
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: isNext ? FontWeight.w800 : FontWeight.w400,
            color: passed ? scheme.outline : scheme.onSurface,
          ),
        ),
        trailing: Text(
          item.time == null ? '—' : DateFormat.Hm().format(item.time!),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: passed
                ? scheme.outline
                : isNext
                    ? scheme.primary
                    : scheme.onSurface,
          ),
        ),
        onTap: () => _showExplainer(context, item),
      ),
    );
  }

  void _showExplainer(BuildContext context, ZmanItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(item.explanation, style: const TextStyle(fontSize: 15)),
            if (item.time != null) ...[
              const SizedBox(height: 12),
              Text(
                'היום: ${DateFormat.Hm().format(item.time!)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.info,
    required this.now,
    required this.locationName,
    this.nightDate,
  });

  final JewishDayInfo info;
  final DateTime now;
  final String locationName;

  /// Non-null after tzeit: the Hebrew date that began at nightfall.
  final String? nightDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badges = <String>[
      if (info.holiday.isNotEmpty) info.holiday,
      if (info.isRoshChodesh) 'ראש חודש',
      if (info.isFastDay) 'יום תענית',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nightDate ?? info.hebrewDate,
          style: TextStyle(
            fontFamily: YeadutTheme.displayFont,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: scheme.primary,
          ),
        ),
        if (nightDate != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '🌙 ירד הלילה — התאריך העברי התחלף',
              style: TextStyle(fontSize: 12, color: scheme.tertiary),
            ),
          ),
        const SizedBox(height: 2),
        Text(
          DateFormat.yMMMMEEEEd().format(now),
          style: TextStyle(fontSize: 13, color: scheme.outline),
        ),
        const SizedBox(height: 2),
        Text(
          'פרשת ${info.parsha} · $locationName',
          style: TextStyle(fontSize: 13, color: scheme.outline),
        ),
        if (badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in badges)
                  Chip(
                    label: Text(b, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fast-day card: name, when the fast began, and the countdown-relevant
/// end time per the user's tzeit shita.
class _FastCard extends StatelessWidget {
  const _FastCard({required this.fast, required this.now});

  final FastInfo fast;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat.Hm();
    final ended = fast.end != null && now.isAfter(fast.end!);

    return Card(
      color: scheme.errorContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.no_food_outlined,
                    size: 20, color: scheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fast.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: scheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ended
                  ? 'הצום הסתיים ב־${fmt.format(fast.end!)}. צום קל ומועיל!'
                  : [
                      if (fast.start != null)
                        fast.startsAtNight
                            ? 'הצום נכנס אמש ב־${fmt.format(fast.start!)}'
                            : 'תחילת הצום: ${fmt.format(fast.start!)}',
                      if (fast.end != null)
                        'סיום הצום: ${fmt.format(fast.end!)}',
                    ].join(' · '),
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'חולים, מעוברות ומניקות — שאלו רב. פיקוח נפש דוחה את הצום.',
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onErrorContainer.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eruv tavshilin banner — shown only on an erev Yom Tov that flows
/// into Shabbat.
class _EruvTavshilinBanner extends StatelessWidget {
  const _EruvTavshilinBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.egg_outlined, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'עירוב תבשילין היום! יום טוב נכנס הערב ונמשך לשבת — '
                'מניחים עירוב לפני כניסת החג כדי שמותר יהיה לבשל '
                'מהחג לשבת.',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Sefirat HaOmer entry point — only visible during the omer.
class _OmerCard extends StatelessWidget {
  const _OmerCard({required this.count});

  final OmerCount? count;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    if (count == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              '${count.day}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          title: const Text('ספירת העומר',
              style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(count.isEveningCount
              ? 'הערב סופרים יום ${count.day} — לנוסח המלא'
              : 'יום ${count.day} מתוך 49 · ${OmerService.sefirahOfDay(count.day)}'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OmerScreen()),
          ),
        ),
      ),
    );
  }
}
