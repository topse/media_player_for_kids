// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'hearing_stats.dart';

class PlayEventMapper extends ClassMapperBase<PlayEvent> {
  PlayEventMapper._();

  static PlayEventMapper? _instance;
  static PlayEventMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayEventMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PlayEvent';

  static String _$startedAt(PlayEvent v) => v.startedAt;
  static const Field<PlayEvent, String> _f$startedAt = Field(
    'startedAt',
    _$startedAt,
    key: r'started_at',
  );
  static int _$durationMs(PlayEvent v) => v.durationMs;
  static const Field<PlayEvent, int> _f$durationMs = Field(
    'durationMs',
    _$durationMs,
    key: r'duration_ms',
    opt: true,
    def: 0,
  );
  static double _$playCountFraction(PlayEvent v) => v.playCountFraction;
  static const Field<PlayEvent, double> _f$playCountFraction = Field(
    'playCountFraction',
    _$playCountFraction,
    key: r'play_count_fraction',
    opt: true,
    def: 0.0,
  );

  @override
  final MappableFields<PlayEvent> fields = const {
    #startedAt: _f$startedAt,
    #durationMs: _f$durationMs,
    #playCountFraction: _f$playCountFraction,
  };

  static PlayEvent _instantiate(DecodingData data) {
    return PlayEvent(
      startedAt: data.dec(_f$startedAt),
      durationMs: data.dec(_f$durationMs),
      playCountFraction: data.dec(_f$playCountFraction),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayEvent fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayEvent>(map);
  }

  static PlayEvent fromJson(String json) {
    return ensureInitialized().decodeJson<PlayEvent>(json);
  }
}

mixin PlayEventMappable {
  String toJson() {
    return PlayEventMapper.ensureInitialized().encodeJson<PlayEvent>(
      this as PlayEvent,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayEventMapper.ensureInitialized().encodeMap<PlayEvent>(
      this as PlayEvent,
    );
  }

  PlayEventCopyWith<PlayEvent, PlayEvent, PlayEvent> get copyWith =>
      _PlayEventCopyWithImpl<PlayEvent, PlayEvent>(
        this as PlayEvent,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayEventMapper.ensureInitialized().stringifyValue(
      this as PlayEvent,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayEventMapper.ensureInitialized().equalsValue(
      this as PlayEvent,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayEventMapper.ensureInitialized().hashValue(this as PlayEvent);
  }
}

extension PlayEventValueCopy<$R, $Out> on ObjectCopyWith<$R, PlayEvent, $Out> {
  PlayEventCopyWith<$R, PlayEvent, $Out> get $asPlayEvent =>
      $base.as((v, t, t2) => _PlayEventCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayEventCopyWith<$R, $In extends PlayEvent, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? startedAt, int? durationMs, double? playCountFraction});
  PlayEventCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayEventCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayEvent, $Out>
    implements PlayEventCopyWith<$R, PlayEvent, $Out> {
  _PlayEventCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayEvent> $mapper =
      PlayEventMapper.ensureInitialized();
  @override
  $R call({String? startedAt, int? durationMs, double? playCountFraction}) =>
      $apply(
        FieldCopyWithData({
          if (startedAt != null) #startedAt: startedAt,
          if (durationMs != null) #durationMs: durationMs,
          if (playCountFraction != null) #playCountFraction: playCountFraction,
        }),
      );
  @override
  PlayEvent $make(CopyWithData data) => PlayEvent(
    startedAt: data.get(#startedAt, or: $value.startedAt),
    durationMs: data.get(#durationMs, or: $value.durationMs),
    playCountFraction: data.get(
      #playCountFraction,
      or: $value.playCountFraction,
    ),
  );

  @override
  PlayEventCopyWith<$R2, PlayEvent, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayEventCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class HearingStatsMapper extends ClassMapperBase<HearingStats> {
  HearingStatsMapper._();

  static HearingStatsMapper? _instance;
  static HearingStatsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HearingStatsMapper._());
      PlayEventMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HearingStats';

  static String _$itemId(HearingStats v) => v.itemId;
  static const Field<HearingStats, String> _f$itemId = Field(
    'itemId',
    _$itemId,
    key: r'item_id',
  );
  static String _$title(HearingStats v) => v.title;
  static const Field<HearingStats, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
    def: '',
  );
  static List<PlayEvent> _$playEvents(HearingStats v) => v.playEvents;
  static const Field<HearingStats, List<PlayEvent>> _f$playEvents = Field(
    'playEvents',
    _$playEvents,
    key: r'play_events',
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<HearingStats> fields = const {
    #itemId: _f$itemId,
    #title: _f$title,
    #playEvents: _f$playEvents,
  };

  static HearingStats _instantiate(DecodingData data) {
    return HearingStats(
      itemId: data.dec(_f$itemId),
      title: data.dec(_f$title),
      playEvents: data.dec(_f$playEvents),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HearingStats fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HearingStats>(map);
  }

  static HearingStats fromJson(String json) {
    return ensureInitialized().decodeJson<HearingStats>(json);
  }
}

mixin HearingStatsMappable {
  String toJson() {
    return HearingStatsMapper.ensureInitialized().encodeJson<HearingStats>(
      this as HearingStats,
    );
  }

  Map<String, dynamic> toMap() {
    return HearingStatsMapper.ensureInitialized().encodeMap<HearingStats>(
      this as HearingStats,
    );
  }

  HearingStatsCopyWith<HearingStats, HearingStats, HearingStats> get copyWith =>
      _HearingStatsCopyWithImpl<HearingStats, HearingStats>(
        this as HearingStats,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return HearingStatsMapper.ensureInitialized().stringifyValue(
      this as HearingStats,
    );
  }

  @override
  bool operator ==(Object other) {
    return HearingStatsMapper.ensureInitialized().equalsValue(
      this as HearingStats,
      other,
    );
  }

  @override
  int get hashCode {
    return HearingStatsMapper.ensureInitialized().hashValue(
      this as HearingStats,
    );
  }
}

extension HearingStatsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, HearingStats, $Out> {
  HearingStatsCopyWith<$R, HearingStats, $Out> get $asHearingStats =>
      $base.as((v, t, t2) => _HearingStatsCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class HearingStatsCopyWith<$R, $In extends HearingStats, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, PlayEvent, PlayEventCopyWith<$R, PlayEvent, PlayEvent>>
  get playEvents;
  $R call({String? itemId, String? title, List<PlayEvent>? playEvents});
  HearingStatsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _HearingStatsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, HearingStats, $Out>
    implements HearingStatsCopyWith<$R, HearingStats, $Out> {
  _HearingStatsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<HearingStats> $mapper =
      HearingStatsMapper.ensureInitialized();
  @override
  ListCopyWith<$R, PlayEvent, PlayEventCopyWith<$R, PlayEvent, PlayEvent>>
  get playEvents => ListCopyWith(
    $value.playEvents,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(playEvents: v),
  );
  @override
  $R call({String? itemId, String? title, List<PlayEvent>? playEvents}) =>
      $apply(
        FieldCopyWithData({
          if (itemId != null) #itemId: itemId,
          if (title != null) #title: title,
          if (playEvents != null) #playEvents: playEvents,
        }),
      );
  @override
  HearingStats $make(CopyWithData data) => HearingStats(
    itemId: data.get(#itemId, or: $value.itemId),
    title: data.get(#title, or: $value.title),
    playEvents: data.get(#playEvents, or: $value.playEvents),
  );

  @override
  HearingStatsCopyWith<$R2, HearingStats, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _HearingStatsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

