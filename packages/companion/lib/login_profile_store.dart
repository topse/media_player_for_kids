import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'login_profile.dart';

class LoginProfileStore {
  static const String _key = 'login_profiles';

  List<LoginProfile> loadProfiles() {
    try {
      final json = di<SharedPreferencesWithCache>().getString(_key);
      if (json != null) {
        return LoginProfile.decode(json);
      }
    } catch (_) {}
    return [];
  }

  void saveProfiles(List<LoginProfile> profiles) {
    di<SharedPreferencesWithCache>().setString(
      _key,
      LoginProfile.encode(profiles),
    );
  }

  /// Upsert: add or overwrite by composite key (url + username).
  void addOrUpdate(LoginProfile profile) {
    final profiles = loadProfiles();
    final index = profiles.indexWhere((p) => p.key == profile.key);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    saveProfiles(profiles);
  }

  void remove(String url, String username) {
    final key = '$url\n$username';
    final profiles = loadProfiles()..removeWhere((p) => p.key == key);
    saveProfiles(profiles);
  }
}
