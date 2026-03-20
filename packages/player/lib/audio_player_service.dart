import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:player/audio_device_service.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('audio_player_service');

/// An AudioSource that plays from in-memory bytes.
class DartCouchDbAttachmentAudioSource extends StreamAudioSource {
  final String docId;
  final String attachmentId;
  final String contentType;

  final String debugString;

  Uint8List? _cachedBytes;

  DartCouchDbAttachmentAudioSource({
    required this.docId,
    required this.attachmentId,
    required this.contentType,
    required this.debugString,
  });

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    _log.info(
      "DartCouchDbAttachmentAudioSource.request docid: $docId, attachmentId: $attachmentId, start: $start, end: $end",
    );

    if (_cachedBytes == null) {
      final stopwatch = Stopwatch()..start();
      _cachedBytes = await di<DartCouchDb>().getAttachment(docId, attachmentId);
      stopwatch.stop();
      _log.info(
        'getAttachment $debugString took ${stopwatch.elapsedMilliseconds} ms',
      );
    }

    if (_cachedBytes == null) {
      // Attachment could not be loaded??? Return an empty stream to avoid crashing.
      // TODO: Maybe better throw?
      _log.severe('getAttachment $debugString returned null!');
      return StreamAudioResponse(
        sourceLength: 0,
        contentLength: 0,
        offset: 0,
        stream: Stream.empty(),
        contentType: '',
      );
    }

    start ??= 0;
    end ??= _cachedBytes!.length;
    return StreamAudioResponse(
      sourceLength: _cachedBytes!.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_cachedBytes!.sublist(start, end)),
      contentType: contentType,
    );
  }
}

/// Describes a single track to be played.
class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? album;
  final AudioSource source;
  final double? lufs;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.album,
    required this.source,
    this.lufs,
  });
}

/// Audio player service using just_audio + audio_service for background playback.
///
/// Usage:
/// 1. Call [AudioPlayerService.init] once at app startup (returns the singleton).
/// 2. Call [loadAndPlay] with a list of [AudioTrack]s to start playback.
/// 3. Use [play], [pause], [seekTo], [skipToNext], [skipToPrevious] for controls.
/// 4. Listen to streams: [playbackState], [currentMediaItem], [player] for UI updates.
class AudioPlayerService extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  static const double _targetLufs = -14.0;
  static const double _maxVolumeFactor = 4.0;
  static const double _minVolumeFactor = 0.1;

  final AudioPlayer player = AudioPlayer();
  List<AudioSource>? _audioSources;
  List<AudioTrack> _tracks = [];
  int? _currentTrackIndex;

  /// The current track list in playback order (pre-shuffled if shuffle is on).
  List<AudioTrack> get tracks => _tracks;

  AudioPlayerService._() {
    _listenToPlayerState();
  }

  /// Initializes audio_service and returns the handler singleton.
  static Future<AudioPlayerService> init() async {
    final service = AudioPlayerService._();

    // Configure audio session for proper audio behavior
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    await AudioService.init(
      builder: () => service,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.media_player_for_kids.audio',
        androidNotificationChannelName: 'Media Player for Kids',
        //androidNotificationOngoing: true,
        //androidStopForegroundOnPause: true,
      ),
    );

    // Re-apply volume whenever the active output device or its limit changes.
    di<AudioDeviceService>().addListener(service._onDeviceServiceChanged);

    return service;
  }

  void _listenToPlayerState() {
    // Forward player state to audio_service's playbackState stream
    player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });

    player.processingStateStream.listen((state) {
      _log.info(
        'processingState: $state  currentIndex=${player.currentIndex}  nextIndex=${player.nextIndex}',
      );
    });

    // Listen for errors during playback
    player.errorStream.listen((PlayerException e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
    });

    // Update media item and apply loudness normalization when track changes
    player.currentIndexStream.listen((index) {
      if (index != null && index < _tracks.length) {
        final track = _tracks[index];
        _currentTrackIndex = index;

        final volume = _volumeForTrack(track);
        player.setVolume(volume);
        _log.info('Track "${track.title}": lufs=${track.lufs}, volume=$volume');

        mediaItem.add(
          MediaItem(
            id: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
          ),
        );
      }
    });
  }

  double _volumeForTrack(AudioTrack track) {
    // LUFS normalisation
    double lufsFactor = 1.0;
    if (track.lufs != null) {
      final gainDb = _targetLufs - track.lufs!;
      lufsFactor = pow(10, gainDb / 20).toDouble();
      _log.info(
        '_volumeForTrack "${track.title}": '
        'lufs=${track.lufs} targetLufs=$_targetLufs '
        'gainDb=${gainDb.toStringAsFixed(2)} lufsFactor=${lufsFactor.toStringAsFixed(4)}',
      );
    } else {
      _log.info(
        '_volumeForTrack "${track.title}": no LUFS metadata, lufsFactor=1.0',
      );
    }

    // Device volume limit set by admin (multiplied on top of LUFS factor).
    // If the service is not yet registered (very early startup), skip safely.
    double deviceLimitFactor = 1.0;
    if (di.isRegistered<AudioDeviceService>()) {
      final svc = di<AudioDeviceService>();
      deviceLimitFactor = svc.currentDeviceVolumeLimitFactor;
      final currentDevice = svc.currentDevice;
      _log.info(
        '_volumeForTrack "${track.title}": '
        'currentDevice=${currentDevice?.type.name ?? "none"} '
        'deviceLimitFactor=${deviceLimitFactor.toStringAsFixed(4)}',
      );
    } else {
      _log.info(
        '_volumeForTrack "${track.title}": AudioDeviceService not registered, deviceLimitFactor=1.0',
      );
    }

    final combined = lufsFactor * deviceLimitFactor;
    final clamped = combined.clamp(_minVolumeFactor, _maxVolumeFactor);
    _log.info(
      '_volumeForTrack "${track.title}": '
      'combined=${combined.toStringAsFixed(4)} '
      'clamped=${clamped.toStringAsFixed(4)} '
      '(min=$_minVolumeFactor max=$_maxVolumeFactor)',
    );
    return clamped;
  }

  /// Called whenever [AudioDeviceService] notifies a change (device switch or
  /// admin volume-limit update). Re-applies the volume for the current track.
  void _onDeviceServiceChanged() {
    final index = _currentTrackIndex;
    if (index != null && index < _tracks.length) {
      final svc = di<AudioDeviceService>();
      _log.info(
        '_onDeviceServiceChanged: currentDevice=${svc.currentDevice?.type.name ?? "none"} '
        'limitFactor=${svc.currentDeviceVolumeLimitFactor.toStringAsFixed(4)}',
      );
      final volume = _volumeForTrack(_tracks[index]);
      player.setVolume(volume);
      _log.info(
        '_onDeviceServiceChanged: set volume=$volume for track "${_tracks[index].title}"',
      );
    } else {
      _log.info(
        '_onDeviceServiceChanged: no active track (index=$index), volume not changed',
      );
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// Loads a list of tracks and starts playback.
  ///
  /// [shuffle] — when true, the queue is shuffled before playback begins
  ///   (just_audio's [ShuffleOrder] is applied so track order is randomised).
  ///
  /// [repeat] — when true, the player loops the whole queue indefinitely
  ///   ([LoopMode.all]). When false, playback stops after the last track
  ///   ([LoopMode.off]).
  Future<void> loadAndPlay(
    List<AudioTrack> tracks, {
    bool shuffle = false,
    bool repeat = false,
    int initialTrack = 0,
    Duration initialPosition = Duration.zero,
  }) async {
    // Pre-shuffle in Dart and keep just_audio's shuffle mode disabled.
    //
    // just_audio maintains its OWN shuffle order in the Dart layer AND sends
    // a separate shuffle order to the native ExoPlayer. After calling
    // player.shuffle(), the current physical track index (0 after setAudioSources)
    // can land anywhere in the Dart-side shuffle order — e.g. at position 4 of 8.
    // This means nextIndex becomes null after only 3 more skips, disabling the
    // skip button too early, while ExoPlayer continues in its own order forever.
    //
    // By pre-shuffling the list in Dart and leaving shuffleModeEnabled=false,
    // both layers agree: the playlist is a plain sequential list, nextIndex is
    // accurate, and completed fires correctly at the true end.
    if (shuffle) {
      final indices = List.generate(tracks.length, (i) => i)..shuffle();
      _tracks = indices.map((i) => tracks[i]).toList();
      _log.info('loadAndPlay: shuffle order: $indices');
    } else {
      _tracks = tracks;
    }

    _audioSources = _tracks.map((e) => e.source).toList();

    _log.info(
      'loadAndPlay: ${_tracks.length} tracks, shuffle=$shuffle, repeat=$repeat',
    );

    // Publish queue to audio_service
    queue.add(
      _tracks
          .map(
            (t) => MediaItem(
              id: t.id,
              title: t.title,
              artist: t.artist,
              album: t.album,
            ),
          )
          .toList(),
    );

    try {
      await player.stop(); // 🔥 VERY IMPORTANT

      await player.setLoopMode(repeat ? LoopMode.all : LoopMode.off);
      await player.setShuffleModeEnabled(false);

      await player.setAudioSources(_audioSources!, preload: true);

      if (initialTrack > 0 || initialPosition != Duration.zero) {
        await player.seek(initialPosition, index: initialTrack);
      }

      await player.play();
      _log.info('loadAndPlay: playback started');
    } catch (e) {
      _log.warning("Load error: $e");
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    await player.seek(Duration.zero, index: index);
  }

  /// Disposes the player. Call when the service is no longer needed.
  Future<void> dispose() async {
    await player.dispose();
  }
}
