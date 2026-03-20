import 'dart:io';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

import 'loudness_scanner.dart';

final _log = Logger('LoudnessBatchScanner');

/// Scans all MediaItems for tracks missing EBU R128 loudness data or duration,
/// downloads the audio, analyzes it with ffmpeg, and updates the documents.
///
/// Force-rescans all tracks regardless of existing data.
Future<void> scanMissingLoudnessData() async {
  if (!di.isRegistered<DartCouchDb>()) return;
  final db = di<DartCouchDb>();

  _log.info('Starting loudness batch scan (force rescan all)...');

  final allDocsResult = await db.allDocs(includeDocs: true);

  final itemsToUpdate = <MediaItem>[];

  for (final row in allDocsResult.rows) {
    final doc = row.doc;
    if (doc is MediaItem && doc.media.isNotEmpty) {
      itemsToUpdate.add(doc);
    }
  }

  if (itemsToUpdate.isEmpty) {
    _log.info('No MediaItems with tracks found — nothing to scan.');
    return;
  }

  _log.info('${itemsToUpdate.length} MediaItem(s) to scan.');

  int scannedCount = 0;
  int failedCount = 0;

  for (final item in itemsToUpdate) {
    bool itemModified = false;
    final updatedMedia = <MediaAttachment>[];

    for (final media in item.media) {
      // Download audio to temp file for ffmpeg analysis
      try {
        final bytes = await db.getAttachment(
          media.attachmentId,
          MediaTrack.audioAttachmentName,
        );
        if (bytes == null || bytes.isEmpty) {
          _log.warning(
            'No audio data for track ${media.attachmentId} (${media.title})',
          );
          updatedMedia.add(media);
          failedCount++;
          continue;
        }

        final tempFile = await File(
          '${Directory.systemTemp.path}/loudness_scan_${media.attachmentId}',
        ).create();
        try {
          await tempFile.writeAsBytes(bytes);
          final analysis = await analyzeAudio(tempFile.path);

          if (analysis != null) {
            updatedMedia.add(
              media.copyWith(
                lufs: analysis.lufs,
                lra: analysis.lra,
                truePeak: analysis.truePeak,
                durationMs: analysis.durationMs,
              ),
            );
            itemModified = true;
            scannedCount++;
            _log.info('Scanned ${media.title}: $analysis');
          } else {
            updatedMedia.add(media);
            failedCount++;
          }
        } finally {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      } catch (e) {
        _log.warning(
          'Failed to scan track ${media.attachmentId} (${media.title}): $e',
        );
        updatedMedia.add(media);
        failedCount++;
      }
    }

    if (itemModified) {
      try {
        await db.put(item.copyWith(media: updatedMedia));
      } catch (e) {
        _log.severe('Failed to update MediaItem ${item.id}: $e');
      }
    }
  }

  _log.info(
    'Loudness batch scan complete: $scannedCount track(s) scanned, '
    '$failedCount failed.',
  );
}
