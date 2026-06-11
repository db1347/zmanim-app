import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../models/zman_item.dart';
import '../../services/calendar_service.dart';
import '../../services/settings_service.dart';
import '../../services/zmanim_service.dart';
import '../calendar/calendar_screen.dart';
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
  ShabbatTimes? _shabbat;

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
    _shabbat = ZmanimService.nextShabbatOrYomTov(profile, _now);
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
          _DateHeader(info: info, now: _now, locationName: profile.locationName),
          const SizedBox(height: 12),
          NextZmanCard(next: day.nextAfter(_now), now: _now),
          const SizedBox(height: 12),
          if (shabbat != null) ...[
            ShabbatCard(times: shabbat),
            const SizedBox(height: 12),
          ],
          Card(
            child: Column(
              children: [
                for (final item in day.items)
                  ListTile(
                    dense: true,
                    title: Text(item.name),
                    trailing: Text(
                      item.time == null
                          ? '—'
                          : DateFormat.Hm().format(item.time!),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: item.time != null && item.time!.isBefore(_now)
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onTap: () => _showExplainer(context, item),
                  ),
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
  });

  final JewishDayInfo info;
  final DateTime now;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badges = <String>[
      if (info.holiday.isNotEmpty) info.holiday,
      if (info.isRoshChodesh) 'ראש חודש',
      if (info.isFastDay) 'יום תענית',
      if (info.omerDay > 0) 'יום ${info.omerDay} לעומר',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.hebrewDate,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
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
