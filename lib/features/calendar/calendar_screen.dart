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

/// Dual-mode month calendar:
/// - Gregorian mode: civil month grid with Hebrew dates annotated.
/// - Hebrew mode (לוח עברי): the Jewish month is the grid — Hebrew dates
///   primary, civil dates annotated.
/// Tap any day for its full details.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _hebrewMode = false;

  /// Gregorian mode: first of the displayed civil month.
  late DateTime _month;

  /// Hebrew mode: Gregorian date of the 1st of the displayed Jewish month.
  late DateTime _hebrewAnchor;

  // Cells are recomputed only when the displayed month/mode changes.
  UserProfile? _cacheProfile;
  String _cacheKey = '';
  List<String> _labels = const [];
  List<String> _hebrewNumbers = const [];
  String _titlePrimary = '';
  String _titleSecondary = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _hebrewAnchor = _firstOfJewishMonth(now);
  }

  static DateTime _firstOfJewishMonth(DateTime date) {
    final jc = JewishDate.fromDateTime(date);
    return DateTime(
        date.year, date.month, date.day - (jc.getJewishDayOfMonth() - 1));
  }

  /// First grid day + number of days for the current mode.
  (DateTime, int) _gridRange() {
    if (_hebrewMode) {
      final jc = JewishDate.fromDateTime(_hebrewAnchor);
      return (_hebrewAnchor, jc.getDaysInJewishMonth());
    }
    return (
      DateTime(_month.year, _month.month, 1),
      DateTime(_month.year, _month.month + 1, 0).day,
    );
  }

  void _shift(int delta) {
    setState(() {
      if (_hebrewMode) {
        if (delta > 0) {
          final days =
              JewishDate.fromDateTime(_hebrewAnchor).getDaysInJewishMonth();
          _hebrewAnchor = DateTime(_hebrewAnchor.year, _hebrewAnchor.month,
              _hebrewAnchor.day + days);
        } else {
          final prevLast = DateTime(
              _hebrewAnchor.year, _hebrewAnchor.month, _hebrewAnchor.day - 1);
          _hebrewAnchor = _firstOfJewishMonth(prevLast);
        }
      } else {
        _month = DateTime(_month.year, _month.month + delta);
      }
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month);
      _hebrewAnchor = _firstOfJewishMonth(now);
    });
  }

  void _refreshCells(UserProfile profile) {
    final (first, dayCount) = _gridRange();
    final key = '$_hebrewMode|$first';
    if (identical(_cacheProfile, profile) && _cacheKey == key) return;
    _cacheProfile = profile;
    _cacheKey = key;

    _labels = List.generate(
        dayCount,
        (i) => CalendarService.cellLabel(profile,
            DateTime(first.year, first.month, first.day + i)));
    _hebrewNumbers = List.generate(
        dayCount,
        (i) => CalendarService.hebrewDayNumber(profile,
            DateTime(first.year, first.month, first.day + i)));

    final fmt = HebrewDateFormatter()..hebrewFormat = true;
    final firstJc = JewishCalendar.fromDateTime(first)
      ..inIsrael = profile.inIsrael;
    final last = DateTime(first.year, first.month, first.day + dayCount - 1);
    final lastJc = JewishCalendar.fromDateTime(last)
      ..inIsrael = profile.inIsrael;

    if (_hebrewMode) {
      _titlePrimary =
          '${fmt.formatMonth(firstJc)} ${fmt.formatHebrewNumber(firstJc.getJewishYear() % 1000)}';
      final gregFirst = DateFormat.MMMM().format(first);
      final gregLast = DateFormat.MMMM().format(last);
      _titleSecondary = gregFirst == gregLast
          ? DateFormat.yMMMM().format(first)
          : '$gregFirst–${DateFormat.yMMMM().format(last)}';
    } else {
      _titlePrimary = DateFormat.yMMMM().format(_month);
      final hebFirst = fmt.formatMonth(firstJc);
      final hebLast = fmt.formatMonth(lastJc);
      final year = fmt.formatHebrewNumber(lastJc.getJewishYear() % 1000);
      _titleSecondary =
          hebFirst == hebLast ? '$hebFirst $year' : '$hebFirst–$hebLast $year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SettingsService>().profile;
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    _refreshCells(profile);
    final (first, dayCount) = _gridRange();
    final leadingBlanks = first.weekday % 7; // grid starts Sunday

    final todayDate = DateTime(today.year, today.month, today.day);
    final isCurrentMonth = !todayDate.isBefore(first) &&
        todayDate.isBefore(
            DateTime(first.year, first.month, first.day + dayCount));

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
          IconButton(
            tooltip: _hebrewMode ? 'מעבר ללוח לועזי' : 'מעבר ללוח עברי',
            icon: Icon(_hebrewMode
                ? Icons.calendar_view_month
                : Icons.synagogue_outlined),
            onPressed: () => setState(() {
              _hebrewMode = !_hebrewMode;
              // Keep the view anchored near what was on screen.
              if (_hebrewMode) {
                _hebrewAnchor = _firstOfJewishMonth(
                    isCurrentMonth ? todayDate : _month);
              } else {
                final ref = isCurrentMonth ? todayDate : _hebrewAnchor;
                _month = DateTime(ref.year, ref.month);
              }
            }),
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
                        _titlePrimary,
                        textAlign: TextAlign.center,
                        style: _hebrewMode
                            ? TextStyle(
                                fontFamily: YeadutTheme.displayFont,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                              )
                            : const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _titleSecondary,
                        textAlign: TextAlign.center,
                        style: _hebrewMode
                            ? TextStyle(
                                fontSize: 13, color: scheme.outline)
                            : TextStyle(
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
              itemCount: leadingBlanks + dayCount,
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();
                final i = index - leadingBlanks;
                final date =
                    DateTime(first.year, first.month, first.day + i);
                final isToday = date == todayDate;
                final label = _labels[i];
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
                      children: _hebrewMode
                          ? [
                              Text(_hebrewNumbers[i],
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface)),
                              Text('${date.day}',
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: scheme.primary)),
                              if (label.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 8.5,
                                        color: scheme.tertiary),
                                  ),
                                ),
                            ]
                          : [
                              Text('${date.day}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                _hebrewNumbers[i],
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
                                        fontSize: 8.5,
                                        color: scheme.tertiary),
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
/// havdalah, fast times, omer, daf yomi, molad on Rosh Chodesh.
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

    String? moladLabel;
    if (info.isRoshChodesh) {
      try {
        final molad = jc.getMoladAsDateTime();
        moladLabel = DateFormat('EEEE HH:mm').format(molad);
      } catch (_) {}
    }

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
      if (moladLabel != null)
        (Icons.brightness_3_outlined, 'המולד (משוער)', moladLabel),
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
