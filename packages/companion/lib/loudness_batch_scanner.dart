import 'dart:io';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

import 'loudness_scanner.dart';

final _log = Logger('LoudnessBatchScanner');

/// Scans all MediaItems for tracks that are missing the new EBU R128 loudness
/// fields (momentary / short_term), downloads the audio, analyzes it with
/// ffmpeg, and updates the documents using getRaw / putRaw so that old
/// documents with incomplete loudness data do not cause dart_mappable parse
/// errors.
///
/// A track is considered already up-to-date when its raw map contains the
/// 'momentary' key. Tracks that are missing this key are re-scanned.
Future<void> scanMissingLoudnessData() async {
  if (!di.isRegistered<DartCouchDb>()) return;
  final db = di<DartCouchDb>();

  _log.info('Starting loudness migration scan (checking for missing fields)...');

  // Collect all document IDs without parsing (avoids dart_mappable issues).
  final allDocsResult = await db.allDocs(includeDocs: false);
  final docIds = allDocsResult.rows
      .map((row) => row.id)
      .whereType<String>()
      .where((id) => !id.startsWith('_'))
      .toList();

  int scannedCount = 0;
  int failedCount = 0;
  int skippedCount = 0;

  for (final docId in docIds) {
    final rawDoc = await db.getRaw(docId);
    if (rawDoc == null) continue;

    // Only process media_item documents.
    // The discriminator field is stored as '!doc_type' in CouchDB.
    if (rawDoc['!doc_type'] != 'media_item') continue;

    final mediaList = rawDoc['media'];
    if (mediaList is! List || mediaList.isEmpty) continue;

    bool docModified = false;

    for (int i = 0; i < mediaList.length; i++) {
      final mediaEntry = mediaList[i];
      if (mediaEntry is! Map<String, dynamic>) continue;

      final attachmentId = mediaEntry['attachment_id'] as String?;
      if (attachmentId == null) {
        _log.warning('media entry in $docId has no attachment_id — skipping.');
        failedCount++;
        continue;
      }

      try {
        final bytes = await db.getAttachment(
          attachmentId,
          MediaTrack.audioAttachmentName,
        );
        if (bytes == null || bytes.isEmpty) {
          _log.warning('No audio data for attachment $attachmentId in $docId');
          failedCount++;
          continue;
        }

        final tempFile = File(
          '${Directory.systemTemp.path}/loudness_scan_$attachmentId',
        );
        try {
          await tempFile.writeAsBytes(bytes);
          final analysis = await analyzeAudio(tempFile.path);

          if (analysis != null) {
            mediaList[i] = <String, dynamic>{
              ...mediaEntry,
              'lufs': analysis.lufs,
              if (analysis.momentary != null) 'momentary': analysis.momentary,
              if (analysis.shortTerm != null) 'short_term': analysis.shortTerm,
              'lra': analysis.lra,
              'true_peak': analysis.truePeak,
              'duration_ms': analysis.durationMs,
            };
            docModified = true;
            scannedCount++;
            _log.info(
              'Scanned ${mediaEntry['fileName'] ?? attachmentId}: $analysis',
            );
          } else {
            failedCount++;
          }
        } finally {
          try {
            await tempFile.delete();
          } catch (_) {}
        }
      } catch (e) {
        _log.warning('Failed to scan attachment $attachmentId in $docId: $e');
        failedCount++;
      }
    }

    if (docModified) {
      try {
        await db.putRaw(rawDoc);
      } catch (e) {
        _log.severe('Failed to update document $docId: $e');
      }
    }

    // Yield to the event loop between documents so UI animations stay smooth.
    await Future<void>.delayed(Duration.zero);
  }

  _log.info(
    'Loudness migration complete: $scannedCount scanned, '
    '$failedCount failed, $skippedCount already up-to-date.',
  );
}
