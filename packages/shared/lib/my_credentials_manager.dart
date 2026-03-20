import 'dart:convert';
import 'package:dart_couch/dart_couch.dart';
import 'package:dart_couch_widgets/dart_couch_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

class MyCredentialsManager extends CredentialsManagerBase {
  static const String _keyName = 'last_credentials';

  @override
  LoginCredentials? getCredentials() {
    try {
      final lastCredentials = di<SharedPreferencesWithCache>().getString(
        _keyName,
      );
      if (lastCredentials != null) {
        return LoginCredentials.fromJson(jsonDecode(lastCredentials));
      }
    } catch (_) {}
    return null;
  }

  @override
  void saveCredentials(LoginCredentials? credentials) {
    if (credentials == null) {
      di<SharedPreferencesWithCache>().remove(_keyName);
    } else {
      di<SharedPreferencesWithCache>().setString(
        _keyName,
        jsonEncode(credentials.toJson()),
      );
    }
  }
}
