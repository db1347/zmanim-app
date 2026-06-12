import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/navigation.dart';
import 'core/theme.dart';
import 'features/alarm/alarm_screen.dart';
import 'features/events/events_screen.dart';
import 'features/omer/omer_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/home_shell.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

/// Pushes the screen a notification payload points at.
void routeNotificationPayload(String? payload) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null || payload == null) return;
  switch (payload) {
    case 'omer':
      navigator.push(MaterialPageRoute(builder: (_) => const OmerScreen()));
    case 'alarm':
      navigator.push(MaterialPageRoute(builder: (_) => const AlarmScreen()));
    case 'events':
      navigator.push(MaterialPageRoute(builder: (_) => const EventsScreen()));
    // 'today' and anything unknown: the home shell already shows it.
  }
}

class YeadutApp extends StatefulWidget {
  const YeadutApp({super.key});

  @override
  State<YeadutApp> createState() => _YeadutAppState();
}

class _YeadutAppState extends State<YeadutApp> {
  @override
  void initState() {
    super.initState();
    // Route the notification that cold-started the app (if any) once the
    // first frame — and therefore the navigator — exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload =
          context.read<NotificationService>().consumeLaunchPayload();
      if (payload != null) routeNotificationPayload(payload);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context
        .select<SettingsService, bool>((s) => s.profile.onboardingComplete);
    final themeMode = context.select<SettingsService, ThemeMode>(
        (s) => switch (s.profile.themeMode) {
              'light' => ThemeMode.light,
              'dark' => ThemeMode.dark,
              _ => ThemeMode.system,
            });
    return MaterialApp(
      title: 'יהדות',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      // Hebrew-first: the app locale is Hebrew, which also flips the whole
      // UI to RTL via the framework.
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,
      theme: YeadutTheme.light(),
      darkTheme: YeadutTheme.dark(),
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
