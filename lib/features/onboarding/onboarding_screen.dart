import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import 'steps.dart';

/// ≤90-second onboarding: welcome → location → gender → nusach → zmanim.
/// Every step is skippable; defaults are labeled "most common"; everything
/// is editable later in Profile.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  UserProfile _draft = const UserProfile();
  bool _locating = false;

  static const _pageCount = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final settings = context.read<SettingsService>();
    await settings.update(_draft.copyWith(
      onboardingComplete: true,
      // Smart defaults by gender — overridable in Profile › Reminders.
      tefillinReminderEnabled: _draft.gender == Gender.male,
      candleReminderEnabled: _draft.gender == Gender.female,
    ));
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    final loc = await LocationService.getCurrent();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (loc != null) {
        _draft = _draft.copyWith(
          locationName: loc.name,
          latitude: loc.latitude,
          longitude: loc.longitude,
          inIsrael: loc.inIsrael,
        );
        _next();
      }
    });
    if (loc == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('המיקום אינו זמין — בחרו עיר מהרשימה.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_page + 1) / _pageCount,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  TextButton(
                    onPressed: _page == 0 ? null : _finish,
                    child: const Text('דילוג'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  WelcomeStep(onNext: _next),
                  LocationStep(
                    locating: _locating,
                    selectedName: _draft.locationName,
                    onUseGps: _useGps,
                    onPickCity: (city) {
                      setState(() {
                        _draft = _draft.copyWith(
                          locationName: city.name,
                          latitude: city.latitude,
                          longitude: city.longitude,
                          inIsrael: city.inIsrael,
                        );
                      });
                      _next();
                    },
                  ),
                  GenderStep(
                    selected: _draft.gender,
                    onChanged: (g) =>
                        setState(() => _draft = _draft.copyWith(gender: g)),
                    onNext: _next,
                  ),
                  NusachStep(
                    selected: _draft.nusach,
                    onChanged: (n) =>
                        setState(() => _draft = _draft.copyWith(nusach: n)),
                    onNext: _next,
                  ),
                  ZmanimStep(
                    profile: _draft,
                    onChanged: (p) => setState(() => _draft = p),
                    onNext: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
