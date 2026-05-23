import 'package:dart_couch/dart_couch.dart';
import 'package:dart_mappable/dart_mappable.dart';

part 'play_log.mapper.dart';

// ── Play log event ───────────────────────────────────────────────────────────

@MappableClass()
class PlayLogEvent with PlayLogEventMappable {
  @MappableField(key: 'started_at')
  final String startedAt;

  @MappableField(key: 'duration_ms')
  final int durationMs;

  @MappableField(key: 'play_count_fraction')
  final double playCountFraction;

  const PlayLogEvent({
    required this.startedAt,
    this.durationMs = 0,
    this.playCountFraction = 0.0,
  });
}

// ── Play log item ─────────────────────────────────────────────────────────────

/// Groups the events for one MediaItem, storing the item title once at the
/// item level rather than repeating it on every event.
@MappableClass()
class PlayLogItem with PlayLogItemMappable {
  final String title;
  final List<PlayLogEvent> events;

  const PlayLogItem({
    this.title = '',
    this.events = const [],
  });
}

// ── Play log document ────────────────────────────────────────────────────────

/// Per-device play log stored as a single replicated CouchDB document.
///
/// Document ID: `playlog-<deviceUuid>`
///
/// Contains recent play events grouped by item ID. Events older than 31 days
/// are archived into [PlayLogArchive] on startup and pruned from this document.
@MappableClass(discriminatorValue: 'play_log', ignoreNull: true)
class PlayLog extends CouchDocumentBase with PlayLogMappable {
  static String docIdFor(String deviceUuid) => 'playlog-$deviceUuid';

  @MappableField(key: 'device_id')
  final String deviceId;

  /// Play events grouped by MediaItem ID.
  final Map<String, PlayLogItem> items;

  PlayLog({
    required this.deviceId,
    this.items = const {},
    super.id,
    super.rev,
    super.attachments,
    super.deleted,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });
}

// ── Play log archive ─────────────────────────────────────────────────────────

@MappableClass()
class PlayLogArchiveItem with PlayLogArchiveItemMappable {
  @MappableField(key: 'total_play_count')
  final int totalPlayCount;

  @MappableField(key: 'total_duration_ms')
  final int totalDurationMs;

  @MappableField(key: 'first_played')
  final String firstPlayed;

  @MappableField(key: 'last_played')
  final String lastPlayed;

  final String title;

  /// Monthly buckets for trend analysis. Key format: "YYYY-MM".
  final Map<String, PlayLogMonthlyBucket> monthly;

  const PlayLogArchiveItem({
    this.totalPlayCount = 0,
    this.totalDurationMs = 0,
    this.firstPlayed = '',
    this.lastPlayed = '',
    this.title = '',
    this.monthly = const {},
  });
}

@MappableClass()
class PlayLogMonthlyBucket with PlayLogMonthlyBucketMappable {
  @MappableField(key: 'play_count')
  final int playCount;

  @MappableField(key: 'duration_ms')
  final int durationMs;

  const PlayLogMonthlyBucket({
    this.playCount = 0,
    this.durationMs = 0,
  });
}

/// Per-device archive of aggregated play statistics.
///
/// Document ID: `playlog_archive-<deviceUuid>`
///
/// Entries older than 31 days in [PlayLog] are aggregated here with per-item
/// totals and monthly buckets, then pruned from the play log.
@MappableClass(discriminatorValue: 'play_log_archive', ignoreNull: true)
class PlayLogArchive extends CouchDocumentBase with PlayLogArchiveMappable {
  static String docIdFor(String deviceUuid) => 'playlog_archive-$deviceUuid';

  @MappableField(key: 'device_id')
  final String deviceId;

  /// Aggregated stats per MediaItem ID.
  final Map<String, PlayLogArchiveItem> items;

  PlayLogArchive({
    required this.deviceId,
    this.items = const {},
    super.id,
    super.rev,
    super.attachments,
    super.deleted,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });
}

// ── Device identity ──────────────────────────────────────────────────────────

/// Per-device identity document stored in the replicated database.
///
/// Document ID: `device-id-<uuid>`
@MappableClass(discriminatorValue: 'device_identity', ignoreNull: true)
class DeviceIdentity extends CouchDocumentBase with DeviceIdentityMappable {
  static String docIdFor(String uuid) => 'device-id-$uuid';

  final String uuid;

  @MappableField(key: 'kid_name')
  final String kidName;

  DeviceIdentity({
    required this.uuid,
    required this.kidName,
    super.id,
    super.rev,
    super.attachments,
    super.deleted,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });
}
