import 'dart:convert';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';

final _log = Logger('DbRepair');

/// Scans the database for several classes of inconsistency introduced by the
/// MediaTrack architecture and repairs them in-place.
///
/// **0. Orphaned subtrees** — [MediaFolder]/[MediaItem] documents that are no
/// longer reachable from the root because an ancestor folder was deleted
/// out-of-band (Fauxton, scripts, a replication race) without cascading. These
/// strand silently: they are invisible in the tree UI (so a parent cannot
/// delete them), their items keep referencing their tracks (so pass 2 would
/// otherwise keep the audio), and their items still "exist" (so pass 4 would
/// otherwise keep their stats). This pass deletes the unreachable nodes first
/// so passes 1, 2 and 4 then reclaim the freed tracks and play-data for free.
///
/// **1. Stale media links** — [MediaItem] documents that reference a
/// [MediaTrack] doc ID in their `media` list, but the [MediaTrack] doc no
/// longer exists (e.g. deleted out-of-band, or a crash between `post` and
/// `put` during import). Those entries are removed from the media list and
/// the [MediaItem] is updated.
///
/// **2. Orphaned [MediaTrack] docs** — [MediaTrack] documents whose ID is
/// not referenced by any [MediaItem.media] list (e.g. the parent [MediaItem]
/// was deleted, or a crash occurred between creating the track and saving the
/// item). These are permanently deleted.
///
/// **3. Expired date rules** — Removes date-based visibility rules that are
/// no longer relevant (e.g., "from" dates in the past, "to" dates that have
/// already passed).
///
/// Safe to call at every login: idempotent, does nothing when already
/// consistent.
Future<void> repairDatabase(
  DartCouchDb db, {
  void Function(String task, double progress)? onProgress,
}) async {
  _log.info('Starting database consistency check...');
  
  if (onProgress != null) {
    onProgress('Checking database consistency...', 0.1);
  }

  final allDocsResult = await db.allDocs(includeDocs: true);

  final allMediaBase = <MediaBase>[]; // folders + items, for reachability
  final allMediaItems = <MediaItem>[];
  final allMediaTracks = <String, MediaTrack>{}; // doc ID → doc

  for (final row in allDocsResult.rows) {
    final doc = row.doc;
    if (doc is MediaBase) {
      allMediaBase.add(doc);
      if (doc is MediaItem) allMediaItems.add(doc);
    } else if (doc is MediaTrack) {
      allMediaTracks[doc.id!] = doc;
    }
  }

  if (onProgress != null) {
    onProgress('Analyzing media structure...', 0.2);
  }

  // --- 0. Reclaim orphaned subtrees (MediaBase nodes unreachable from root) ---
  // We delete the unreachable nodes directly (not via the MediaBase.delete
  // cascade): we already hold the full set in memory, direct removal is
  // cycle-safe, and the play-position purge is handled by pass 4 below.
  final orphans = _findOrphanedMedia(allMediaBase);
  if (orphans.isNotEmpty) {
    if (onProgress != null) {
      onProgress('Reclaiming orphaned media...', 0.3);
    }
    final orphanIds = {for (final o in orphans) o.id!};
    int reclaimed = 0;
    for (final doc in orphans) {
      _log.warning(
        'Orphaned ${doc is MediaFolder ? 'folder' : 'item'} "${doc.name}" '
        '(${doc.id}, parent: ${doc.parent}) unreachable from root — deleting.',
      );
      try {
        await db.remove(doc.id!, doc.rev!);
        reclaimed++;
      } catch (e) {
        _log.severe('Failed to delete orphaned media ${doc.id}: $e');
      }
    }
    // Drop them from the working set so the passes below see their tracks as
    // unreferenced (pass 2) and their play-data entries as invalid (pass 4).
    allMediaItems.removeWhere((i) => orphanIds.contains(i.id));
    _log.info('Reclaimed $reclaimed orphaned media node(s).');
  }

  // Collect all track IDs that are legitimately referenced.
  final referencedTrackIds = <String>{};
  for (final item in allMediaItems) {
    for (final m in item.media) {
      referencedTrackIds.add(m.attachmentId);
    }
  }

  // --- 1. Remove stale media links from MediaItems ---
  int repairedItems = 0;
  for (final item in allMediaItems) {
    final valid = item.media
        .where((m) => allMediaTracks.containsKey(m.attachmentId))
        .toList();
    final staleCount = item.media.length - valid.length;
    if (staleCount > 0) {
      _log.warning(
        'MediaItem "${item.name}" (${item.id}): removing $staleCount stale '
        'track reference(s).',
      );
      try {
        await db.put(item.copyWith(media: valid));
        repairedItems++;
      } catch (e) {
        _log.severe('Failed to repair MediaItem ${item.id}: $e');
      }
    }
  }
  
  if (onProgress != null) {
    onProgress('Removing stale media links...', 0.4);
  }

  // --- 2. Delete orphaned MediaTrack docs ---
  int deletedTracks = 0;
  for (final entry in allMediaTracks.entries) {
    if (!referencedTrackIds.contains(entry.key)) {
      _log.warning(
        'Orphaned MediaTrack ${entry.key} (parent: ${entry.value.parent}) — '
        'deleting.',
      );
      try {
        await db.remove(entry.key, entry.value.rev!);
        deletedTracks++;
      } catch (e) {
        _log.severe('Failed to delete orphaned MediaTrack ${entry.key}: $e');
      }
    }
  }
  
  if (onProgress != null) {
    onProgress('Deleting orphaned tracks...', 0.6);
  }

  if (repairedItems == 0 && deletedTracks == 0) {
    _log.info('Database is consistent — nothing to repair.');
  } else {
    _log.info(
      'Repair complete: $repairedItems item(s) updated, '
      '$deletedTracks orphaned track(s) deleted.',
    );
  }

  // --- 3. Scan tracks missing new EBU R128 loudness fields (one-shot migration) ---
  /*if (onProgress != null) {
    onProgress('Scanning for missing loudness data...', 0.7);
  }
  await scanMissingLoudnessData();*/

  // --- 4. Drop hearing-data entries for items that no longer exist ---
  if (onProgress != null) {
    onProgress('Cleaning up orphaned hearing data...', 0.7);
  }
  final validItemIds = {for (final i in allMediaItems) i.id!};
  await _cleanupOrphanedHearingData(db, validItemIds);

  // --- 5. Clean up expired date rules ---
  if (onProgress != null) {
    onProgress('Cleaning up expired date rules...', 0.85);
  }
  await _cleanupExpiredDateRules(db, onProgress: onProgress);

  if (onProgress != null) {
    onProgress('Finalizing repairs...', 1.0);
  }
}

/// Returns every [MediaBase] in [allMediaBase] that is NOT reachable from the
/// root by following `parent` links — i.e. its parent chain hits a deleted
/// ancestor or a cycle. The whole stranded subtree is returned, since every
/// descendant of an unreachable node is itself unreachable.
List<MediaBase> _findOrphanedMedia(List<MediaBase> allMediaBase) {
  final byId = {for (final m in allMediaBase) m.id!: m};
  final reachable = <String, bool>{};

  bool isReachable(MediaBase start) {
    final path = <String>{};
    MediaBase cur = start;
    late bool result;
    while (true) {
      final cid = cur.id!;
      final memoed = reachable[cid];
      if (memoed != null) {
        result = memoed; // joined a chain we already resolved
        break;
      }
      if (cur.parent == null) {
        result = true; // reached the root
        break;
      }
      if (!path.add(cid)) {
        result = false; // cid already on the path → cycle
        break;
      }
      final next = byId[cur.parent];
      if (next == null) {
        result = false; // parent points at a doc that no longer exists
        break;
      }
      cur = next;
    }
    for (final id in path) {
      reachable[id] = result;
    }
    return result;
  }

  return [
    for (final m in allMediaBase)
      if (!isReachable(m)) m,
  ];
}

/// Drops entries in every `playlog-<uuid>` and `playposition-<uuid>`
/// document whose key is not in [validItemIds].
///
/// `playlog_archive-<uuid>` is deliberately NOT swept: archive items are the
/// long-term aggregated record of past listening and carry their own `title`
/// so they remain meaningful even after the original [MediaItem] is gone.
///
/// Catches entries left behind by:
/// - items deleted before the immediate purge on `_deleteItem` existed
/// - items deleted out-of-band (Fauxton, direct CouchDB edits, scripts)
/// - races where a deletion replicated but the immediate purge didn't reach
///   that device's per-device hearing doc
///
/// Idempotent — only writes a doc back when at least one entry was removed.
Future<void> _cleanupOrphanedHearingData(
  DartCouchDb db,
  Set<String> validItemIds,
) async {
  Future<void> sweep(String prefix, _ItemMapRewriter rewrite) async {
    final result = await db.allDocs(
      startkey: jsonEncode(prefix),
      endkey: jsonEncode('$prefix￿'),
      includeDocs: true,
    );
    for (final row in result.rows) {
      final doc = row.doc;
      if (doc == null) continue;
      final rewritten = rewrite(doc, validItemIds);
      if (rewritten == null) continue;
      try {
        await db.put(rewritten);
      } catch (e) {
        _log.severe('Failed to clean orphaned hearing data in ${doc.id}: $e');
      }
    }
  }

  await sweep('playlog-', (doc, ids) {
    if (doc is! PlayLog) return null;
    final kept = {
      for (final e in doc.items.entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    if (kept.length == doc.items.length) return null;
    _log.info(
      'PlayLog ${doc.id}: dropping ${doc.items.length - kept.length} orphaned entry/ies',
    );
    return doc.copyWith(items: kept);
  });

  await sweep('playposition-', (doc, ids) {
    if (doc is! PlayPosition) return null;
    final kept = {
      for (final e in doc.items.entries)
        if (ids.contains(e.key)) e.key: e.value,
    };
    if (kept.length == doc.items.length) return null;
    _log.info(
      'PlayPosition ${doc.id}: dropping ${doc.items.length - kept.length} orphaned entry/ies',
    );
    return doc.copyWith(items: kept);
  });
}

typedef _ItemMapRewriter = CouchDocumentBase? Function(
  CouchDocumentBase doc,
  Set<String> validItemIds,
);

/// Removes date-based visibility rules that are no longer relevant.
/// This includes:
/// - "from" dates that are in the past (content is already visible)
/// - "to" dates that have already passed (content should no longer be restricted)
Future<void> _cleanupExpiredDateRules(
  DartCouchDb db, {
  void Function(String task, double progress)? onProgress,
}) async {
  _log.info('Starting cleanup of expired date rules...');

  final allDocsResult = await db.allDocs(includeDocs: true);
  int cleanedItems = 0;
  int totalItems = allDocsResult.rows.length;
  int processedItems = 0;

  for (final row in allDocsResult.rows) {
    final doc = row.doc;
    if (doc is MediaBase) {
      bool needsUpdate = false;
      String? newFromDateTime;
      String? newToDateTime;

      // Check if "from" date is in the past
      if (doc.fromDateTime != null) {
        final fromDate = DateTime.parse(doc.fromDateTime!);
        if (fromDate.isBefore(DateTime.now())) {
          _log.fine('Removing expired "from" date from ${doc.name} (${doc.id})');
          newFromDateTime = null;
          needsUpdate = true;
        }
      }

      // Check if "to" date has passed
      if (doc.toDateTime != null) {
        final toDate = DateTime.parse(doc.toDateTime!);
        if (toDate.isBefore(DateTime.now())) {
          _log.fine('Removing expired "to" date from ${doc.name} (${doc.id})');
          newToDateTime = null;
          needsUpdate = true;
        }
      }

      // Update the document if needed
      if (needsUpdate) {
        try {
          final updatedDoc = doc.copyWith(
            fromDateTime: newFromDateTime,
            toDateTime: newToDateTime,
          );
          await db.put(updatedDoc);
          cleanedItems++;
        } catch (e) {
          _log.severe('Failed to update date rules for ${doc.id}: $e');
        }
      }
    }
    
    processedItems++;
    if (onProgress != null && totalItems > 0) {
      final progress = 0.8 + (processedItems / totalItems) * 0.2; // 80-100% range
      onProgress('Cleaning up expired date rules...', progress.clamp(0.8, 1.0));
    }
  }

  if (cleanedItems == 0) {
    _log.info('No expired date rules found — nothing to clean up.');
  } else {
    _log.info('Date rule cleanup complete: $cleanedItems document(s) updated.');
  }
}
