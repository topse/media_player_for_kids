import 'dart:async';
import 'dart:convert';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

// ── Value type ───────────────────────────────────────────────────────────────

/// Aggregated play statistics for a single MediaItem.
class ItemStats {
  final double playCount;
  final int durationMs;

  const ItemStats({required this.playCount, required this.durationMs});

  const ItemStats.zero() : playCount = 0, durationMs = 0;

  bool get isEmpty => playCount == 0 && durationMs == 0;

  ItemStats operator +(ItemStats other) => ItemStats(
    playCount: playCount + other.playCount,
    durationMs: durationMs + other.durationMs,
  );

  /// Returns a compact human-readable string, e.g. "3.0× · 1h 24m".
  /// Returns an empty string when [isEmpty].
  String format() {
    if (isEmpty) return '';
    final countStr = '${playCount.toStringAsFixed(1)}×';
    final dur = formatDuration();
    return dur.isEmpty ? countStr : '$countStr · $dur';
  }

  /// Returns just the play-count portion, e.g. "3.0×".
  String formatCount() => '${playCount.toStringAsFixed(1)}×';

  /// Returns just the duration portion, e.g. "1h 24m", or empty string.
  String formatDuration() {
    if (durationMs == 0) return '';
    final totalSeconds = durationMs ~/ 1000;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : m > 0
        ? '${m}m ${s.toString().padLeft(2, '0')}s'
        : '${s}s';
  }
}

// ── Device record ─────────────────────────────────────────────────────────────

/// Identity of a player device known to the companion.
typedef DeviceInfo = ({String uuid, String kidName});

// ── Service ───────────────────────────────────────────────────────────────────

/// Aggregates hearing statistics from per-device [PlayLog] and
/// [PlayLogArchive] documents and exposes them as a reactive flat map.
///
/// Call [init] once after the [DartCouchDb] singleton is registered, then
/// register this class with the DI container and consume it via
/// [ChangeNotifier] listeners (or [watch_it]'s [WatchIt]).
///
/// [stats] contains the combined play count + duration for each MediaItem ID.
/// Recursive folder aggregation is intentionally left to the UI layer so that
/// this service stays narrowly focused and easily extensible.
class HearingStatsService extends ChangeNotifier {
  final List<DeviceInfo> _devices = [];
  final Map<String, PlayLog> _liveLogs = {};
  final Map<String, PlayLogArchive> _archives = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Map<String, ItemStats> _stats = const {};

  // ── Public state ────────────────────────────────────────────────────────────

  /// All known player devices, populated after [init].
  List<DeviceInfo> get devices => List.unmodifiable(_devices);

  /// Currently selected device UUID, or `null` to aggregate all devices.
  String? _selectedDeviceId;
  String? get selectedDeviceId => _selectedDeviceId;
  set selectedDeviceId(String? value) {
    if (_selectedDeviceId == value) return;
    _selectedDeviceId = value;
    _recompute();
  }

  /// Flat map from MediaItem ID → aggregated stats for the selected device
  /// (or all devices when [selectedDeviceId] is `null`).
  Map<String, ItemStats> get stats => _stats;

  // ── Initialisation ───────────────────────────────────────────────────────────

  /// Discovers all devices and subscribes to their log documents.
  /// Must be called once, after the [DartCouchDb] is ready.
  Future<void> init(DartCouchDb db) async {
    // Discover all device-id- documents.
    final result = await db.allDocs(
      startkey: jsonEncode('device-id-'),
      endkey: jsonEncode('device-id-\u{ffff}'),
      includeDocs: true,
    );

    for (final row in result.rows) {
      final doc = row.doc;
      if (doc is! DeviceIdentity) continue;
      final uuid = doc.uuid;
      _devices.add((uuid: uuid, kidName: doc.kidName));
      _subscribeToDevice(db, uuid);
    }

    _recompute();
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _subscribeToDevice(DartCouchDb db, String uuid) {
    // Live log
    _subscriptions.add(
      db.useDoc(PlayLog.docIdFor(uuid)).listen((doc) {
        if (doc is PlayLog) {
          _liveLogs[uuid] = doc;
        } else {
          _liveLogs.remove(uuid);
        }
        _recompute();
      }),
    );

    // Archive
    _subscriptions.add(
      db.useDoc(PlayLogArchive.docIdFor(uuid)).listen((doc) {
        if (doc is PlayLogArchive) {
          _archives[uuid] = doc;
        } else {
          _archives.remove(uuid);
        }
        _recompute();
      }),
    );
  }

  void _recompute() {
    final uuids = _selectedDeviceId != null
        ? [_selectedDeviceId!]
        : _devices.map((d) => d.uuid).toList();

    final result = <String, ItemStats>{};

    for (final uuid in uuids) {
      // Archive totals
      final archive = _archives[uuid];
      if (archive != null) {
        for (final entry in archive.items.entries) {
          final existing = result[entry.key] ?? const ItemStats.zero();
          result[entry.key] =
              existing +
              ItemStats(
                playCount: entry.value.totalPlayCount.toDouble(),
                durationMs: entry.value.totalDurationMs,
              );
        }
      }

      // Live log (recent 31 days — events not yet archived)
      final live = _liveLogs[uuid];
      if (live != null) {
        for (final entry in live.items.entries) {
          final existing = result[entry.key] ?? const ItemStats.zero();
          final liveCount = entry.value.events.fold(
            0.0,
            (sum, e) => sum + e.playCountFraction,
          );
          final liveDuration = entry.value.events.fold(
            0,
            (sum, e) => sum + e.durationMs,
          );
          result[entry.key] =
              existing +
              ItemStats(playCount: liveCount, durationMs: liveDuration);
        }
      }
    }

    _stats = result;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

// ── UI helper: recursive folder aggregation ───────────────────────────────────

/// Computes the sum of [ItemStats] for [doc] and all its descendants.
///
/// For a [MediaItem], returns the direct stats from [hearingStats].
/// For a [MediaFolder], recursively sums stats for all descendant items.
/// Returns [ItemStats.zero] when [hearingStats] is null or there is no data.
ItemStats subtreeHearingStats(
  MediaBase doc,
  Map<String, ItemStats>? hearingStats,
  Map<String, MediaBase> allDocuments,
) {
  if (hearingStats == null) return const ItemStats.zero();
  if (doc is MediaItem) {
    return hearingStats[doc.id] ?? const ItemStats.zero();
  }
  // MediaFolder: sum all descendants
  var total = const ItemStats.zero();
  for (final child in allDocuments.values) {
    if (child is! MediaItem) continue;
    // Check if this item is a descendant of doc by walking the parent chain.
    if (_isDescendantOf(child, doc.id!, allDocuments)) {
      total = total + (hearingStats[child.id] ?? const ItemStats.zero());
    }
  }
  return total;
}

bool _isDescendantOf(
  MediaBase item,
  String folderId,
  Map<String, MediaBase> allDocuments,
) {
  String? current = item.parent;
  // Guard against cycles (shouldn't happen but be safe)
  final visited = <String>{};
  while (current != null && !visited.contains(current)) {
    if (current == folderId) return true;
    visited.add(current);
    current = allDocuments[current]?.parent;
  }
  return false;
}

// ── Widget ────────────────────────────────────────────────────────────────────

/// Compact teal chip showing play count and optional duration for a media item.
class StatsChip extends StatelessWidget {
  final ItemStats stats;

  const StatsChip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final countStr = stats.formatCount();
    final durStr = stats.formatDuration();
    return Tooltip(
      message:
          'Plays: $countStr${durStr.isNotEmpty ? '  Duration: $durStr' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.15),
          border: Border.all(color: Colors.teal.shade300, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hearing, size: 11, color: Colors.teal.shade700),
            const SizedBox(width: 3),
            Text(
              durStr.isNotEmpty ? '$countStr  $durStr' : countStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
