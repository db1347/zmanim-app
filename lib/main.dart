import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'he';
  await initializeDateFormatting('he');

  final settings = await SettingsService.load();
  final notifications = NotificationService();
  await notifications.init();
  notifications.onNotificationTap = routeNotificationPayload;
  // Top up the rolling reminder + Shabbat-alarm window on every launch.
  await notifications.rescheduleAll(settings.profile);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings),
        Provider<NotificationService>.value(value: notifications),
      ],
      child: const YeadutApp(),
    ),
  );
}
