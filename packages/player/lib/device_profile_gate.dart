import 'dart:async';
import 'dart:convert';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:watch_it/watch_it.dart';

import 'error_overlay.dart';
import 'hearing_stats_service.dart';
import 'kid_name_dialog.dart';
import 'play_position_service.dart';

final _log = Logger('DeviceProfileGate');

/// SharedPreferences key holding the device profile UUID (the `<uuid>` in
/// `device-id-`, `playlog-`, `playlog_archive-` and `playposition-` docs).
const String kDeviceUuidPrefKey = 'device_uuid';

/// SharedPreferences key holding the profile documents that still have to
/// arrive locally after an existing profile was adopted: JSON map
/// `{docId: remoteRev}`. Absent once everything is local.
const String kProfilePendingDocsPrefKey = 'device_profile_pending_docs';

/// How often the gates re-check the server / local database while waiting.
const Duration _pollInterval = Duration(seconds: 5);

/// Whether `onLogin` may start the per-device services right away: a profile
/// is chosen and all of its documents are local.
bool deviceProfileReady() {
  final prefs = di<SharedPreferencesWithCache>();
  return prefs.getString(kDeviceUuidPrefKey) != null &&
      prefs.getString(kProfilePendingDocsPrefKey) == null;
}

/// Starts the per-device services for the profile [deviceUuid].
///
/// Called from `onLogin` when [deviceProfileReady], otherwise by
/// [ProfileSyncGate] once the profile's documents are local. Requires
/// [DartCouchDb] and `DocStore` to be registered. Idempotent.
Future<void> initDeviceServices(String deviceUuid) async {
  if (di.isRegistered<PlayPositionService>()) return;
  final playPos = PlayPositionService();
  di.registerSingleton<PlayPositionService>(playPos);
  await playPos.load(deviceUuid);

  // Initialise hearing stats from the playlog document.
  await di<HearingStatsService>().init(deviceUuid);
}

/// The server-side copy of the user database. Reading profiles from there
/// lets the parent choose right after login instead of after the (long)
/// initial replication.
Future<DartCouchDb> _remoteDb() async {
  final local = di<DartCouchDb>();
  final server = di<DartCouchServer>();
  if (server is! OfflineFirstServer) return local; // HTTP debug mode
  final remote = await server.httpServer.db(local.dbname);
  if (remote == null) throw StateError('remote db ${local.dbname} unavailable');
  return remote;
}

// ── Gate 1: choose profile ───────────────────────────────────────────────────

/// Gate that ensures the device has a profile (UUID + kid name) before
/// [child] is shown. Sits directly after login, *before* the replication
/// screen, so the parent chooses while still at the device.
///
/// - Profile already set: only a missing kid name is asked for (legacy).
/// - Fresh install: profiles are listed from the **server**. The parent may
///   reuse one (e.g. replacement for a broken phone) so play stats, audiobook
///   positions and the already-consumed listening budget carry over, or
///   create a new one. Nothing is written before that choice — no throwaway
///   profile is ever created. Reusing records the profile's documents as
///   pending; [ProfileSyncGate] waits for them.
/// - Server unreachable (only possible after an interrupted first start):
///   waits and retries every [_pollInterval].
class DeviceProfileGate extends StatefulWidget {
  final Widget child;

  const DeviceProfileGate({super.key, required this.child});

  @override
  State<DeviceProfileGate> createState() => _DeviceProfileGateState();
}

class _DeviceProfileGateState extends State<DeviceProfileGate> {
  bool _ready = false;
  bool _waitingForServer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfile());
  }

  Future<void> _ensureProfile() async {
    try {
      final deviceUuid = di<SharedPreferencesWithCache>().getString(
        kDeviceUuidPrefKey,
      );
      if (deviceUuid != null) {
        await _ensureKidName(deviceUuid);
      } else {
        await _chooseProfile();
      }
      if (mounted) setState(() => _ready = true);
    } catch (e, st) {
      // Otherwise the gate would spin forever without any visible hint.
      reportAppError(e, st, context: 'DeviceProfileGate');
    }
  }

  /// Fresh install: reuse an existing profile or create a new one.
  Future<void> _chooseProfile() async {
    final profiles = await _untilServerAnswers(
      () async => _loadProfiles(await _remoteDb()),
    );
    if (!mounted) return;
    _log.info('No device_uuid yet — ${profiles.length} profile(s) on server');

    final prefs = di<SharedPreferencesWithCache>();
    final chosen = profiles.isEmpty
        ? null
        : await _showProfileChoiceDialog(context, profiles);

    if (chosen != null) {
      final uuid = chosen.identity.uuid;
      final pending = await _untilServerAnswers(
        () async => _remoteProfileRevs(await _remoteDb(), uuid),
      );
      if (!mounted) return;
      _log.info(
        'Reusing profile $uuid ("${chosen.identity.kidName}"), '
        'waiting for ${pending.length} doc(s)',
      );
      // Pending list first: if the app dies in between, the next start must
      // not treat the adopted profile as complete.
      await prefs.setString(kProfilePendingDocsPrefKey, jsonEncode(pending));
      await prefs.setString(kDeviceUuidPrefKey, uuid);
      return;
    }

    if (!mounted) return;
    final name = await _askKidName();
    final uuid = const Uuid().v4();
    // A stale pending list can remain if an earlier "reuse" choice was cut
    // off before its UUID was stored — it must not apply to the new profile.
    await prefs.remove(kProfilePendingDocsPrefKey);
    // UUID before identity doc: if the app dies in between, the next start
    // just asks for the name again (_ensureKidName). The reverse order would
    // leave an orphaned profile that shows up in the choice and companion.
    await prefs.setString(kDeviceUuidPrefKey, uuid);
    await _putIdentity(di<DartCouchDb>(), uuid, name, rev: null);
    _log.info('Created new profile $uuid ("$name")');
  }

  /// Runs the server request [load], retrying every [_pollInterval] (with a
  /// "waiting for server" hint) until it succeeds.
  Future<T> _untilServerAnswers<T>(Future<T> Function() load) async {
    while (true) {
      try {
        final result = await load();
        if (mounted && _waitingForServer) {
          setState(() => _waitingForServer = false);
        }
        return result;
      } catch (e) {
        _log.info('Server request failed, retrying: $e');
        if (mounted && !_waitingForServer) {
          setState(() => _waitingForServer = true);
        }
        await Future<void>.delayed(_pollInterval);
      }
    }
  }

  /// Existing profile without a kid name (legacy installs): ask for it.
  Future<void> _ensureKidName(String deviceUuid) async {
    final db = di<DartCouchDb>();
    final docId = DeviceIdentity.docIdFor(deviceUuid);
    DeviceIdentity? existing;
    try {
      final doc = await db.get(docId);
      if (doc is DeviceIdentity) existing = doc;
    } catch (e) {
      _log.info('DeviceIdentity doc not readable for $deviceUuid: $e');
    }
    // An adopted profile's identity may still be on its way — it carries the
    // name, so don't ask.
    if (existing != null && existing.kidName.isNotEmpty) return;
    if (_isPending(docId)) return;
    if (!mounted) return;
    final name = await _askKidName();
    await _putIdentity(db, deviceUuid, name, rev: existing?.rev);
  }

  /// Blocks until a non-empty name was entered (the dialog is not
  /// dismissible, so this loops only defensively).
  Future<String> _askKidName() async {
    while (true) {
      final name = await showKidNameDialog(context);
      if (name != null && name.isNotEmpty) return name;
      if (!mounted) return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    final l10n = SharedL10n.of(context);
    return _WaitScaffold(
      message: _waitingForServer ? l10n.deviceProfileWaitingForServer : null,
    );
  }
}

// ── Gate 2: wait for an adopted profile's documents ─────────────────────────

/// Gate that holds the app back until an adopted profile's documents have
/// replicated to this device, then starts the per-device services.
///
/// Starting the services earlier would let them write fresh `playlog-` /
/// `playposition-` docs that later conflict with the incoming ones — the
/// conflict resolver keeps only one side, silently dropping history.
///
/// Only active while [kProfilePendingDocsPrefKey] is set, i.e. after "reuse
/// existing profile" until everything arrived. Every other start passes
/// straight through. The pending list lives in prefs, so this also survives
/// restarts and works offline. Checks every [_pollInterval]; keeps the
/// screen on while waiting.
class ProfileSyncGate extends StatefulWidget {
  final Widget child;

  const ProfileSyncGate({super.key, required this.child});

  @override
  State<ProfileSyncGate> createState() => _ProfileSyncGateState();
}

class _ProfileSyncGateState extends State<ProfileSyncGate> {
  bool _ready = false;
  int _arrived = 0;
  int _total = 0;
  bool _wakelock = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _disposed = true;
    _releaseWakelock();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      await _waitAndStart();
    } catch (e, st) {
      // Otherwise the gate would spin forever without any visible hint.
      _releaseWakelock();
      reportAppError(e, st, context: 'ProfileSyncGate');
    }
  }

  Future<void> _waitAndStart() async {
    final prefs = di<SharedPreferencesWithCache>();
    final uuid = prefs.getString(kDeviceUuidPrefKey);
    if (uuid == null) {
      // Cannot happen below DeviceProfileGate; fail open rather than hang.
      _log.warning('ProfileSyncGate without device_uuid');
      if (mounted) setState(() => _ready = true);
      return;
    }

    final pending = _pendingDocs();
    if (pending.isNotEmpty) {
      _wakelock = true;
      unawaited(WakelockPlus.enable());
      while (!_disposed) {
        final arrived = await _countArrived(pending);
        if (_disposed) return;
        setState(() {
          _arrived = arrived;
          _total = pending.length;
        });
        if (arrived == pending.length) break;
        await Future<void>.delayed(_pollInterval);
      }
      if (_disposed) return;
      _log.info('All ${pending.length} adopted profile doc(s) are local');
      await prefs.remove(kProfilePendingDocsPrefKey);
      _releaseWakelock();
    }

    await initDeviceServices(uuid);
    if (mounted) setState(() => _ready = true);
  }

  /// Number of pending docs that exist locally in at least the remote
  /// revision recorded at adoption time.
  Future<int> _countArrived(Map<String, String> pending) async {
    final db = di<DartCouchDb>();
    var arrived = 0;
    for (final MapEntry(key: docId, value: remoteRev) in pending.entries) {
      try {
        final local = await db.get(docId);
        final localRev = local?.rev;
        if (localRev != null && _revGen(localRev) >= _revGen(remoteRev)) {
          arrived++;
        }
      } catch (e) {
        _log.fine('Pending doc $docId not readable yet: $e');
      }
    }
    return arrived;
  }

  void _releaseWakelock() {
    if (!_wakelock) return;
    _wakelock = false;
    unawaited(WakelockPlus.disable());
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;
    if (_total == 0) return const _WaitScaffold();
    final l10n = SharedL10n.of(context);
    return _WaitScaffold(
      message: l10n.deviceProfileSyncing(_arrived, _total),
      progress: _arrived / _total,
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Map<String, String> _pendingDocs() {
  final raw = di<SharedPreferencesWithCache>().getString(
    kProfilePendingDocsPrefKey,
  );
  if (raw == null) return const {};
  try {
    return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
  } catch (e) {
    _log.warning('Corrupt pending-docs pref, ignoring: $e');
    return const {};
  }
}

bool _isPending(String docId) => _pendingDocs().containsKey(docId);

/// Revision generation: the `N` in `N-hash`.
int _revGen(String rev) => int.tryParse(rev.split('-').first) ?? 0;

/// `{docId: rev}` of the profile's documents that exist on the server.
Future<Map<String, String>> _remoteProfileRevs(
  DartCouchDb remote,
  String uuid,
) async {
  final ids = [
    DeviceIdentity.docIdFor(uuid),
    PlayLog.docIdFor(uuid),
    PlayLogArchive.docIdFor(uuid),
    PlayPosition.docIdFor(uuid),
  ];
  final revs = <String, String>{};
  for (final id in ids) {
    final rev = (await remote.get(id))?.rev;
    if (rev != null) revs[id] = rev;
  }
  return revs;
}

Future<void> _putIdentity(
  DartCouchDb db,
  String uuid,
  String kidName, {
  required String? rev,
}) async {
  try {
    await db.put(
      DeviceIdentity(
        id: DeviceIdentity.docIdFor(uuid),
        uuid: uuid,
        kidName: kidName,
        rev: rev,
      ),
    );
  } catch (e) {
    _log.warning('Failed to persist device identity: $e');
  }
}

class _WaitScaffold extends StatelessWidget {
  final String? message;
  final double? progress;

  const _WaitScaffold({this.message, this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile listing ──────────────────────────────────────────────────────────

class _ProfileOption {
  final DeviceIdentity identity;

  /// Most recent play event in the live playlog (last 31 days), if any.
  final DateTime? lastPlayed;

  const _ProfileOption(this.identity, this.lastPlayed);
}

/// All named profiles in [db], most recently used first.
Future<List<_ProfileOption>> _loadProfiles(DartCouchDb db) async {
  final result = await db.allDocs(
    startkey: jsonEncode('device-id-'),
    endkey: jsonEncode('device-id-\u{ffff}'),
    includeDocs: true,
  );
  final options = <_ProfileOption>[];
  for (final row in result.rows) {
    final doc = row.doc;
    if (doc is! DeviceIdentity || doc.kidName.isEmpty) continue;
    options.add(_ProfileOption(doc, await _lastPlayed(db, doc.uuid)));
  }
  options.sort((a, b) {
    final la = a.lastPlayed, lb = b.lastPlayed;
    if (la == null && lb == null) {
      return a.identity.kidName.compareTo(b.identity.kidName);
    }
    if (la == null) return 1;
    if (lb == null) return -1;
    return lb.compareTo(la);
  });
  return options;
}

Future<DateTime?> _lastPlayed(DartCouchDb db, String uuid) async {
  try {
    final doc = await db.get(PlayLog.docIdFor(uuid));
    if (doc is! PlayLog) return null;
    DateTime? latest;
    for (final item in doc.items.values) {
      for (final event in item.events) {
        final t = DateTime.tryParse(event.startedAt);
        if (t != null && (latest == null || t.isAfter(latest))) latest = t;
      }
    }
    return latest;
  } catch (_) {
    return null;
  }
}

/// Returns the chosen existing profile, or `null` for "create new profile".
Future<_ProfileOption?> _showProfileChoiceDialog(
  BuildContext context,
  List<_ProfileOption> profiles,
) {
  final l10n = SharedL10n.of(context);
  final dateFormat = DateFormat.yMd(Localizations.localeOf(context).toString());
  final theme = Theme.of(context);

  return showDialog<_ProfileOption?>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.deviceProfileTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deviceProfileIntro),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deviceProfileWarning,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final p in profiles)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(p.identity.kidName),
                  subtitle: Text(
                    p.lastPlayed == null
                        ? l10n.deviceProfileNoRecentPlays
                        : l10n.deviceProfileLastPlayed(
                            dateFormat.format(p.lastPlayed!),
                          ),
                  ),
                  onTap: () => Navigator.of(context).pop(p),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.deviceProfileCreateNew),
        ),
      ],
    ),
  );
}
