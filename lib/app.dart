import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/home_shell.dart';
import 'services/settings_service.dart';

class YeadutApp extends StatelessWidget {
  const YeadutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarded = context
        .select<SettingsService, bool>((s) => s.profile.onboardingComplete);
    return MaterialApp(
      title: 'יהדות',
      debugShowCheckedModeBanner: false,
      // Hebrew-first: the app locale is Hebrew, which also flips the whole
      // UI to RTL via the framework.
      locale: const Locale('he'),
      supportedLocales: const [Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: YeadutTheme.light(),
      darkTheme: YeadutTheme.dark(),
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
