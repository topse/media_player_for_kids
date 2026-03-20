import 'dart:convert';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'package:media_kit/media_kit.dart';

import 'audio_player_service.dart';
import 'db_repair.dart';
import 'login_screen.dart';
import 'my_home_page.dart';

import 'package:shared/shared.dart';

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
      // Run after migration so all docs are already in the new format.
      repairDatabase(db).ignore();
    } else {
      if (di.isRegistered<DartCouchDb>()) {
        di.unregister<DartCouchDb>();
      }
    }
    setState(() => _isLoggedIn = true);
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
      home: _isLoggedIn
          ? MyHomePage(onLogout: handleLogout)
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}
