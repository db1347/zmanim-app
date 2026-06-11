import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/location_service.dart';

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onNext,
    this.nextLabel = 'המשך',
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 20),
          Expanded(child: child),
          if (onNext != null)
            FilledButton(onPressed: onNext, child: Text(nextLabel)),
        ],
      ),
    );
  }
}

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: 'ברוכים הבאים ליהדות',
      subtitle: 'זמני היום, לוח השנה העברי וכלים הלכתיים יומיומיים — '
          'מותאמים לקהילה ולמנהגים שלכם.',
      onNext: onNext,
      nextLabel: 'מתחילים',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'יהדות',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ההגדרה אורכת פחות מ־90 שניות.\nכל בחירה ניתנת לשינוי '
              'בהמשך בפרופיל.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationStep extends StatelessWidget {
  const LocationStep({
    super.key,
    required this.locating,
    required this.selectedName,
    required this.onUseGps,
    required this.onPickCity,
  });

  final bool locating;
  final String selectedName;
  final VoidCallback onUseGps;
  final ValueChanged<ResolvedLocation> onPickCity;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'איפה אתם?',
      subtitle: 'כל זמן הלכתי, זמני הדלקת נרות ומצפן התפילה תלויים '
          'במיקום שלכם.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: locating ? null : onUseGps,
            icon: locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(locating ? 'מאתר…' : 'השתמשו במיקום שלי'),
          ),
          const SizedBox(height: 16),
          Text('או בחרו עיר:',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final city in kCities)
                  ListTile(
                    dense: true,
                    title: Text(city.name),
                    trailing: city.name == selectedName
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => onPickCity(city),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GenderStep extends StatelessWidget {
  const GenderStep({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  final Gender selected;
  final ValueChanged<Gender> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'קצת עליכם',
      subtitle: 'משמש רק לבחירת תזכורות מתאימות מראש — תפילין לגברים, '
          'הדלקת נרות לנשים. תמיד ניתן לשינוי.',
      onNext: onNext,
      child: RadioGroup<Gender>(
        groupValue: selected,
        onChanged: (g) {
          if (g != null) onChanged(g);
        },
        child: const Column(
          children: [
            RadioListTile<Gender>(
              value: Gender.male,
              title: Text('גבר'),
            ),
            RadioListTile<Gender>(
              value: Gender.female,
              title: Text('אישה'),
            ),
            RadioListTile<Gender>(
              value: Gender.unspecified,
              title: Text('מעדיפים לא לציין'),
            ),
          ],
        ),
      ),
    );
  }
}

class NusachStep extends StatelessWidget {
  const NusachStep({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onNext,
  });

  final Nusach selected;
  final ValueChanged<Nusach> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'הנוסח שלכם',
      subtitle: 'נוסח התפילה של הקהילה שלכם. משמש לנוסחי ברכות ומנהגים.',
      onNext: onNext,
      child: RadioGroup<Nusach>(
        groupValue: selected,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        child: ListView(
          children: [
            for (final n in Nusach.values)
              RadioListTile<Nusach>(
                value: n,
                title: Text(n.label),
                subtitle:
                    n == Nusach.ashkenaz ? const Text('הנפוץ ביותר') : null,
              ),
          ],
        ),
      ),
    );
  }
}

class ZmanimStep extends StatelessWidget {
  const ZmanimStep({
    super.key,
    required this.profile,
    required this.onChanged,
    required this.onNext,
  });

  final UserProfile profile;
  final ValueChanged<UserProfile> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'שיטת חישוב הזמנים',
      subtitle: 'ההגדרות הסטנדרטיות (גר״א) מתאימות לרוב הקהילות. '
          'שיטות מתקדמות אפשר לקבוע עכשיו או בהמשך בפרופיל.',
      onNext: onNext,
      nextLabel: 'סיום',
      child: ListView(
        children: [
          SwitchListTile(
            title: const Text('אורך יום סטנדרטי (גר״א)'),
            subtitle: const Text('הנפוץ ביותר · מהנץ עד השקיעה'),
            value: profile.dayLengthShita == DayLengthShita.gra,
            onChanged: (v) => onChanged(profile.copyWith(
              dayLengthShita:
                  v ? DayLengthShita.gra : DayLengthShita.magenAvraham,
            )),
          ),
          ExpansionTile(
            title: const Text('אפשרויות מתקדמות'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ListTile(
                title: const Text('צאת השבת / צאת הכוכבים'),
                trailing: DropdownButton<TzeitShita>(
                  value: profile.tzeitShita,
                  onChanged: (v) =>
                      onChanged(profile.copyWith(tzeitShita: v)),
                  items: [
                    for (final t in TzeitShita.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                ),
              ),
              ListTile(
                title: const Text('עלות השחר'),
                trailing: DropdownButton<AlosShita>(
                  value: profile.alosShita,
                  onChanged: (v) => onChanged(profile.copyWith(alosShita: v)),
                  items: [
                    for (final a in AlosShita.values)
                      DropdownMenuItem(value: a, child: Text(a.label)),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('הדלקת נרות כמנהג ירושלים (40 דק׳)'),
                subtitle: const Text('ברירת המחדל: 18 דקות לפני השקיעה'),
                value: profile.candleLightingMinutes == 40,
                onChanged: (v) => onChanged(
                    profile.copyWith(candleLightingMinutes: v ? 40 : 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
