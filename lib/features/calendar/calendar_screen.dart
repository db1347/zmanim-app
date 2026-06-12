import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/calendar_service.dart';
import '../../services/fast_day_service.dart';
import '../../services/settings_service.dart';
import '../../services/zmanim_service.dart';

/// Dual Hebrew/Gregorian month view. Tap any day for its full details:
/// Hebrew date, holiday, parsha, candle lighting / havdalah, fast times.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;

  // Cell labels are recomputed only when the month or profile changes,
  // not per cell per frame.
  UserProfile? _cacheProfile;
  DateTime? _cacheMonth;
  List<String> _labels = const [];
  List<String> _hebrewNumbers = const [];
  String _hebrewMonthRange = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() => _month = DateTime(now.year, now.month));
  }

  void _refreshCells(UserProfile profile, int daysInMonth) {
    if (identical(_cacheProfile, profile) && _cacheMonth == _month) return;
    _cacheProfile = profile;
    _cacheMonth = _month;
    _labels = List.generate(
        daysInMonth,
        (i) => CalendarService.cellLabel(
            profile, DateTime(_month.year, _month.month, i + 1)));
    _hebrewNumbers = List.generate(
        daysInMonth,
        (i) => CalendarService.hebrewDayNumber(
            profile, DateTime(_month.year, _month.month, i + 1)));
    _hebrewMonthRange = _computeHebrewRange(profile, daysInMonth);
  }

  /// e.g. "סיון–תמוז תשפ״ו" (a Gregorian month spans two Hebrew months).
  String _computeHebrewRange(UserProfile profile, int daysInMonth) {
    final fmt = HebrewDateFormatter()..hebrewFormat = true;
    final first = JewishCalendar.fromDateTime(
        DateTime(_month.year, _month.month, 1))
      ..inIsrael = profile.inIsrael;
    final last = JewishCalendar.fromDateTime(
        DateTime(_month.year, _month.month, daysInMonth))
      ..inIsrael = profile.inIsrael;
    final firstMonth = fmt.formatMonth(first);
    final lastMonth = fmt.formatMonth(last);
    final year = fmt.formatHebrewNumber(last.getJewishYear() % 1000);
    return firstMonth == lastMonth
        ? '$firstMonth $year'
        : '$firstMonth–$lastMonth $year';
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsService>().profile;
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Grid starts on Sunday (rightmost column in RTL).
    final leadingBlanks = firstOfMonth.weekday % 7;
    _refreshCells(profile, daysInMonth);

    final isCurrentMonth =
        _month.year == today.year && _month.month == today.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('לוח שנה'),
        actions: [
          if (!isCurrentMonth)
            IconButton(
              tooltip: 'חזרה להיום',
              icon: const Icon(Icons.today),
              onPressed: _jumpToToday,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                    tooltip: 'חודש קודם',
                    onPressed: () => _shift(-1),
                    icon: const Icon(Icons.chevron_right)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat.yMMMM().format(_month),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _hebrewMonthRange,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: YeadutTheme.displayFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: 'חודש הבא',
                    onPressed: () => _shift(1),
                    icon: const Icon(Icons.chevron_left)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final d in const ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'])
                  Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.outline),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.62,
              ),
              itemCount: leadingBlanks + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final dayNum = index - leadingBlanks + 1;
                final date = DateTime(_month.year, _month.month, dayNum);
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final label = _labels[dayNum - 1];
                final isShabbat = date.weekday == DateTime.saturday;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showDaySheet(context, profile, date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isToday
                          ? scheme.primaryContainer
                          : isShabbat || label.isNotEmpty
                              ? scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.6)
                              : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 1.4)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text('$dayNum',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(
                          _hebrewNumbers[dayNum - 1],
                          style: TextStyle(
                              fontSize: 11, color: scheme.primary),
                        ),
                        if (label.isNotEmpty)
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 8.5, color: scheme.tertiary),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDaySheet(BuildContext context, UserProfile p, DateTime date) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DayDetailsSheet(profile: p, date: date),
    );
  }
}

/// Everything about one day: dates, holiday, parsha, candle lighting /
/// havdalah, fast times, omer, daf yomi, sunrise/sunset.
class _DayDetailsSheet extends StatelessWidget {
  const _DayDetailsSheet({required this.profile, required this.date});

  final UserProfile profile;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fmt = DateFormat.Hm();
    final info = CalendarService.dayInfo(profile, date);
    final fast = FastDayService.fastInfo(profile, date);
    final calendar = ZmanimService.calendarFor(profile, date);

    final jc = JewishCalendar.fromDateTime(date)..inIsrael = profile.inIsrael;
    final isRestricted =
        jc.getDayOfWeek() == 7 || jc.isYomTovAssurBemelacha();
    final tomorrow = JewishCalendar.fromDateTime(
        DateTime(date.year, date.month, date.day + 1))
      ..inIsrael = profile.inIsrael;
    final tomorrowRestricted =
        tomorrow.getDayOfWeek() == 7 || tomorrow.isYomTovAssurBemelacha();

    final candleLighting = !isRestricted && tomorrowRestricted
        ? calendar.getCandleLighting()
        : null;
    final havdalah = isRestricted && !tomorrowRestricted
        ? ZmanimService.tzeit(calendar, profile.tzeitShita)
        : null;

    final rows = <(IconData, String, String)>[
      (
        Icons.wb_sunny_outlined,
        'הנץ / שקיעה',
        '${_fmtOrDash(calendar.getElevationAdjustedSunrise(), fmt)} · '
            '${_fmtOrDash(calendar.getElevationAdjustedSunset(), fmt)}'
      ),
      if (candleLighting != null)
        (
          Icons.local_fire_department_outlined,
          'הדלקת נרות',
          fmt.format(candleLighting)
        ),
      if (havdalah != null)
        (Icons.auto_awesome_outlined, 'הבדלה / צאת', fmt.format(havdalah)),
      if (fast != null)
        (
          Icons.no_food_outlined,
          fast.name,
          '${_fmtOrDash(fast.start, fmt)} – ${_fmtOrDash(fast.end, fmt)}'
        ),
      if (info.omerDay > 0)
        (Icons.filter_9_plus_outlined, 'ספירת העומר', 'יום ${info.omerDay}'),
      if (info.dafYomi.isNotEmpty)
        (Icons.menu_book_outlined, 'הדף היומי', info.dafYomi),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.hebrewDate,
              style: TextStyle(
                fontFamily: YeadutTheme.displayFont,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            Text(
              DateFormat.yMMMMEEEEd().format(date),
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (info.holiday.isNotEmpty)
                  _chip(context, info.holiday, scheme.tertiary),
                if (info.isRoshChodesh)
                  _chip(context, 'ראש חודש', scheme.primary),
                if (date.weekday == DateTime.saturday)
                  _chip(context, 'פרשת ${info.parsha}', scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            for (final (icon, label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(icon, size: 19, color: scheme.outline),
                    const SizedBox(width: 10),
                    Expanded(child: Text(label)),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtOrDash(DateTime? t, DateFormat fmt) =>
      t == null ? '—' : fmt.format(t);

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
