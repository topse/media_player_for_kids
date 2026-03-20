import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';

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
/// Safe to call at every login: idempotent, does nothing when already
/// consistent.
Future<void> repairDatabase(DartCouchDb db) async {
  _log.info('Starting database consistency check...');

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

  if (repairedItems == 0 && deletedTracks == 0) {
    _log.info('Database is consistent — nothing to repair.');
  } else {
    _log.info(
      'Repair complete: $repairedItems item(s) updated, '
      '$deletedTracks orphaned track(s) deleted.',
    );
  }
}
