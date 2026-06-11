import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/calendar_service.dart';
import '../../services/settings_service.dart';

/// Dual Hebrew/Gregorian month view with holiday labels.
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
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

    return Scaffold(
      appBar: AppBar(title: const Text('לוח שנה')),
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
                  child: Text(
                    DateFormat.yMMMM().format(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
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

                return Container(
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
                  ),
                  child: Column(
                    children: [
                      Text('$dayNum',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                        _hebrewNumbers[dayNum - 1],
                        style:
                            TextStyle(fontSize: 11, color: scheme.primary),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
