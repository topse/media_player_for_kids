import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:watch_it/watch_it.dart';

import 'package:shared/shared.dart';

final Logger _log = Logger("AudioPlayerService");

/// Service for managing audio playback.
///
/// Uses [media_kit] (libmpv) which supports M4A/AAC, MP3, WAV, FLAC, OGG,
/// and virtually every other audio format on Windows with no NuGet dependency.
class AudioPlayerService {
  final _player = Player();

  File? _tempFile;

  MediaItem? _currentItem;
  MediaAttachment? _currentAttachment;

  final _playingNotifier = ValueNotifier<bool>(false);
  final _currentPositionNotifier = ValueNotifier<Duration>(Duration.zero);
  final _durationNotifier = ValueNotifier<Duration>(Duration.zero);
  final _currentTrackNotifier = ValueNotifier<String?>(null);

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _completeSubscription;

  ValueListenable<bool> get isPlaying => _playingNotifier;
  ValueListenable<Duration> get currentPosition => _currentPositionNotifier;
  ValueListenable<Duration> get duration => _durationNotifier;
  ValueListenable<String?> get currentTrackName => _currentTrackNotifier;

  MediaItem? get currentItem => _currentItem;
  MediaAttachment? get currentAttachment => _currentAttachment;

  Future<void> initialize() async {
    _playingSubscription = _player.stream.playing.listen((playing) {
      _playingNotifier.value = playing;
    });

    _positionSubscription = _player.stream.position.listen((pos) {
      _currentPositionNotifier.value = pos;
    });

    _durationSubscription = _player.stream.duration.listen((dur) {
      _durationNotifier.value = dur;
    });

    _completeSubscription = _player.stream.completed.listen((completed) {
      if (completed) {
        _clearCurrentTrackState();
        _deleteTempFile();
      }
    });
  }

  Future<void> play(MediaItem item, MediaAttachment attachment) async {
    await stop();

    _currentItem = item;
    _currentAttachment = attachment;
    _currentTrackNotifier.value = attachment.title;

    try {
      final db = di<DartCouchDb>();
      final attachmentData = await db.getAttachment(
        attachment.attachmentId,
        MediaTrack.audioAttachmentName,
      );

      if (attachmentData == null) {
        throw Exception('Attachment not found');
      }

      // Write to a temp file with the correct extension so libmpv picks the
      // right demuxer (critical for M4A/AAC).
      final ext = attachment.fileName.split('.').last.toLowerCase();
      final tmpDir = await getTemporaryDirectory();
      final tmpFile = File('${tmpDir.path}/mkp_playback.$ext');
      await tmpFile.writeAsBytes(attachmentData, flush: true);
      _tempFile = tmpFile;

      _log.fine(
        'Playing ${attachment.fileName} (${attachmentData.length} bytes) '
        'from temp file: ${tmpFile.path}',
      );

      await _player.open(Media(tmpFile.uri.toString()));
    } catch (e) {
      _log.warning('Error playing audio: $e');
      _currentItem = null;
      _currentAttachment = null;
      _currentTrackNotifier.value = null;
      rethrow;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _clearCurrentTrackState();
    await _deleteTempFile();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    _currentPositionNotifier.value = position;
  }

  void _clearCurrentTrackState() {
    _playingNotifier.value = false;
    _currentPositionNotifier.value = Duration.zero;
    _durationNotifier.value = Duration.zero;
    _currentItem = null;
    _currentAttachment = null;
    _currentTrackNotifier.value = null;
  }

  Future<void> _deleteTempFile() async {
    final f = _tempFile;
    _tempFile = null;
    try {
      if (f != null && await f.exists()) {
        await f.delete();
      }
    } catch (e) {
      _log.warning('Could not delete temp file: $e');
    }
  }

  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    _deleteTempFile();
    _playingNotifier.dispose();
    _currentPositionNotifier.dispose();
    _durationNotifier.dispose();
    _currentTrackNotifier.dispose();
  }
}
