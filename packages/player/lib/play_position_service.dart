import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('PlayPositionService');

/// Persists per-audiobook playback positions and "done" markers.
///
/// Backed by a replicated CouchDB document (`playposition-<deviceUuid>`)
/// holding a [PlayPosition] map keyed by `itemId`. The companion may also
/// read this document to clean up entries when a media item is deleted.
///
/// Writes are gated by the minimum-play threshold from
/// [HearingStatsService] — see player CLAUDE.md for the rules around
/// "done" preservation and in-progress upgrades.
class PlayPositionService extends ChangeNotifier {
  String? _deviceUuid;
  PlayPosition _doc = PlayPosition(deviceId: '');

  /// Serialises all [_persist] calls to avoid CouchDB 409 conflicts when
  /// two saves race (e.g. save-before-seek immediately followed by exit).
  Future<void> _persistChain = Future.value();

  StreamSubscription<dynamic>? _docSub;

  PlayPositionService();

  /// Load positions from the database. Call once after DB is available.
  Future<void> load(String deviceUuid) async {
    _deviceUuid = deviceUuid;
    final db = di<DartCouchDb>();
    final docId = PlayPosition.docIdFor(deviceUuid);
    try {
      final loaded = await db.get(docId);
      if (loaded is PlayPosition) {
        _doc = loaded;
      } else {
        _doc = PlayPosition(deviceId: deviceUuid, id: docId);
      }
    } catch (e) {
      _log.warning('Failed to load play positions: $e');
      _doc = PlayPosition(deviceId: deviceUuid, id: docId);
    }

    // React to external writes (e.g. companion purges an entry after a
    // catalog deletion, or a sibling device updates the doc). Mirror of
    // the playlog subscription in HearingStatsService — same own-write
    // detection by comparing the incoming rev to our last persisted rev.
    await _docSub?.cancel();
    _docSub = db.useDoc(docId).listen((doc) {
      if (doc == null) {
        if (_doc.rev != null) {
          _log.info('PlayPosition deleted externally — clearing in-memory state');
          _doc = PlayPosition(deviceId: deviceUuid, id: docId);
          _notifyDeferred();
        }
      } else if (doc is PlayPosition && doc.rev != _doc.rev) {
        _log.info('PlayPosition updated externally (rev ${doc.rev}) — reloading');
        _doc = doc;
        _notifyDeferred();
      }
    });

    notifyListeners();
  }

  /// Returns the saved entry for [itemId], or null.
  PlayPositionItem? getEntry(String itemId) => _doc.items[itemId];

  /// Update position in memory and persist to DB.
  void savePosition(
    String itemId, {
    required String title,
    required int track,
    required int seconds,
  }) {
    _doc = _doc.copyWith(
      items: {
        ..._doc.items,
        itemId: PlayPositionItem(
          title: title,
          position: PlayPositionPoint(track: track, seconds: seconds),
        ),
      },
    );
    _notifyDeferred();
    _persist();
  }

  /// Mark an audiobook as done in memory and persist to DB.
  void saveDone(String itemId, {required String title}) {
    _doc = _doc.copyWith(
      items: {
        ..._doc.items,
        itemId: PlayPositionItem(title: title, done: true),
      },
    );
    _notifyDeferred();
    _persist();
  }

  /// Notify listeners after the current frame to avoid calling setState()
  /// while the widget tree is locked (e.g. during dispose/unmount).
  void _notifyDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _persist() {
    _persistChain = _persistChain.then((_) => _doPersist());
    return _persistChain;
  }

  Future<void> _doPersist() async {
    if (_deviceUuid == null) return;
    try {
      final saved = await di<DartCouchDb>().put(_doc) as PlayPosition;
      _doc = saved;
    } catch (e) {
      _log.warning('Failed to persist play positions: $e');
    }
  }

  @override
  void dispose() {
    _docSub?.cancel();
    super.dispose();
  }
}
