import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:player/admin/admin_override_service.dart';
import 'package:player/hearing_stats_service.dart';
import 'package:player/media_player_page.dart';
import 'package:player/play_position_service.dart';
import 'package:player/widgets/media_app_bar.dart';
import 'package:shared/models/datatypes.dart';
import 'package:shared/shared.dart'
    show
        ConstraintEvaluator,
        ConstraintStatus,
        EvaluationResult,
        HearingStats,
        MediaBaseIcon,
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
    with WidgetsBindingObserver {
  String? parentNodeId;
  List<MediaBase>? entries;

  StreamSubscription? _dbSubscription;
  Timer? _visibilityTimer;

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
    if (mounted) setState(() {});
  }

  double? _computeProgress(MediaItem item) {
    final entry = di<PlayPositionService>().getEntry(item.id!);
    if (entry == null) return null;
    if (entry.containsKey('done')) return 1.0;
    if (!entry.containsKey('position')) return null;

    final pos = entry['position'] as Map<String, dynamic>;
    final trackIndex = pos['track'] as int;
    final seconds = pos['seconds'] as int;

    final media = item.media;
    int totalMs = 0;
    int elapsedMs = 0;
    for (int i = 0; i < media.length; i++) {
      final dMs = media[i].durationMs;
      totalMs += dMs;
      if (i < trackIndex) elapsedMs += dMs;
      if (i == trackIndex) elapsedMs += seconds * 1000;
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
      for (final doc in docs ?? []) {
        _log.info(
          '  doc id=${doc.id} rev=${doc.rev} attachments=${doc.attachments?.keys.toList()}',
        );
      }

      setState(() {
        entries = docs;
        // Reset to root if the current folder (or any ancestor) became hidden.
        if (parentNodeId != null && docs != null) {
          final byId = {for (final d in docs) if (d.id != null) d.id!: d};
          if (_isHiddenOrHasHiddenAncestor(parentNodeId!, byId)) {
            parentNodeId = null;
          }
        }
      });
      _scheduleVisibilityRefresh();
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
    di<HearingStatsService>().removeListener(_onPlayPositionsChanged);
    di<AdminOverrideService>().removeListener(_onPlayPositionsChanged);
    di<PlayPositionService>().removeListener(_onPlayPositionsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _visibilityTimer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
  }

  EvaluationResult _evalWithAncestors(
    MediaBase item,
    Map<String, MediaBase> allDocuments,
  ) {
    if (di<AdminOverrideService>().ignoreConstraints) {
      return EvaluationResult.allowed;
    }
    final statsService = di<HearingStatsService>();
    return const ConstraintEvaluator().effectiveEvaluation(
      item: item,
      allDocuments: allDocuments,
      allStats: Map.fromEntries(
        allDocuments.keys.map(
          (id) => MapEntry(id, statsService.statsFor(id)),
        ),
      ),
      globalConstraint: statsService.globalConstraint,
      globalStats: statsService.globalStats(),
    );
  }

  /// Whether the kid can no longer hear [item] to its natural end, even with
  /// the configured grace period. Drives the red timer marker in the grid.
  ///
  /// Returns `false` when the item is blocked (a separate lock overlay handles
  /// that), when no quantifiable allowance applies, or when remaining time
  /// (plus grace) still covers the item.
  bool _cannotFinishWithGrace(
    MediaBase item,
    Map<String, MediaBase> allDocuments,
    int itemDurationMs,
  ) {
    if (itemDurationMs <= 0) return false;
    if (di<AdminOverrideService>().ignoreConstraints) return false;
    final evalResult = _evalWithAncestors(item, allDocuments);
    if (evalResult.status == ConstraintStatus.blocked) return false;

    final statsService = di<HearingStatsService>();
    final allStats = Map<String, HearingStats?>.fromEntries(
      allDocuments.keys.map((id) => MapEntry(id, statsService.statsFor(id))),
    );

    final effectiveRemainingMs = const ConstraintEvaluator()
        .effectiveRemainingAllowance(
      item: item,
      allDocuments: allDocuments,
      allStats: allStats,
      globalConstraint: statsService.globalConstraint,
      globalStats: statsService.globalStats(),
    );
    if (effectiveRemainingMs == null) return false;

    final graceMs = (di<SharedPreferencesWithCache>().getInt(
              AdminOverrideService.kGracePeriodMinutes,
            ) ??
            AdminOverrideService.defaultGracePeriodMinutes) *
        60000;
    return effectiveRemainingMs + graceMs < itemDurationMs;
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

    return Scaffold(
      appBar: MediaAppBar(
        onBack: parentNodeId != null
            ? () {
                setState(() {
                  final currentParent = allDocuments[parentNodeId];
                  parentNodeId = currentParent?.parent;
                });
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
                    if (overrides.ignoreConstraints) 'Hörregeln deaktiviert',
                    if (overrides.ignoreDateSettings)
                      'Datumssperren deaktiviert',
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: rootItems.isEmpty
                  ? const Center(child: Text('No media items found'))
                  : OrientationBuilder(
                builder: (context, orientation) {
                  final prefs = di<SharedPreferencesWithCache>();
                  final crossAxisCount = orientation == Orientation.portrait
                      ? (prefs.getInt('grid_columns_portrait') ?? 2)
                      : (prefs.getInt('grid_columns_landscape') ?? 4);
                  return GridView.builder(
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
                      final constraintResult =
                          _evalWithAncestors(item, allDocuments);
                      final itemDurationMs = item is MediaItem
                          ? item.media.fold<int>(
                              0, (s, t) => s + t.durationMs)
                          : 0;
                      final cannotFinish = _cannotFinishWithGrace(
                          item, allDocuments, itemDurationMs);

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
                                      'Jetzt nicht verfügbar',
                                ),
                              ),
                            );
                            return;
                          }
                          if (item is MediaFolder) {
                            setState(() {
                              parentNodeId = item.id;
                            });
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
