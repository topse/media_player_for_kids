import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:player/admin/admin_override_service.dart';
import 'package:player/hearing_stats_service.dart';
import 'package:player/main.dart' show routeObserver;
import 'package:player/media_player_page.dart';
import 'package:player/play_position_service.dart';
import 'package:player/widgets/media_app_bar.dart';
import 'package:shared/l10n/shared_l10n.dart';
import 'package:shared/models/datatypes.dart';
import 'package:shared/shared.dart'
    show
        ConstraintEvaluator,
        ConstraintStatus,
        EvaluationResult,
        MediaBaseIcon,
        StatsLookup,
        buildEffectiveIsNewMap;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('DirectoryView');

/// Child-facing media browsing screen.
///
/// Renders the catalog as a grid of [MediaBase] items filtered by visibility
/// (`fromDateTime` / `toDateTime` and the `hidden` flag, unless the
/// `ignoreDateSettings` admin override is on). Drives navigation into
/// subfolders and into [MediaPlayerPage] for items, and renders the per-item
/// soft-hint constraint indicators (lock overlay when blocked, red timer icon
/// when the item can no longer be finished — see [_cannotFinishWithGrace]).
class DirectoryView extends StatefulWidget {
  const DirectoryView({super.key});

  @override
  State<DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends State<DirectoryView>
    with WidgetsBindingObserver, RouteAware {
  String? parentNodeId;
  List<MediaBase>? entries;

  StreamSubscription? _dbSubscription;
  Timer? _visibilityTimer;
  final ScrollController _gridScrollController = ScrollController();

  /// True while the directory page is the topmost route. Flipped by
  /// [RouteAware] callbacks so that play-stats ticks fired by the player page
  /// (every 5 s during playback) don't force an invisible grid rebuild.
  bool _isCurrentRoute = true;

  /// Set by [_onPlayPositionsChanged] when a notification arrives while
  /// hidden. We rebuild once on return so the kid sees up-to-date markers.
  bool _pendingRebuild = false;

  /// Resets the grid scroll position to the top. Called after navigating
  /// into a folder or back to a parent so the kid always starts at the top
  /// of the new directory.
  void _scrollGridToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridScrollController.hasClients) {
        _gridScrollController.jumpTo(0);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createSubscription();
    di<PlayPositionService>().addListener(_onPlayPositionsChanged);
    di<AdminOverrideService>().addListener(_onPlayPositionsChanged);
    di<HearingStatsService>().addListener(_onPlayPositionsChanged);
  }

  void _onPlayPositionsChanged() {
    if (!mounted) return;
    // While the player page (or any other route) is on top, swallow the
    // notification — the grid is invisible and the rebuild is wasted work.
    // We mark it dirty so we rebuild once on return.
    if (!_isCurrentRoute) {
      _pendingRebuild = true;
      return;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _isCurrentRoute = false;
  }

  @override
  void didPopNext() {
    _isCurrentRoute = true;
    if (_pendingRebuild && mounted) {
      _pendingRebuild = false;
      setState(() {});
    }
  }

  double? _computeProgress(MediaItem item) {
    final entry = di<PlayPositionService>().getEntry(item.id!);
    if (entry == null) return null;
    if (entry.done) return 1.0;
    final pos = entry.position;
    if (pos == null) return null;

    final media = item.media;
    int totalMs = 0;
    int elapsedMs = 0;
    for (int i = 0; i < media.length; i++) {
      final dMs = media[i].durationMs;
      totalMs += dMs;
      if (i < pos.track) elapsedMs += dMs;
      if (i == pos.track) elapsedMs += pos.seconds * 1000;
    }
    if (totalMs == 0) return null;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
  }

  bool _isHiddenOrHasHiddenAncestor(String id, Map<String, MediaBase> byId) {
    String? current = id;
    while (current != null) {
      final doc = byId[current];
      if (doc == null) break;
      if (doc.hidden) return true;
      current = doc.parent;
    }
    return false;
  }

  void _createSubscription() {
    _dbSubscription
        ?.cancel(); // Cancel any existing subscription to avoid duplicates

    /*final stream = di<DartCouchDb>().useView(
      'mediatree/by_parent',
      includeDocs: true,
      startkey: parentNodeId != null ? '["$parentNodeId"]' : '[null]',
      endkey: parentNodeId != null ? '["$parentNodeId", {}]' : '[null, {}]',
    );*/
    final stream = di<DartCouchDb>().useAllDocs(includeDocs: true);

    _dbSubscription = stream.listen((result) {
      final docs = result?.rows
          .map((e) => e.doc)
          .whereType<MediaBase>()
          .toList();
      _log.info('useAllDocs update: ${docs?.length} docs');

      // Always update internal state — the grid must reflect fresh data when
      // it becomes visible again. The expensive part (constraint evaluation
      // for every tile) lives in build(), so we only skip the rebuild when
      // the page is covered.
      entries = docs;
      if (parentNodeId != null && docs != null) {
        final byId = {for (final d in docs) if (d.id != null) d.id!: d};
        if (_isHiddenOrHasHiddenAncestor(parentNodeId!, byId)) {
          parentNodeId = null;
          _scrollGridToTop();
        }
      }
      _scheduleVisibilityRefresh();

      if (!_isCurrentRoute) {
        // Grid is covered (e.g. player page on top). Defer rebuild until
        // [didPopNext]; the playlog persists every 60 s and play-position
        // writes echo through this stream, and forcing a hidden grid to
        // re-evaluate constraints for every tile on each emission was the
        // dominant cost during playback.
        _pendingRebuild = true;
        return;
      }
      if (mounted) setState(() {});
    });
  }

  /// Schedules a one-shot timer to fire at the next visibility transition
  /// (earliest future fromDateTime or toDateTime across all entries).
  /// When the timer fires the widget rebuilds with the updated DateTime.now(),
  /// and the timer is rescheduled for the next transition after that.
  void _scheduleVisibilityRefresh() {
    _visibilityTimer?.cancel();
    _visibilityTimer = null;

    final now = DateTime.now();
    DateTime? next;

    for (final entry in entries ?? []) {
      for (final raw in [entry.fromDateTime, entry.toDateTime]) {
        if (raw == null) continue;
        final dt = DateTime.parse(raw);
        if (dt.isAfter(now) && (next == null || dt.isBefore(next))) {
          next = dt;
        }
      }
    }

    if (next == null) return;

    _visibilityTimer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleVisibilityRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _visibilityTimer?.cancel();
      _visibilityTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _scheduleVisibilityRefresh();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    di<HearingStatsService>().removeListener(_onPlayPositionsChanged);
    di<AdminOverrideService>().removeListener(_onPlayPositionsChanged);
    di<PlayPositionService>().removeListener(_onPlayPositionsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _visibilityTimer?.cancel();
    _dbSubscription?.cancel();
    _gridScrollController.dispose();
    super.dispose();
  }

  /// Combined constraint check for a single grid tile.
  ///
  /// Returns the [EvaluationResult] used for the lock overlay AND whether the
  /// kid can no longer finish [item] within the configured grace period
  /// (drives the red timer marker). The two used to be separate methods that
  /// each walked the ancestor tree and built a fresh `Map<String, HearingStats?>`
  /// per call; combining them halves the work per tile.
  ///
  /// Hot path — only invoked by [build] via the per-holder cache in
  /// [_HolderEvalCache].
  ({EvaluationResult result, bool cannotFinish}) _evalForTile({
    required BuildContext context,
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    required _HolderEvalCache cache,
    required int itemDurationMs,
    required int graceMs,
  }) {
    if (di<AdminOverrideService>().ignoreConstraints) {
      return (result: EvaluationResult.allowed, cannotFinish: false);
    }
    final perHolder = cache.forItem(item, allDocuments, context);
    final result = perHolder.result;
    bool cannotFinish = false;
    if (itemDurationMs > 0 &&
        result.status != ConstraintStatus.blocked &&
        perHolder.effectiveRemainingMs != null) {
      cannotFinish = perHolder.effectiveRemainingMs! + graceMs < itemDurationMs;
    }
    return (result: result, cannotFinish: cannotFinish);
  }

  @override
  Widget build(BuildContext context) {
    if (entries == null) {
      return Scaffold(
        appBar: const MediaAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Create a map of all documents by ID for cover resolution
    final allDocuments = {for (var doc in entries!) doc.id!: doc};

    // Filter to get only root-level items (parent is null), respecting date visibility
    final now = DateTime.now();
    final overrides = di<AdminOverrideService>();
    final effectivelyNewById = buildEffectiveIsNewMap(
      allDocuments,
      includeInTraversal: (media) =>
          (overrides.ignoreDateSettings || media.isVisibleAt(now)) &&
          !media.hidden,
    );
    final rootItems =
        entries!
            .where(
              (e) =>
                  e.parent == parentNodeId &&
                  (overrides.ignoreDateSettings || e.isVisibleAt(now)) &&
                  !e.hidden,
            )
            .toList()
          ..sort((a, b) => a.sortHint.compareTo(b.sortHint));

    // Check if the current parent folder has item numbering enabled
    final parentFolder = parentNodeId != null
        ? allDocuments[parentNodeId]
        : null;
    final showItemNumbering =
        parentFolder is MediaFolder && parentFolder.showItemNumbering;

    // Build ancestor chain: walk up from current parent to root
    List<MediaBase>? ancestors;
    if (parentNodeId != null) {
      ancestors = [];
      String? id = parentNodeId;
      while (id != null) {
        final node = allDocuments[id];
        if (node == null) break;
        ancestors.insert(0, node);
        id = node.parent;
      }
    }

    final l10n = SharedL10n.of(context);

    // Build per-tile constraint cache. Most siblings share the same nearest
    // constraint holder, so for typical folders this collapses M tiles' worth
    // of evaluation work into 1 or 2 holder evaluations. Grace period and
    // override flag are read once for the whole build.
    final graceMs = (di<SharedPreferencesWithCache>().getInt(
              AdminOverrideService.kGracePeriodMinutes,
            ) ??
            AdminOverrideService.defaultGracePeriodMinutes) *
        60000;
    final statsService = di<HearingStatsService>();
    final evalCache = _HolderEvalCache(
      statsService: statsService,
    );

    return Scaffold(
      appBar: MediaAppBar(
        onBack: parentNodeId != null
            ? () {
                setState(() {
                  final currentParent = allDocuments[parentNodeId];
                  parentNodeId = currentParent?.parent;
                });
                _scrollGridToTop();
              }
            : null,
        ancestors: ancestors,
        allDocuments: allDocuments,
        // When the kid is browsing inside a folder, feed that folder as the
        // indicator's context so its nearest-wins constraint contributes.
        // At root (parentNodeId == null) only the global constraint applies.
        currentItem: parentFolder,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (overrides.anyOverrideActive)
              MaterialBanner(
                backgroundColor: Colors.orange[100],
                leading:
                    const Icon(Icons.warning_amber, color: Colors.orange),
                content: Text(
                  [
                    if (overrides.ignoreConstraints)
                      l10n.directoryHearingRulesDisabled,
                    if (overrides.ignoreDateSettings)
                      l10n.directoryDateLocksDisabled,
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: rootItems.isEmpty
                  ? Center(child: Text(l10n.directoryNoMediaItems))
                  : OrientationBuilder(
                builder: (context, orientation) {
                  final prefs = di<SharedPreferencesWithCache>();
                  final crossAxisCount = orientation == Orientation.portrait
                      ? (prefs.getInt('grid_columns_portrait') ?? 2)
                      : (prefs.getInt('grid_columns_landscape') ?? 4);
                  return GridView.builder(
                    controller: _gridScrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: rootItems.length,
                    itemBuilder: (context, index) {
                      final item = rootItems[index];
                      final progress = (item is MediaItem && item.isAudioBook)
                          ? _computeProgress(item)
                          : null;
                      final itemDurationMs = item is MediaItem
                          ? item.media.fold<int>(
                              0, (s, t) => s + t.durationMs)
                          : 0;
                      final tileEval = _evalForTile(
                        context: context,
                        item: item,
                        allDocuments: allDocuments,
                        cache: evalCache,
                        itemDurationMs: itemDurationMs,
                        graceMs: graceMs,
                      );
                      final constraintResult = tileEval.result;
                      final cannotFinish = tileEval.cannotFinish;

                      return _MediaGridItem(
                        key: ValueKey(item.id),
                        item: item,
                        allDocuments: allDocuments,
                        itemNumber: showItemNumbering ? index + 1 : null,
                        progress: progress,
                        isNew: effectivelyNewById[item.id] ?? false,
                        constraintResult: constraintResult,
                        cannotFinish: cannotFinish,
                        onTap: () {
                          if (constraintResult.status ==
                              ConstraintStatus.blocked) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  constraintResult.humanReadableReason ??
                                      l10n.directoryItemUnavailable,
                                ),
                              ),
                            );
                            return;
                          }
                          if (item is MediaFolder) {
                            setState(() {
                              parentNodeId = item.id;
                            });
                            _scrollGridToTop();
                          } else if (item is MediaItem) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MediaPlayerPage(
                                  item: item,
                                  allDocuments: allDocuments,
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-build cache that collapses constraint evaluation across grid tiles
/// that share the same nearest-wins constraint holder.
///
/// In a typical folder the kid is browsing, every direct child sibling
/// resolves to the same holder (the folder's own constraint, or an
/// inherited ancestor). Without this cache each tile redundantly walks the
/// ancestor tree and re-aggregates child stats — `effectiveEvaluation` +
/// `effectiveRemainingAllowance` per tile per build.
///
/// Cache key strategy:
/// - When the holder is the item itself (item carries its own constraint)
///   the cached entry is unique to that item — its [`MediaBase.id`] equals
///   the holder id.
/// - When the holder is a folder ancestor, all siblings resolve to the same
///   holder id and share the entry.
/// - When no per-item constraint exists, the global constraint still applies
///   uniformly, so a `__no_holder__` sentinel collapses those too.
///
/// `effectiveRemainingMs` is shared across siblings; the per-tile
/// "cannotFinish" check then combines it with the tile's own duration.
class _HolderEvalCache {
  final HearingStatsService statsService;
  final Map<String, _HolderEval> _cache = {};
  // Closure that adapts the stats service to the StatsLookup typedef; built
  // once and passed into the evaluator for every cache miss.
  late final StatsLookup _lookup = statsService.statsFor;
  static const String _noHolderKey = '__no_holder__';

  _HolderEvalCache({required this.statsService});

  _HolderEval forItem(
    MediaBase item,
    Map<String, MediaBase> allDocuments,
    BuildContext context,
  ) {
    final holder = ConstraintEvaluator.findNearestConstraintHolder(
      item: item,
      allDocuments: allDocuments,
    );
    final key = holder?.id ?? _noHolderKey;
    return _cache.putIfAbsent(
        key, () => _compute(item, holder, allDocuments, context));
  }

  _HolderEval _compute(
    MediaBase item,
    MediaBase? holder,
    Map<String, MediaBase> allDocuments,
    BuildContext context,
  ) {
    const evaluator = ConstraintEvaluator();
    final loc = SharedL10n.of(context);
    final globalConstraint = statsService.globalConstraint;
    final globalStats = statsService.globalStats();

    EvaluationResult perItem;
    int? perItemRemainingMs;
    if (holder == null) {
      perItem = EvaluationResult.allowed;
      perItemRemainingMs = null;
    } else {
      perItem = evaluator.evaluateAtHolder(
        item: item,
        holder: holder,
        allDocuments: allDocuments,
        lookup: _lookup,
        loc: loc,
      );
      perItemRemainingMs = evaluator.remainingAllowanceAtHolder(
        item: item,
        holder: holder,
        allDocuments: allDocuments,
        lookup: _lookup,
      );
    }

    // Combine with global through the canonical helpers in
    // [ConstraintEvaluator] so the most-restrictive-wins rule stays in one
    // place — see root CLAUDE.md.
    EvaluationResult combinedResult = perItem;
    int? combinedRemainingMs = perItemRemainingMs;
    if (globalConstraint != null) {
      final globalEval = evaluator.evaluate(
        constraint: globalConstraint,
        itemId: '_global',
        stats: globalStats,
        loc: loc,
      );
      combinedResult = evaluator.combineStatus(perItem, globalEval);
      final globalRemainingMs = evaluator.remainingAllowance(
        constraint: globalConstraint,
        stats: globalStats,
      );
      combinedRemainingMs =
          evaluator.combineRemainingMs(perItemRemainingMs, globalRemainingMs);
    }

    return _HolderEval(combinedResult, combinedRemainingMs);
  }
}

class _HolderEval {
  final EvaluationResult result;
  final int? effectiveRemainingMs;
  const _HolderEval(this.result, this.effectiveRemainingMs);
}

/// Red timer badge shown in the bottom-left of a grid item when the kid's
/// remaining allowance (plus grace period) is no longer enough to hear the
/// item to its natural end.
class _CannotFinishMarker extends StatelessWidget {
  const _CannotFinishMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.timer,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}

class _AudiobookProgressBar extends StatelessWidget {
  final double progress;

  const _AudiobookProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final isDone = progress >= 1.0;
    // Clamp visual width: min 10% so tiny progress is visible,
    // max 90% so "almost done" is clearly distinct from "done".
    final visualWidth = isDone
        ? 1.0
        : progress.clamp(0.10, 0.90);
    final color = isDone ? Colors.green : Colors.blue;
    final colorDark = isDone ? Colors.green[900]! : Colors.blue[900]!;

    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: visualWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 3, color: colorDark),
          Container(height: 6, color: color),
        ],
      ),
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final MediaBase item;
  final Map<String, MediaBase> allDocuments;
  final VoidCallback? onTap;
  final int? itemNumber;
  final double? progress;
  final bool isNew;
  final EvaluationResult? constraintResult;
  final bool cannotFinish;

  const _MediaGridItem({
    super.key,
    required this.item,
    required this.allDocuments,
    this.onTap,
    this.itemNumber,
    this.progress,
    this.isNew = false,
    this.constraintResult,
    this.cannotFinish = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: isNew
            ? BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amberAccent.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              )
            : null,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: isNew
              ? RoundedRectangleBorder(
                  borderRadius: borderRadius,
                  side: const BorderSide(color: Colors.amber, width: 3),
                )
              : null,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey[300],
                        child: MediaBaseIcon(
                          media: item,
                          allDocuments: allDocuments,
                          iconSize: 64,
                          showTypeBadge: true,
                          overlayNumber: itemNumber,
                          showNewStar: isNew,
                        ),
                      ),
                      if (progress != null && progress! > 0)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          right: 0,
                          child: _AudiobookProgressBar(progress: progress!),
                        ),
                      // Blocked overlay — lock icon only, no text
                      if (constraintResult?.status ==
                          ConstraintStatus.blocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        )
                      else if (cannotFinish)
                        const Positioned(
                          left: 4,
                          bottom: 4,
                          child: _CannotFinishMarker(),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
