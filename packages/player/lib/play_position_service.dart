import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

import 'package:dart_couch_widgets/dart_couch.dart';

/// Persists per-audiobook playback positions and "done" markers.
///
/// A thin facade over a [LiveDocHandle] for the replicated CouchDB document
/// `playposition-<deviceUuid>` (a [PlayPosition] map keyed by `itemId`). The
/// handle owns all the rev-currency, write-coalescing, own-write detection and
/// external-merge logic that this service used to hand-roll. The companion may
/// also write this document to purge entries when a media item is deleted; the
/// cell merges those external writes (rev-aware) without clobbering pending
/// local writes.
///
/// Writes are gated by the minimum-play threshold from `HearingStatsService`
/// — see player CLAUDE.md for the rules around "done" preservation and
/// in-progress upgrades. Each [savePosition] / [saveDone] expresses its write
/// as a mutation over the current document, so concurrent saves (e.g.
/// save-before-seek immediately followed by exit) coalesce into one rev-safe
/// put instead of racing on the `_rev`.
class PlayPositionService extends ChangeNotifier {
  LiveDocHandle<PlayPosition>? _handle;

  PlayPositionService();

  /// Load positions from the database and start watching for changes. Call
  /// once after the DB (and [DocStore]) are available.
  Future<void> load(String deviceUuid) async {
    final docId = PlayPosition.docIdFor(deviceUuid);
    final handle = di<DocStore>().handle<PlayPosition>(
      docId,
      emptyValue: PlayPosition(deviceId: deviceUuid, id: docId),
    );
    // Forward both optimistic and external changes to our listeners (grid,
    // player page). Deferred to post-frame so we never call setState() while
    // the widget tree is locked (e.g. during build/dispose).
    handle.state.addListener(_notifyDeferred);
    await handle.start();
    _handle = handle;
    notifyListeners();
  }

  /// Returns the saved entry for [itemId], or null.
  PlayPositionItem? getEntry(String itemId) => _handle?.current.items[itemId];

  /// Update position in memory and persist to DB (fire-and-forget).
  void savePosition(
    String itemId, {
    required String title,
    required int track,
    required int seconds,
  }) {
    _handle?.update(
      (doc) => doc.copyWith(
        items: {
          ...doc.items,
          itemId: PlayPositionItem(
            title: title,
            position: PlayPositionPoint(track: track, seconds: seconds),
          ),
        },
      ),
    );
  }

  /// Mark an audiobook as done in memory and persist to DB (fire-and-forget).
  void saveDone(String itemId, {required String title}) {
    _handle?.update(
      (doc) => doc.copyWith(
        items: {
          ...doc.items,
          itemId: PlayPositionItem(title: title, done: true),
        },
      ),
    );
  }

  /// Notify listeners after the current frame to avoid calling setState()
  /// while the widget tree is locked (e.g. during dispose/unmount).
  void _notifyDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    // The handle's lifetime is owned by [DocStore]; just detach our listener.
    _handle?.state.removeListener(_notifyDeferred);
    super.dispose();
  }
}
