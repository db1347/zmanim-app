import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

const String _kProfileKey = 'user_profile_v1';

/// The API key is stored under its own entry — never inside the profile
/// JSON blob — so profile serialization and logging can't leak it.
const String _kApiKeyKey = 'anthropic_api_key_v1';

/// Loads and persists the user profile. The single source of truth for
/// settings across the app; widgets listen via [ChangeNotifier].
class SettingsService extends ChangeNotifier {
  SettingsService(this._prefs, this._profile);

  final SharedPreferences _prefs;
  UserProfile _profile;

  UserProfile get profile => _profile;

  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfileKey);
    UserProfile profile = const UserProfile();
    if (raw != null) {
      try {
        profile = UserProfile.decode(raw);
      } catch (e) {
        // Log the type only — never the raw blob.
        debugPrint(
            'SettingsService: corrupt profile (${e.runtimeType}), using '
            'defaults');
      }
    }
    final apiKey = prefs.getString(_kApiKeyKey);
    if (apiKey != null && apiKey.isNotEmpty) {
      profile = profile.copyWith(anthropicApiKey: apiKey);
    }
    return SettingsService(prefs, profile);
  }

  /// Persists a new immutable profile, then notifies listeners. Persisting
  /// first keeps memory and disk consistent if storage fails.
  Future<void> update(UserProfile newProfile) async {
    final profileOk =
        await _prefs.setString(_kProfileKey, newProfile.encode());
    final keyOk =
        await _prefs.setString(_kApiKeyKey, newProfile.anthropicApiKey);
    if (!profileOk || !keyOk) {
      debugPrint('SettingsService: failed to persist settings');
      return;
    }
    _profile = newProfile;
    notifyListeners();
  }
}
