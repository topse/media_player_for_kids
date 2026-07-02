import 'dart:convert';

import 'package:path/path.dart' as p;

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:dart_couch_widgets/dart_couch_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:player/directory_view.dart';
import 'package:player/error_overlay.dart';
import 'package:player/kid_name_gate.dart';

import 'package:player/admin/admin_override_service.dart';
import 'package:player/audio_player_service.dart';
import 'package:player/hearing_stats_service.dart';
import 'package:player/play_position_service.dart';
import 'package:shared/shared.dart';
import 'package:player/audio_device_service.dart';
import 'package:player/admin/audio_device_admin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:watch_it/watch_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Surface unhandled errors on-device (logs aren't reachable on the target).
  // Must be installed before anything can throw asynchronously.
  installGlobalErrorHandlers();
  // A throw anywhere in bootstrap means runApp() is never reached and the
  // overlay has nothing to paint into -> black screen. Catch it, report it,
  // and bring up a minimal app whose only job is to render the overlay.
  try {
    await _bootstrap();
    runApp(const MainApp());
  } catch (e, st) {
    reportAppError(e, st, context: 'Bootstrap (main)');
    runApp(const _BootstrapErrorApp());
  }
}

Future<void> _bootstrap() async {
  DartCouchDb.ensureInitialized();
  await initializeDateFormatting();

  initializeMappers();

  // INFO is the normal level. Crank up to FINE/FINEST when actively debugging
  // a subsystem — but be aware that the constraint evaluator and audio
  // pipeline emit fine-level lines on hot paths, and string interpolation
  // happens regardless of level.
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (record.loggerName.startsWith('dart_couch')) {
      // Don't log dart_couch stuff, it's not in focus here. Adjust the filter as needed when debugging.
      return;
    }
    LineSplitter ls = LineSplitter();
    for (final line in ls.convert(record.message)) {
      // ignore: avoid_print
      print('${record.loggerName} ${record.level.name}: ${record.time}: $line');
    }
  });

  SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      // When an allowlist is included, any keys that aren't included cannot be used.
      allowList: <String>{
        'last_credentials',
        'admin_password',
        'audio_device_configs',
        'grid_columns_portrait',
        'grid_columns_landscape',
        'device_uuid',
        AdminOverrideService.kIgnoreConstraints,
        AdminOverrideService.kIgnoreDateSettings,
        AdminOverrideService.kGracePeriodMinutes,
        HearingStatsService.kMinPlaySeconds,
      },
    ),
  );
  di.registerSingleton<SharedPreferencesWithCache>(prefs);

  OfflineFirstServer server = OfflineFirstServer(migration: MyMigration());
  di.registerSingleton<DartCouchServer>(server);

  // AudioDeviceService must be registered before AudioPlayerService so the
  // player can attach a listener to it during init().
  di.registerSingleton<AudioDeviceService>(await AudioDeviceService.create());
  di.registerSingleton<AudioPlayerService>(await AudioPlayerService.init());
  di.registerSingleton<AdminOverrideService>(AdminOverrideService());
  di.registerSingleton<HearingStatsService>(HearingStatsService());
}

/// Global navigator observer used by routes that need to pause expensive
/// work while another page is on top of them (e.g. the directory grid stops
/// reacting to playlog ticks while the player page is presented).
final RouteObserver<ModalRoute<dynamic>> routeObserver =
    RouteObserver<ModalRoute<dynamic>>();

/// Minimal fallback app shown when [main]'s bootstrap throws before [MainApp]
/// can mount. Its only purpose is to give [GlobalErrorOverlay] somewhere to
/// paint the already-reported error instead of leaving a black screen.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          GlobalErrorOverlay(child: child ?? const SizedBox.shrink()),
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
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
      localizationsDelegates: SharedL10n.localizationsDelegates,
      supportedLocales: SharedL10n.supportedLocales,
      // Mount the global error overlay above every route (including the
      // nested MaterialApp below) so any unhandled error is painted on
      // top of a frozen/black page instead of being invisible.
      builder: (context, child) =>
          GlobalErrorOverlay(child: child ?? const SizedBox.shrink()),
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
                localizationsDelegates: SharedL10n.localizationsDelegates,
                supportedLocales: SharedL10n.supportedLocales,
                navigatorObservers: [routeObserver],
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
                    // DbStateProxyWidget swallows any exception thrown here
                    // (see _handleLogin's try/catch) and then renders the child
                    // against a half-initialised DI graph — the original black
                    // screen. Surface the error on-device before rethrowing so
                    // it becomes a visible red panel instead.
                    try {
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
                        // Central per-document store backing PlayPositionService
                        // and HearingStatsService (rev-safe, coalesced writes).
                        di.registerSingleton<DocStore>(DocStore(CouchDocDb(db)));

                        // Device identity: generate UUID on first run.
                        final prefs = di<SharedPreferencesWithCache>();
                        var deviceUuid = prefs.getString('device_uuid');
                        if (deviceUuid == null) {
                          deviceUuid = const Uuid().v4();
                          await prefs.setString('device_uuid', deviceUuid);
                        }

                        final playPos = PlayPositionService();
                        di.registerSingleton<PlayPositionService>(playPos);
                        await playPos.load(deviceUuid);

                        // Initialise hearing stats from the playlog document.
                        await di<HearingStatsService>().init(deviceUuid);
                      } else {
                        di.unregister<DartCouchDb>();
                        if (di.isRegistered<DocStore>()) {
                          di<DocStore>().dispose();
                          di.unregister<DocStore>();
                        }
                      }
                    } catch (e, st) {
                      reportAppError(e, st, context: 'Login bootstrap (onLogin)');
                      rethrow;
                    }
                  },
                  child: server is OfflineFirstServer
                      ? KidNameGate(
                          child: ReplicationStateProxyWidget(
                            server: server,
                            waitForUsersDatabase: true,
                            keepScreenOn: true,
                            child: const DirectoryView(),
                          ),
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
    final l10n = SharedL10n.of(context);
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminAccessRequired),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.adminPassword,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (!verifyPassword(value ?? '')) {
                return l10n.adminPasswordIncorrect;
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
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: Text(l10n.adminPasswordVerify),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Shows a dialog to change the admin password
  /// Returns true if password was changed, false if cancelled or failed
  static Future<bool> changePassword(BuildContext context) async {
    final l10n = SharedL10n.of(context);
    final TextEditingController currentController = TextEditingController();
    final TextEditingController newController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final prefs = di.get<SharedPreferencesWithCache>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminPasswordChangeTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminPasswordCurrent,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final currentPassword = prefs.getString('admin_password');
                  if (value != currentPassword) {
                    return l10n.adminPasswordIncorrectCurrent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminPasswordNew,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.adminPasswordPleaseEnterNew;
                  }
                  if (value.length < 4) {
                    return l10n.adminPasswordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminPasswordConfirmNew,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != newController.text) {
                    return l10n.adminPasswordsDoNotMatch;
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
            child: Text(l10n.commonCancel),
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
            child: Text(l10n.adminPasswordChange),
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
    final l10n = SharedL10n.of(context);
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminPasswordSetTitle),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.adminPasswordSetExplanation,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminPasswordPlain,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.adminPasswordPleaseEnter;
                  }
                  if (value.length < 4) {
                    return l10n.adminPasswordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.adminPasswordConfirm,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != passwordController.text) {
                    return l10n.adminPasswordsDoNotMatch;
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
            child: Text(l10n.adminPasswordSet),
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
  late int _minPlaySeconds;
  late int _gracePeriodMinutes;
  String? _appVersion;
  String? _appBuild;

  @override
  void initState() {
    super.initState();
    final prefs = di<SharedPreferencesWithCache>();
    _portraitColumns = prefs.getInt('grid_columns_portrait') ?? 2;
    _landscapeColumns = prefs.getInt('grid_columns_landscape') ?? 4;
    _minPlaySeconds =
        prefs.getInt(HearingStatsService.kMinPlaySeconds) ??
        HearingStatsService.defaultMinPlaySeconds;
    _gracePeriodMinutes =
        prefs.getInt(AdminOverrideService.kGracePeriodMinutes) ??
        AdminOverrideService.defaultGracePeriodMinutes;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = info.version;
      _appBuild = info.buildNumber;
    });
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

  Future<void> _setMinPlaySeconds(int value) async {
    setState(() => _minPlaySeconds = value);
    await di<SharedPreferencesWithCache>().setInt(
      HearingStatsService.kMinPlaySeconds,
      value,
    );
  }

  Future<void> _setGracePeriodMinutes(int value) async {
    setState(() => _gracePeriodMinutes = value);
    await di<SharedPreferencesWithCache>().setInt(
      AdminOverrideService.kGracePeriodMinutes,
      value,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharedL10n.of(context);
    final versionLabel = (_appVersion != null && _appBuild != null)
        ? l10n.adminVersion(_appVersion!, _appBuild!)
        : l10n.adminVersionLoading;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock),
            title: Text(l10n.adminPasswordChangeTitle),
            onTap: () async {
              final changed = await AdminPasswordGate.changePassword(context);
              if (changed && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.adminPasswordChangedSnack)),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.speaker_group),
            title: Text(l10n.adminAudioOutputDevices),
            subtitle: Text(l10n.adminAudioOutputDevicesSubtitle),
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
                  l10n.adminGridColumnsPortrait(_portraitColumns),
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
                  l10n.adminGridColumnsLandscape(_landscapeColumns),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.hearing, color: Colors.grey),
                const SizedBox(width: 16),
                Text(
                  l10n.adminHearingRulesSection,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l10n.adminMinPlayDurationDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _minPlaySeconds == 0
                  ? l10n.adminMinPlayDurationDisabled
                  : l10n.adminMinPlayDuration(_minPlaySeconds),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Slider(
            value: _minPlaySeconds.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            label: _minPlaySeconds == 0
                ? l10n.adminMinPlaySliderLabelOff
                : l10n.adminMinPlaySliderLabel(_minPlaySeconds),
            onChanged: (v) => _setMinPlaySeconds(v.round()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              l10n.adminGracePeriodDescription,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.adminGracePeriod(_gracePeriodMinutes),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Slider(
            value: _gracePeriodMinutes.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            label: l10n.adminGraceSliderLabel(_gracePeriodMinutes),
            onChanged: (v) => _setGracePeriodMinutes(v.round()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(versionLabel),
            dense: true,
          ),
        ],
      ),
    );
  }
}
