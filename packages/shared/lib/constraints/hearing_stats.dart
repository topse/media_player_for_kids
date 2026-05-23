import 'package:dart_mappable/dart_mappable.dart';

part 'hearing_stats.mapper.dart';

@MappableClass()
class PlayEvent with PlayEventMappable {
  @MappableField(key: 'started_at')
  final String startedAt;

  /// Actual playback duration in milliseconds (not wall-clock time).
  @MappableField(key: 'duration_ms')
  final int durationMs;

  /// Fraction of the total item heard (0.0 to 1.0+). Computed as
  /// accumulatedPlayMs / totalItemDurationMs at recording time.
  @MappableField(key: 'play_count_fraction')
  final double playCountFraction;

  const PlayEvent({
    required this.startedAt,
    this.durationMs = 0,
    this.playCountFraction = 0.0,
  });
}

@MappableClass()
class HearingStats with HearingStatsMappable {
  static const String docIdPrefix = '_local/hearing_stats/';
  static String docIdFor(String itemId) => '$docIdPrefix$itemId';

  @MappableField(key: 'item_id')
  final String itemId;

  /// Human-readable title of the MediaItem at recording time. Stored once at
  /// item level and updated on each play start (survives item rename/deletion).
  final String title;

  @MappableField(key: 'play_events')
  final List<PlayEvent> playEvents;

  const HearingStats({
    required this.itemId,
    this.title = '',
    this.playEvents = const [],
  });
}
