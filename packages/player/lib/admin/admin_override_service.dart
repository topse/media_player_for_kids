import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

/// Lightweight ChangeNotifier that persists two emergency override flags in
/// SharedPreferences. Read throughout the player where visibility and
/// constraint decisions are made.
///
/// Both overrides are accessible only through the password-protected admin
/// area (FR-21, FR-22). A persistent warning banner is shown while either
/// override is active (FR-23).
class AdminOverrideService extends ChangeNotifier {
  static const String kIgnoreConstraints = 'override_ignore_constraints';
  static const String kIgnoreDateSettings = 'override_ignore_date_settings';

  /// Grace period: if the remaining item duration is at or below this value
  /// when the allowance expires, playback is allowed to finish naturally.
  /// 0 = disabled (strict enforcement). Must appear in the SharedPreferences
  /// allowList in main.dart.
  static const String kGracePeriodMinutes = 'grace_period_minutes';
  static const int defaultGracePeriodMinutes = 5;

  bool get ignoreConstraints =>
      di<SharedPreferencesWithCache>().getBool(kIgnoreConstraints) ?? false;

  bool get ignoreDateSettings =>
      di<SharedPreferencesWithCache>().getBool(kIgnoreDateSettings) ?? false;

  Future<void> setIgnoreConstraints(bool value) async {
    await di<SharedPreferencesWithCache>().setBool(kIgnoreConstraints, value);
    notifyListeners();
  }

  Future<void> setIgnoreDateSettings(bool value) async {
    await di<SharedPreferencesWithCache>().setBool(kIgnoreDateSettings, value);
    notifyListeners();
  }

  bool get anyOverrideActive => ignoreConstraints || ignoreDateSettings;
}
