import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/shabbat_alarm.dart';

/// Shabbat mode: a dimmed, non-interactive clock. Preset alarms fire on
/// schedule, ring for their set duration, and stop themselves — the user
/// never needs to touch the device.
class ShabbatModeScreen extends StatefulWidget {
  const ShabbatModeScreen({super.key, required this.alarms});

  final List<ShabbatAlarm> alarms;

  @override
  State<ShabbatModeScreen> createState() => _ShabbatModeScreenState();
}

class _ShabbatModeScreenState extends State<ShabbatModeScreen> {
  final AudioPlayer _player = AudioPlayer();
  late Timer _ticker;
  DateTime _now = DateTime.now();
  bool _ringing = false;
  Timer? _stopTimer;

  /// Alarms already rung, keyed by "y-m-d-hour-minute" to avoid re-firing.
  final Set<String> _fired = {};

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError(
        (Object e) => debugPrint('ShabbatMode: wakelock enable failed: $e'));
    _player.setReleaseMode(ReleaseMode.loop);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    _stopTimer?.cancel();
    _player.dispose();
    WakelockPlus.disable().catchError(
        (Object e) => debugPrint('ShabbatMode: wakelock disable failed: $e'));
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    setState(() => _now = now);
    if (_ringing) return;

    for (final alarm in widget.alarms) {
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;
      final key = '${now.year}-${now.month}-${now.day}-'
          '${alarm.hour}-${alarm.minute}';
      if (_fired.contains(key)) continue;
      _fired.add(key);
      _startRinging(alarm);
      break;
    }
  }

  Future<void> _startRinging(ShabbatAlarm alarm) async {
    setState(() => _ringing = true);
    try {
      await _player.play(AssetSource('sounds/alarm.wav'), volume: 1.0);
    } catch (e) {
      debugPrint('ShabbatMode: failed to play alarm: $e');
    }
    if (!mounted) return;
    _stopTimer = Timer(Duration(minutes: alarm.ringMinutes), () async {
      try {
        await _player.stop();
      } catch (e) {
        // Player may already be disposed if the screen was exited.
        debugPrint('ShabbatMode: alarm stop failed: $e');
      }
      if (mounted) setState(() => _ringing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _nextAlarmLabel();

    // PopScope guards against accidental swipes; exiting requires a
    // deliberate long-press (intended for after Shabbat or emergencies).
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.Hm().format(_now),
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w200,
                        color: _ringing
                            ? const Color(0xFFFAC775)
                            : Colors.white.withValues(alpha: 0.85),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'מצב שבת',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    if (upcoming != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'התראה הבאה: $upcoming',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                      ),
                    if (_ringing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'ההתראה תיכבה מעצמה',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55)),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onLongPress: () => Navigator.of(context).pop(),
                    child: Text(
                      'לחיצה ארוכה ליציאה (אחרי צאת השבת)',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _nextAlarmLabel() {
    final nowMinutes = _now.hour * 60 + _now.minute;
    ShabbatAlarm? next;
    var bestDelta = 24 * 60 + 1;
    for (final alarm in widget.alarms) {
      final alarmMinutes = alarm.hour * 60 + alarm.minute;
      final delta = alarmMinutes - nowMinutes;
      final normalized = delta == 0 ? 0 : (delta < 0 ? delta + 24 * 60 : delta);
      if (normalized < bestDelta) {
        bestDelta = normalized;
        next = alarm;
      }
    }
    return next?.label;
  }
}
