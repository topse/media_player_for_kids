import 'dart:async';
import 'dart:typed_data';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:player/audio_player_service.dart';
import 'package:player/play_position_service.dart';
import 'package:player/widgets/media_app_bar.dart';
import 'package:shared/models/datatypes.dart' as models;
import 'package:shared/shared.dart' show MediaBaseIcon;
import 'package:watch_it/watch_it.dart';

final _log = Logger('media_player_page');

class MediaPlayerPage extends StatefulWidget {
  final models.MediaItem item;

  const MediaPlayerPage({super.key, required this.item});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage>
    with WidgetsBindingObserver {
  late AudioPlayerService _audioService;
  bool _isLoading = true;
  bool _completedNaturally = false;
  StreamSubscription<ProcessingState>? _completionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription? _dbSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAudioAndPlay();
  }

  void _saveCurrentPosition() {
    final currentIndex = _audioService.player.currentIndex;
    if (currentIndex == null) return;
    final position = _audioService.player.position;
    final lastTrackIndex = widget.item.media.length - 1;
    final lastTrackDurationMs = widget.item.media.last.durationMs;

    final isNearEnd =
        currentIndex == lastTrackIndex &&
        position.inMilliseconds >= (lastTrackDurationMs - 30000);

    final svc = di<PlayPositionService>();
    if (isNearEnd) {
      svc.saveDone(widget.item.id!);
    } else {
      svc.savePosition(
        widget.item.id!,
        track: currentIndex,
        seconds: position.inSeconds,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        widget.item.isAudioBook &&
        !_completedNaturally) {
      _saveCurrentPosition();
    }
  }

  bool _isItemOrAncestorHidden(
    String id,
    Map<String, models.MediaBase> byId,
  ) {
    String? current = id;
    while (current != null) {
      final doc = byId[current];
      if (doc == null) break;
      if (doc.hidden) return true;
      current = doc.parent;
    }
    return false;
  }

  Future<void> _initAudioAndPlay() async {
    _audioService = di<AudioPlayerService>();
    _audioService.stop();

    // Pop the page if this item (or any ancestor folder) becomes hidden.
    _dbSubscription = di<DartCouchDb>()
        .useAllDocs(includeDocs: true)
        .listen((result) {
      if (!mounted) return;
      final docs = result?.rows
          .map((e) => e.doc)
          .whereType<models.MediaBase>()
          .toList();
      if (docs == null) return;
      final byId = {for (final d in docs) if (d.id != null) d.id!: d};
      if (_isItemOrAncestorHidden(widget.item.id!, byId)) {
        _audioService.stop();
        Navigator.of(context).pop();
      }
    });

    // Load all audio attachments from CouchDB into memory
    final db = di<DartCouchDb>();
    final tracks = <AudioTrack>[];

    for (int i = 0; i < widget.item.media.length; ++i) {
      final media = widget.item.media[i];
      final data = await db.getAttachmentAsReadonlyFile(
        media.attachmentId,
        models.MediaTrack.audioAttachmentName,
      );
      if (data != null) {
        // Determine content type from the attachment info
        //final attachmentInfo = widget.item.attachments?[media.attachmentId];
        //final contentType = attachmentInfo?.contentType;

        tracks.add(
          AudioTrack(
            id: media.attachmentId,
            source: AudioSource.file(data),
            //source: DartCouchDbAttachmentAudioSource(
            //  docId: widget.item.id!,
            //  attachmentId: media.attachmentId,
            //  contentType: contentType!,
            //  debugString: media.title
            //),
            title: media.title,
            album: media.album,
            artist: media.artist,
            lufs: media.lufs,
          ),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    // Clear the "new" flag on first playback
    if (widget.item.isNew) {
      di<DartCouchDb>().put(widget.item.copyWith(isNew: false));
    }

    if (tracks.isNotEmpty) {
      int initialTrack = 0;
      Duration initialPosition = Duration.zero;

      // Resume audiobook from saved position
      if (widget.item.isAudioBook) {
        final saved = di<PlayPositionService>().getEntry(widget.item.id!);
        if (saved != null && saved.containsKey('position')) {
          final pos = saved['position'] as Map<String, dynamic>;
          initialTrack = pos['track'] as int;
          initialPosition = Duration(seconds: pos['seconds'] as int);
        }
      }

      await _audioService.loadAndPlay(
        tracks,
        shuffle: widget.item.isAudioBook ? false : widget.item.shuffle,
        repeat: widget.item.repeat,
        initialTrack: initialTrack,
        initialPosition: initialPosition,
      );
    }

    // Save position whenever playback is paused (covers app-kill-while-paused).
    _playingSub = _audioService.player.playingStream.listen((playing) {
      if (!playing && widget.item.isAudioBook && !_completedNaturally) {
        _saveCurrentPosition();
      }
    });

    // Close the player page automatically when the playlist finishes.
    // With LoopMode.all (repeat==true) the player never reaches
    // ProcessingState.completed, so this fires only when repeat is off.
    _completionSub = _audioService.player.processingStateStream.listen((state) {
      // nextIndex == null confirms we are at the true end of the playlist
      // (not a transient completed state between tracks).
      // We stop the player immediately before popping: after completed,
      // ExoPlayer resets currentIndex internally, which would make nextIndex
      // non-null again and could trigger auto-advance on the singleton player
      // while the page dismiss animation is still running.
      _log.info(
        'processingState: $state  '
        'currentIndex=${_audioService.player.currentIndex}  '
        'nextIndex=${_audioService.player.nextIndex}',
      );
      if (state == ProcessingState.completed &&
          _audioService.player.nextIndex == null &&
          mounted) {
        _log.info('playlist complete — stopping and closing player');
        _completedNaturally = true;
        if (widget.item.isAudioBook) {
          di<PlayPositionService>().saveDone(widget.item.id!);
        }
        _audioService.stop();
        Navigator.of(context).pop();
      }
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _completionSub?.cancel();
    _playingSub?.cancel();
    _dbSubscription?.cancel();

    if (widget.item.isAudioBook &&
        !_completedNaturally &&
        _audioService.player.currentIndex != null) {
      _saveCurrentPosition();
    }

    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleTracks = widget.item.media.length > 1;

    return Scaffold(
      appBar: MediaAppBar(onBack: () => Navigator.of(context).pop()),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Cover image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.item.showTrackCoverRatherThanItemCover
                              ? StreamBuilder<int?>(
                                  stream:
                                      _audioService.player.currentIndexStream,
                                  builder: (context, snapshot) {
                                    final index = snapshot.data ?? 0;
                                    final tracks = _audioService.tracks;
                                    final trackDocId = index < tracks.length
                                        ? tracks[index].id
                                        : null;
                                    if (trackDocId == null) {
                                      return MediaBaseIcon(
                                        media: widget.item,
                                        iconSize: 96,
                                      );
                                    }
                                    return _TrackCoverImage(
                                      key: ValueKey(trackDocId),
                                      trackDocId: trackDocId,
                                      fallbackItem: widget.item,
                                    );
                                  },
                                )
                              : MediaBaseIcon(media: widget.item, iconSize: 96),
                        ),
                      ),
                    ),
                  ),
                ),

                // Track title
                StreamBuilder<int?>(
                  stream: _audioService.player.currentIndexStream,
                  builder: (context, snapshot) {
                    final index = snapshot.data ?? 0;
                    final tracks = _audioService.tracks;
                    final track = index < tracks.length ? tracks[index] : null;

                    return Column(
                      children: [
                        if (track != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                            ),
                            child: Text(
                              track.title,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (hasMultipleTracks)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Track ${index + 1} of ${widget.item.media.length}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Progress bar with skip buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: StreamBuilder<int?>(
                    stream: _audioService.player.currentIndexStream,
                    builder: (context, indexSnapshot) {
                      // Use just_audio's nextIndex / previousIndex rather than
                      // comparing currentIndex against the source-list length.
                      // These getters return null when there is no next/previous
                      // track given the *current shuffle order* and loop mode,
                      // which is the correct signal to disable the buttons.
                      final hasPrevious =
                          _audioService.player.previousIndex != null;
                      final hasNext = _audioService.player.nextIndex != null;

                      return Row(
                        children: [
                          if (hasMultipleTracks)
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              iconSize: 36,
                              onPressed: hasPrevious
                                  ? _audioService.skipToPrevious
                                  : null,
                            ),
                          Expanded(
                            child: StreamBuilder<Duration>(
                              stream: _audioService.player.positionStream,
                              builder: (context, posSnapshot) {
                                final position =
                                    posSnapshot.data ?? Duration.zero;
                                final duration =
                                    _audioService.player.duration ??
                                    Duration.zero;
                                final maxSeconds = duration.inMilliseconds > 0
                                    ? duration.inMilliseconds.toDouble()
                                    : 1.0;

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Slider(
                                      value: position.inMilliseconds
                                          .toDouble()
                                          .clamp(0.0, maxSeconds),
                                      min: 0.0,
                                      max: maxSeconds,
                                      onChanged: (value) {
                                        _audioService.seek(
                                          Duration(milliseconds: value.toInt()),
                                        );
                                      },
                                    ),
                                    Text(
                                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (hasMultipleTracks)
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              iconSize: 36,
                              onPressed: hasNext
                                  ? _audioService.skipToNext
                                  : null,
                            ),
                        ],
                      );
                    },
                  ),
                ),

                // Play/pause button
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: StreamBuilder<PlayerState>(
                      stream: _audioService.player.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;

                        return IconButton(
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                          ),
                          iconSize: 72,
                          onPressed: () {
                            if (playing) {
                              _audioService.pause();
                            } else {
                              _audioService.play();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Loads and displays the cover image for a single [MediaTrack] document.
///
/// Falls back to [MediaBaseIcon] using [fallbackItem] when no track cover is available.
class _TrackCoverImage extends StatefulWidget {
  final String trackDocId;
  final models.MediaItem fallbackItem;
  final double iconSize;

  const _TrackCoverImage({
    super.key,
    required this.trackDocId,
    required this.fallbackItem,
    // ignore: unused_element_parameter
    this.iconSize = 96,
  });

  @override
  State<_TrackCoverImage> createState() => _TrackCoverImageState();
}

class _TrackCoverImageState extends State<_TrackCoverImage> {
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  @override
  void didUpdateWidget(_TrackCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackDocId != widget.trackDocId) {
      _loadCover();
    }
  }

  Future<void> _loadCover() async {
    final docId = widget.trackDocId;
    if (mounted) setState(() => _isLoading = true);

    final data = await di<DartCouchDb>().getAttachment(
      docId,
      models.MediaTrack.coverAttachmentName,
    );

    if (mounted && widget.trackDocId == docId) {
      setState(() {
        _imageData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
    // Fallback to item cover
    return MediaBaseIcon(media: widget.fallbackItem, iconSize: widget.iconSize);
  }
}
