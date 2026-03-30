import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'loudness_batch_scanner.dart';

final _log = Logger('DbRepair');

/// Scans the database for two classes of inconsistency introduced by the
/// MediaTrack architecture and repairs them in-place.
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

  final allMediaItems = <MediaItem>[];
  final allMediaTracks = <String, MediaTrack>{}; // doc ID → doc

  for (final row in allDocsResult.rows) {
    final doc = row.doc;
    if (doc is MediaItem) {
      allMediaItems.add(doc);
    } else if (doc is MediaTrack) {
      allMediaTracks[doc.id!] = doc;
    }
  }
  
  if (onProgress != null) {
    onProgress('Analyzing media structure...', 0.2);
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

  // --- 5. Clean up expired date rules ---
  if (onProgress != null) {
    onProgress('Cleaning up expired date rules...', 0.85);
  }
  await _cleanupExpiredDateRules(db, onProgress: onProgress);

  if (onProgress != null) {
    onProgress('Finalizing repairs...', 1.0);
  }
}

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
