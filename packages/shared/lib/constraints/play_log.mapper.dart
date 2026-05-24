// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'play_log.dart';

class PlayLogEventMapper extends ClassMapperBase<PlayLogEvent> {
  PlayLogEventMapper._();

  static PlayLogEventMapper? _instance;
  static PlayLogEventMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogEventMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLogEvent';

  static String _$startedAt(PlayLogEvent v) => v.startedAt;
  static const Field<PlayLogEvent, String> _f$startedAt = Field(
    'startedAt',
    _$startedAt,
    key: r'started_at',
  );
  static int _$durationMs(PlayLogEvent v) => v.durationMs;
  static const Field<PlayLogEvent, int> _f$durationMs = Field(
    'durationMs',
    _$durationMs,
    key: r'duration_ms',
    opt: true,
    def: 0,
  );
  static double _$playCountFraction(PlayLogEvent v) => v.playCountFraction;
  static const Field<PlayLogEvent, double> _f$playCountFraction = Field(
    'playCountFraction',
    _$playCountFraction,
    key: r'play_count_fraction',
    opt: true,
    def: 0.0,
  );

  @override
  final MappableFields<PlayLogEvent> fields = const {
    #startedAt: _f$startedAt,
    #durationMs: _f$durationMs,
    #playCountFraction: _f$playCountFraction,
  };

  static PlayLogEvent _instantiate(DecodingData data) {
    return PlayLogEvent(
      startedAt: data.dec(_f$startedAt),
      durationMs: data.dec(_f$durationMs),
      playCountFraction: data.dec(_f$playCountFraction),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLogEvent fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLogEvent>(map);
  }

  static PlayLogEvent fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLogEvent>(json);
  }
}

mixin PlayLogEventMappable {
  String toJson() {
    return PlayLogEventMapper.ensureInitialized().encodeJson<PlayLogEvent>(
      this as PlayLogEvent,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayLogEventMapper.ensureInitialized().encodeMap<PlayLogEvent>(
      this as PlayLogEvent,
    );
  }

  PlayLogEventCopyWith<PlayLogEvent, PlayLogEvent, PlayLogEvent> get copyWith =>
      _PlayLogEventCopyWithImpl<PlayLogEvent, PlayLogEvent>(
        this as PlayLogEvent,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayLogEventMapper.ensureInitialized().stringifyValue(
      this as PlayLogEvent,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayLogEventMapper.ensureInitialized().equalsValue(
      this as PlayLogEvent,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogEventMapper.ensureInitialized().hashValue(
      this as PlayLogEvent,
    );
  }
}

extension PlayLogEventValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayLogEvent, $Out> {
  PlayLogEventCopyWith<$R, PlayLogEvent, $Out> get $asPlayLogEvent =>
      $base.as((v, t, t2) => _PlayLogEventCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayLogEventCopyWith<$R, $In extends PlayLogEvent, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? startedAt, int? durationMs, double? playCountFraction});
  PlayLogEventCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayLogEventCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLogEvent, $Out>
    implements PlayLogEventCopyWith<$R, PlayLogEvent, $Out> {
  _PlayLogEventCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLogEvent> $mapper =
      PlayLogEventMapper.ensureInitialized();
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
  PlayLogEvent $make(CopyWithData data) => PlayLogEvent(
    startedAt: data.get(#startedAt, or: $value.startedAt),
    durationMs: data.get(#durationMs, or: $value.durationMs),
    playCountFraction: data.get(
      #playCountFraction,
      or: $value.playCountFraction,
    ),
  );

  @override
  PlayLogEventCopyWith<$R2, PlayLogEvent, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayLogEventCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayLogItemMapper extends ClassMapperBase<PlayLogItem> {
  PlayLogItemMapper._();

  static PlayLogItemMapper? _instance;
  static PlayLogItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogItemMapper._());
      PlayLogEventMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLogItem';

  static String _$title(PlayLogItem v) => v.title;
  static const Field<PlayLogItem, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
    def: '',
  );
  static List<PlayLogEvent> _$events(PlayLogItem v) => v.events;
  static const Field<PlayLogItem, List<PlayLogEvent>> _f$events = Field(
    'events',
    _$events,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<PlayLogItem> fields = const {
    #title: _f$title,
    #events: _f$events,
  };

  static PlayLogItem _instantiate(DecodingData data) {
    return PlayLogItem(title: data.dec(_f$title), events: data.dec(_f$events));
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLogItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLogItem>(map);
  }

  static PlayLogItem fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLogItem>(json);
  }
}

mixin PlayLogItemMappable {
  String toJson() {
    return PlayLogItemMapper.ensureInitialized().encodeJson<PlayLogItem>(
      this as PlayLogItem,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayLogItemMapper.ensureInitialized().encodeMap<PlayLogItem>(
      this as PlayLogItem,
    );
  }

  PlayLogItemCopyWith<PlayLogItem, PlayLogItem, PlayLogItem> get copyWith =>
      _PlayLogItemCopyWithImpl<PlayLogItem, PlayLogItem>(
        this as PlayLogItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayLogItemMapper.ensureInitialized().stringifyValue(
      this as PlayLogItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayLogItemMapper.ensureInitialized().equalsValue(
      this as PlayLogItem,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogItemMapper.ensureInitialized().hashValue(this as PlayLogItem);
  }
}

extension PlayLogItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayLogItem, $Out> {
  PlayLogItemCopyWith<$R, PlayLogItem, $Out> get $asPlayLogItem =>
      $base.as((v, t, t2) => _PlayLogItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayLogItemCopyWith<$R, $In extends PlayLogItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    PlayLogEvent,
    PlayLogEventCopyWith<$R, PlayLogEvent, PlayLogEvent>
  >
  get events;
  $R call({String? title, List<PlayLogEvent>? events});
  PlayLogItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayLogItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLogItem, $Out>
    implements PlayLogItemCopyWith<$R, PlayLogItem, $Out> {
  _PlayLogItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLogItem> $mapper =
      PlayLogItemMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    PlayLogEvent,
    PlayLogEventCopyWith<$R, PlayLogEvent, PlayLogEvent>
  >
  get events => ListCopyWith(
    $value.events,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(events: v),
  );
  @override
  $R call({String? title, List<PlayLogEvent>? events}) => $apply(
    FieldCopyWithData({
      if (title != null) #title: title,
      if (events != null) #events: events,
    }),
  );
  @override
  PlayLogItem $make(CopyWithData data) => PlayLogItem(
    title: data.get(#title, or: $value.title),
    events: data.get(#events, or: $value.events),
  );

  @override
  PlayLogItemCopyWith<$R2, PlayLogItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayLogItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayLogMapper extends SubClassMapperBase<PlayLog> {
  PlayLogMapper._();

  static PlayLogMapper? _instance;
  static PlayLogMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      PlayLogItemMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLog';

  static String _$deviceId(PlayLog v) => v.deviceId;
  static const Field<PlayLog, String> _f$deviceId = Field(
    'deviceId',
    _$deviceId,
    key: r'device_id',
  );
  static Map<String, PlayLogItem> _$items(PlayLog v) => v.items;
  static const Field<PlayLog, Map<String, PlayLogItem>> _f$items = Field(
    'items',
    _$items,
    opt: true,
    def: const {},
  );
  static String? _$id(PlayLog v) => v.id;
  static const Field<PlayLog, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static String? _$rev(PlayLog v) => v.rev;
  static const Field<PlayLog, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(PlayLog v) => v.attachments;
  static const Field<PlayLog, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(PlayLog v) => v.deleted;
  static const Field<PlayLog, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static Revisions? _$revisions(PlayLog v) => v.revisions;
  static const Field<PlayLog, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(PlayLog v) => v.revsInfo;
  static const Field<PlayLog, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(PlayLog v) => v.unmappedProps;
  static const Field<PlayLog, Map<String, dynamic>> _f$unmappedProps = Field(
    'unmappedProps',
    _$unmappedProps,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<PlayLog> fields = const {
    #deviceId: _f$deviceId,
    #items: _f$items,
    #id: _f$id,
    #rev: _f$rev,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = 'play_log';
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static PlayLog _instantiate(DecodingData data) {
    return PlayLog(
      deviceId: data.dec(_f$deviceId),
      items: data.dec(_f$items),
      id: data.dec(_f$id),
      rev: data.dec(_f$rev),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLog fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLog>(map);
  }

  static PlayLog fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLog>(json);
  }
}

mixin PlayLogMappable {
  String toJson() {
    return PlayLogMapper.ensureInitialized().encodeJson<PlayLog>(
      this as PlayLog,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayLogMapper.ensureInitialized().encodeMap<PlayLog>(
      this as PlayLog,
    );
  }

  PlayLogCopyWith<PlayLog, PlayLog, PlayLog> get copyWith =>
      _PlayLogCopyWithImpl<PlayLog, PlayLog>(
        this as PlayLog,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayLogMapper.ensureInitialized().stringifyValue(this as PlayLog);
  }

  @override
  bool operator ==(Object other) {
    return PlayLogMapper.ensureInitialized().equalsValue(
      this as PlayLog,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogMapper.ensureInitialized().hashValue(this as PlayLog);
  }
}

extension PlayLogValueCopy<$R, $Out> on ObjectCopyWith<$R, PlayLog, $Out> {
  PlayLogCopyWith<$R, PlayLog, $Out> get $asPlayLog =>
      $base.as((v, t, t2) => _PlayLogCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayLogCopyWith<$R, $In extends PlayLog, $Out>
    implements CouchDocumentBaseCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    PlayLogItem,
    PlayLogItemCopyWith<$R, PlayLogItem, PlayLogItem>
  >
  get items;
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions;
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps;
  @override
  $R call({
    String? deviceId,
    Map<String, PlayLogItem>? items,
    String? id,
    String? rev,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  PlayLogCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayLogCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLog, $Out>
    implements PlayLogCopyWith<$R, PlayLog, $Out> {
  _PlayLogCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLog> $mapper =
      PlayLogMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    PlayLogItem,
    PlayLogItemCopyWith<$R, PlayLogItem, PlayLogItem>
  >
  get items => MapCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments => $value.attachments != null
      ? MapCopyWith(
          $value.attachments!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(attachments: v),
        )
      : null;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions =>
      $value.revisions?.copyWith.$chain((v) => call(revisions: v));
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo => $value.revsInfo != null
      ? ListCopyWith(
          $value.revsInfo!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(revsInfo: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps => MapCopyWith(
    $value.unmappedProps,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unmappedProps: v),
  );
  @override
  $R call({
    String? deviceId,
    Map<String, PlayLogItem>? items,
    Object? id = $none,
    Object? rev = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (deviceId != null) #deviceId: deviceId,
      if (items != null) #items: items,
      if (id != $none) #id: id,
      if (rev != $none) #rev: rev,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  PlayLog $make(CopyWithData data) => PlayLog(
    deviceId: data.get(#deviceId, or: $value.deviceId),
    items: data.get(#items, or: $value.items),
    id: data.get(#id, or: $value.id),
    rev: data.get(#rev, or: $value.rev),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  PlayLogCopyWith<$R2, PlayLog, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PlayLogCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayLogArchiveItemMapper extends ClassMapperBase<PlayLogArchiveItem> {
  PlayLogArchiveItemMapper._();

  static PlayLogArchiveItemMapper? _instance;
  static PlayLogArchiveItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogArchiveItemMapper._());
      PlayLogMonthlyBucketMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLogArchiveItem';

  static int _$totalPlayCount(PlayLogArchiveItem v) => v.totalPlayCount;
  static const Field<PlayLogArchiveItem, int> _f$totalPlayCount = Field(
    'totalPlayCount',
    _$totalPlayCount,
    key: r'total_play_count',
    opt: true,
    def: 0,
  );
  static int _$totalDurationMs(PlayLogArchiveItem v) => v.totalDurationMs;
  static const Field<PlayLogArchiveItem, int> _f$totalDurationMs = Field(
    'totalDurationMs',
    _$totalDurationMs,
    key: r'total_duration_ms',
    opt: true,
    def: 0,
  );
  static String _$firstPlayed(PlayLogArchiveItem v) => v.firstPlayed;
  static const Field<PlayLogArchiveItem, String> _f$firstPlayed = Field(
    'firstPlayed',
    _$firstPlayed,
    key: r'first_played',
    opt: true,
    def: '',
  );
  static String _$lastPlayed(PlayLogArchiveItem v) => v.lastPlayed;
  static const Field<PlayLogArchiveItem, String> _f$lastPlayed = Field(
    'lastPlayed',
    _$lastPlayed,
    key: r'last_played',
    opt: true,
    def: '',
  );
  static String _$title(PlayLogArchiveItem v) => v.title;
  static const Field<PlayLogArchiveItem, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
    def: '',
  );
  static Map<String, PlayLogMonthlyBucket> _$monthly(PlayLogArchiveItem v) =>
      v.monthly;
  static const Field<PlayLogArchiveItem, Map<String, PlayLogMonthlyBucket>>
  _f$monthly = Field('monthly', _$monthly, opt: true, def: const {});

  @override
  final MappableFields<PlayLogArchiveItem> fields = const {
    #totalPlayCount: _f$totalPlayCount,
    #totalDurationMs: _f$totalDurationMs,
    #firstPlayed: _f$firstPlayed,
    #lastPlayed: _f$lastPlayed,
    #title: _f$title,
    #monthly: _f$monthly,
  };

  static PlayLogArchiveItem _instantiate(DecodingData data) {
    return PlayLogArchiveItem(
      totalPlayCount: data.dec(_f$totalPlayCount),
      totalDurationMs: data.dec(_f$totalDurationMs),
      firstPlayed: data.dec(_f$firstPlayed),
      lastPlayed: data.dec(_f$lastPlayed),
      title: data.dec(_f$title),
      monthly: data.dec(_f$monthly),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLogArchiveItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLogArchiveItem>(map);
  }

  static PlayLogArchiveItem fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLogArchiveItem>(json);
  }
}

mixin PlayLogArchiveItemMappable {
  String toJson() {
    return PlayLogArchiveItemMapper.ensureInitialized()
        .encodeJson<PlayLogArchiveItem>(this as PlayLogArchiveItem);
  }

  Map<String, dynamic> toMap() {
    return PlayLogArchiveItemMapper.ensureInitialized()
        .encodeMap<PlayLogArchiveItem>(this as PlayLogArchiveItem);
  }

  PlayLogArchiveItemCopyWith<
    PlayLogArchiveItem,
    PlayLogArchiveItem,
    PlayLogArchiveItem
  >
  get copyWith =>
      _PlayLogArchiveItemCopyWithImpl<PlayLogArchiveItem, PlayLogArchiveItem>(
        this as PlayLogArchiveItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayLogArchiveItemMapper.ensureInitialized().stringifyValue(
      this as PlayLogArchiveItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayLogArchiveItemMapper.ensureInitialized().equalsValue(
      this as PlayLogArchiveItem,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogArchiveItemMapper.ensureInitialized().hashValue(
      this as PlayLogArchiveItem,
    );
  }
}

extension PlayLogArchiveItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayLogArchiveItem, $Out> {
  PlayLogArchiveItemCopyWith<$R, PlayLogArchiveItem, $Out>
  get $asPlayLogArchiveItem => $base.as(
    (v, t, t2) => _PlayLogArchiveItemCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayLogArchiveItemCopyWith<
  $R,
  $In extends PlayLogArchiveItem,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    PlayLogMonthlyBucket,
    PlayLogMonthlyBucketCopyWith<$R, PlayLogMonthlyBucket, PlayLogMonthlyBucket>
  >
  get monthly;
  $R call({
    int? totalPlayCount,
    int? totalDurationMs,
    String? firstPlayed,
    String? lastPlayed,
    String? title,
    Map<String, PlayLogMonthlyBucket>? monthly,
  });
  PlayLogArchiveItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayLogArchiveItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLogArchiveItem, $Out>
    implements PlayLogArchiveItemCopyWith<$R, PlayLogArchiveItem, $Out> {
  _PlayLogArchiveItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLogArchiveItem> $mapper =
      PlayLogArchiveItemMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    PlayLogMonthlyBucket,
    PlayLogMonthlyBucketCopyWith<$R, PlayLogMonthlyBucket, PlayLogMonthlyBucket>
  >
  get monthly => MapCopyWith(
    $value.monthly,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(monthly: v),
  );
  @override
  $R call({
    int? totalPlayCount,
    int? totalDurationMs,
    String? firstPlayed,
    String? lastPlayed,
    String? title,
    Map<String, PlayLogMonthlyBucket>? monthly,
  }) => $apply(
    FieldCopyWithData({
      if (totalPlayCount != null) #totalPlayCount: totalPlayCount,
      if (totalDurationMs != null) #totalDurationMs: totalDurationMs,
      if (firstPlayed != null) #firstPlayed: firstPlayed,
      if (lastPlayed != null) #lastPlayed: lastPlayed,
      if (title != null) #title: title,
      if (monthly != null) #monthly: monthly,
    }),
  );
  @override
  PlayLogArchiveItem $make(CopyWithData data) => PlayLogArchiveItem(
    totalPlayCount: data.get(#totalPlayCount, or: $value.totalPlayCount),
    totalDurationMs: data.get(#totalDurationMs, or: $value.totalDurationMs),
    firstPlayed: data.get(#firstPlayed, or: $value.firstPlayed),
    lastPlayed: data.get(#lastPlayed, or: $value.lastPlayed),
    title: data.get(#title, or: $value.title),
    monthly: data.get(#monthly, or: $value.monthly),
  );

  @override
  PlayLogArchiveItemCopyWith<$R2, PlayLogArchiveItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayLogArchiveItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayLogMonthlyBucketMapper extends ClassMapperBase<PlayLogMonthlyBucket> {
  PlayLogMonthlyBucketMapper._();

  static PlayLogMonthlyBucketMapper? _instance;
  static PlayLogMonthlyBucketMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogMonthlyBucketMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLogMonthlyBucket';

  static int _$playCount(PlayLogMonthlyBucket v) => v.playCount;
  static const Field<PlayLogMonthlyBucket, int> _f$playCount = Field(
    'playCount',
    _$playCount,
    key: r'play_count',
    opt: true,
    def: 0,
  );
  static int _$durationMs(PlayLogMonthlyBucket v) => v.durationMs;
  static const Field<PlayLogMonthlyBucket, int> _f$durationMs = Field(
    'durationMs',
    _$durationMs,
    key: r'duration_ms',
    opt: true,
    def: 0,
  );

  @override
  final MappableFields<PlayLogMonthlyBucket> fields = const {
    #playCount: _f$playCount,
    #durationMs: _f$durationMs,
  };

  static PlayLogMonthlyBucket _instantiate(DecodingData data) {
    return PlayLogMonthlyBucket(
      playCount: data.dec(_f$playCount),
      durationMs: data.dec(_f$durationMs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLogMonthlyBucket fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLogMonthlyBucket>(map);
  }

  static PlayLogMonthlyBucket fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLogMonthlyBucket>(json);
  }
}

mixin PlayLogMonthlyBucketMappable {
  String toJson() {
    return PlayLogMonthlyBucketMapper.ensureInitialized()
        .encodeJson<PlayLogMonthlyBucket>(this as PlayLogMonthlyBucket);
  }

  Map<String, dynamic> toMap() {
    return PlayLogMonthlyBucketMapper.ensureInitialized()
        .encodeMap<PlayLogMonthlyBucket>(this as PlayLogMonthlyBucket);
  }

  PlayLogMonthlyBucketCopyWith<
    PlayLogMonthlyBucket,
    PlayLogMonthlyBucket,
    PlayLogMonthlyBucket
  >
  get copyWith =>
      _PlayLogMonthlyBucketCopyWithImpl<
        PlayLogMonthlyBucket,
        PlayLogMonthlyBucket
      >(this as PlayLogMonthlyBucket, $identity, $identity);
  @override
  String toString() {
    return PlayLogMonthlyBucketMapper.ensureInitialized().stringifyValue(
      this as PlayLogMonthlyBucket,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayLogMonthlyBucketMapper.ensureInitialized().equalsValue(
      this as PlayLogMonthlyBucket,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogMonthlyBucketMapper.ensureInitialized().hashValue(
      this as PlayLogMonthlyBucket,
    );
  }
}

extension PlayLogMonthlyBucketValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayLogMonthlyBucket, $Out> {
  PlayLogMonthlyBucketCopyWith<$R, PlayLogMonthlyBucket, $Out>
  get $asPlayLogMonthlyBucket => $base.as(
    (v, t, t2) => _PlayLogMonthlyBucketCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayLogMonthlyBucketCopyWith<
  $R,
  $In extends PlayLogMonthlyBucket,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? playCount, int? durationMs});
  PlayLogMonthlyBucketCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayLogMonthlyBucketCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLogMonthlyBucket, $Out>
    implements PlayLogMonthlyBucketCopyWith<$R, PlayLogMonthlyBucket, $Out> {
  _PlayLogMonthlyBucketCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLogMonthlyBucket> $mapper =
      PlayLogMonthlyBucketMapper.ensureInitialized();
  @override
  $R call({int? playCount, int? durationMs}) => $apply(
    FieldCopyWithData({
      if (playCount != null) #playCount: playCount,
      if (durationMs != null) #durationMs: durationMs,
    }),
  );
  @override
  PlayLogMonthlyBucket $make(CopyWithData data) => PlayLogMonthlyBucket(
    playCount: data.get(#playCount, or: $value.playCount),
    durationMs: data.get(#durationMs, or: $value.durationMs),
  );

  @override
  PlayLogMonthlyBucketCopyWith<$R2, PlayLogMonthlyBucket, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PlayLogMonthlyBucketCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayLogArchiveMapper extends SubClassMapperBase<PlayLogArchive> {
  PlayLogArchiveMapper._();

  static PlayLogArchiveMapper? _instance;
  static PlayLogArchiveMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayLogArchiveMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      PlayLogArchiveItemMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayLogArchive';

  static String _$deviceId(PlayLogArchive v) => v.deviceId;
  static const Field<PlayLogArchive, String> _f$deviceId = Field(
    'deviceId',
    _$deviceId,
    key: r'device_id',
  );
  static Map<String, PlayLogArchiveItem> _$items(PlayLogArchive v) => v.items;
  static const Field<PlayLogArchive, Map<String, PlayLogArchiveItem>> _f$items =
      Field('items', _$items, opt: true, def: const {});
  static String? _$id(PlayLogArchive v) => v.id;
  static const Field<PlayLogArchive, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static String? _$rev(PlayLogArchive v) => v.rev;
  static const Field<PlayLogArchive, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(PlayLogArchive v) =>
      v.attachments;
  static const Field<PlayLogArchive, Map<String, AttachmentInfo>>
  _f$attachments = Field(
    'attachments',
    _$attachments,
    key: r'_attachments',
    opt: true,
  );
  static bool _$deleted(PlayLogArchive v) => v.deleted;
  static const Field<PlayLogArchive, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static Revisions? _$revisions(PlayLogArchive v) => v.revisions;
  static const Field<PlayLogArchive, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(PlayLogArchive v) => v.revsInfo;
  static const Field<PlayLogArchive, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(PlayLogArchive v) =>
      v.unmappedProps;
  static const Field<PlayLogArchive, Map<String, dynamic>> _f$unmappedProps =
      Field('unmappedProps', _$unmappedProps, opt: true, def: const {});

  @override
  final MappableFields<PlayLogArchive> fields = const {
    #deviceId: _f$deviceId,
    #items: _f$items,
    #id: _f$id,
    #rev: _f$rev,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = 'play_log_archive';
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static PlayLogArchive _instantiate(DecodingData data) {
    return PlayLogArchive(
      deviceId: data.dec(_f$deviceId),
      items: data.dec(_f$items),
      id: data.dec(_f$id),
      rev: data.dec(_f$rev),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayLogArchive fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayLogArchive>(map);
  }

  static PlayLogArchive fromJson(String json) {
    return ensureInitialized().decodeJson<PlayLogArchive>(json);
  }
}

mixin PlayLogArchiveMappable {
  String toJson() {
    return PlayLogArchiveMapper.ensureInitialized().encodeJson<PlayLogArchive>(
      this as PlayLogArchive,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayLogArchiveMapper.ensureInitialized().encodeMap<PlayLogArchive>(
      this as PlayLogArchive,
    );
  }

  PlayLogArchiveCopyWith<PlayLogArchive, PlayLogArchive, PlayLogArchive>
  get copyWith => _PlayLogArchiveCopyWithImpl<PlayLogArchive, PlayLogArchive>(
    this as PlayLogArchive,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return PlayLogArchiveMapper.ensureInitialized().stringifyValue(
      this as PlayLogArchive,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayLogArchiveMapper.ensureInitialized().equalsValue(
      this as PlayLogArchive,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayLogArchiveMapper.ensureInitialized().hashValue(
      this as PlayLogArchive,
    );
  }
}

extension PlayLogArchiveValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayLogArchive, $Out> {
  PlayLogArchiveCopyWith<$R, PlayLogArchive, $Out> get $asPlayLogArchive =>
      $base.as((v, t, t2) => _PlayLogArchiveCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayLogArchiveCopyWith<$R, $In extends PlayLogArchive, $Out>
    implements CouchDocumentBaseCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    PlayLogArchiveItem,
    PlayLogArchiveItemCopyWith<$R, PlayLogArchiveItem, PlayLogArchiveItem>
  >
  get items;
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions;
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps;
  @override
  $R call({
    String? deviceId,
    Map<String, PlayLogArchiveItem>? items,
    String? id,
    String? rev,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  PlayLogArchiveCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayLogArchiveCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayLogArchive, $Out>
    implements PlayLogArchiveCopyWith<$R, PlayLogArchive, $Out> {
  _PlayLogArchiveCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayLogArchive> $mapper =
      PlayLogArchiveMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    PlayLogArchiveItem,
    PlayLogArchiveItemCopyWith<$R, PlayLogArchiveItem, PlayLogArchiveItem>
  >
  get items => MapCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments => $value.attachments != null
      ? MapCopyWith(
          $value.attachments!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(attachments: v),
        )
      : null;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions =>
      $value.revisions?.copyWith.$chain((v) => call(revisions: v));
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo => $value.revsInfo != null
      ? ListCopyWith(
          $value.revsInfo!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(revsInfo: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps => MapCopyWith(
    $value.unmappedProps,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unmappedProps: v),
  );
  @override
  $R call({
    String? deviceId,
    Map<String, PlayLogArchiveItem>? items,
    Object? id = $none,
    Object? rev = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (deviceId != null) #deviceId: deviceId,
      if (items != null) #items: items,
      if (id != $none) #id: id,
      if (rev != $none) #rev: rev,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  PlayLogArchive $make(CopyWithData data) => PlayLogArchive(
    deviceId: data.get(#deviceId, or: $value.deviceId),
    items: data.get(#items, or: $value.items),
    id: data.get(#id, or: $value.id),
    rev: data.get(#rev, or: $value.rev),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  PlayLogArchiveCopyWith<$R2, PlayLogArchive, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayLogArchiveCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayPositionPointMapper extends ClassMapperBase<PlayPositionPoint> {
  PlayPositionPointMapper._();

  static PlayPositionPointMapper? _instance;
  static PlayPositionPointMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayPositionPointMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PlayPositionPoint';

  static int _$track(PlayPositionPoint v) => v.track;
  static const Field<PlayPositionPoint, int> _f$track = Field('track', _$track);
  static int _$seconds(PlayPositionPoint v) => v.seconds;
  static const Field<PlayPositionPoint, int> _f$seconds = Field(
    'seconds',
    _$seconds,
  );

  @override
  final MappableFields<PlayPositionPoint> fields = const {
    #track: _f$track,
    #seconds: _f$seconds,
  };

  static PlayPositionPoint _instantiate(DecodingData data) {
    return PlayPositionPoint(
      track: data.dec(_f$track),
      seconds: data.dec(_f$seconds),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayPositionPoint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayPositionPoint>(map);
  }

  static PlayPositionPoint fromJson(String json) {
    return ensureInitialized().decodeJson<PlayPositionPoint>(json);
  }
}

mixin PlayPositionPointMappable {
  String toJson() {
    return PlayPositionPointMapper.ensureInitialized()
        .encodeJson<PlayPositionPoint>(this as PlayPositionPoint);
  }

  Map<String, dynamic> toMap() {
    return PlayPositionPointMapper.ensureInitialized()
        .encodeMap<PlayPositionPoint>(this as PlayPositionPoint);
  }

  PlayPositionPointCopyWith<
    PlayPositionPoint,
    PlayPositionPoint,
    PlayPositionPoint
  >
  get copyWith =>
      _PlayPositionPointCopyWithImpl<PlayPositionPoint, PlayPositionPoint>(
        this as PlayPositionPoint,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayPositionPointMapper.ensureInitialized().stringifyValue(
      this as PlayPositionPoint,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayPositionPointMapper.ensureInitialized().equalsValue(
      this as PlayPositionPoint,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayPositionPointMapper.ensureInitialized().hashValue(
      this as PlayPositionPoint,
    );
  }
}

extension PlayPositionPointValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayPositionPoint, $Out> {
  PlayPositionPointCopyWith<$R, PlayPositionPoint, $Out>
  get $asPlayPositionPoint => $base.as(
    (v, t, t2) => _PlayPositionPointCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayPositionPointCopyWith<
  $R,
  $In extends PlayPositionPoint,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? track, int? seconds});
  PlayPositionPointCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayPositionPointCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayPositionPoint, $Out>
    implements PlayPositionPointCopyWith<$R, PlayPositionPoint, $Out> {
  _PlayPositionPointCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayPositionPoint> $mapper =
      PlayPositionPointMapper.ensureInitialized();
  @override
  $R call({int? track, int? seconds}) => $apply(
    FieldCopyWithData({
      if (track != null) #track: track,
      if (seconds != null) #seconds: seconds,
    }),
  );
  @override
  PlayPositionPoint $make(CopyWithData data) => PlayPositionPoint(
    track: data.get(#track, or: $value.track),
    seconds: data.get(#seconds, or: $value.seconds),
  );

  @override
  PlayPositionPointCopyWith<$R2, PlayPositionPoint, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayPositionPointCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayPositionItemMapper extends ClassMapperBase<PlayPositionItem> {
  PlayPositionItemMapper._();

  static PlayPositionItemMapper? _instance;
  static PlayPositionItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayPositionItemMapper._());
      PlayPositionPointMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayPositionItem';

  static String _$title(PlayPositionItem v) => v.title;
  static const Field<PlayPositionItem, String> _f$title = Field(
    'title',
    _$title,
    opt: true,
    def: '',
  );
  static PlayPositionPoint? _$position(PlayPositionItem v) => v.position;
  static const Field<PlayPositionItem, PlayPositionPoint> _f$position = Field(
    'position',
    _$position,
    opt: true,
  );
  static bool _$done(PlayPositionItem v) => v.done;
  static const Field<PlayPositionItem, bool> _f$done = Field(
    'done',
    _$done,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<PlayPositionItem> fields = const {
    #title: _f$title,
    #position: _f$position,
    #done: _f$done,
  };
  @override
  final bool ignoreNull = true;

  static PlayPositionItem _instantiate(DecodingData data) {
    return PlayPositionItem(
      title: data.dec(_f$title),
      position: data.dec(_f$position),
      done: data.dec(_f$done),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayPositionItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayPositionItem>(map);
  }

  static PlayPositionItem fromJson(String json) {
    return ensureInitialized().decodeJson<PlayPositionItem>(json);
  }
}

mixin PlayPositionItemMappable {
  String toJson() {
    return PlayPositionItemMapper.ensureInitialized()
        .encodeJson<PlayPositionItem>(this as PlayPositionItem);
  }

  Map<String, dynamic> toMap() {
    return PlayPositionItemMapper.ensureInitialized()
        .encodeMap<PlayPositionItem>(this as PlayPositionItem);
  }

  PlayPositionItemCopyWith<PlayPositionItem, PlayPositionItem, PlayPositionItem>
  get copyWith =>
      _PlayPositionItemCopyWithImpl<PlayPositionItem, PlayPositionItem>(
        this as PlayPositionItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayPositionItemMapper.ensureInitialized().stringifyValue(
      this as PlayPositionItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayPositionItemMapper.ensureInitialized().equalsValue(
      this as PlayPositionItem,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayPositionItemMapper.ensureInitialized().hashValue(
      this as PlayPositionItem,
    );
  }
}

extension PlayPositionItemValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayPositionItem, $Out> {
  PlayPositionItemCopyWith<$R, PlayPositionItem, $Out>
  get $asPlayPositionItem =>
      $base.as((v, t, t2) => _PlayPositionItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayPositionItemCopyWith<$R, $In extends PlayPositionItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  PlayPositionPointCopyWith<$R, PlayPositionPoint, PlayPositionPoint>?
  get position;
  $R call({String? title, PlayPositionPoint? position, bool? done});
  PlayPositionItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayPositionItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayPositionItem, $Out>
    implements PlayPositionItemCopyWith<$R, PlayPositionItem, $Out> {
  _PlayPositionItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayPositionItem> $mapper =
      PlayPositionItemMapper.ensureInitialized();
  @override
  PlayPositionPointCopyWith<$R, PlayPositionPoint, PlayPositionPoint>?
  get position => $value.position?.copyWith.$chain((v) => call(position: v));
  @override
  $R call({String? title, Object? position = $none, bool? done}) => $apply(
    FieldCopyWithData({
      if (title != null) #title: title,
      if (position != $none) #position: position,
      if (done != null) #done: done,
    }),
  );
  @override
  PlayPositionItem $make(CopyWithData data) => PlayPositionItem(
    title: data.get(#title, or: $value.title),
    position: data.get(#position, or: $value.position),
    done: data.get(#done, or: $value.done),
  );

  @override
  PlayPositionItemCopyWith<$R2, PlayPositionItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayPositionItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayPositionMapper extends SubClassMapperBase<PlayPosition> {
  PlayPositionMapper._();

  static PlayPositionMapper? _instance;
  static PlayPositionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayPositionMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      PlayPositionItemMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayPosition';

  static String _$deviceId(PlayPosition v) => v.deviceId;
  static const Field<PlayPosition, String> _f$deviceId = Field(
    'deviceId',
    _$deviceId,
    key: r'device_id',
  );
  static Map<String, PlayPositionItem> _$items(PlayPosition v) => v.items;
  static const Field<PlayPosition, Map<String, PlayPositionItem>> _f$items =
      Field('items', _$items, opt: true, def: const {});
  static String? _$id(PlayPosition v) => v.id;
  static const Field<PlayPosition, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static String? _$rev(PlayPosition v) => v.rev;
  static const Field<PlayPosition, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(PlayPosition v) =>
      v.attachments;
  static const Field<PlayPosition, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(PlayPosition v) => v.deleted;
  static const Field<PlayPosition, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static Revisions? _$revisions(PlayPosition v) => v.revisions;
  static const Field<PlayPosition, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(PlayPosition v) => v.revsInfo;
  static const Field<PlayPosition, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(PlayPosition v) =>
      v.unmappedProps;
  static const Field<PlayPosition, Map<String, dynamic>> _f$unmappedProps =
      Field('unmappedProps', _$unmappedProps, opt: true, def: const {});

  @override
  final MappableFields<PlayPosition> fields = const {
    #deviceId: _f$deviceId,
    #items: _f$items,
    #id: _f$id,
    #rev: _f$rev,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = 'play_position';
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static PlayPosition _instantiate(DecodingData data) {
    return PlayPosition(
      deviceId: data.dec(_f$deviceId),
      items: data.dec(_f$items),
      id: data.dec(_f$id),
      rev: data.dec(_f$rev),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayPosition fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayPosition>(map);
  }

  static PlayPosition fromJson(String json) {
    return ensureInitialized().decodeJson<PlayPosition>(json);
  }
}

mixin PlayPositionMappable {
  String toJson() {
    return PlayPositionMapper.ensureInitialized().encodeJson<PlayPosition>(
      this as PlayPosition,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayPositionMapper.ensureInitialized().encodeMap<PlayPosition>(
      this as PlayPosition,
    );
  }

  PlayPositionCopyWith<PlayPosition, PlayPosition, PlayPosition> get copyWith =>
      _PlayPositionCopyWithImpl<PlayPosition, PlayPosition>(
        this as PlayPosition,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayPositionMapper.ensureInitialized().stringifyValue(
      this as PlayPosition,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayPositionMapper.ensureInitialized().equalsValue(
      this as PlayPosition,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayPositionMapper.ensureInitialized().hashValue(
      this as PlayPosition,
    );
  }
}

extension PlayPositionValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayPosition, $Out> {
  PlayPositionCopyWith<$R, PlayPosition, $Out> get $asPlayPosition =>
      $base.as((v, t, t2) => _PlayPositionCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayPositionCopyWith<$R, $In extends PlayPosition, $Out>
    implements CouchDocumentBaseCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    PlayPositionItem,
    PlayPositionItemCopyWith<$R, PlayPositionItem, PlayPositionItem>
  >
  get items;
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions;
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps;
  @override
  $R call({
    String? deviceId,
    Map<String, PlayPositionItem>? items,
    String? id,
    String? rev,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  PlayPositionCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayPositionCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayPosition, $Out>
    implements PlayPositionCopyWith<$R, PlayPosition, $Out> {
  _PlayPositionCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayPosition> $mapper =
      PlayPositionMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    PlayPositionItem,
    PlayPositionItemCopyWith<$R, PlayPositionItem, PlayPositionItem>
  >
  get items => MapCopyWith(
    $value.items,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(items: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments => $value.attachments != null
      ? MapCopyWith(
          $value.attachments!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(attachments: v),
        )
      : null;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions =>
      $value.revisions?.copyWith.$chain((v) => call(revisions: v));
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo => $value.revsInfo != null
      ? ListCopyWith(
          $value.revsInfo!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(revsInfo: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps => MapCopyWith(
    $value.unmappedProps,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unmappedProps: v),
  );
  @override
  $R call({
    String? deviceId,
    Map<String, PlayPositionItem>? items,
    Object? id = $none,
    Object? rev = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (deviceId != null) #deviceId: deviceId,
      if (items != null) #items: items,
      if (id != $none) #id: id,
      if (rev != $none) #rev: rev,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  PlayPosition $make(CopyWithData data) => PlayPosition(
    deviceId: data.get(#deviceId, or: $value.deviceId),
    items: data.get(#items, or: $value.items),
    id: data.get(#id, or: $value.id),
    rev: data.get(#rev, or: $value.rev),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  PlayPositionCopyWith<$R2, PlayPosition, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayPositionCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DeviceIdentityMapper extends SubClassMapperBase<DeviceIdentity> {
  DeviceIdentityMapper._();

  static DeviceIdentityMapper? _instance;
  static DeviceIdentityMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DeviceIdentityMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'DeviceIdentity';

  static String _$uuid(DeviceIdentity v) => v.uuid;
  static const Field<DeviceIdentity, String> _f$uuid = Field('uuid', _$uuid);
  static String _$kidName(DeviceIdentity v) => v.kidName;
  static const Field<DeviceIdentity, String> _f$kidName = Field(
    'kidName',
    _$kidName,
    key: r'kid_name',
  );
  static String? _$id(DeviceIdentity v) => v.id;
  static const Field<DeviceIdentity, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static String? _$rev(DeviceIdentity v) => v.rev;
  static const Field<DeviceIdentity, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(DeviceIdentity v) =>
      v.attachments;
  static const Field<DeviceIdentity, Map<String, AttachmentInfo>>
  _f$attachments = Field(
    'attachments',
    _$attachments,
    key: r'_attachments',
    opt: true,
  );
  static bool _$deleted(DeviceIdentity v) => v.deleted;
  static const Field<DeviceIdentity, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static Revisions? _$revisions(DeviceIdentity v) => v.revisions;
  static const Field<DeviceIdentity, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(DeviceIdentity v) => v.revsInfo;
  static const Field<DeviceIdentity, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(DeviceIdentity v) =>
      v.unmappedProps;
  static const Field<DeviceIdentity, Map<String, dynamic>> _f$unmappedProps =
      Field('unmappedProps', _$unmappedProps, opt: true, def: const {});

  @override
  final MappableFields<DeviceIdentity> fields = const {
    #uuid: _f$uuid,
    #kidName: _f$kidName,
    #id: _f$id,
    #rev: _f$rev,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = 'device_identity';
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static DeviceIdentity _instantiate(DecodingData data) {
    return DeviceIdentity(
      uuid: data.dec(_f$uuid),
      kidName: data.dec(_f$kidName),
      id: data.dec(_f$id),
      rev: data.dec(_f$rev),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DeviceIdentity fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DeviceIdentity>(map);
  }

  static DeviceIdentity fromJson(String json) {
    return ensureInitialized().decodeJson<DeviceIdentity>(json);
  }
}

mixin DeviceIdentityMappable {
  String toJson() {
    return DeviceIdentityMapper.ensureInitialized().encodeJson<DeviceIdentity>(
      this as DeviceIdentity,
    );
  }

  Map<String, dynamic> toMap() {
    return DeviceIdentityMapper.ensureInitialized().encodeMap<DeviceIdentity>(
      this as DeviceIdentity,
    );
  }

  DeviceIdentityCopyWith<DeviceIdentity, DeviceIdentity, DeviceIdentity>
  get copyWith => _DeviceIdentityCopyWithImpl<DeviceIdentity, DeviceIdentity>(
    this as DeviceIdentity,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return DeviceIdentityMapper.ensureInitialized().stringifyValue(
      this as DeviceIdentity,
    );
  }

  @override
  bool operator ==(Object other) {
    return DeviceIdentityMapper.ensureInitialized().equalsValue(
      this as DeviceIdentity,
      other,
    );
  }

  @override
  int get hashCode {
    return DeviceIdentityMapper.ensureInitialized().hashValue(
      this as DeviceIdentity,
    );
  }
}

extension DeviceIdentityValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DeviceIdentity, $Out> {
  DeviceIdentityCopyWith<$R, DeviceIdentity, $Out> get $asDeviceIdentity =>
      $base.as((v, t, t2) => _DeviceIdentityCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DeviceIdentityCopyWith<$R, $In extends DeviceIdentity, $Out>
    implements CouchDocumentBaseCopyWith<$R, $In, $Out> {
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions;
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps;
  @override
  $R call({
    String? uuid,
    String? kidName,
    String? id,
    String? rev,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  DeviceIdentityCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DeviceIdentityCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DeviceIdentity, $Out>
    implements DeviceIdentityCopyWith<$R, DeviceIdentity, $Out> {
  _DeviceIdentityCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DeviceIdentity> $mapper =
      DeviceIdentityMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    AttachmentInfo,
    AttachmentInfoCopyWith<$R, AttachmentInfo, AttachmentInfo>
  >?
  get attachments => $value.attachments != null
      ? MapCopyWith(
          $value.attachments!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(attachments: v),
        )
      : null;
  @override
  RevisionsCopyWith<$R, Revisions, Revisions>? get revisions =>
      $value.revisions?.copyWith.$chain((v) => call(revisions: v));
  @override
  ListCopyWith<$R, RevsInfo, RevsInfoCopyWith<$R, RevsInfo, RevsInfo>>?
  get revsInfo => $value.revsInfo != null
      ? ListCopyWith(
          $value.revsInfo!,
          (v, t) => v.copyWith.$chain(t),
          (v) => call(revsInfo: v),
        )
      : null;
  @override
  MapCopyWith<$R, String, dynamic, ObjectCopyWith<$R, dynamic, dynamic>?>
  get unmappedProps => MapCopyWith(
    $value.unmappedProps,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(unmappedProps: v),
  );
  @override
  $R call({
    String? uuid,
    String? kidName,
    Object? id = $none,
    Object? rev = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (uuid != null) #uuid: uuid,
      if (kidName != null) #kidName: kidName,
      if (id != $none) #id: id,
      if (rev != $none) #rev: rev,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  DeviceIdentity $make(CopyWithData data) => DeviceIdentity(
    uuid: data.get(#uuid, or: $value.uuid),
    kidName: data.get(#kidName, or: $value.kidName),
    id: data.get(#id, or: $value.id),
    rev: data.get(#rev, or: $value.rev),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  DeviceIdentityCopyWith<$R2, DeviceIdentity, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _DeviceIdentityCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

