// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'global_constraints.dart';

class GlobalConstraintsMapper extends SubClassMapperBase<GlobalConstraints> {
  GlobalConstraintsMapper._();

  static GlobalConstraintsMapper? _instance;
  static GlobalConstraintsMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GlobalConstraintsMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      HearingConstraintMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GlobalConstraints';

  static HearingConstraint? _$hearingConstraint(GlobalConstraints v) =>
      v.hearingConstraint;
  static const Field<GlobalConstraints, HearingConstraint>
  _f$hearingConstraint = Field(
    'hearingConstraint',
    _$hearingConstraint,
    key: r'hearing_constraint',
    opt: true,
  );
  static String? _$id(GlobalConstraints v) => v.id;
  static const Field<GlobalConstraints, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static String? _$rev(GlobalConstraints v) => v.rev;
  static const Field<GlobalConstraints, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(GlobalConstraints v) =>
      v.attachments;
  static const Field<GlobalConstraints, Map<String, AttachmentInfo>>
  _f$attachments = Field(
    'attachments',
    _$attachments,
    key: r'_attachments',
    opt: true,
  );
  static bool _$deleted(GlobalConstraints v) => v.deleted;
  static const Field<GlobalConstraints, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static Revisions? _$revisions(GlobalConstraints v) => v.revisions;
  static const Field<GlobalConstraints, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(GlobalConstraints v) => v.revsInfo;
  static const Field<GlobalConstraints, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(GlobalConstraints v) =>
      v.unmappedProps;
  static const Field<GlobalConstraints, Map<String, dynamic>> _f$unmappedProps =
      Field('unmappedProps', _$unmappedProps, opt: true, def: const {});

  @override
  final MappableFields<GlobalConstraints> fields = const {
    #hearingConstraint: _f$hearingConstraint,
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
  final dynamic discriminatorValue = 'global_constraints';
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static GlobalConstraints _instantiate(DecodingData data) {
    return GlobalConstraints(
      hearingConstraint: data.dec(_f$hearingConstraint),
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

  static GlobalConstraints fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GlobalConstraints>(map);
  }

  static GlobalConstraints fromJson(String json) {
    return ensureInitialized().decodeJson<GlobalConstraints>(json);
  }
}

mixin GlobalConstraintsMappable {
  String toJson() {
    return GlobalConstraintsMapper.ensureInitialized()
        .encodeJson<GlobalConstraints>(this as GlobalConstraints);
  }

  Map<String, dynamic> toMap() {
    return GlobalConstraintsMapper.ensureInitialized()
        .encodeMap<GlobalConstraints>(this as GlobalConstraints);
  }

  GlobalConstraintsCopyWith<
    GlobalConstraints,
    GlobalConstraints,
    GlobalConstraints
  >
  get copyWith =>
      _GlobalConstraintsCopyWithImpl<GlobalConstraints, GlobalConstraints>(
        this as GlobalConstraints,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GlobalConstraintsMapper.ensureInitialized().stringifyValue(
      this as GlobalConstraints,
    );
  }

  @override
  bool operator ==(Object other) {
    return GlobalConstraintsMapper.ensureInitialized().equalsValue(
      this as GlobalConstraints,
      other,
    );
  }

  @override
  int get hashCode {
    return GlobalConstraintsMapper.ensureInitialized().hashValue(
      this as GlobalConstraints,
    );
  }
}

extension GlobalConstraintsValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GlobalConstraints, $Out> {
  GlobalConstraintsCopyWith<$R, GlobalConstraints, $Out>
  get $asGlobalConstraints => $base.as(
    (v, t, t2) => _GlobalConstraintsCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class GlobalConstraintsCopyWith<
  $R,
  $In extends GlobalConstraints,
  $Out
>
    implements CouchDocumentBaseCopyWith<$R, $In, $Out> {
  HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>?
  get hearingConstraint;
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
    HearingConstraint? hearingConstraint,
    String? id,
    String? rev,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  GlobalConstraintsCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GlobalConstraintsCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GlobalConstraints, $Out>
    implements GlobalConstraintsCopyWith<$R, GlobalConstraints, $Out> {
  _GlobalConstraintsCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GlobalConstraints> $mapper =
      GlobalConstraintsMapper.ensureInitialized();
  @override
  HearingConstraintCopyWith<$R, HearingConstraint, HearingConstraint>?
  get hearingConstraint => $value.hearingConstraint?.copyWith.$chain(
    (v) => call(hearingConstraint: v),
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
    Object? hearingConstraint = $none,
    Object? id = $none,
    Object? rev = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (hearingConstraint != $none) #hearingConstraint: hearingConstraint,
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
  GlobalConstraints $make(CopyWithData data) => GlobalConstraints(
    hearingConstraint: data.get(
      #hearingConstraint,
      or: $value.hearingConstraint,
    ),
    id: data.get(#id, or: $value.id),
    rev: data.get(#rev, or: $value.rev),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  GlobalConstraintsCopyWith<$R2, GlobalConstraints, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GlobalConstraintsCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

