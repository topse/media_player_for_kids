import 'dart:convert';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'package:shared/shared.dart';

import 'package:media_kit/media_kit.dart';

import 'audio_player_service.dart';
import 'db_repair.dart';
import 'login_screen.dart';
import 'my_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  DartCouchDb.ensureInitialized();

  MediaBaseMapper.ensureInitialized();
  MediaItemMapper.ensureInitialized();
  MediaFolderMapper.ensureInitialized();
  MediaTrackMapper.ensureInitialized();

  // Initialize and register audio player service
  final audioPlayer = AudioPlayerService();
  await audioPlayer.initialize();
  di.registerSingleton<AudioPlayerService>(audioPlayer);

  Logger.root.level = Level.FINEST; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    LineSplitter ls = LineSplitter();
    for (final line in ls.convert(record.message)) {
      // ignore: avoid_print
      print('${record.loggerName} ${record.level.name}: ${record.time}: $line');
    }
  });

  //OfflineFirstServer server = OfflineFirstServer(migration: MyMigration());
  HttpDartCouchServer server = HttpDartCouchServer(migration: MyMigration());
  di.registerSingleton<DartCouchServer>(server);

  SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      // When an allowlist is included, any keys that aren't included cannot be used.
      allowList: <String>{'last_credentials', 'login_profiles'},
    ),
  );
  di.registerSingleton<SharedPreferencesWithCache>(prefs);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isLoggedIn = false;
  bool _isRepairingDatabase = false;
  String _currentRepairTask = 'Starting database cleanup...';
  double _repairProgress = 0.0;
  final _log = Logger('MyApp');

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        if (di.isRegistered<AudioPlayerService>()) {
          di<AudioPlayerService>().dispose();
        }
        //if (di.isRegistered<DouchServer>()) {
        //  await di<DouchServer>().dispose();
        //}
        return .exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess() async {
    final server = di<DartCouchServer>() as HttpDartCouchServer;
    final db = await server.db(
      DartCouchDb.usernameToDbName(server.username!),
    );
    if (db != null) {
      di.registerSingleton<DartCouchDb>(db);
      
      // Show progress page while running database repair.
      // The extra frame delay lets Flutter paint the spinner before we start
      // heavy async work — without it the indicator never animates.
      setState(() => _isRepairingDatabase = true);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      try {
        await repairDatabase(db, onProgress: (task, progress) {
          _currentRepairTask = task;
          _repairProgress = progress;
          if (mounted) setState(() {});
        });
      } catch (e) {
        _log.severe('Database cleanup failed: $e');
      } finally {
        setState(() => _isRepairingDatabase = false);
        setState(() => _isLoggedIn = true);
      }
    } else {
      if (di.isRegistered<DartCouchDb>()) {
        di.unregister<DartCouchDb>();
      }
      setState(() => _isLoggedIn = true);
    }
  }

  Future<void> handleLogout() async {
    if (di.isRegistered<DartCouchDb>()) {
      di.unregister<DartCouchDb>();
    }
    final server = di<DartCouchServer>() as HttpDartCouchServer;
    await server.logout();
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Player for kids Companion',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _isRepairingDatabase
          ? _buildRepairProgressPage()
          : _isLoggedIn
              ? MyHomePage(onLogout: handleLogout)
              : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }

  Widget _buildRepairProgressPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Cleanup'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _currentRepairTask,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _repairProgress,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                _repairProgress < 1.0
                    ? '${(_repairProgress * 100).toStringAsFixed(0)}%'
                    : 'Complete',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
