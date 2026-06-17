import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:shared/shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('HearingStatsService');

/// Records, persists, and prunes hearing statistics for constraint evaluation.
///
/// Backed by a single replicated CouchDB document `playlog-<deviceUuid>`,
/// structured by item ID. The document is loaded into memory on [init] and
/// written back on a 60 s timer and on app lifecycle exit.
///
/// On startup, events older than 31 days are aggregated into a separate
/// `playlog_archive-<deviceUuid>` document with per-item monthly buckets,
/// then pruned from the play log.
class HearingStatsService extends ChangeNotifier {
  static const int _pruneOlderThanDays = 31;
  static const Duration _persistInterval = Duration(seconds: 60);

  /// In-memory refresh ticker. Faster than [_persistInterval] so UI views
  /// that derive from stats (e.g. the app-bar allowance indicator) update
  /// while playback is in flight, without doing a CouchDB write on every
  /// tick. The refreshed event is the same one the persist timer will
  /// later write.
  ///
  /// Fires the dedicated [liveTicker] (not the main change notifier) so the
  /// player page and directory view aren't dragged into a full re-evaluation
  /// on every tick — the only consumer that needs the live update is the
  /// app-bar allowance indicator.
  static const Duration _refreshInterval = Duration(seconds: 5);

  /// Dedicated notifier fired by the in-flight 5 s refresh tick. UI that
  /// must tick down live during playback (the app-bar allowance indicator)
  /// listens here in addition to the main change notifier.
  ///
  /// Kept separate so the player page's allowance-timer reschedule and the
  /// directory grid's full rebuild don't run on every tick — they only react
  /// to real stats changes (record events, external sync, constraint config
  /// changes) on the main channel.
  final ChangeNotifier liveTicker = _PublicNotifier();

  /// SharedPreferences key for the minimum-play threshold.
  /// Must appear in the SharedPreferences allowList in main.dart.
  static const String kMinPlaySeconds = 'min_play_seconds';
  static const int defaultMinPlaySeconds = 15;

  /// In-memory view for fast constraint evaluation.
  /// Built from the playlog document on [init].
  final Map<String, HearingStats> _statsById = {};

  String? _deviceUuid;

  /// Owns persistence, rev-currency, own-write detection and the change-stream
  /// subscription for the `playlog-<uuid>` document. Created in [init].
  /// [_statsById] is the in-memory source of truth for fast constraint
  /// evaluation; each persist builds a [PlayLog] snapshot of it inside the
  /// writer's build closure (rev-safe and coalesced) — no second copy of the
  /// document is held here. [_onPlayLogExternalChange] reloads [_statsById] when
  /// the document changes underneath us (companion purge, admin wipe, another
  /// device).
  SaveDocWriter? _writer;

  // ── Active session state ──────────────────────────────────────────────────

  String? _activeItemId;
  String _activeItemTitle = '';
  String _activeEventStartedAt = '';
  int _totalItemDurationMs = 0;
  int _accumulatedPlayMs = 0;
  Duration _lastKnownPosition = Duration.zero;
  int _lastKnownTrackIndex = 0;
  bool _sessionCompleted = false;
  bool _dirty = false;
  Timer? _persistTimer;
  Timer? _refreshTimer;

  /// True if any contiguous segment in the current session has crossed the
  /// minimum-play threshold. Drives new-flag clearing and position-save
  /// decisions independently of the latest (possibly short) segment.
  bool _sessionHadValidSegment = false;

  // ── Global constraint ─────────────────────────────────────────────────────

  /// The global hearing constraint from the companion app's
  /// `global-constraints` CouchDB document. `null` means no global limit.
  HearingConstraint? _globalConstraint;
  StreamSubscription<dynamic>? _globalConstraintsSub;

  /// The active global constraint, or `null` if none is configured.
  HearingConstraint? get globalConstraint => _globalConstraint;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Initialise the service by loading the playlog document from CouchDB
  /// and running the archival/pruning pass.
  ///
  /// Must be called once after login when [DartCouchDb] is available.
  Future<void> init(String deviceUuid) async {
    _deviceUuid = deviceUuid;
    _log.info('Initialising HearingStatsService for device $deviceUuid');

    final docId = PlayLog.docIdFor(deviceUuid);
    final writer = di<DocStore>().writer(docId);
    // React to external changes (companion purge, admin wipe, another device);
    // own writes are handled rev-aware inside the writer and never call back.
    writer.onExternalChange = _onPlayLogExternalChange;
    final loaded = await writer.start();
    _writer = writer;
    // Populate the in-memory eval cache from the loaded document.
    final playLog = loaded is PlayLog
        ? loaded
        : PlayLog(id: docId, deviceId: deviceUuid);
    _loadFromPlayLog(playLog);
    _log.info('Loaded playlog: ${playLog.items.length} item(s)');

    // Archive old events into playlog_archive document.
    await _archiveAndPrune();

    // Load and subscribe to the global constraint config.
    await _initGlobalConstraints();

    _notifyDeferred();
  }

  /// Build the in-memory stats map from the playlog document.
  void _loadFromPlayLog(PlayLog playLog) {
    _statsById.clear();
    for (final entry in playLog.items.entries) {
      final itemId = entry.key;
      final item = entry.value;
      final events = item.events
          .map(
            (e) => PlayEvent(
              startedAt: e.startedAt,
              durationMs: e.durationMs,
              playCountFraction: e.playCountFraction,
            ),
          )
          .toList();
      _statsById[itemId] = HearingStats(
        itemId: itemId,
        title: item.title,
        playEvents: events,
      );
    }
  }

  /// Returns the in-memory stats for [itemId], or null if none exist.
  HearingStats? statsFor(String itemId) => _statsById[itemId];

  /// Returns aggregated [HearingStats] across **all** items, for use with
  /// the global hearing constraint. Returns `null` when no play events exist
  /// (fail-open, consistent with EC-08).
  HearingStats? globalStats() {
    final allEvents = _statsById.values.expand((s) => s.playEvents).toList();
    if (allEvents.isEmpty) return null;
    return HearingStats(itemId: '_global', playEvents: allEvents);
  }

  /// Whether the current session has had at least one contiguous play segment
  /// that crossed the configured minimum-play threshold.
  ///
  /// "Session" = from [recordPlayStart] until [recordPlayStop] /
  /// [recordPlayCompletion]. A user-initiated seek or track skip (via
  /// [recordSeek]) ends one segment and starts another. Pauses do NOT end a
  /// segment — natural pause/resume continues accumulating.
  ///
  /// True if either the current in-progress segment has already crossed the
  /// threshold, or any previously-finalized segment did. Used by callers
  /// (e.g. new-flag clearing) to decide whether the kid has listened "for
  /// real" rather than scanning through.
  bool meetsMinimumPlayThreshold() =>
      _sessionHadValidSegment || _currentSegmentMeetsThreshold();

  /// Whether the **current** (in-progress) play segment has crossed the
  /// minimum-play threshold. Unlike [meetsMinimumPlayThreshold] this only
  /// looks at the segment running right now, not the session as a whole.
  ///
  /// Used by audiobook position saving so the saved position always reflects
  /// a spot where the kid actually listened past the threshold — not a spot
  /// they briefly skimmed after seeking away from a valid segment.
  bool currentSegmentMeetsThreshold() => _currentSegmentMeetsThreshold();

  // ── Recording ──────────────────────────────────────────────────────────────

  /// Call when playback starts for [itemId]. Creates a new [PlayEvent] with
  /// `completed = false` and starts the periodic persist timer.
  ///
  /// [totalItemDurationMs] is the sum of all track durations for the item,
  /// used to compute [PlayEvent.playCountFraction].
  ///
  /// [itemTitle] is stored at item level so the play log remains readable
  /// even after the MediaItem is deleted or renamed.
  ///
  /// P-02: This must only be called AFTER the constraint check passes.
  void recordPlayStart(
    String itemId, {
    required int totalItemDurationMs,
    required String itemTitle,
  }) {
    // Finalise any previous session that was not properly stopped.
    if (_activeItemId != null && _activeItemId != itemId) {
      _log.info(
        'Finalising stale session for $_activeItemId '
        'before starting $itemId',
      );
      _finaliseSession();
    }

    _activeItemId = itemId;
    _activeItemTitle = itemTitle;
    _activeEventStartedAt = _formatLocalDateTime(DateTime.now());
    _totalItemDurationMs = totalItemDurationMs;
    _accumulatedPlayMs = 0;
    _lastKnownPosition = Duration.zero;
    _lastKnownTrackIndex = 0;
    _sessionCompleted = false;
    _sessionHadValidSegment = false;
    _dirty = true;

    _log.info(
      'Play start: "$itemTitle" ($itemId), '
      'totalDuration=${totalItemDurationMs}ms',
    );

    // Create the initial event.
    final event = PlayEvent(startedAt: _activeEventStartedAt);

    final existing = _statsById[itemId];
    if (existing != null) {
      _statsById[itemId] = existing.copyWith(
        title: itemTitle,
        playEvents: [...existing.playEvents, event],
      );
    } else {
      _statsById[itemId] = HearingStats(
        itemId: itemId,
        title: itemTitle,
        playEvents: [event],
      );
    }

    // Update title if the item was renamed.
    _refreshTitle(itemId, itemTitle);

    _notifyDeferred();
    _persistPlayLog();

    // Start periodic persist timer (safety net for crash/kill).
    _persistTimer?.cancel();
    _persistTimer = Timer.periodic(_persistInterval, (_) {
      _persistIfDirty();
    });

    // Start in-memory refresh ticker so allowance-indicator UIs reflect
    // current playback without waiting for the slower persist cycle.
    // Fires only [liveTicker], not the main channel — see field docs.
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      final id = _activeItemId;
      if (id == null) return;
      _updateActiveEvent(id);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        (liveTicker as _PublicNotifier).fire();
      });
    });
  }

  /// Called from MediaPlayerPage when the audio player reports a new position.
  /// Accumulates actual playback duration (not wall-clock time).
  ///
  /// [position] is the current position within the current track.
  /// [trackIndex] is the index of the currently playing track.
  /// [isPlaying] must be true for the delta to count.
  /// [isBuffering] must be false for the delta to count — just_audio's
  /// positionStream interpolation timer continues ticking during seeks
  /// (buffering state), so we reset the baseline instead of accumulating.
  void onPositionUpdate(
    Duration position,
    int trackIndex,
    bool isPlaying, {
    bool isBuffering = false,
  }) {
    if (_activeItemId == null || _sessionCompleted) return;

    if (!isPlaying || isBuffering) {
      // Update baseline so we don't count pause/seek time as a delta.
      _lastKnownPosition = position;
      _lastKnownTrackIndex = trackIndex;
      return;
    }

    if (trackIndex != _lastKnownTrackIndex) {
      // Track changed — reset baseline to avoid negative/huge deltas.
      _log.fine('Track changed: $_lastKnownTrackIndex → $trackIndex');
      _lastKnownPosition = Duration.zero;
      _lastKnownTrackIndex = trackIndex;
    }

    final deltaMs = position.inMilliseconds - _lastKnownPosition.inMilliseconds;
    if (deltaMs > 0 && deltaMs < 5000) {
      // Only accumulate reasonable deltas (< 5s accounts for stream interval).
      // Larger jumps indicate seeks and should not be counted as play time.
      _accumulatedPlayMs += deltaMs;
      _dirty = true;
    }

    _lastKnownPosition = position;
  }

  /// Call when the user initiates a seek or track skip. Ends the current
  /// segment and starts a fresh one with `startedAt = now`.
  ///
  /// Threshold semantics: the minimum-play threshold is checked **per
  /// segment**. A short play (e.g. 10 s with a 15 s threshold) followed by
  /// a seek discards that segment's event entirely. The kid effectively gets
  /// a clean start for the new position — no "credit" carries over.
  ///
  /// Pauses do NOT call this; pause/resume keeps the same segment.
  ///
  /// No-op if [itemId] is not the active session.
  void recordSeek(String itemId) {
    if (_activeItemId != itemId || _sessionCompleted) return;

    if (_currentSegmentMeetsThreshold()) {
      _log.info(
        'Seek: finalising segment as event '
        '(${_accumulatedPlayMs}ms)',
      );
      _updateActiveEvent(itemId);
      _sessionHadValidSegment = true;
    } else {
      _log.info(
        'Seek: discarding short segment '
        '(${_accumulatedPlayMs}ms) for $itemId',
      );
      _discardActiveEvent(itemId);
    }

    // Start a new segment with a fresh event entry.
    _activeEventStartedAt = _formatLocalDateTime(DateTime.now());
    _accumulatedPlayMs = 0;
    _lastKnownPosition = Duration.zero;

    final newEvent = PlayEvent(startedAt: _activeEventStartedAt);
    final stats = _statsById[itemId];
    if (stats != null) {
      _statsById[itemId] = stats.copyWith(
        playEvents: [...stats.playEvents, newEvent],
      );
    } else {
      _statsById[itemId] = HearingStats(
        itemId: itemId,
        title: _activeItemTitle,
        playEvents: [newEvent],
      );
    }

    _dirty = true;
    _notifyDeferred();
    _persistPlayLog();
  }

  /// Call when the playlist ends naturally. Finalises the active event and persists.
  Future<void> recordPlayCompletion(String itemId) async {
    if (_activeItemId != itemId) return;
    _sessionCompleted = true;
    _persistTimer?.cancel();
    _persistTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;

    // Natural completion always counts as a valid segment regardless of
    // accumulated duration (e.g. a short item heard to the end).
    _updateActiveEvent(itemId);
    _sessionHadValidSegment = true;
    _dirty = true;

    final fraction = _totalItemDurationMs > 0
        ? (_accumulatedPlayMs / _totalItemDurationMs).clamp(0.0, 1.0)
        : 0.0;
    _log.info(
      'Play completed: "$_activeItemTitle" ($itemId), '
      'duration=${_accumulatedPlayMs}ms, fraction=${fraction.toStringAsFixed(2)}',
    );

    _notifyDeferred();
    await _persistPlayLog();

    _activeItemId = null;
  }

  /// Call on dispose / stop without natural completion. Idempotent.
  Future<void> recordPlayStop(String itemId) async {
    if (_activeItemId != itemId) return;
    if (_sessionCompleted) {
      // Already finalised by recordPlayCompletion.
      _activeItemId = null;
      return;
    }

    final fraction = _totalItemDurationMs > 0
        ? (_accumulatedPlayMs / _totalItemDurationMs).clamp(0.0, 1.0)
        : 0.0;
    _log.info(
      'Play stopped: "$_activeItemTitle" ($itemId), '
      'duration=${_accumulatedPlayMs}ms, fraction=${fraction.toStringAsFixed(2)}',
    );

    _finaliseSession();
  }

  /// Persist the active event's current accumulated duration if dirty.
  /// Call on app lifecycle changes (pause/inactive) as a safety net.
  void persistActiveSession() {
    _persistIfDirty();
  }

  // ── Internal: session management ───────────────────────────────────────────

  void _finaliseSession() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final itemId = _activeItemId;
    if (itemId == null) return;

    if (_currentSegmentMeetsThreshold()) {
      _updateActiveEvent(itemId);
      _sessionHadValidSegment = true;
    } else {
      _log.info(
        'Final segment too short (${_accumulatedPlayMs}ms) — '
        'discarding event for $itemId',
      );
      _discardActiveEvent(itemId);
    }
    _dirty = true;

    _notifyDeferred();
    _persistPlayLog();

    _activeItemId = null;
  }

  /// Returns true if the **current segment**'s accumulated play time meets
  /// the minimum threshold.
  ///
  /// A segment runs from the last [recordPlayStart] or [recordSeek] until
  /// the next [recordSeek] or session end. Threshold = [kMinPlaySeconds]
  /// seconds, capped at the item's total duration so items shorter than
  /// the threshold always count.
  bool _currentSegmentMeetsThreshold() {
    final prefs = di<SharedPreferencesWithCache>();
    final minSeconds = prefs.getInt(kMinPlaySeconds) ?? defaultMinPlaySeconds;
    final configuredMs = minSeconds * 1000;

    // If the item is shorter than the threshold it auto-passes — the child
    // must have heard most of it to reach the end at all.
    final thresholdMs =
        (_totalItemDurationMs > 0 && _totalItemDurationMs < configuredMs)
        ? _totalItemDurationMs
        : configuredMs;

    return _accumulatedPlayMs >= thresholdMs;
  }

  /// Removes the most-recently-started (incomplete) event for [itemId].
  /// Used when a session is discarded because it was too short.
  void _discardActiveEvent(String itemId) {
    final stats = _statsById[itemId];
    if (stats == null || stats.playEvents.isEmpty) return;

    final events = List<PlayEvent>.from(stats.playEvents)..removeLast();
    if (events.isEmpty) {
      _statsById.remove(itemId);
    } else {
      _statsById[itemId] = stats.copyWith(playEvents: events);
    }
  }

  void _persistIfDirty() {
    final itemId = _activeItemId;
    if (itemId == null || !_dirty) return;
    _updateActiveEvent(itemId);
    _persistPlayLog();
  }

  void _updateActiveEvent(String itemId) {
    final stats = _statsById[itemId];
    if (stats == null || stats.playEvents.isEmpty) return;

    // Clamp both values to the declared item duration. just_audio's interpolation
    // timer can tick position a few milliseconds past the metadata duration, so
    // raw _accumulatedPlayMs may slightly exceed _totalItemDurationMs. Clamping
    // keeps stored values consistent: fraction stays in [0.0, 1.0] and
    // duration_ms never exceeds the item's declared length.
    final fraction = _totalItemDurationMs > 0
        ? (_accumulatedPlayMs / _totalItemDurationMs).clamp(0.0, 1.0)
        : 0.0;
    final clampedDurationMs = _totalItemDurationMs > 0
        ? _accumulatedPlayMs.clamp(0, _totalItemDurationMs)
        : _accumulatedPlayMs;

    final events = List<PlayEvent>.from(stats.playEvents);
    final last = events.last;
    events[events.length - 1] = PlayEvent(
      startedAt: last.startedAt,
      durationMs: clampedDurationMs,
      playCountFraction: fraction,
    );
    _statsById[itemId] = stats.copyWith(playEvents: events);
  }

  /// Updates the title on the [HearingStats] for [itemId] if it has changed.
  void _refreshTitle(String itemId, String currentTitle) {
    final stats = _statsById[itemId];
    if (stats == null || stats.title == currentTitle) return;

    _log.info('Updated stale title for $itemId → "$currentTitle"');
    _statsById[itemId] = stats.copyWith(title: currentTitle);
    _dirty = true;
  }

  // ── Internal: persistence ──────────────────────────────────────────────────

  /// Persists a snapshot of the in-memory [_statsById] through the
  /// [SaveDocWriter].
  ///
  /// Fire-and-forget: the writer coalesces rapid calls into a single rev-safe
  /// put and retries on conflict. Callers that must block until the write has
  /// landed `await` the returned future ([SaveDocWriter.settle]); the rest
  /// ignore it. The build closure constructs a fresh [PlayLog] from the current
  /// [_statsById], stamped with the writer's latest rev — so no second copy of
  /// the document is held, and on a conflict retry it is simply rebuilt from the
  /// (possibly reloaded) stats against the fresh rev. Replaces the old
  /// hand-rolled `_persistChain` + `_rev` tracking.
  Future<void> _persistPlayLog() {
    final uuid = _deviceUuid;
    final writer = _writer;
    if (uuid == null || writer == null) return Future.value();
    writer.save(
      (rev) => PlayLog(
        id: PlayLog.docIdFor(uuid),
        deviceId: uuid,
        items: _buildItems(),
        rev: rev,
      ),
    );
    _dirty = false;
    return writer.settle();
  }

  /// Builds the playlog item map from the in-memory stats. Invoked at write
  /// time (inside the persist mutation), so the persisted snapshot reflects the
  /// latest [_statsById] — matching the previous "build from stats on persist"
  /// model.
  Map<String, PlayLogItem> _buildItems() {
    final items = <String, PlayLogItem>{};
    for (final entry in _statsById.entries) {
      final stats = entry.value;
      items[entry.key] = PlayLogItem(
        title: stats.title,
        events: stats.playEvents
            .map(
              (e) => PlayLogEvent(
                startedAt: e.startedAt,
                durationMs: e.durationMs,
                playCountFraction: e.playCountFraction,
              ),
            )
            .toList(),
      );
    }
    return items;
  }

  /// Reloads [_statsById] when the playlog document changes externally — a
  /// companion purge after a catalog deletion, an admin wipe (null doc), or
  /// another device writing to it. Mirrors the previous `useDoc` external/delete
  /// branches: reload from the external truth, and if that dropped the active
  /// session's item (e.g. the document was deleted), re-seed a fresh in-progress
  /// event so it is still recorded on the next persist.
  void _onPlayLogExternalChange(CouchDocumentBase? doc) {
    final playLog = doc is PlayLog ? doc : PlayLog(deviceId: _deviceUuid ?? '');
    _loadFromPlayLog(playLog);
    final activeId = _activeItemId;
    if (activeId != null && _statsById[activeId] == null) {
      _statsById[activeId] = HearingStats(
        itemId: activeId,
        title: _activeItemTitle,
        playEvents: [PlayEvent(startedAt: _activeEventStartedAt)],
      );
      _dirty = true;
    }
    _notifyDeferred();
  }

  // ── Internal: archival ─────────────────────────────────────────────────────

  /// Archives events older than 31 days into the playlog_archive document,
  /// then prunes them from the in-memory stats (and the playlog doc on next
  /// persist).
  Future<void> _archiveAndPrune() async {
    final uuid = _deviceUuid;
    if (uuid == null) return;

    final cutoff = DateTime.now().subtract(
      const Duration(days: _pruneOlderThanDays),
    );
    final oldEvents = <String, ({List<PlayEvent> events, String title})>{};

    // Separate old events from recent ones.
    for (final entry in _statsById.entries) {
      final itemId = entry.key;
      final stats = entry.value;
      final old = <PlayEvent>[];
      final recent = <PlayEvent>[];
      for (final e in stats.playEvents) {
        if (DateTime.parse(e.startedAt).isBefore(cutoff)) {
          old.add(e);
        } else {
          recent.add(e);
        }
      }
      if (old.isNotEmpty) {
        oldEvents[itemId] = (events: old, title: stats.title);
        _statsById[itemId] = stats.copyWith(playEvents: recent);
      }
    }

    // Remove items with no remaining events.
    _statsById.removeWhere((_, v) => v.playEvents.isEmpty);

    if (oldEvents.isEmpty) return;

    _log.info('Archiving old events for ${oldEvents.length} item(s)');

    // Read-modify-write the archive rev-safely: load the existing archive,
    // aggregate the old events into it, and put — retrying on conflict (the
    // archive is otherwise only touched at startup, so a one-shot update is the
    // right tool rather than a long-lived writer).
    final saved = await di<DocStore>().update<PlayLogArchive>(
      PlayLogArchive.docIdFor(uuid),
      (current) {
        final base = current ?? PlayLogArchive(deviceId: uuid);
        final archiveItems = Map<String, PlayLogArchiveItem>.from(base.items);
        for (final entry in oldEvents.entries) {
          final itemId = entry.key;
          final (:events, :title) = entry.value;
          final existing = archiveItems[itemId] ?? const PlayLogArchiveItem();

          int totalPlayCount = existing.totalPlayCount;
          int totalDurationMs = existing.totalDurationMs;
          String firstPlayed = existing.firstPlayed;
          String lastPlayed = existing.lastPlayed;
          // Use the current item title (already up to date via _refreshTitle).
          String archiveTitle = title.isNotEmpty ? title : existing.title;
          final monthly = Map<String, PlayLogMonthlyBucket>.from(
            existing.monthly,
          );

          for (final e in events) {
            totalPlayCount++;
            totalDurationMs += e.durationMs;

            // First/last played.
            if (firstPlayed.isEmpty || e.startedAt.compareTo(firstPlayed) < 0) {
              firstPlayed = e.startedAt;
            }
            if (lastPlayed.isEmpty || e.startedAt.compareTo(lastPlayed) > 0) {
              lastPlayed = e.startedAt;
            }

            // Monthly bucket.
            final dt = DateTime.parse(e.startedAt);
            final monthKey =
                '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            final bucket = monthly[monthKey] ?? const PlayLogMonthlyBucket();
            monthly[monthKey] = PlayLogMonthlyBucket(
              playCount: bucket.playCount + 1,
              durationMs: bucket.durationMs + e.durationMs,
            );
          }

          archiveItems[itemId] = PlayLogArchiveItem(
            totalPlayCount: totalPlayCount,
            totalDurationMs: totalDurationMs,
            firstPlayed: firstPlayed,
            lastPlayed: lastPlayed,
            title: archiveTitle,
            monthly: monthly,
          );
        }

        return PlayLogArchive(
          id: PlayLogArchive.docIdFor(uuid),
          deviceId: uuid,
          items: archiveItems,
          rev: base.rev,
        );
      },
    );
    if (saved != null) {
      _log.info('Archived ${oldEvents.length} item(s) into playlog_archive');
    }

    // Persist pruned playlog.
    _dirty = true;
    await _persistPlayLog();
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  // ── Global constraint loading ──────────────────────────────────────────────────

  Future<void> _initGlobalConstraints() async {
    final db = di<DartCouchDb>();
    try {
      final doc = await db.get(GlobalConstraints.docId);
      if (doc != null) {
        _globalConstraint = (doc as GlobalConstraints).hearingConstraint;
        _log.info(
          'Loaded global constraint: '
          '${_globalConstraint != null ? "active" : "none"}',
        );
      } else {
        _log.info('No global-constraints document — no global constraint');
      }
    } catch (e) {
      _log.warning('Failed to load global-constraints: $e');
    }

    _globalConstraintsSub = db.useDoc(GlobalConstraints.docId).listen((doc) {
      final newConstraint = (doc as GlobalConstraints?)?.hearingConstraint;
      if (newConstraint != _globalConstraint) {
        _log.info('Global constraint changed via CouchDB subscription');
        _globalConstraint = newConstraint;
        _notifyDeferred();
      }
    });
  }

  @override
  void dispose() {
    _globalConstraintsSub?.cancel();
    // The writer's lifetime is owned by [DocStore]; just detach our callback.
    _writer?.onExternalChange = null;
    _persistTimer?.cancel();
    _refreshTimer?.cancel();
    liveTicker.dispose();
    super.dispose();
  }

  /// Notify listeners after the current frame to avoid calling setState()
  /// during build/dispose.
  void _notifyDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Formats a DateTime as ISO 8601 local datetime string without offset
  /// (e.g. "2026-03-30T14:05:00"), matching EC-09.
  String _formatLocalDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:$s';
  }
}

/// Thin [ChangeNotifier] whose [notifyListeners] is callable from outside its
/// own class via [fire]. Used so [HearingStatsService] can expose a
/// secondary notifier ([HearingStatsService.liveTicker]) without subclassing.
class _PublicNotifier extends ChangeNotifier {
  void fire() => notifyListeners();
}
