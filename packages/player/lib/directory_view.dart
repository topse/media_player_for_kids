import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:player/media_player_page.dart';
import 'package:player/play_position_service.dart';
import 'package:player/widgets/media_app_bar.dart';
import 'package:shared/models/datatypes.dart';
import 'package:shared/shared.dart' show MediaBaseIcon, buildEffectiveIsNewMap;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('DirectoryView');

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
      if (dMs == null) return null;
      totalMs += dMs;
      if (i < trackIndex) elapsedMs += dMs;
      if (i == trackIndex) elapsedMs += seconds * 1000;
    }
    if (totalMs == 0) return null;
    return (elapsedMs / totalMs).clamp(0.0, 1.0);
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
    di<PlayPositionService>().removeListener(_onPlayPositionsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _visibilityTimer?.cancel();
    _dbSubscription?.cancel();
    super.dispose();
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
    final effectivelyNewById = buildEffectiveIsNewMap(
      allDocuments,
      includeInTraversal: (media) => media.isVisibleAt(now),
    );
    final rootItems =
        entries!
            .where((e) => e.parent == parentNodeId && e.isVisibleAt(now))
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
      ),
      body: SafeArea(
        top: false,
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

                      return _MediaGridItem(
                        key: ValueKey(item.id),
                        item: item,
                        allDocuments: allDocuments,
                        itemNumber: showItemNumbering ? index + 1 : null,
                        progress: progress,
                        isNew: effectivelyNewById[item.id] ?? false,
                        onTap: () {
                          if (item is MediaFolder) {
                            setState(() {
                              parentNodeId = item.id;
                            });
                          } else if (item is MediaItem) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MediaPlayerPage(item: item),
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

  const _MediaGridItem({
    super.key,
    required this.item,
    required this.allDocuments,
    this.onTap,
    this.itemNumber,
    this.progress,
    this.isNew = false,
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
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress!,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(height: 2, color: Colors.green[900]),
                                Container(height: 2, color: Colors.green),
                              ],
                            ),
                          ),
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
