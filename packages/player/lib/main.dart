import 'dart:convert';

import 'package:path/path.dart' as p;

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:dart_couch_widgets/dart_couch_widgets.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:player/directory_view.dart';

import 'package:player/audio_player_service.dart';
import 'package:player/play_position_service.dart';
import 'package:shared/shared.dart';
import 'package:player/audio_device_service.dart';
import 'package:player/admin/audio_device_admin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartCouchDb.ensureInitialized();

  MediaBaseMapper.ensureInitialized();
  MediaItemMapper.ensureInitialized();
  MediaFolderMapper.ensureInitialized();
  MediaTrackMapper.ensureInitialized();

  Logger.root.level = Level.FINEST; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    LineSplitter ls = LineSplitter();
    for (final line in ls.convert(record.message)) {
      // ignore: avoid_print
      print('${record.loggerName} ${record.level.name}: ${record.time}: $line');
    }
  });

  OfflineFirstServer server = OfflineFirstServer(migration: MyMigration());
  di.registerSingleton<DartCouchServer>(server);

  SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      // When an allowlist is included, any keys that aren't included cannot be used.
      allowList: <String>{
        'last_credentials',
        'admin_password',
        'audio_device_configs',
        'grid_columns_portrait',
        'grid_columns_landscape',
      },
    ),
  );
  di.registerSingleton<SharedPreferencesWithCache>(prefs);

  // AudioDeviceService must be registered before AudioPlayerService so the
  // player can attach a listener to it during init().
  di.registerSingleton<AudioDeviceService>(await AudioDeviceService.create());
  di.registerSingleton<AudioPlayerService>(await AudioPlayerService.init());

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final OfflineFirstServerLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = OfflineFirstServerLifecycleObserver(
      server: di<DartCouchServer>() as OfflineFirstServer,
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => AdminPasswordGate(
          child: FutureBuilder<Directory>(
            future: getApplicationSupportDirectory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final server = di<DartCouchServer>();
              final localFilePath = p.join(snapshot.data!.path, 'DartCouchDb');
              return MaterialApp(
                title: 'Media Player for kids Companion',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.deepPurple,
                  ),
                ),
                home: DbStateProxyWidget(
                  server: server,
                  localFilePath: localFilePath,
                  databaseFileNamePrefix: 'media_player_for_kids_companion',
                  credentialsManager: MyCredentialsManager(),
                  onLogin: () async {
                    final db = await server.db(
                      DartCouchDb.usernameToDbName(
                        (server is OfflineFirstServer
                            ? server.username
                            : server is HttpDartCouchServer
                            ? server.username
                            : null)!,
                      ),
                    );
                    if (db != null) {
                      di.registerSingleton<DartCouchDb>(db);
                      final playPos = PlayPositionService();
                      di.registerSingleton<PlayPositionService>(playPos);
                      await playPos.load();
                    } else {
                      di.unregister<DartCouchDb>();
                    }
                  },
                  child: server is OfflineFirstServer
                      ? ReplicationStateProxyWidget(
                          server: server,
                          waitForUsersDatabase: true,
                          keepScreenOn: true,
                          child: const DirectoryView(),
                        )
                      : const DirectoryView(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AdminPasswordGate extends StatefulWidget {
  final Widget child;

  const AdminPasswordGate({super.key, required this.child});

  @override
  State<AdminPasswordGate> createState() => _AdminPasswordGateState();

  /// Verifies if the provided password matches the stored admin password
  static bool verifyPassword(String password) {
    final prefs = di.get<SharedPreferencesWithCache>();
    final storedPassword = prefs.getString('admin_password');
    return storedPassword == password;
  }

  /// Shows a dialog to verify admin password
  /// Returns true if password is correct, false if cancelled or incorrect
  static Future<bool> requestPasswordVerification(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access Required'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Admin Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!verifyPassword(value ?? '')) {
                return 'Incorrect password';
              }
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Shows a dialog to change the admin password
  /// Returns true if password was changed, false if cancelled or failed
  static Future<bool> changePassword(BuildContext context) async {
    final TextEditingController currentController = TextEditingController();
    final TextEditingController newController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final prefs = di.get<SharedPreferencesWithCache>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final currentPassword = prefs.getString('admin_password');
                  if (value != currentPassword) {
                    return 'Incorrect current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != newController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await prefs.setString('admin_password', newController.text);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

class _AdminPasswordGateState extends State<AdminPasswordGate> {
  bool _isPasswordSet = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminPassword();
  }

  Future<void> _checkAdminPassword() async {
    final prefs = di.get<SharedPreferencesWithCache>();
    final password = prefs.getString('admin_password');

    setState(() {
      _isPasswordSet = password != null && password.isNotEmpty;
      _isChecking = false;
    });

    if (!_isPasswordSet) {
      // Show the dialog after the first frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetPasswordDialog();
      });
    }
  }

  Future<void> _showSetPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set Admin Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please set an admin password for first-time setup.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _savePassword(passwordController.text);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Set Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePassword(String password) async {
    final prefs = di.get<SharedPreferencesWithCache>();
    await prefs.setString('admin_password', password);

    setState(() {
      _isPasswordSet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPasswordSet) {
      // Show a placeholder while the dialog is being shown
      return const Center(child: CircularProgressIndicator());
    }

    return widget.child;
  }
}

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late int _portraitColumns;
  late int _landscapeColumns;

  @override
  void initState() {
    super.initState();
    final prefs = di<SharedPreferencesWithCache>();
    _portraitColumns = prefs.getInt('grid_columns_portrait') ?? 2;
    _landscapeColumns = prefs.getInt('grid_columns_landscape') ?? 4;
  }

  Future<void> _setPortraitColumns(int value) async {
    setState(() => _portraitColumns = value);
    await di<SharedPreferencesWithCache>().setInt(
      'grid_columns_portrait',
      value,
    );
  }

  Future<void> _setLandscapeColumns(int value) async {
    setState(() => _landscapeColumns = value);
    await di<SharedPreferencesWithCache>().setInt(
      'grid_columns_landscape',
      value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Admin Password'),
            onTap: () async {
              final changed = await AdminPasswordGate.changePassword(context);
              if (changed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully'),
                  ),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.speaker_group),
            title: const Text('Audio Output Devices'),
            subtitle: const Text('Set volume limits per output device'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AudioDeviceAdminPage(),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: Colors.grey),
                const SizedBox(width: 16),
                Text(
                  'Grid Columns (Portrait): $_portraitColumns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Slider(
            value: _portraitColumns.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            label: '$_portraitColumns',
            onChanged: (v) => _setPortraitColumns(v.round()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.grid_view, color: Colors.grey),
                const SizedBox(width: 16),
                Text(
                  'Grid Columns (Landscape): $_landscapeColumns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Slider(
            value: _landscapeColumns.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            label: '$_landscapeColumns',
            onChanged: (v) => _setLandscapeColumns(v.round()),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
