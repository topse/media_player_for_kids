import 'dart:async';
import 'dart:typed_data';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:player/admin/admin_override_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:player/audio_player_service.dart';
import 'package:player/hearing_stats_service.dart';
import 'package:player/play_position_service.dart';
import 'package:player/widgets/media_app_bar.dart';
import 'package:shared/models/datatypes.dart' as models;
import 'package:shared/shared.dart'
    show ConstraintEvaluator, ConstraintStatus, MediaBaseIcon, SharedL10n;
import 'package:watch_it/watch_it.dart';

final _log = Logger('media_player_page');

/// Player screen for a single [models.MediaItem].
///
/// Owns the lifecycle of one playback session against the singleton
/// [AudioPlayerService]:
///
/// - **Constraint gate (hard).** Before loading audio, evaluates the item's
///   nearest-wins constraint *and* the global constraint. A blocked result
///   pops the page immediately, with no audio loaded and no stats recorded.
/// - **Mid-playback enforcement.** Schedules a [Timer] for the smaller of
///   the per-item and global remaining allowance. On expiry, allows the kid
///   to finish if the remaining item time is within the admin-configured
///   grace period; otherwise stops and pops the page.
/// - **Position forwarding.** Forwards `positionStream` updates to
///   [HearingStatsService.onPositionUpdate] so segment accumulation runs
///   against actual playback (not wall-clock). Slider seeks and skip-next /
///   skip-previous additionally call [HearingStatsService.recordSeek] to end
///   the current segment.
/// - **Audiobook resume.** If the item is an audiobook, resumes from the
///   saved position on entry and saves position on pause / dispose, gated
///   by the per-segment minimum-play threshold (see player CLAUDE.md).
/// - **Side effects on real listening.** Clears the `isNew` flag only after
///   the session has had at least one segment passing the threshold (see
///   [_clearNewFlagIfThresholdMet]).
class MediaPlayerPage extends StatefulWidget {
  final models.MediaItem item;
  final Map<String, models.MediaBase> allDocuments;

  const MediaPlayerPage({
    super.key,
    required this.item,
    required this.allDocuments,
  });

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage>
    with WidgetsBindingObserver {
  late AudioPlayerService _audioService;
  late Map<String, models.MediaBase> _liveDocuments;
  bool _isLoading = true;
  bool _completedNaturally = false;
  int _totalItemDurationMs = 0;

  /// Cumulative start time (ms) of each track within the audiobook, so the
  /// audiobook slider can map a global position to a (track, local-position)
  /// pair and paint chapter markers at the file boundaries.
  late final List<int> _cumulativeTrackStartsMs =
      _computeCumulativeTrackStarts();

  /// While the kid is dragging the audiobook slider, this holds the thumb
  /// position in ms so the slider follows the finger smoothly. The actual
  /// (potentially cross-track) seek runs only on release in [onChangeEnd] —
  /// otherwise seeking on every drag tick fights the position stream and the
  /// thumb feels sticky.
  double? _audiobookDragMs;
  Timer? _allowanceTimer;
  StreamSubscription<ProcessingState>? _completionSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _liveDocuments = Map.of(widget.allDocuments);
    WidgetsBinding.instance.addObserver(this);
    // No HearingStatsService listener — the [useAllDocs] subscription set up
    // in [_initAudioAndPlay] already fires on external playlog and
    // global-constraint sync, which is the only case where a mid-play
    // re-evaluation is needed. Local record events (start/seek/stop)
    // schedule the allowance timer inline at their call sites.
    _initAudioAndPlay();
  }

  /// Clears the [models.MediaItem.isNew] flag in CouchDB if the current
  /// session had at least one contiguous play segment that met the
  /// minimum-play threshold. Briefly scanning an item (e.g. open + close
  /// without listening past the threshold) must NOT clear the flag.
  ///
  /// Uses the live document (via [_liveDocuments]) rather than [widget.item]
  /// so the write carries the current `_rev` — replication may have updated
  /// the item while the kid was listening, in which case the captured
  /// `widget.item._rev` is stale and the put would fail with 409.
  void _clearNewFlagIfThresholdMet() {
    if (!di<HearingStatsService>().meetsMinimumPlayThreshold()) return;
    final current = _liveDocuments[widget.item.id!] ?? widget.item;
    if (current is! models.MediaItem || !current.isNew) return;
    // Rev-safe one-shot: refetches the freshest item and retries on conflict,
    // so a replication update mid-listen can't make this lose to a 409.
    di<DocStore>().update<models.MediaItem>(
      current.id!,
      (cur) => cur?.copyWith(isNew: false),
    );
  }

  /// True when the singleton [AudioPlayerService] is currently loaded with
  /// this page's item — i.e. our `loadAndPlay` has run and the queue still
  /// reflects our tracks.
  ///
  /// Critical because `_saveCurrentPosition` reads `currentIndex`, `position`
  /// and the threshold accumulator from singleton services. If the kid backed
  /// out before our `loadAndPlay` completed (so the previous item's tracks
  /// are still in the queue) those reads return the *previous* item's state.
  /// Writing that under *our* item's id would create a phantom resume
  /// position — exactly the cross-item contamination we saw in the playlog.
  bool _audioIsForOurItem() {
    final tracks = _audioService.tracks;
    if (tracks.isEmpty) return false;
    return tracks.first.id == widget.item.media.first.attachmentId;
  }

  /// Saves the current playhead as the audiobook resume position, gated on
  /// the **current** play segment having met the minimum-play threshold.
  ///
  /// "Current segment" = play time since the last [recordPlayStart] or
  /// [recordSeek] (pauses do not reset it). This guarantees the saved
  /// position always corresponds to a spot the kid actually listened to past
  /// the threshold — never a spot they briefly skimmed.
  ///
  /// Call BEFORE any seek/skip (so the pre-seek position is captured while
  /// the about-to-end segment is still the current one). On exit/pause it's
  /// called from the lifecycle hooks; if the kid hasn't accumulated enough
  /// in the current segment, the existing saved position (or "done" marker)
  /// is left untouched.
  ///
  /// Near-end detection still overrides the gate so that finishing within
  /// 30 s of the last track always marks the item as done.
  void _saveCurrentPosition() {
    if (!widget.item.isAudioBook) return;
    if (!_audioIsForOurItem()) return;
    final currentIndex = _audioService.player.currentIndex;
    if (currentIndex == null) return;
    final position = _audioService.player.position;
    final lastTrackIndex = widget.item.media.length - 1;
    final lastTrackDurationMs = widget.item.media.last.durationMs;

    final isNearEnd =
        currentIndex == lastTrackIndex &&
        position.inMilliseconds >= (lastTrackDurationMs - 30000);

    final svc = di<PlayPositionService>();
    final itemId = widget.item.id!;
    final title = widget.item.name;

    if (isNearEnd) {
      svc.saveDone(itemId, title: title);
      return;
    }

    if (!di<HearingStatsService>().currentSegmentMeetsThreshold()) return;

    svc.savePosition(
      itemId,
      title: title,
      track: currentIndex,
      seconds: position.inSeconds,
    );
  }

  /// Bookkeeping for every user-initiated seek or track skip, regardless of
  /// surface: registered as [AudioPlayerService.onBeforeUserSeek], so the
  /// media notification, lock screen and headset buttons run exactly the
  /// same path as the on-page slider and skip buttons.
  ///
  /// Order matters: the pre-seek position is captured while the about-to-end
  /// segment is still current, then [HearingStatsService.recordSeek] splits
  /// the segment, then the allowance timer is recomputed (a finalised or
  /// discarded segment changes the consumed stats).
  void _onUserSeek() {
    _saveCurrentPosition();
    di<HearingStatsService>().recordSeek(widget.item.id!);
    _scheduleAllowanceTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      di<HearingStatsService>().persistActiveSession();
      if (widget.item.isAudioBook && !_completedNaturally) {
        _saveCurrentPosition();
      }
      _clearNewFlagIfThresholdMet();
    }
  }

  bool _isItemOrAncestorHidden(String id, Map<String, models.MediaBase> byId) {
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

    // Subscribe to position stream immediately — same as the slider StreamBuilder.
    // Must be before any await so there is no gap where events are missed.
    _positionSub = _audioService.player.positionStream.listen((position) {
      final trackIndex = _audioService.player.currentIndex ?? 0;
      final isPlaying = _audioService.player.playing;
      final isBuffering =
          _audioService.player.processingState == ProcessingState.buffering;
      di<HearingStatsService>().onPositionUpdate(
        position,
        trackIndex,
        isPlaying,
        isBuffering: isBuffering,
      );
    });

    // P-01: Authoritative constraint gate — combined per-item + global.
    // The grid overlay is only a UX hint; this is the real enforcement.
    if (!di<AdminOverrideService>().ignoreConstraints) {
      final statsService = di<HearingStatsService>();
      final result = const ConstraintEvaluator().effectiveEvaluation(
        item: widget.item,
        allDocuments: widget.allDocuments,
        statsLookup: statsService.statsFor,
        globalConstraint: statsService.globalConstraint,
        globalStats: statsService.globalStats(),
      );
      if (result.status == ConstraintStatus.blocked) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }

    // Pop the page if this item (or any ancestor folder) becomes hidden.
    // Also update _liveDocuments so constraint re-evaluation uses fresh data.
    _dbSubscription = di<DartCouchDb>().useAllDocs(includeDocs: true).listen((
      result,
    ) {
      if (!mounted) return;
      final docs = result?.rows
          .map((e) => e.doc)
          .whereType<models.MediaBase>()
          .toList();
      if (docs == null) return;
      final byId = {
        for (final d in docs)
          if (d.id != null) d.id!: d,
      };
      if (_isItemOrAncestorHidden(widget.item.id!, byId)) {
        _audioService.stop();
        Navigator.of(context).pop();
        return;
      }
      _liveDocuments = byId;
      _reevaluateConstraintIfPlaying();
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

    if (tracks.isNotEmpty) {
      int initialTrack = 0;
      Duration initialPosition = Duration.zero;

      // Resume audiobook from saved position
      if (widget.item.isAudioBook) {
        final saved = di<PlayPositionService>().getEntry(widget.item.id!);
        final pos = saved?.position;
        if (pos != null) {
          initialTrack = pos.track;
          initialPosition = Duration(seconds: pos.seconds);
        }
      }

      // P-02: recordPlayStart only AFTER the constraint check has passed.
      _totalItemDurationMs = widget.item.media.fold<int>(
        0,
        (sum, t) => sum + t.durationMs,
      );
      di<HearingStatsService>().recordPlayStart(
        widget.item.id!,
        totalItemDurationMs: _totalItemDurationMs,
        itemTitle: widget.item.name,
      );

      await _audioService.loadAndPlay(
        tracks,
        shuffle: widget.item.isAudioBook ? false : widget.item.shuffle,
        repeat: widget.item.repeat,
        initialTrack: initialTrack,
        initialPosition: initialPosition,
      );
    }

    // The kid may have backed out while the tracks were loading — never arm
    // the timer or the subscriptions below on a disposed page (their
    // callbacks read the singleton player and write positions/stats).
    if (!mounted) return;

    // Funnel ALL user seeks/skips (page controls, notification, lock screen,
    // headset buttons) through a single bookkeeping path.
    _audioService.onBeforeUserSeek = _onUserSeek;

    // Schedule mid-playback constraint enforcement.
    _scheduleAllowanceTimer();

    // Save position whenever playback is paused (covers app-kill-while-paused).
    // On resume, reschedule the allowance timer with updated stats.
    _playingSub = _audioService.player.playingStream.listen((playing) {
      if (!playing) {
        _allowanceTimer?.cancel();
        di<HearingStatsService>().persistActiveSession();
        if (widget.item.isAudioBook && !_completedNaturally) {
          _saveCurrentPosition();
        }
      } else {
        // Resumed — recalculate allowance from current stats.
        _scheduleAllowanceTimer();
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
        di<HearingStatsService>().recordPlayCompletion(widget.item.id!);
        _clearNewFlagIfThresholdMet();
        if (widget.item.isAudioBook) {
          di<PlayPositionService>().saveDone(
            widget.item.id!,
            title: widget.item.name,
          );
        }
        _audioService.stop();
        Navigator.of(context).pop();
      }
    });
  }

  // ── Allowance timer ────────────────────────────────────────────────────────

  /// Computes remaining allowance from constraints and schedules a timer
  /// that stops playback when the allowance runs out.
  /// Skipped when admin overrides are active or item is on repeat.
  void _scheduleAllowanceTimer() {
    _allowanceTimer?.cancel();
    _allowanceTimer = null;

    if (di<AdminOverrideService>().ignoreConstraints) return;

    final statsService = di<HearingStatsService>();
    final allowanceMs = const ConstraintEvaluator().effectiveRemainingAllowance(
      item: widget.item,
      allDocuments: _liveDocuments,
      statsLookup: statsService.statsFor,
      globalConstraint: statsService.globalConstraint,
      globalStats: statsService.globalStats(),
    );

    if (allowanceMs == null || allowanceMs <= 0) {
      if (allowanceMs != null && allowanceMs <= 0) {
        // Already exceeded — check grace period immediately.
        _onAllowanceExpired();
      }
      return;
    }

    _log.info('Allowance timer: ${allowanceMs}ms remaining');
    _allowanceTimer = Timer(Duration(milliseconds: allowanceMs), () {
      _onAllowanceExpired();
    });
  }

  /// Re-evaluates time-based constraints against live documents and current
  /// stats, then reschedules the allowance timer.
  ///
  /// Deliberately does NOT check [PlayCountConstraint] or similar gate-only
  /// constraints: once a play has passed the gate check, count-based limits
  /// must not interrupt it mid-play. Only [PlayDurationConstraint] and
  /// [TimeOfDayConstraint] can end an ongoing session — and those are already
  /// handled inside [_scheduleAllowanceTimer] via [remainingAllowanceWithAncestors].
  ///
  /// No-op when paused, not yet playing, or overrides are active.
  void _reevaluateConstraintIfPlaying() {
    if (!mounted || _completedNaturally || _isLoading) return;
    if (!_audioService.player.playing) return;
    if (di<AdminOverrideService>().ignoreConstraints) return;
    _scheduleAllowanceTimer();
  }

  List<int> _computeCumulativeTrackStarts() {
    final media = widget.item.media;
    final starts = List<int>.filled(media.length, 0);
    for (int i = 1; i < media.length; i++) {
      starts[i] = starts[i - 1] + media[i - 1].durationMs;
    }
    return starts;
  }

  /// Track-boundary positions as fractions in [0,1] of the total audiobook
  /// duration, used to paint chapter markers on the slider. Excludes 0 and 1
  /// (start/end of the slider).
  List<double> _chapterFractions() {
    if (_totalItemDurationMs <= 0) return const [];
    final total = _totalItemDurationMs.toDouble();
    return [
      for (int i = 1; i < _cumulativeTrackStartsMs.length; i++)
        _cumulativeTrackStartsMs[i] / total,
    ];
  }

  /// Seek to a position expressed in milliseconds across the whole
  /// audiobook (not within a single track). Picks the right track from
  /// the cumulative starts and seeks to the local offset.
  void _seekGlobalMs(int globalMs) {
    final media = widget.item.media;
    if (media.isEmpty) return;
    int target = 0;
    for (int i = media.length - 1; i >= 0; i--) {
      if (globalMs >= _cumulativeTrackStartsMs[i]) {
        target = i;
        break;
      }
    }
    final localMs = globalMs - _cumulativeTrackStartsMs[target];
    _audioService.player.seek(Duration(milliseconds: localMs), index: target);
  }

  /// Milliseconds from the current playhead to the natural end of the
  /// playlist. Returns 0 if no playback is active. Ignores repeat mode —
  /// callers handle that separately.
  int _remainingPlaylistMs() {
    final currentIndex = _audioService.player.currentIndex;
    if (currentIndex == null) return 0;
    final positionMs = _audioService.player.position.inMilliseconds;
    int remaining = 0;
    for (int i = currentIndex; i < widget.item.media.length; i++) {
      remaining += widget.item.media[i].durationMs;
    }
    remaining -= positionMs;
    return remaining < 0 ? 0 : remaining;
  }

  void _onAllowanceExpired() {
    if (!mounted || _completedNaturally) return;

    // Grace period: if remaining playback to the end of the playlist is
    // within the configured threshold, allow the child to finish rather
    // than cutting off near the end.
    //
    // Remaining is measured from the playhead (currentIndex + position +
    // remaining track durations), not from session-accumulated time —
    // otherwise resumed audiobooks and items the kid seeked through
    // would compute the wrong "remaining".
    //
    // Repeat carve-out: with repeat enabled the playlist never ends, so
    // grace would let playback loop indefinitely past the limit. Treat
    // remaining as effectively infinite (stop immediately).
    final graceMinutes =
        di<SharedPreferencesWithCache>().getInt(
          AdminOverrideService.kGracePeriodMinutes,
        ) ??
        AdminOverrideService.defaultGracePeriodMinutes;
    final graceThresholdMs = graceMinutes * 60 * 1000;
    final remainingItemMs = widget.item.repeat ? -1 : _remainingPlaylistMs();

    if (remainingItemMs > 0 && remainingItemMs <= graceThresholdMs) {
      _log.info(
        'Allowance expired but within ${graceMinutes}min grace '
        '(${remainingItemMs}ms remaining of ${_totalItemDurationMs}ms) '
        '— allowing completion',
      );
      return;
    }

    _log.info('Allowance expired — stopping playback');
    _completedNaturally = false;
    di<HearingStatsService>().recordPlayStop(widget.item.id!);
    if (widget.item.isAudioBook) {
      _saveCurrentPosition();
    }
    _audioService.stop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SharedL10n.of(context).playerListeningTimeUp)),
      );
      Navigator.of(context).pop();
    }
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
    _allowanceTimer?.cancel();
    _completionSub?.cancel();
    _playingSub?.cancel();
    _positionSub?.cancel();
    _dbSubscription?.cancel();
    _audioService.onBeforeUserSeek = null;

    di<HearingStatsService>().recordPlayStop(widget.item.id!);

    if (widget.item.isAudioBook &&
        !_completedNaturally &&
        _audioService.player.currentIndex != null) {
      _saveCurrentPosition();
    }

    // Clear new flag only if the session actually had real listening.
    // Must run AFTER recordPlayStop so the final segment has been finalised
    // (or discarded) into the session's threshold state.
    _clearNewFlagIfThresholdMet();

    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleTracks = widget.item.media.length > 1;

    return Scaffold(
      appBar: MediaAppBar(
        onBack: () => Navigator.of(context).pop(),
        currentItem: widget.item,
        allDocuments: _liveDocuments,
      ),
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
                              // Seek bookkeeping runs via onBeforeUserSeek.
                              onPressed: hasPrevious
                                  ? () => _audioService.skipToPrevious()
                                  : null,
                            ),
                          Expanded(
                            child: StreamBuilder<Duration>(
                              stream: _audioService.player.positionStream,
                              builder: (context, posSnapshot) {
                                final position =
                                    posSnapshot.data ?? Duration.zero;
                                // Audiobooks: one global slider spanning the
                                // whole item, with chapter markers at file
                                // boundaries. Other items: per-track slider.
                                if (widget.item.isAudioBook &&
                                    hasMultipleTracks &&
                                    _totalItemDurationMs > 0) {
                                  final idx =
                                      indexSnapshot.data ??
                                      _audioService.player.currentIndex ??
                                      0;
                                  final safeIdx = idx.clamp(
                                    0,
                                    _cumulativeTrackStartsMs.length - 1,
                                  );
                                  final playheadMs =
                                      (_cumulativeTrackStartsMs[safeIdx] +
                                              position.inMilliseconds)
                                          .clamp(0, _totalItemDurationMs)
                                          .toDouble();
                                  final maxMs = _totalItemDurationMs.toDouble();
                                  // While dragging, the slider follows the
                                  // finger; otherwise it follows the audio.
                                  final sliderValue =
                                      (_audiobookDragMs ?? playheadMs).clamp(
                                        0.0,
                                        maxMs,
                                      );
                                  final displayMs = sliderValue.toInt();

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackShape: _ChapterMarkerTrackShape(
                                            chapterFractions:
                                                _chapterFractions(),
                                          ),
                                        ),
                                        child: Slider(
                                          value: sliderValue,
                                          min: 0.0,
                                          max: maxMs,
                                          onChangeStart: (value) {
                                            setState(() {
                                              _audiobookDragMs = value;
                                            });
                                          },
                                          onChanged: (value) {
                                            setState(() {
                                              _audiobookDragMs = value;
                                            });
                                          },
                                          onChangeEnd: (value) {
                                            // _seekGlobalMs seeks via
                                            // player.seek directly (needs a
                                            // track index), bypassing the
                                            // handler hook — run the seek
                                            // bookkeeping explicitly.
                                            _onUserSeek();
                                            _seekGlobalMs(value.toInt());
                                            setState(() {
                                              _audiobookDragMs = null;
                                            });
                                          },
                                        ),
                                      ),
                                      Text(
                                        '${_formatDuration(Duration(milliseconds: displayMs))} / ${_formatDuration(Duration(milliseconds: _totalItemDurationMs))}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  );
                                }

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
                                        // Fires onBeforeUserSeek per drag
                                        // tick; after the first recordSeek
                                        // the segment is 0 ms, so further
                                        // ticks can't pass the threshold.
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
                                  ? () => _audioService.skipToNext()
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

/// Slider track shape that paints thin chapter-boundary notches on top of
/// the default rounded track. Used by the audiobook slider so the kid can
/// see where each file (chapter) begins.
class _ChapterMarkerTrackShape extends RoundedRectSliderTrackShape {
  final List<double> chapterFractions;

  const _ChapterMarkerTrackShape({required this.chapterFractions});

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: additionalActiveTrackHeight,
    );

    if (chapterFractions.isEmpty) return;

    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final notchHeight = trackRect.height * 2.5;
    final centerY = trackRect.center.dy;
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (final fraction in chapterFractions) {
      if (fraction <= 0 || fraction >= 1) continue;
      final x = trackRect.left + trackRect.width * fraction;
      context.canvas.drawLine(
        Offset(x, centerY - notchHeight / 2),
        Offset(x, centerY + notchHeight / 2),
        paint,
      );
    }
  }
}
