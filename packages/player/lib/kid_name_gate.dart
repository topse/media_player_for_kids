import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

import 'kid_name_dialog.dart';

final _log = Logger('KidNameGate');

/// Gate widget that ensures a kid name is set before showing [child].
///
/// On first display after login, checks SharedPreferences for a device UUID
/// and whether a [DeviceIdentity] document exists. If the kid name is missing,
/// shows a blocking dialog.
class KidNameGate extends StatefulWidget {
  final Widget child;

  const KidNameGate({super.key, required this.child});

  @override
  State<KidNameGate> createState() => _KidNameGateState();
}

class _KidNameGateState extends State<KidNameGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureKidName();
    });
  }

  String _replState(DartCouchDb db) {
    if (db is OfflineFirstDb) {
      return db.replicationController.progress.value.state.toString();
    }
    return '(not OfflineFirstDb)';
  }

  Future<void> _ensureKidName() async {
    final prefs = di<SharedPreferencesWithCache>();
    final deviceUuid = prefs.getString('device_uuid');
    if (deviceUuid == null) {
      // No UUID yet — onLogin hasn't run. Just show child.
      _log.info('_ensureKidName: no device_uuid yet, skipping');
      setState(() => _ready = true);
      return;
    }

    final db = di<DartCouchDb>();
    _log.info(
      '_ensureKidName START — uuid=$deviceUuid replication=${_replState(db)}',
    );

    // Check if DeviceIdentity doc exists with a kid name.
    final docId = DeviceIdentity.docIdFor(deviceUuid);
    DeviceIdentity? existing;
    try {
      existing = await db.get(docId) as DeviceIdentity?;
      if (existing != null && existing.kidName.isNotEmpty) {
        _log.info('Kid name already set: "${existing.kidName}"');
        setState(() => _ready = true);
        return;
      }
      _log.info(
        'DeviceIdentity doc found but kidName empty — replication=${_replState(db)}',
      );
    } catch (e) {
      _log.info(
        'DeviceIdentity doc not found (expected for new device) — '
        'replication=${_replState(db)} error=$e',
      );
    }

    // Prompt for kid name.
    _log.info(
      'Showing kid-name dialog — replication=${_replState(db)}',
    );
    if (!mounted) return;
    final name = await showKidNameDialog(context);

    _log.info(
      'Dialog closed, name=${name == null ? "null" : '"$name"'} — '
      'replication=${_replState(db)}',
    );

    if (name != null && name.isNotEmpty) {
      final identity = DeviceIdentity(
        id: docId,
        uuid: deviceUuid,
        kidName: name,
        rev: existing?.rev,
      );

      _log.info(
        'Calling db.put(DeviceIdentity) — replication=${_replState(db)}',
      );
      try {
        final saved = await db.put(identity);
        _log.info(
          'db.put succeeded — rev=${saved.rev} replication=${_replState(db)}',
        );
        // Watch for the next replication cycle to confirm the document is
        // visible on the remote.  This fires at most once, then cancels itself.
        _watchForPush(db, docId);
      } catch (e) {
        _log.warning('Failed to persist device identity: $e');
      }
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  /// Subscribes to replication-progress changes and logs every state
  /// transition until [ReplicationState.inSync] is reached, so we can
  /// confirm in the log whether the document made it through the push cycle.
  void _watchForPush(DartCouchDb db, String docId) {
    if (db is! OfflineFirstDb) return;
    bool triggered = false;

    void onProgress() {
      if (triggered) return;
      final state = db.replicationController.progress.value.state;
      _log.info('Replication progress after put: $state');
      if (state == ReplicationState.inSync) {
        triggered = true;
        db.replicationController.progress.removeListener(onProgress);
        // Read the document back from local to confirm it still exists.
        db.get(docId).then((doc) {
          _log.info(
            'Post-inSync check — DeviceIdentity in local db: ${doc != null} '
            'rev=${doc?.rev}',
          );
        }).catchError((e) {
          _log.warning('Post-inSync get failed: $e');
        });
      }
    }

    db.replicationController.progress.addListener(onProgress);
    // Also fire immediately in case we are already inSync.
    onProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.child;
  }
}
