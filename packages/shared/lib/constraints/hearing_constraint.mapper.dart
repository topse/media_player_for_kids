// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'hearing_constraint.dart';

class TimeWindowTypeMapper extends EnumMapper<TimeWindowType> {
  TimeWindowTypeMapper._();

  static TimeWindowTypeMapper? _instance;
  static TimeWindowTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TimeWindowTypeMapper._());
    }
    return _instance!;
  }

  static TimeWindowType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  TimeWindowType decode(dynamic value) {
    switch (value) {
      case r'perDay':
        return TimeWindowType.perDay;
      case r'perWeek':
        return TimeWindowType.perWeek;
      case r'perMonth':
        return TimeWindowType.perMonth;
      case r'sinceDate':
        return TimeWindowType.sinceDate;
      case r'rollingHours':
        return TimeWindowType.rollingHours;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(TimeWindowType self) {
    switch (self) {
      case TimeWindowType.perDay:
        return r'perDay';
      case TimeWindowType.perWeek:
        return r'perWeek';
      case TimeWindowType.perMonth:
        return r'perMonth';
      case TimeWindowType.sinceDate:
        return r'sinceDate';
      case TimeWindowType.rollingHours:
        return r'rollingHours';
    }
  }
}

extension TimeWindowTypeMapperExtension on TimeWindowType {
  String toValue() {
    TimeWindowTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<TimeWindowType>(this) as String;
  }
}

class TimeWindowMapper extends ClassMapperBase<TimeWindow> {
  TimeWindowMapper._();

  static TimeWindowMapper? _instance;
  static TimeWindowMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TimeWindowMapper._());
      TimeWindowTypeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'TimeWindow';

  static TimeWindowType _$type(TimeWindow v) => v.type;
  static const Field<TimeWindow, TimeWindowType> _f$type = Field(
    'type',
    _$type,
  );
  static String? _$sinceDate(TimeWindow v) => v.sinceDate;
  static const Field<TimeWindow, String> _f$sinceDate = Field(
    'sinceDate',
    _$sinceDate,
    key: r'since_date',
    opt: true,
  );
  static int? _$rollingHours(TimeWindow v) => v.rollingHours;
  static const Field<TimeWindow, int> _f$rollingHours = Field(
    'rollingHours',
    _$rollingHours,
    key: r'rolling_hours',
    opt: true,
  );

  @override
  final MappableFields<TimeWindow> fields = const {
    #type: _f$type,
    #sinceDate: _f$sinceDate,
    #rollingHours: _f$rollingHours,
  };

  static TimeWindow _instantiate(DecodingData data) {
    return TimeWindow(
      type: data.dec(_f$type),
      sinceDate: data.dec(_f$sinceDate),
      rollingHours: data.dec(_f$rollingHours),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TimeWindow fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TimeWindow>(map);
  }

  static TimeWindow fromJson(String json) {
    return ensureInitialized().decodeJson<TimeWindow>(json);
  }
}

mixin TimeWindowMappable {
  String toJson() {
    return TimeWindowMapper.ensureInitialized().encodeJson<TimeWindow>(
      this as TimeWindow,
    );
  }

  Map<String, dynamic> toMap() {
    return TimeWindowMapper.ensureInitialized().encodeMap<TimeWindow>(
      this as TimeWindow,
    );
  }

  TimeWindowCopyWith<TimeWindow, TimeWindow, TimeWindow> get copyWith =>
      _TimeWindowCopyWithImpl<TimeWindow, TimeWindow>(
        this as TimeWindow,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TimeWindowMapper.ensureInitialized().stringifyValue(
      this as TimeWindow,
    );
  }

  @override
  bool operator ==(Object other) {
    return TimeWindowMapper.ensureInitialized().equalsValue(
      this as TimeWindow,
      other,
    );
  }

  @override
  int get hashCode {
    return TimeWindowMapper.ensureInitialized().hashValue(this as TimeWindow);
  }
}

extension TimeWindowValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TimeWindow, $Out> {
  TimeWindowCopyWith<$R, TimeWindow, $Out> get $asTimeWindow =>
      $base.as((v, t, t2) => _TimeWindowCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TimeWindowCopyWith<$R, $In extends TimeWindow, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({TimeWindowType? type, String? sinceDate, int? rollingHours});
  TimeWindowCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TimeWindowCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TimeWindow, $Out>
    implements TimeWindowCopyWith<$R, TimeWindow, $Out> {
  _TimeWindowCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TimeWindow> $mapper =
      TimeWindowMapper.ensureInitialized();
  @override
  $R call({
    TimeWindowType? type,
    Object? sinceDate = $none,
    Object? rollingHours = $none,
  }) => $apply(
    FieldCopyWithData({
      if (type != null) #type: type,
      if (sinceDate != $none) #sinceDate: sinceDate,
      if (rollingHours != $none) #rollingHours: rollingHours,
    }),
  );
  @override
  TimeWindow $make(CopyWithData data) => TimeWindow(
    type: data.get(#type, or: $value.type),
    sinceDate: data.get(#sinceDate, or: $value.sinceDate),
    rollingHours: data.get(#rollingHours, or: $value.rollingHours),
  );

  @override
  TimeWindowCopyWith<$R2, TimeWindow, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TimeWindowCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class HearingConstraintMapper extends ClassMapperBase<HearingConstraint> {
  HearingConstraintMapper._();

  static HearingConstraintMapper? _instance;
  static HearingConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = HearingConstraintMapper._());
      LogicalAndConstraintMapper.ensureInitialized();
      LogicalOrConstraintMapper.ensureInitialized();
      LogicalNotConstraintMapper.ensureInitialized();
      PlayCountConstraintMapper.ensureInitialized();
      PlayDurationConstraintMapper.ensureInitialized();
      FolderItemCountConstraintMapper.ensureInitialized();
      TimeOfDayConstraintMapper.ensureInitialized();
      DayOfWeekConstraintMapper.ensureInitialized();
      DateRangeConstraintMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'HearingConstraint';

  @override
  final MappableFields<HearingConstraint> fields = const {};

  static HearingConstraint _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'HearingConstraint',
      '!constraint_type',
      '${data.value['!constraint_type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static HearingConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<HearingConstraint>(map);
  }

  static HearingConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<HearingConstraint>(json);
  }
}

mixin HearingConstraintMappable {
  String toJson();
  Map<String, dynamic> toMap();
  HearingConstraintCopyWith<
    HearingConstraint,
    HearingConstraint,
    HearingConstraint
  >
  get copyWith;
}

abstract class HearingConstraintCopyWith<
  $R,
  $In extends HearingConstraint,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call();
  HearingConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class LogicalAndConstraintMapper
    extends SubClassMapperBase<LogicalAndConstraint> {
  LogicalAndConstraintMapper._();

  static LogicalAndConstraintMapper? _instance;
  static LogicalAndConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LogicalAndConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      HearingConstraintMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LogicalAndConstraint';

  static List<HearingConstraint> _$nodes(LogicalAndConstraint v) => v.nodes;
  static const Field<LogicalAndConstraint, List<HearingConstraint>> _f$nodes =
      Field('nodes', _$nodes);

  @override
  final MappableFields<LogicalAndConstraint> fields = const {#nodes: _f$nodes};

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'and';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static LogicalAndConstraint _instantiate(DecodingData data) {
    return LogicalAndConstraint(nodes: data.dec(_f$nodes));
  }

  @override
  final Function instantiate = _instantiate;

  static LogicalAndConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LogicalAndConstraint>(map);
  }

  static LogicalAndConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<LogicalAndConstraint>(json);
  }
}

mixin LogicalAndConstraintMappable {
  String toJson() {
    return LogicalAndConstraintMapper.ensureInitialized()
        .encodeJson<LogicalAndConstraint>(this as LogicalAndConstraint);
  }

  Map<String, dynamic> toMap() {
    return LogicalAndConstraintMapper.ensureInitialized()
        .encodeMap<LogicalAndConstraint>(this as LogicalAndConstraint);
  }

  LogicalAndConstraintCopyWith<
    LogicalAndConstraint,
    LogicalAndConstraint,
    LogicalAndConstraint
  >
  get copyWith =>
      _LogicalAndConstraintCopyWithImpl<
        LogicalAndConstraint,
        LogicalAndConstraint
      >(this as LogicalAndConstraint, $identity, $identity);
  @override
  String toString() {
    return LogicalAndConstraintMapper.ensureInitialized().stringifyValue(
      this as LogicalAndConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return LogicalAndConstraintMapper.ensureInitialized().equalsValue(
      this as LogicalAndConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return LogicalAndConstraintMapper.ensureInitialized().hashValue(
      this as LogicalAndConstraint,
    );
  }
}

extension LogicalAndConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LogicalAndConstraint, $Out> {
  LogicalAndConstraintCopyWith<$R, LogicalAndConstraint, $Out>
  get $asLogicalAndConstraint => $base.as(
    (v, t, t2) => _LogicalAndConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class LogicalAndConstraintCopyWith<
  $R,
  $In extends LogicalAndConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    HearingConstraint,
    HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>
  >
  get nodes;
  @override
  $R call({List<HearingConstraint>? nodes});
  LogicalAndConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LogicalAndConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LogicalAndConstraint, $Out>
    implements LogicalAndConstraintCopyWith<$R, LogicalAndConstraint, $Out> {
  _LogicalAndConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LogicalAndConstraint> $mapper =
      LogicalAndConstraintMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    HearingConstraint,
    HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>
  >
  get nodes => ListCopyWith(
    $value.nodes,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(nodes: v),
  );
  @override
  $R call({List<HearingConstraint>? nodes}) =>
      $apply(FieldCopyWithData({if (nodes != null) #nodes: nodes}));
  @override
  LogicalAndConstraint $make(CopyWithData data) =>
      LogicalAndConstraint(nodes: data.get(#nodes, or: $value.nodes));

  @override
  LogicalAndConstraintCopyWith<$R2, LogicalAndConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LogicalAndConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LogicalOrConstraintMapper
    extends SubClassMapperBase<LogicalOrConstraint> {
  LogicalOrConstraintMapper._();

  static LogicalOrConstraintMapper? _instance;
  static LogicalOrConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LogicalOrConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      HearingConstraintMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LogicalOrConstraint';

  static List<HearingConstraint> _$nodes(LogicalOrConstraint v) => v.nodes;
  static const Field<LogicalOrConstraint, List<HearingConstraint>> _f$nodes =
      Field('nodes', _$nodes);

  @override
  final MappableFields<LogicalOrConstraint> fields = const {#nodes: _f$nodes};

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'or';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static LogicalOrConstraint _instantiate(DecodingData data) {
    return LogicalOrConstraint(nodes: data.dec(_f$nodes));
  }

  @override
  final Function instantiate = _instantiate;

  static LogicalOrConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LogicalOrConstraint>(map);
  }

  static LogicalOrConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<LogicalOrConstraint>(json);
  }
}

mixin LogicalOrConstraintMappable {
  String toJson() {
    return LogicalOrConstraintMapper.ensureInitialized()
        .encodeJson<LogicalOrConstraint>(this as LogicalOrConstraint);
  }

  Map<String, dynamic> toMap() {
    return LogicalOrConstraintMapper.ensureInitialized()
        .encodeMap<LogicalOrConstraint>(this as LogicalOrConstraint);
  }

  LogicalOrConstraintCopyWith<
    LogicalOrConstraint,
    LogicalOrConstraint,
    LogicalOrConstraint
  >
  get copyWith =>
      _LogicalOrConstraintCopyWithImpl<
        LogicalOrConstraint,
        LogicalOrConstraint
      >(this as LogicalOrConstraint, $identity, $identity);
  @override
  String toString() {
    return LogicalOrConstraintMapper.ensureInitialized().stringifyValue(
      this as LogicalOrConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return LogicalOrConstraintMapper.ensureInitialized().equalsValue(
      this as LogicalOrConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return LogicalOrConstraintMapper.ensureInitialized().hashValue(
      this as LogicalOrConstraint,
    );
  }
}

extension LogicalOrConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LogicalOrConstraint, $Out> {
  LogicalOrConstraintCopyWith<$R, LogicalOrConstraint, $Out>
  get $asLogicalOrConstraint => $base.as(
    (v, t, t2) => _LogicalOrConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class LogicalOrConstraintCopyWith<
  $R,
  $In extends LogicalOrConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    HearingConstraint,
    HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>
  >
  get nodes;
  @override
  $R call({List<HearingConstraint>? nodes});
  LogicalOrConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LogicalOrConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LogicalOrConstraint, $Out>
    implements LogicalOrConstraintCopyWith<$R, LogicalOrConstraint, $Out> {
  _LogicalOrConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LogicalOrConstraint> $mapper =
      LogicalOrConstraintMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    HearingConstraint,
    HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>
  >
  get nodes => ListCopyWith(
    $value.nodes,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(nodes: v),
  );
  @override
  $R call({List<HearingConstraint>? nodes}) =>
      $apply(FieldCopyWithData({if (nodes != null) #nodes: nodes}));
  @override
  LogicalOrConstraint $make(CopyWithData data) =>
      LogicalOrConstraint(nodes: data.get(#nodes, or: $value.nodes));

  @override
  LogicalOrConstraintCopyWith<$R2, LogicalOrConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LogicalOrConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LogicalNotConstraintMapper
    extends SubClassMapperBase<LogicalNotConstraint> {
  LogicalNotConstraintMapper._();

  static LogicalNotConstraintMapper? _instance;
  static LogicalNotConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LogicalNotConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      HearingConstraintMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LogicalNotConstraint';

  static HearingConstraint _$node(LogicalNotConstraint v) => v.node;
  static const Field<LogicalNotConstraint, HearingConstraint> _f$node = Field(
    'node',
    _$node,
  );

  @override
  final MappableFields<LogicalNotConstraint> fields = const {#node: _f$node};

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'not';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static LogicalNotConstraint _instantiate(DecodingData data) {
    return LogicalNotConstraint(node: data.dec(_f$node));
  }

  @override
  final Function instantiate = _instantiate;

  static LogicalNotConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LogicalNotConstraint>(map);
  }

  static LogicalNotConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<LogicalNotConstraint>(json);
  }
}

mixin LogicalNotConstraintMappable {
  String toJson() {
    return LogicalNotConstraintMapper.ensureInitialized()
        .encodeJson<LogicalNotConstraint>(this as LogicalNotConstraint);
  }

  Map<String, dynamic> toMap() {
    return LogicalNotConstraintMapper.ensureInitialized()
        .encodeMap<LogicalNotConstraint>(this as LogicalNotConstraint);
  }

  LogicalNotConstraintCopyWith<
    LogicalNotConstraint,
    LogicalNotConstraint,
    LogicalNotConstraint
  >
  get copyWith =>
      _LogicalNotConstraintCopyWithImpl<
        LogicalNotConstraint,
        LogicalNotConstraint
      >(this as LogicalNotConstraint, $identity, $identity);
  @override
  String toString() {
    return LogicalNotConstraintMapper.ensureInitialized().stringifyValue(
      this as LogicalNotConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return LogicalNotConstraintMapper.ensureInitialized().equalsValue(
      this as LogicalNotConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return LogicalNotConstraintMapper.ensureInitialized().hashValue(
      this as LogicalNotConstraint,
    );
  }
}

extension LogicalNotConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, LogicalNotConstraint, $Out> {
  LogicalNotConstraintCopyWith<$R, LogicalNotConstraint, $Out>
  get $asLogicalNotConstraint => $base.as(
    (v, t, t2) => _LogicalNotConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class LogicalNotConstraintCopyWith<
  $R,
  $In extends LogicalNotConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint> get node;
  @override
  $R call({HearingConstraint? node});
  LogicalNotConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _LogicalNotConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LogicalNotConstraint, $Out>
    implements LogicalNotConstraintCopyWith<$R, LogicalNotConstraint, $Out> {
  _LogicalNotConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LogicalNotConstraint> $mapper =
      LogicalNotConstraintMapper.ensureInitialized();
  @override
  HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>
  get node => $value.node.copyWith.$chain((v) => call(node: v));
  @override
  $R call({HearingConstraint? node}) =>
      $apply(FieldCopyWithData({if (node != null) #node: node}));
  @override
  LogicalNotConstraint $make(CopyWithData data) =>
      LogicalNotConstraint(node: data.get(#node, or: $value.node));

  @override
  LogicalNotConstraintCopyWith<$R2, LogicalNotConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LogicalNotConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayCountConstraintMapper
    extends SubClassMapperBase<PlayCountConstraint> {
  PlayCountConstraintMapper._();

  static PlayCountConstraintMapper? _instance;
  static PlayCountConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayCountConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      TimeWindowMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayCountConstraint';

  static int _$maxCount(PlayCountConstraint v) => v.maxCount;
  static const Field<PlayCountConstraint, int> _f$maxCount = Field(
    'maxCount',
    _$maxCount,
    key: r'max_count',
  );
  static TimeWindow _$window(PlayCountConstraint v) => v.window;
  static const Field<PlayCountConstraint, TimeWindow> _f$window = Field(
    'window',
    _$window,
  );

  @override
  final MappableFields<PlayCountConstraint> fields = const {
    #maxCount: _f$maxCount,
    #window: _f$window,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'play_count';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static PlayCountConstraint _instantiate(DecodingData data) {
    return PlayCountConstraint(
      maxCount: data.dec(_f$maxCount),
      window: data.dec(_f$window),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayCountConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayCountConstraint>(map);
  }

  static PlayCountConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<PlayCountConstraint>(json);
  }
}

mixin PlayCountConstraintMappable {
  String toJson() {
    return PlayCountConstraintMapper.ensureInitialized()
        .encodeJson<PlayCountConstraint>(this as PlayCountConstraint);
  }

  Map<String, dynamic> toMap() {
    return PlayCountConstraintMapper.ensureInitialized()
        .encodeMap<PlayCountConstraint>(this as PlayCountConstraint);
  }

  PlayCountConstraintCopyWith<
    PlayCountConstraint,
    PlayCountConstraint,
    PlayCountConstraint
  >
  get copyWith =>
      _PlayCountConstraintCopyWithImpl<
        PlayCountConstraint,
        PlayCountConstraint
      >(this as PlayCountConstraint, $identity, $identity);
  @override
  String toString() {
    return PlayCountConstraintMapper.ensureInitialized().stringifyValue(
      this as PlayCountConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayCountConstraintMapper.ensureInitialized().equalsValue(
      this as PlayCountConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayCountConstraintMapper.ensureInitialized().hashValue(
      this as PlayCountConstraint,
    );
  }
}

extension PlayCountConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayCountConstraint, $Out> {
  PlayCountConstraintCopyWith<$R, PlayCountConstraint, $Out>
  get $asPlayCountConstraint => $base.as(
    (v, t, t2) => _PlayCountConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayCountConstraintCopyWith<
  $R,
  $In extends PlayCountConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window;
  @override
  $R call({int? maxCount, TimeWindow? window});
  PlayCountConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayCountConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayCountConstraint, $Out>
    implements PlayCountConstraintCopyWith<$R, PlayCountConstraint, $Out> {
  _PlayCountConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayCountConstraint> $mapper =
      PlayCountConstraintMapper.ensureInitialized();
  @override
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window =>
      $value.window.copyWith.$chain((v) => call(window: v));
  @override
  $R call({int? maxCount, TimeWindow? window}) => $apply(
    FieldCopyWithData({
      if (maxCount != null) #maxCount: maxCount,
      if (window != null) #window: window,
    }),
  );
  @override
  PlayCountConstraint $make(CopyWithData data) => PlayCountConstraint(
    maxCount: data.get(#maxCount, or: $value.maxCount),
    window: data.get(#window, or: $value.window),
  );

  @override
  PlayCountConstraintCopyWith<$R2, PlayCountConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PlayCountConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PlayDurationConstraintMapper
    extends SubClassMapperBase<PlayDurationConstraint> {
  PlayDurationConstraintMapper._();

  static PlayDurationConstraintMapper? _instance;
  static PlayDurationConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayDurationConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      TimeWindowMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayDurationConstraint';

  static int _$maxMinutes(PlayDurationConstraint v) => v.maxMinutes;
  static const Field<PlayDurationConstraint, int> _f$maxMinutes = Field(
    'maxMinutes',
    _$maxMinutes,
    key: r'max_minutes',
  );
  static TimeWindow _$window(PlayDurationConstraint v) => v.window;
  static const Field<PlayDurationConstraint, TimeWindow> _f$window = Field(
    'window',
    _$window,
  );

  @override
  final MappableFields<PlayDurationConstraint> fields = const {
    #maxMinutes: _f$maxMinutes,
    #window: _f$window,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'play_duration';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static PlayDurationConstraint _instantiate(DecodingData data) {
    return PlayDurationConstraint(
      maxMinutes: data.dec(_f$maxMinutes),
      window: data.dec(_f$window),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayDurationConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayDurationConstraint>(map);
  }

  static PlayDurationConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<PlayDurationConstraint>(json);
  }
}

mixin PlayDurationConstraintMappable {
  String toJson() {
    return PlayDurationConstraintMapper.ensureInitialized()
        .encodeJson<PlayDurationConstraint>(this as PlayDurationConstraint);
  }

  Map<String, dynamic> toMap() {
    return PlayDurationConstraintMapper.ensureInitialized()
        .encodeMap<PlayDurationConstraint>(this as PlayDurationConstraint);
  }

  PlayDurationConstraintCopyWith<
    PlayDurationConstraint,
    PlayDurationConstraint,
    PlayDurationConstraint
  >
  get copyWith =>
      _PlayDurationConstraintCopyWithImpl<
        PlayDurationConstraint,
        PlayDurationConstraint
      >(this as PlayDurationConstraint, $identity, $identity);
  @override
  String toString() {
    return PlayDurationConstraintMapper.ensureInitialized().stringifyValue(
      this as PlayDurationConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayDurationConstraintMapper.ensureInitialized().equalsValue(
      this as PlayDurationConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayDurationConstraintMapper.ensureInitialized().hashValue(
      this as PlayDurationConstraint,
    );
  }
}

extension PlayDurationConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, PlayDurationConstraint, $Out> {
  PlayDurationConstraintCopyWith<$R, PlayDurationConstraint, $Out>
  get $asPlayDurationConstraint => $base.as(
    (v, t, t2) => _PlayDurationConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class PlayDurationConstraintCopyWith<
  $R,
  $In extends PlayDurationConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window;
  @override
  $R call({int? maxMinutes, TimeWindow? window});
  PlayDurationConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _PlayDurationConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayDurationConstraint, $Out>
    implements
        PlayDurationConstraintCopyWith<$R, PlayDurationConstraint, $Out> {
  _PlayDurationConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayDurationConstraint> $mapper =
      PlayDurationConstraintMapper.ensureInitialized();
  @override
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window =>
      $value.window.copyWith.$chain((v) => call(window: v));
  @override
  $R call({int? maxMinutes, TimeWindow? window}) => $apply(
    FieldCopyWithData({
      if (maxMinutes != null) #maxMinutes: maxMinutes,
      if (window != null) #window: window,
    }),
  );
  @override
  PlayDurationConstraint $make(CopyWithData data) => PlayDurationConstraint(
    maxMinutes: data.get(#maxMinutes, or: $value.maxMinutes),
    window: data.get(#window, or: $value.window),
  );

  @override
  PlayDurationConstraintCopyWith<$R2, PlayDurationConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _PlayDurationConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class FolderItemCountConstraintMapper
    extends SubClassMapperBase<FolderItemCountConstraint> {
  FolderItemCountConstraintMapper._();

  static FolderItemCountConstraintMapper? _instance;
  static FolderItemCountConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = FolderItemCountConstraintMapper._(),
      );
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
      TimeWindowMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'FolderItemCountConstraint';

  static int _$maxItems(FolderItemCountConstraint v) => v.maxItems;
  static const Field<FolderItemCountConstraint, int> _f$maxItems = Field(
    'maxItems',
    _$maxItems,
    key: r'max_items',
  );
  static TimeWindow _$window(FolderItemCountConstraint v) => v.window;
  static const Field<FolderItemCountConstraint, TimeWindow> _f$window = Field(
    'window',
    _$window,
  );

  @override
  final MappableFields<FolderItemCountConstraint> fields = const {
    #maxItems: _f$maxItems,
    #window: _f$window,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'folder_item_count';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static FolderItemCountConstraint _instantiate(DecodingData data) {
    return FolderItemCountConstraint(
      maxItems: data.dec(_f$maxItems),
      window: data.dec(_f$window),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static FolderItemCountConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<FolderItemCountConstraint>(map);
  }

  static FolderItemCountConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<FolderItemCountConstraint>(json);
  }
}

mixin FolderItemCountConstraintMappable {
  String toJson() {
    return FolderItemCountConstraintMapper.ensureInitialized()
        .encodeJson<FolderItemCountConstraint>(
          this as FolderItemCountConstraint,
        );
  }

  Map<String, dynamic> toMap() {
    return FolderItemCountConstraintMapper.ensureInitialized()
        .encodeMap<FolderItemCountConstraint>(
          this as FolderItemCountConstraint,
        );
  }

  FolderItemCountConstraintCopyWith<
    FolderItemCountConstraint,
    FolderItemCountConstraint,
    FolderItemCountConstraint
  >
  get copyWith =>
      _FolderItemCountConstraintCopyWithImpl<
        FolderItemCountConstraint,
        FolderItemCountConstraint
      >(this as FolderItemCountConstraint, $identity, $identity);
  @override
  String toString() {
    return FolderItemCountConstraintMapper.ensureInitialized().stringifyValue(
      this as FolderItemCountConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return FolderItemCountConstraintMapper.ensureInitialized().equalsValue(
      this as FolderItemCountConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return FolderItemCountConstraintMapper.ensureInitialized().hashValue(
      this as FolderItemCountConstraint,
    );
  }
}

extension FolderItemCountConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, FolderItemCountConstraint, $Out> {
  FolderItemCountConstraintCopyWith<$R, FolderItemCountConstraint, $Out>
  get $asFolderItemCountConstraint => $base.as(
    (v, t, t2) => _FolderItemCountConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class FolderItemCountConstraintCopyWith<
  $R,
  $In extends FolderItemCountConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window;
  @override
  $R call({int? maxItems, TimeWindow? window});
  FolderItemCountConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _FolderItemCountConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, FolderItemCountConstraint, $Out>
    implements
        FolderItemCountConstraintCopyWith<$R, FolderItemCountConstraint, $Out> {
  _FolderItemCountConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<FolderItemCountConstraint> $mapper =
      FolderItemCountConstraintMapper.ensureInitialized();
  @override
  TimeWindowCopyWith<$R, TimeWindow, TimeWindow> get window =>
      $value.window.copyWith.$chain((v) => call(window: v));
  @override
  $R call({int? maxItems, TimeWindow? window}) => $apply(
    FieldCopyWithData({
      if (maxItems != null) #maxItems: maxItems,
      if (window != null) #window: window,
    }),
  );
  @override
  FolderItemCountConstraint $make(CopyWithData data) =>
      FolderItemCountConstraint(
        maxItems: data.get(#maxItems, or: $value.maxItems),
        window: data.get(#window, or: $value.window),
      );

  @override
  FolderItemCountConstraintCopyWith<$R2, FolderItemCountConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _FolderItemCountConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TimeOfDayConstraintMapper
    extends SubClassMapperBase<TimeOfDayConstraint> {
  TimeOfDayConstraintMapper._();

  static TimeOfDayConstraintMapper? _instance;
  static TimeOfDayConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TimeOfDayConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'TimeOfDayConstraint';

  static String _$fromTime(TimeOfDayConstraint v) => v.fromTime;
  static const Field<TimeOfDayConstraint, String> _f$fromTime = Field(
    'fromTime',
    _$fromTime,
    key: r'from_time',
  );
  static String _$toTime(TimeOfDayConstraint v) => v.toTime;
  static const Field<TimeOfDayConstraint, String> _f$toTime = Field(
    'toTime',
    _$toTime,
    key: r'to_time',
  );

  @override
  final MappableFields<TimeOfDayConstraint> fields = const {
    #fromTime: _f$fromTime,
    #toTime: _f$toTime,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'time_of_day';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static TimeOfDayConstraint _instantiate(DecodingData data) {
    return TimeOfDayConstraint(
      fromTime: data.dec(_f$fromTime),
      toTime: data.dec(_f$toTime),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TimeOfDayConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TimeOfDayConstraint>(map);
  }

  static TimeOfDayConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<TimeOfDayConstraint>(json);
  }
}

mixin TimeOfDayConstraintMappable {
  String toJson() {
    return TimeOfDayConstraintMapper.ensureInitialized()
        .encodeJson<TimeOfDayConstraint>(this as TimeOfDayConstraint);
  }

  Map<String, dynamic> toMap() {
    return TimeOfDayConstraintMapper.ensureInitialized()
        .encodeMap<TimeOfDayConstraint>(this as TimeOfDayConstraint);
  }

  TimeOfDayConstraintCopyWith<
    TimeOfDayConstraint,
    TimeOfDayConstraint,
    TimeOfDayConstraint
  >
  get copyWith =>
      _TimeOfDayConstraintCopyWithImpl<
        TimeOfDayConstraint,
        TimeOfDayConstraint
      >(this as TimeOfDayConstraint, $identity, $identity);
  @override
  String toString() {
    return TimeOfDayConstraintMapper.ensureInitialized().stringifyValue(
      this as TimeOfDayConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return TimeOfDayConstraintMapper.ensureInitialized().equalsValue(
      this as TimeOfDayConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return TimeOfDayConstraintMapper.ensureInitialized().hashValue(
      this as TimeOfDayConstraint,
    );
  }
}

extension TimeOfDayConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TimeOfDayConstraint, $Out> {
  TimeOfDayConstraintCopyWith<$R, TimeOfDayConstraint, $Out>
  get $asTimeOfDayConstraint => $base.as(
    (v, t, t2) => _TimeOfDayConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class TimeOfDayConstraintCopyWith<
  $R,
  $In extends TimeOfDayConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  @override
  $R call({String? fromTime, String? toTime});
  TimeOfDayConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TimeOfDayConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TimeOfDayConstraint, $Out>
    implements TimeOfDayConstraintCopyWith<$R, TimeOfDayConstraint, $Out> {
  _TimeOfDayConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TimeOfDayConstraint> $mapper =
      TimeOfDayConstraintMapper.ensureInitialized();
  @override
  $R call({String? fromTime, String? toTime}) => $apply(
    FieldCopyWithData({
      if (fromTime != null) #fromTime: fromTime,
      if (toTime != null) #toTime: toTime,
    }),
  );
  @override
  TimeOfDayConstraint $make(CopyWithData data) => TimeOfDayConstraint(
    fromTime: data.get(#fromTime, or: $value.fromTime),
    toTime: data.get(#toTime, or: $value.toTime),
  );

  @override
  TimeOfDayConstraintCopyWith<$R2, TimeOfDayConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TimeOfDayConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DayOfWeekConstraintMapper
    extends SubClassMapperBase<DayOfWeekConstraint> {
  DayOfWeekConstraintMapper._();

  static DayOfWeekConstraintMapper? _instance;
  static DayOfWeekConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DayOfWeekConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'DayOfWeekConstraint';

  static List<int> _$allowedDays(DayOfWeekConstraint v) => v.allowedDays;
  static const Field<DayOfWeekConstraint, List<int>> _f$allowedDays = Field(
    'allowedDays',
    _$allowedDays,
    key: r'allowed_days',
  );

  @override
  final MappableFields<DayOfWeekConstraint> fields = const {
    #allowedDays: _f$allowedDays,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'day_of_week';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static DayOfWeekConstraint _instantiate(DecodingData data) {
    return DayOfWeekConstraint(allowedDays: data.dec(_f$allowedDays));
  }

  @override
  final Function instantiate = _instantiate;

  static DayOfWeekConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DayOfWeekConstraint>(map);
  }

  static DayOfWeekConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<DayOfWeekConstraint>(json);
  }
}

mixin DayOfWeekConstraintMappable {
  String toJson() {
    return DayOfWeekConstraintMapper.ensureInitialized()
        .encodeJson<DayOfWeekConstraint>(this as DayOfWeekConstraint);
  }

  Map<String, dynamic> toMap() {
    return DayOfWeekConstraintMapper.ensureInitialized()
        .encodeMap<DayOfWeekConstraint>(this as DayOfWeekConstraint);
  }

  DayOfWeekConstraintCopyWith<
    DayOfWeekConstraint,
    DayOfWeekConstraint,
    DayOfWeekConstraint
  >
  get copyWith =>
      _DayOfWeekConstraintCopyWithImpl<
        DayOfWeekConstraint,
        DayOfWeekConstraint
      >(this as DayOfWeekConstraint, $identity, $identity);
  @override
  String toString() {
    return DayOfWeekConstraintMapper.ensureInitialized().stringifyValue(
      this as DayOfWeekConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return DayOfWeekConstraintMapper.ensureInitialized().equalsValue(
      this as DayOfWeekConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return DayOfWeekConstraintMapper.ensureInitialized().hashValue(
      this as DayOfWeekConstraint,
    );
  }
}

extension DayOfWeekConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DayOfWeekConstraint, $Out> {
  DayOfWeekConstraintCopyWith<$R, DayOfWeekConstraint, $Out>
  get $asDayOfWeekConstraint => $base.as(
    (v, t, t2) => _DayOfWeekConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DayOfWeekConstraintCopyWith<
  $R,
  $In extends DayOfWeekConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get allowedDays;
  @override
  $R call({List<int>? allowedDays});
  DayOfWeekConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DayOfWeekConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DayOfWeekConstraint, $Out>
    implements DayOfWeekConstraintCopyWith<$R, DayOfWeekConstraint, $Out> {
  _DayOfWeekConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DayOfWeekConstraint> $mapper =
      DayOfWeekConstraintMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get allowedDays =>
      ListCopyWith(
        $value.allowedDays,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(allowedDays: v),
      );
  @override
  $R call({List<int>? allowedDays}) => $apply(
    FieldCopyWithData({if (allowedDays != null) #allowedDays: allowedDays}),
  );
  @override
  DayOfWeekConstraint $make(CopyWithData data) => DayOfWeekConstraint(
    allowedDays: data.get(#allowedDays, or: $value.allowedDays),
  );

  @override
  DayOfWeekConstraintCopyWith<$R2, DayOfWeekConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DayOfWeekConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DateRangeConstraintMapper
    extends SubClassMapperBase<DateRangeConstraint> {
  DateRangeConstraintMapper._();

  static DateRangeConstraintMapper? _instance;
  static DateRangeConstraintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DateRangeConstraintMapper._());
      HearingConstraintMapper.ensureInitialized().addSubMapper(_instance!);
    }
    return _instance!;
  }

  @override
  final String id = 'DateRangeConstraint';

  static String? _$fromDate(DateRangeConstraint v) => v.fromDate;
  static const Field<DateRangeConstraint, String> _f$fromDate = Field(
    'fromDate',
    _$fromDate,
    key: r'from_date',
    opt: true,
  );
  static String? _$toDate(DateRangeConstraint v) => v.toDate;
  static const Field<DateRangeConstraint, String> _f$toDate = Field(
    'toDate',
    _$toDate,
    key: r'to_date',
    opt: true,
  );

  @override
  final MappableFields<DateRangeConstraint> fields = const {
    #fromDate: _f$fromDate,
    #toDate: _f$toDate,
  };

  @override
  final String discriminatorKey = '!constraint_type';
  @override
  final dynamic discriminatorValue = 'date_range';
  @override
  late final ClassMapperBase superMapper =
      HearingConstraintMapper.ensureInitialized();

  static DateRangeConstraint _instantiate(DecodingData data) {
    return DateRangeConstraint(
      fromDate: data.dec(_f$fromDate),
      toDate: data.dec(_f$toDate),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static DateRangeConstraint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DateRangeConstraint>(map);
  }

  static DateRangeConstraint fromJson(String json) {
    return ensureInitialized().decodeJson<DateRangeConstraint>(json);
  }
}

mixin DateRangeConstraintMappable {
  String toJson() {
    return DateRangeConstraintMapper.ensureInitialized()
        .encodeJson<DateRangeConstraint>(this as DateRangeConstraint);
  }

  Map<String, dynamic> toMap() {
    return DateRangeConstraintMapper.ensureInitialized()
        .encodeMap<DateRangeConstraint>(this as DateRangeConstraint);
  }

  DateRangeConstraintCopyWith<
    DateRangeConstraint,
    DateRangeConstraint,
    DateRangeConstraint
  >
  get copyWith =>
      _DateRangeConstraintCopyWithImpl<
        DateRangeConstraint,
        DateRangeConstraint
      >(this as DateRangeConstraint, $identity, $identity);
  @override
  String toString() {
    return DateRangeConstraintMapper.ensureInitialized().stringifyValue(
      this as DateRangeConstraint,
    );
  }

  @override
  bool operator ==(Object other) {
    return DateRangeConstraintMapper.ensureInitialized().equalsValue(
      this as DateRangeConstraint,
      other,
    );
  }

  @override
  int get hashCode {
    return DateRangeConstraintMapper.ensureInitialized().hashValue(
      this as DateRangeConstraint,
    );
  }
}

extension DateRangeConstraintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, DateRangeConstraint, $Out> {
  DateRangeConstraintCopyWith<$R, DateRangeConstraint, $Out>
  get $asDateRangeConstraint => $base.as(
    (v, t, t2) => _DateRangeConstraintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class DateRangeConstraintCopyWith<
  $R,
  $In extends DateRangeConstraint,
  $Out
>
    implements HearingConstraintCopyWith<$R, $In, $Out> {
  @override
  $R call({String? fromDate, String? toDate});
  DateRangeConstraintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _DateRangeConstraintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DateRangeConstraint, $Out>
    implements DateRangeConstraintCopyWith<$R, DateRangeConstraint, $Out> {
  _DateRangeConstraintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DateRangeConstraint> $mapper =
      DateRangeConstraintMapper.ensureInitialized();
  @override
  $R call({Object? fromDate = $none, Object? toDate = $none}) => $apply(
    FieldCopyWithData({
      if (fromDate != $none) #fromDate: fromDate,
      if (toDate != $none) #toDate: toDate,
    }),
  );
  @override
  DateRangeConstraint $make(CopyWithData data) => DateRangeConstraint(
    fromDate: data.get(#fromDate, or: $value.fromDate),
    toDate: data.get(#toDate, or: $value.toDate),
  );

  @override
  DateRangeConstraintCopyWith<$R2, DateRangeConstraint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DateRangeConstraintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

