import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:metatagger/metatagger.dart';
import 'package:watch_it/watch_it.dart';

import 'package:shared/shared.dart';

import 'loudness_scanner.dart';

final Logger _log = Logger("audio_import_util");

class ImportProgress {
  final int completedFiles;
  final int totalFiles;
  final int importedFiles;
  final String message;

  const ImportProgress({
    required this.completedFiles,
    required this.totalFiles,
    required this.importedFiles,
    required this.message,
  });

  double get fraction {
    if (totalFiles == 0) return 0;
    return completedFiles / totalFiles;
  }
}

/// Manages a shared import progress dialog across multiple
/// [importAudioFilesToDocument] calls.
class ImportProgressDialog {
  final BuildContext context;
  final int totalFiles;
  int _completedFiles = 0;
  int _importedFiles = 0;
  late final ValueNotifier<ImportProgress> _notifier;
  bool _isShowing = false;

  ImportProgressDialog({required this.context, required this.totalFiles}) {
    _notifier = ValueNotifier<ImportProgress>(
      ImportProgress(
        completedFiles: 0,
        totalFiles: totalFiles,
        importedFiles: 0,
        message: 'Preparing import...',
      ),
    );
  }

  void show() {
    if (_isShowing || !context.mounted) return;
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Importing files'),
        content: ValueListenableBuilder<ImportProgress>(
          valueListenable: _notifier,
          builder: (context, progress, child) {
            final percent = (progress.fraction * 100).toStringAsFixed(0);
            return SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processed ${progress.completedFiles}/${progress.totalFiles} files',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress.fraction),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('$percent%'),
                  ),
                  const SizedBox(height: 8),
                  Text('Imported ${progress.importedFiles} file(s)'),
                  const SizedBox(height: 8),
                  Text(progress.message),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void update(String message) {
    _notifier.value = ImportProgress(
      completedFiles: _completedFiles,
      totalFiles: totalFiles,
      importedFiles: _importedFiles,
      message: message,
    );
  }

  void fileCompleted() => _completedFiles++;
  void fileImported() => _importedFiles++;

  void close() {
    _notifier.dispose();
    if (_isShowing && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Supported audio/video file extensions for import.
const audioExtensions = {'mp3', 'ogg', 'wav', 'm4a', 'mp4', 'flac'};

/// Maps a file path extension to a MIME type string.
/// Returns 'application/octet-stream' for unknown extensions.
String getContentTypeFromExtension(String path) {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'flac':
      return 'audio/flac';
    case 'aac':
      return 'audio/aac';
    case 'm4a':
      return 'audio/mp4';
    case 'ogg':
      return 'audio/ogg';
    case 'mp4':
      return 'video/mp4';
    default:
      return 'application/octet-stream';
  }
}

/// Imports audio/video files from a drop event as attachments to an existing
/// document.
///
/// If [progress] is provided, uses that shared progress dialog instead of
/// creating its own. This allows a single progress dialog to track multiple
/// calls (e.g. when importing each file as a separate MediaItem).
///
/// Returns `({List<MediaAttachment> attachments, String finalRev})` where:
/// - `attachments`: successfully imported attachments (may be empty)
/// - `finalRev`: the document revision after all saveAttachment calls
///
/// Returns `null` if [context] is no longer mounted before the dialog is shown.
///
/// **The caller is responsible for the final [DartCouchDb.put] call** to update the
/// document's media list (and optionally its name).
///
/// When using a shared [progress], the caller is also responsible for calling
/// [ImportProgressDialog.show] before and [ImportProgressDialog.close] after
/// all imports are done.
Future<({List<MediaAttachment> attachments, String finalRev})?>
importAudioFilesToDocument({
  required BuildContext context,
  required List<XFile> files,
  required String docId,
  required String docRev,
  ImportProgressDialog? progress,
}) async {
  if (!context.mounted) return null;
  final newMediaAttachments = <MediaAttachment>[];

  // If no shared progress dialog, create a local one for this call.
  final localProgress = progress == null;
  final prog = progress ??
      ImportProgressDialog(context: context, totalFiles: files.length);
  if (localProgress) prog.show();

  for (final file in files) {
    final path = file.path;
    final contentType = getContentTypeFromExtension(path);
    final filename = path.split(RegExp(r'[/\\]')).last;

    _log.info("$filename has ContentType $contentType");

    try {
      prog.update('Importing file\n$filename');

      if (!contentType.startsWith('audio/') &&
          !contentType.startsWith('video/')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unsupported file type: $filename')),
          );
        }
        prog.update('Skipped unsupported file\n$filename');
        continue;
      }

      Uint8List? bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        if (file.path.isNotEmpty) {
          final f = File(file.path);
          if (await f.exists()) bytes = await f.readAsBytes();
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        // Create a MediaTrack document to hold this audio file and its cover.
        // attachmentId in MediaAttachment now equals the MediaTrack doc ID.
        final trackDoc = MediaTrack(parent: docId, contentType: contentType);
        final postedTrack = await di<DartCouchDb>().post(trackDoc);
        final trackId = postedTrack.id!;
        String trackRev = postedTrack.rev!;

        // Save the audio bytes as the fixed-name 'audio' attachment.
        trackRev = await di<DartCouchDb>().saveAttachment(
          trackId,
          trackRev,
          MediaTrack.audioAttachmentName,
          bytes,
          contentType: contentType,
        );

        String? title;
        String? artist;
        String? album;
        int? track;
        int? trackTotal;
        int? disc;
        int? discTotal;

        if (contentType.startsWith('audio/')) {
          try {
            final tagger = MetaTagger();
            final tags = await tagger.readCommonTags(path);

            title = tags[CommonTags.title];
            artist = tags[CommonTags.artist];
            album = tags[CommonTags.album];

            final trackStr = tags[CommonTags.track];
            if (trackStr != null) track = int.tryParse(trackStr);
            final trackTotalStr = tags[CommonTags.trackTotal];
            if (trackTotalStr != null) trackTotal = int.tryParse(trackTotalStr);

            final discStr = tags[CommonTags.disc];
            if (discStr != null) disc = int.tryParse(discStr);
            final discTotalStr = tags[CommonTags.discTotal];
            if (discTotalStr != null) discTotal = int.tryParse(discTotalStr);

            try {
              final artTag = await tagger.readTag(path, CommonTags.albumArt);
              if (artTag != null && artTag.type == TagType.binary) {
                final artwork = artTag.value as Uint8List;
                if (artwork.isNotEmpty) {
                  trackRev = await di<DartCouchDb>().saveAttachment(
                    trackId,
                    trackRev,
                    MediaTrack.coverAttachmentName,
                    artwork,
                    contentType: 'image/jpeg',
                  );
                }
              }
            } catch (e) {
              debugPrint('Error extracting album art: $e');
            }
          } catch (e) {
            debugPrint('Error extracting metadata: $e');
          }
        }

        // Measure EBU R128 loudness and duration
        prog.update('Analyzing loudness\n$filename');
        double? lufs;
        double? lra;
        double? truePeak;
        int? durationMs;
        try {
          final analysis = await analyzeAudio(path);
          if (analysis != null) {
            lufs = analysis.lufs;
            lra = analysis.lra;
            truePeak = analysis.truePeak;
            durationMs = analysis.durationMs;
            _log.info('$filename: $analysis');
          }
        } catch (e) {
          _log.warning('Failed to analyze loudness for $filename: $e');
        }

        newMediaAttachments.add(
          MediaAttachment(
            fileName: filename,
            title: title,
            artist: artist,
            album: album,
            track: track,
            trackTotal: trackTotal,
            disc: disc,
            discTotal: discTotal,
            attachmentId: trackId,
            lufs: lufs,
            lra: lra,
            truePeak: truePeak,
            durationMs: durationMs,
          ),
        );
        prog.fileImported();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding file: $e')));
      }
    } finally {
      prog.fileCompleted();
      prog.update('Finished file\n$filename');
    }
  }

  if (localProgress) {
    prog.update('Finalizing import...');
    prog.close();
  }

  return (attachments: newMediaAttachments, finalRev: docRev);
}
