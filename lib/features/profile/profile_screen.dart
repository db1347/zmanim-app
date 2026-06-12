import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/settings_service.dart';
import 'widgets/ai_settings_tile.dart';
import 'widgets/reminders_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final notifications = context.read<NotificationService>();
    final p = settings.profile;

    Future<void> update(UserProfile next) async {
      await settings.update(next);
      await notifications.rescheduleAll(next);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('פרופיל')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionHeader('מיקום'),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(p.locationName),
            subtitle: Text(
                '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}'
                '${p.inIsrael ? " · מצב ארץ ישראל" : ""}'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _pickLocation(context, p, update),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.flag_outlined),
            title: const Text('מצב ארץ ישראל'),
            subtitle: const Text('יום טוב אחד, קריאת התורה כמנהג הארץ'),
            value: p.inIsrael,
            onChanged: (v) => update(p.copyWith(inIsrael: v)),
          ),
          const Divider(),
          const _SectionHeader('קהילה ומנהג'),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('נוסח'),
            trailing: DropdownButton<Nusach>(
              value: p.nusach,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(nusach: v)),
              items: [
                for (final n in Nusach.values)
                  DropdownMenuItem(value: n, child: Text(n.label)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('מגדר'),
            trailing: DropdownButton<Gender>(
              value: p.gender,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(gender: v)),
              items: const [
                DropdownMenuItem(value: Gender.male, child: Text('גבר')),
                DropdownMenuItem(value: Gender.female, child: Text('אישה')),
                DropdownMenuItem(
                    value: Gender.unspecified, child: Text('לא צוין')),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('חישוב זמנים'),
          ListTile(
            leading: const Icon(Icons.timelapse),
            title: const Text('אורך היום ההלכתי'),
            trailing: DropdownButton<DayLengthShita>(
              value: p.dayLengthShita,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(dayLengthShita: v)),
              items: const [
                DropdownMenuItem(
                    value: DayLengthShita.gra, child: Text('גר״א')),
                DropdownMenuItem(
                    value: DayLengthShita.magenAvraham,
                    child: Text('מגן אברהם')),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_twilight),
            title: const Text('עלות השחר'),
            trailing: DropdownButton<AlosShita>(
              value: p.alosShita,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(alosShita: v)),
              items: [
                for (final a in AlosShita.values)
                  DropdownMenuItem(value: a, child: Text(a.label)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.nights_stay_outlined),
            title: const Text('צאת הכוכבים / צאת השבת'),
            trailing: DropdownButton<TzeitShita>(
              value: p.tzeitShita,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(tzeitShita: v)),
              items: [
                for (final t in TzeitShita.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.candlestick_chart_outlined),
            title: const Text('הדלקת נרות כמנהג ירושלים (40 דק׳)'),
            value: p.candleLightingMinutes == 40,
            onChanged: (v) =>
                update(p.copyWith(candleLightingMinutes: v ? 40 : 18)),
          ),
          const Divider(),
          const _SectionHeader('תצוגה'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('מצב תצוגה'),
            trailing: DropdownButton<String>(
              value: p.themeMode,
              underline: const SizedBox.shrink(),
              onChanged: (v) => update(p.copyWith(themeMode: v)),
              items: const [
                DropdownMenuItem(value: 'system', child: Text('לפי המערכת')),
                DropdownMenuItem(value: 'light', child: Text('בהיר')),
                DropdownMenuItem(value: 'dark', child: Text('כהה')),
              ],
            ),
          ),
          const Divider(),
          RemindersSection(profile: p, onUpdate: update),
          const Divider(),
          const _SectionHeader('בינה מלאכותית'),
          AiSettingsTile(profile: p, onUpdate: update),
          const Divider(),
          const _SectionHeader('אודות'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('יהדות'),
            subtitle: Text(
              'הזמנים מחושבים במכשיר באמצעות מנוע kosher_dart (גרסת '
              'KosherJava). תשובות הבינה המלאכותית הן לימודיות בלבד ואינן '
              'פסק הלכה — לפסיקה מעשית פנו לרב.',
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text('גרסה'),
              trailing: Text(
                snapshot.hasData
                    ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                    : '…',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLocation(
    BuildContext context,
    UserProfile p,
    Future<void> Function(UserProfile) update,
  ) async {
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.75,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('השתמשו במיקום שלי'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final loc = await LocationService.getCurrent();
                  if (loc == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'המיקום אינו זמין — בדקו את ההרשאות.')));
                    }
                    return;
                  }
                  await update(p.copyWith(
                    locationName: loc.name,
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    inIsrael: loc.inIsrael,
                  ));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setSheetState(() => query = v),
                  decoration: InputDecoration(
                    hintText: 'חיפוש עיר…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              for (final city in filterCities(query))
                ListTile(
                  title: Text(city.name),
                  trailing: city.name == p.locationName
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await update(p.copyWith(
                      locationName: city.name,
                      latitude: city.latitude,
                      longitude: city.longitude,
                      inIsrael: city.inIsrael,
                    ));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
