import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/user_profile.dart';
import '../../services/bearing.dart';
import '../../services/settings_service.dart';

/// Prayer compass: points toward the Temple Mount, Jerusalem.
class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  bool _wasAligned = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final p = settings.profile;

    final target = p.useGreatCircleBearing
        ? greatCircleBearing(
            p.latitude, p.longitude, kJerusalemLat, kJerusalemLng)
        : rhumbLineBearing(
            p.latitude, p.longitude, kJerusalemLat, kJerusalemLng);
    final distanceKm = greatCircleDistanceKm(
        p.latitude, p.longitude, kJerusalemLat, kJerusalemLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('מצפן תפילה'),
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.tune),
            tooltip: 'שיטת חישוב הכיוון',
            onSelected: (v) =>
                settings.update(p.copyWith(useGreatCircleBearing: v)),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(
                value: true,
                checked: p.useGreatCircleBearing,
                child: const Text('קו גדול (הדרך הקצרה)'),
              ),
              CheckedPopupMenuItem(
                value: false,
                checked: !p.useGreatCircleBearing,
                child: const Text('קו ישר במפה (כיוון קבוע)'),
              ),
            ],
          ),
        ],
      ),
      body: _buildCompass(p, target, distanceKm),
    );
  }

  Widget _buildCompass(UserProfile p, double target, double distanceKm) {
    final stream = FlutterCompass.events;
    if (stream == null) return const _CompassUnavailable();
    return StreamBuilder<CompassEvent>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _CompassUnavailable();
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final heading = snapshot.data!.heading;
        if (heading == null) return const _CompassUnavailable();

        final delta = angleDelta(heading, target);
        final aligned = delta.abs() <= kCompassAlignedToleranceDeg;
        if (aligned && !_wasAligned) {
          HapticFeedback.mediumImpact();
        }
        _wasAligned = aligned;

        final accuracy = snapshot.data!.accuracy;
        final lowAccuracy = accuracy != null && accuracy > 30;

        return _CompassBody(
          heading: heading,
          target: target,
          aligned: aligned,
          lowAccuracy: lowAccuracy,
          distanceKm: distanceKm,
          locationName: p.locationName,
        );
      },
    );
  }
}

class _CompassBody extends StatelessWidget {
  const _CompassBody({
    required this.heading,
    required this.target,
    required this.aligned,
    required this.lowAccuracy,
    required this.distanceKm,
    required this.locationName,
  });

  final double heading;
  final double target;
  final bool aligned;
  final bool lowAccuracy;
  final double distanceKm;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arrowColor = aligned ? const Color(0xFFBA7517) : scheme.primary;
    // Rotate the arrow so it points at Jerusalem relative to device heading.
    final arrowAngleRad = (target - heading) * math.pi / 180.0;

    return Column(
      children: [
        if (lowAccuracy)
          MaterialBanner(
            content: const Text(
                'דיוק המצפן נמוך — הניעו את הטלפון בתנועת שמינית לכיול.'),
            leading: const Icon(Icons.explore_off),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Compass rose rotates opposite the device heading.
                    Transform.rotate(
                      angle: -heading * math.pi / 180.0,
                      child: _CompassRose(size: 280, scheme: scheme),
                    ),
                    Transform.rotate(
                      angle: arrowAngleRad,
                      child: Icon(Icons.navigation,
                          size: 110, color: arrowColor),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  aligned ? 'פונים לירושלים' : _turnHint(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: aligned ? arrowColor : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$locationName ← ירושלים · '
                  '${distanceKm.round()} ק״מ · אזימוט ${target.round()}°',
                  style: TextStyle(color: scheme.outline, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _turnHint() {
    final d = angleDelta(heading, target);
    final dir = d > 0 ? 'ימינה' : 'שמאלה';
    return 'סובבו ${d.abs().round()}° $dir';
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose({required this.size, required this.scheme});

  final double size;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (label, angle) in const [
            ('צ', 0.0),
            ('מז', 90.0),
            ('ד', 180.0),
            ('מע', 270.0)
          ])
            Transform.translate(
              offset: Offset(
                (size / 2 - 24) * math.sin(angle * math.pi / 180),
                -(size / 2 - 24) * math.cos(angle * math.pi / 180),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: label == 'צ' ? scheme.error : scheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompassUnavailable extends StatelessWidget {
  const _CompassUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'חיישן המצפן אינו זמין במכשיר זה.\n\nהאזימוט לירושלים מהמיקום '
          'השמור עדיין מוצג בתפריט ההגדרות למעלה.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      ),
    );
  }
}
