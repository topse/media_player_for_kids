// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'datatypes.dart';

class MediaBaseMapper extends SubClassMapperBase<MediaBase> {
  MediaBaseMapper._();

  static MediaBaseMapper? _instance;
  static MediaBaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MediaBaseMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      MediaFolderMapper.ensureInitialized();
      MediaItemMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MediaBase';

  static String? _$parent(MediaBase v) => v.parent;
  static const Field<MediaBase, String> _f$parent = Field(
    'parent',
    _$parent,
    opt: true,
  );
  static int _$sortHint(MediaBase v) => v.sortHint;
  static const Field<MediaBase, int> _f$sortHint = Field(
    'sortHint',
    _$sortHint,
  );
  static String _$name(MediaBase v) => v.name;
  static const Field<MediaBase, String> _f$name = Field('name', _$name);
  static String? _$fromDateTime(MediaBase v) => v.fromDateTime;
  static const Field<MediaBase, String> _f$fromDateTime = Field(
    'fromDateTime',
    _$fromDateTime,
    key: r'from_date_time',
    opt: true,
  );
  static String? _$toDateTime(MediaBase v) => v.toDateTime;
  static const Field<MediaBase, String> _f$toDateTime = Field(
    'toDateTime',
    _$toDateTime,
    key: r'to_date_time',
    opt: true,
  );
  static String? _$id(MediaBase v) => v.id;
  static const Field<MediaBase, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(MediaBase v) =>
      v.attachments;
  static const Field<MediaBase, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(MediaBase v) => v.deleted;
  static const Field<MediaBase, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static String? _$rev(MediaBase v) => v.rev;
  static const Field<MediaBase, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Revisions? _$revisions(MediaBase v) => v.revisions;
  static const Field<MediaBase, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(MediaBase v) => v.revsInfo;
  static const Field<MediaBase, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(MediaBase v) => v.unmappedProps;
  static const Field<MediaBase, Map<String, dynamic>> _f$unmappedProps = Field(
    'unmappedProps',
    _$unmappedProps,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<MediaBase> fields = const {
    #parent: _f$parent,
    #sortHint: _f$sortHint,
    #name: _f$name,
    #fromDateTime: _f$fromDateTime,
    #toDateTime: _f$toDateTime,
    #id: _f$id,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #rev: _f$rev,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = "media_base";
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static MediaBase _instantiate(DecodingData data) {
    throw MapperException.missingSubclass(
      'MediaBase',
      '!doc_type',
      '${data.value['!doc_type']}',
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MediaBase fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MediaBase>(map);
  }

  static MediaBase fromJson(String json) {
    return ensureInitialized().decodeJson<MediaBase>(json);
  }
}

mixin MediaBaseMappable {
  String toJson();
  Map<String, dynamic> toMap();
  MediaBaseCopyWith<MediaBase, MediaBase, MediaBase> get copyWith;
}

abstract class MediaBaseCopyWith<$R, $In extends MediaBase, $Out>
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
    String? parent,
    int? sortHint,
    String? name,
    String? fromDateTime,
    String? toDateTime,
    String? id,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    String? rev,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  MediaBaseCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class MediaFolderMapper extends SubClassMapperBase<MediaFolder> {
  MediaFolderMapper._();

  static MediaFolderMapper? _instance;
  static MediaFolderMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MediaFolderMapper._());
      MediaBaseMapper.ensureInitialized().addSubMapper(_instance!);
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MediaFolder';

  static bool _$showItemNumbering(MediaFolder v) => v.showItemNumbering;
  static const Field<MediaFolder, bool> _f$showItemNumbering = Field(
    'showItemNumbering',
    _$showItemNumbering,
  );
  static String? _$parent(MediaFolder v) => v.parent;
  static const Field<MediaFolder, String> _f$parent = Field(
    'parent',
    _$parent,
    opt: true,
  );
  static int _$sortHint(MediaFolder v) => v.sortHint;
  static const Field<MediaFolder, int> _f$sortHint = Field(
    'sortHint',
    _$sortHint,
  );
  static String _$name(MediaFolder v) => v.name;
  static const Field<MediaFolder, String> _f$name = Field('name', _$name);
  static String? _$fromDateTime(MediaFolder v) => v.fromDateTime;
  static const Field<MediaFolder, String> _f$fromDateTime = Field(
    'fromDateTime',
    _$fromDateTime,
    key: r'from_date_time',
    opt: true,
  );
  static String? _$toDateTime(MediaFolder v) => v.toDateTime;
  static const Field<MediaFolder, String> _f$toDateTime = Field(
    'toDateTime',
    _$toDateTime,
    key: r'to_date_time',
    opt: true,
  );
  static String? _$id(MediaFolder v) => v.id;
  static const Field<MediaFolder, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(MediaFolder v) =>
      v.attachments;
  static const Field<MediaFolder, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(MediaFolder v) => v.deleted;
  static const Field<MediaFolder, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static String? _$rev(MediaFolder v) => v.rev;
  static const Field<MediaFolder, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Revisions? _$revisions(MediaFolder v) => v.revisions;
  static const Field<MediaFolder, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(MediaFolder v) => v.revsInfo;
  static const Field<MediaFolder, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(MediaFolder v) => v.unmappedProps;
  static const Field<MediaFolder, Map<String, dynamic>> _f$unmappedProps =
      Field('unmappedProps', _$unmappedProps, opt: true, def: const {});

  @override
  final MappableFields<MediaFolder> fields = const {
    #showItemNumbering: _f$showItemNumbering,
    #parent: _f$parent,
    #sortHint: _f$sortHint,
    #name: _f$name,
    #fromDateTime: _f$fromDateTime,
    #toDateTime: _f$toDateTime,
    #id: _f$id,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #rev: _f$rev,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = "media_folder";
  @override
  late final ClassMapperBase superMapper = MediaBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static MediaFolder _instantiate(DecodingData data) {
    return MediaFolder(
      showItemNumbering: data.dec(_f$showItemNumbering),
      parent: data.dec(_f$parent),
      sortHint: data.dec(_f$sortHint),
      name: data.dec(_f$name),
      fromDateTime: data.dec(_f$fromDateTime),
      toDateTime: data.dec(_f$toDateTime),
      id: data.dec(_f$id),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      rev: data.dec(_f$rev),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MediaFolder fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MediaFolder>(map);
  }

  static MediaFolder fromJson(String json) {
    return ensureInitialized().decodeJson<MediaFolder>(json);
  }
}

mixin MediaFolderMappable {
  String toJson() {
    return MediaFolderMapper.ensureInitialized().encodeJson<MediaFolder>(
      this as MediaFolder,
    );
  }

  Map<String, dynamic> toMap() {
    return MediaFolderMapper.ensureInitialized().encodeMap<MediaFolder>(
      this as MediaFolder,
    );
  }

  MediaFolderCopyWith<MediaFolder, MediaFolder, MediaFolder> get copyWith =>
      _MediaFolderCopyWithImpl<MediaFolder, MediaFolder>(
        this as MediaFolder,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MediaFolderMapper.ensureInitialized().stringifyValue(
      this as MediaFolder,
    );
  }

  @override
  bool operator ==(Object other) {
    return MediaFolderMapper.ensureInitialized().equalsValue(
      this as MediaFolder,
      other,
    );
  }

  @override
  int get hashCode {
    return MediaFolderMapper.ensureInitialized().hashValue(this as MediaFolder);
  }
}

extension MediaFolderValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MediaFolder, $Out> {
  MediaFolderCopyWith<$R, MediaFolder, $Out> get $asMediaFolder =>
      $base.as((v, t, t2) => _MediaFolderCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MediaFolderCopyWith<$R, $In extends MediaFolder, $Out>
    implements MediaBaseCopyWith<$R, $In, $Out> {
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
    bool? showItemNumbering,
    String? parent,
    int? sortHint,
    String? name,
    String? fromDateTime,
    String? toDateTime,
    String? id,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    String? rev,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  MediaFolderCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MediaFolderCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MediaFolder, $Out>
    implements MediaFolderCopyWith<$R, MediaFolder, $Out> {
  _MediaFolderCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MediaFolder> $mapper =
      MediaFolderMapper.ensureInitialized();
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
    bool? showItemNumbering,
    Object? parent = $none,
    int? sortHint,
    String? name,
    Object? fromDateTime = $none,
    Object? toDateTime = $none,
    Object? id = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? rev = $none,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (showItemNumbering != null) #showItemNumbering: showItemNumbering,
      if (parent != $none) #parent: parent,
      if (sortHint != null) #sortHint: sortHint,
      if (name != null) #name: name,
      if (fromDateTime != $none) #fromDateTime: fromDateTime,
      if (toDateTime != $none) #toDateTime: toDateTime,
      if (id != $none) #id: id,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (rev != $none) #rev: rev,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  MediaFolder $make(CopyWithData data) => MediaFolder(
    showItemNumbering: data.get(
      #showItemNumbering,
      or: $value.showItemNumbering,
    ),
    parent: data.get(#parent, or: $value.parent),
    sortHint: data.get(#sortHint, or: $value.sortHint),
    name: data.get(#name, or: $value.name),
    fromDateTime: data.get(#fromDateTime, or: $value.fromDateTime),
    toDateTime: data.get(#toDateTime, or: $value.toDateTime),
    id: data.get(#id, or: $value.id),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    rev: data.get(#rev, or: $value.rev),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  MediaFolderCopyWith<$R2, MediaFolder, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MediaFolderCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MediaItemMapper extends SubClassMapperBase<MediaItem> {
  MediaItemMapper._();

  static MediaItemMapper? _instance;
  static MediaItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MediaItemMapper._());
      MediaBaseMapper.ensureInitialized().addSubMapper(_instance!);
      MediaAttachmentMapper.ensureInitialized();
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MediaItem';

  static String? _$parent(MediaItem v) => v.parent;
  static const Field<MediaItem, String> _f$parent = Field(
    'parent',
    _$parent,
    opt: true,
  );
  static int _$sortHint(MediaItem v) => v.sortHint;
  static const Field<MediaItem, int> _f$sortHint = Field(
    'sortHint',
    _$sortHint,
  );
  static String _$name(MediaItem v) => v.name;
  static const Field<MediaItem, String> _f$name = Field('name', _$name);
  static List<MediaAttachment> _$media(MediaItem v) => v.media;
  static const Field<MediaItem, List<MediaAttachment>> _f$media = Field(
    'media',
    _$media,
  );
  static bool _$repeat(MediaItem v) => v.repeat;
  static const Field<MediaItem, bool> _f$repeat = Field('repeat', _$repeat);
  static bool _$shuffle(MediaItem v) => v.shuffle;
  static const Field<MediaItem, bool> _f$shuffle = Field('shuffle', _$shuffle);
  static bool _$showTrackCoverRatherThanItemCover(MediaItem v) =>
      v.showTrackCoverRatherThanItemCover;
  static const Field<MediaItem, bool> _f$showTrackCoverRatherThanItemCover =
      Field(
        'showTrackCoverRatherThanItemCover',
        _$showTrackCoverRatherThanItemCover,
        key: r'show_track_cover_rather_than_item_cover',
      );
  static bool _$isAudioBook(MediaItem v) => v.isAudioBook;
  static const Field<MediaItem, bool> _f$isAudioBook = Field(
    'isAudioBook',
    _$isAudioBook,
    key: r'is_audio_book',
  );
  static bool _$isNew(MediaItem v) => v.isNew;
  static const Field<MediaItem, bool> _f$isNew = Field(
    'isNew',
    _$isNew,
    key: r'is_new',
  );
  static String? _$fromDateTime(MediaItem v) => v.fromDateTime;
  static const Field<MediaItem, String> _f$fromDateTime = Field(
    'fromDateTime',
    _$fromDateTime,
    key: r'from_date_time',
    opt: true,
  );
  static String? _$toDateTime(MediaItem v) => v.toDateTime;
  static const Field<MediaItem, String> _f$toDateTime = Field(
    'toDateTime',
    _$toDateTime,
    key: r'to_date_time',
    opt: true,
  );
  static String? _$id(MediaItem v) => v.id;
  static const Field<MediaItem, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(MediaItem v) =>
      v.attachments;
  static const Field<MediaItem, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(MediaItem v) => v.deleted;
  static const Field<MediaItem, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static String? _$rev(MediaItem v) => v.rev;
  static const Field<MediaItem, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Revisions? _$revisions(MediaItem v) => v.revisions;
  static const Field<MediaItem, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(MediaItem v) => v.revsInfo;
  static const Field<MediaItem, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(MediaItem v) => v.unmappedProps;
  static const Field<MediaItem, Map<String, dynamic>> _f$unmappedProps = Field(
    'unmappedProps',
    _$unmappedProps,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<MediaItem> fields = const {
    #parent: _f$parent,
    #sortHint: _f$sortHint,
    #name: _f$name,
    #media: _f$media,
    #repeat: _f$repeat,
    #shuffle: _f$shuffle,
    #showTrackCoverRatherThanItemCover: _f$showTrackCoverRatherThanItemCover,
    #isAudioBook: _f$isAudioBook,
    #isNew: _f$isNew,
    #fromDateTime: _f$fromDateTime,
    #toDateTime: _f$toDateTime,
    #id: _f$id,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #rev: _f$rev,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = "media_item";
  @override
  late final ClassMapperBase superMapper = MediaBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static MediaItem _instantiate(DecodingData data) {
    return MediaItem(
      parent: data.dec(_f$parent),
      sortHint: data.dec(_f$sortHint),
      name: data.dec(_f$name),
      media: data.dec(_f$media),
      repeat: data.dec(_f$repeat),
      shuffle: data.dec(_f$shuffle),
      showTrackCoverRatherThanItemCover: data.dec(
        _f$showTrackCoverRatherThanItemCover,
      ),
      isAudioBook: data.dec(_f$isAudioBook),
      isNew: data.dec(_f$isNew),
      fromDateTime: data.dec(_f$fromDateTime),
      toDateTime: data.dec(_f$toDateTime),
      id: data.dec(_f$id),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      rev: data.dec(_f$rev),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MediaItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MediaItem>(map);
  }

  static MediaItem fromJson(String json) {
    return ensureInitialized().decodeJson<MediaItem>(json);
  }
}

mixin MediaItemMappable {
  String toJson() {
    return MediaItemMapper.ensureInitialized().encodeJson<MediaItem>(
      this as MediaItem,
    );
  }

  Map<String, dynamic> toMap() {
    return MediaItemMapper.ensureInitialized().encodeMap<MediaItem>(
      this as MediaItem,
    );
  }

  MediaItemCopyWith<MediaItem, MediaItem, MediaItem> get copyWith =>
      _MediaItemCopyWithImpl<MediaItem, MediaItem>(
        this as MediaItem,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MediaItemMapper.ensureInitialized().stringifyValue(
      this as MediaItem,
    );
  }

  @override
  bool operator ==(Object other) {
    return MediaItemMapper.ensureInitialized().equalsValue(
      this as MediaItem,
      other,
    );
  }

  @override
  int get hashCode {
    return MediaItemMapper.ensureInitialized().hashValue(this as MediaItem);
  }
}

extension MediaItemValueCopy<$R, $Out> on ObjectCopyWith<$R, MediaItem, $Out> {
  MediaItemCopyWith<$R, MediaItem, $Out> get $asMediaItem =>
      $base.as((v, t, t2) => _MediaItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MediaItemCopyWith<$R, $In extends MediaItem, $Out>
    implements MediaBaseCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    MediaAttachment,
    MediaAttachmentCopyWith<$R, MediaAttachment, MediaAttachment>
  >
  get media;
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
    String? parent,
    int? sortHint,
    String? name,
    List<MediaAttachment>? media,
    bool? repeat,
    bool? shuffle,
    bool? showTrackCoverRatherThanItemCover,
    bool? isAudioBook,
    bool? isNew,
    String? fromDateTime,
    String? toDateTime,
    String? id,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    String? rev,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  MediaItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MediaItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MediaItem, $Out>
    implements MediaItemCopyWith<$R, MediaItem, $Out> {
  _MediaItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MediaItem> $mapper =
      MediaItemMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    MediaAttachment,
    MediaAttachmentCopyWith<$R, MediaAttachment, MediaAttachment>
  >
  get media => ListCopyWith(
    $value.media,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(media: v),
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
    Object? parent = $none,
    int? sortHint,
    String? name,
    List<MediaAttachment>? media,
    bool? repeat,
    bool? shuffle,
    bool? showTrackCoverRatherThanItemCover,
    bool? isAudioBook,
    bool? isNew,
    Object? fromDateTime = $none,
    Object? toDateTime = $none,
    Object? id = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? rev = $none,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (parent != $none) #parent: parent,
      if (sortHint != null) #sortHint: sortHint,
      if (name != null) #name: name,
      if (media != null) #media: media,
      if (repeat != null) #repeat: repeat,
      if (shuffle != null) #shuffle: shuffle,
      if (showTrackCoverRatherThanItemCover != null)
        #showTrackCoverRatherThanItemCover: showTrackCoverRatherThanItemCover,
      if (isAudioBook != null) #isAudioBook: isAudioBook,
      if (isNew != null) #isNew: isNew,
      if (fromDateTime != $none) #fromDateTime: fromDateTime,
      if (toDateTime != $none) #toDateTime: toDateTime,
      if (id != $none) #id: id,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (rev != $none) #rev: rev,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  MediaItem $make(CopyWithData data) => MediaItem(
    parent: data.get(#parent, or: $value.parent),
    sortHint: data.get(#sortHint, or: $value.sortHint),
    name: data.get(#name, or: $value.name),
    media: data.get(#media, or: $value.media),
    repeat: data.get(#repeat, or: $value.repeat),
    shuffle: data.get(#shuffle, or: $value.shuffle),
    showTrackCoverRatherThanItemCover: data.get(
      #showTrackCoverRatherThanItemCover,
      or: $value.showTrackCoverRatherThanItemCover,
    ),
    isAudioBook: data.get(#isAudioBook, or: $value.isAudioBook),
    isNew: data.get(#isNew, or: $value.isNew),
    fromDateTime: data.get(#fromDateTime, or: $value.fromDateTime),
    toDateTime: data.get(#toDateTime, or: $value.toDateTime),
    id: data.get(#id, or: $value.id),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    rev: data.get(#rev, or: $value.rev),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  MediaItemCopyWith<$R2, MediaItem, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MediaItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MediaAttachmentMapper extends ClassMapperBase<MediaAttachment> {
  MediaAttachmentMapper._();

  static MediaAttachmentMapper? _instance;
  static MediaAttachmentMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MediaAttachmentMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MediaAttachment';

  static String _$fileName(MediaAttachment v) => v.fileName;
  static const Field<MediaAttachment, String> _f$fileName = Field(
    'fileName',
    _$fileName,
  );
  static String? _$_title(MediaAttachment v) => v._title;
  static const Field<MediaAttachment, String> _f$_title = Field(
    '_title',
    _$_title,
    key: r'title',
    opt: true,
  );
  static String _$attachmentId(MediaAttachment v) => v.attachmentId;
  static const Field<MediaAttachment, String> _f$attachmentId = Field(
    'attachmentId',
    _$attachmentId,
    key: r'attachment_id',
  );
  static String? _$artist(MediaAttachment v) => v.artist;
  static const Field<MediaAttachment, String> _f$artist = Field(
    'artist',
    _$artist,
    opt: true,
  );
  static String? _$album(MediaAttachment v) => v.album;
  static const Field<MediaAttachment, String> _f$album = Field(
    'album',
    _$album,
    opt: true,
  );
  static int? _$track(MediaAttachment v) => v.track;
  static const Field<MediaAttachment, int> _f$track = Field(
    'track',
    _$track,
    opt: true,
  );
  static int? _$trackTotal(MediaAttachment v) => v.trackTotal;
  static const Field<MediaAttachment, int> _f$trackTotal = Field(
    'trackTotal',
    _$trackTotal,
    opt: true,
  );
  static int? _$disc(MediaAttachment v) => v.disc;
  static const Field<MediaAttachment, int> _f$disc = Field(
    'disc',
    _$disc,
    opt: true,
  );
  static int? _$discTotal(MediaAttachment v) => v.discTotal;
  static const Field<MediaAttachment, int> _f$discTotal = Field(
    'discTotal',
    _$discTotal,
    opt: true,
  );
  static double? _$lufs(MediaAttachment v) => v.lufs;
  static const Field<MediaAttachment, double> _f$lufs = Field(
    'lufs',
    _$lufs,
    opt: true,
  );
  static double? _$lra(MediaAttachment v) => v.lra;
  static const Field<MediaAttachment, double> _f$lra = Field(
    'lra',
    _$lra,
    opt: true,
  );
  static double? _$truePeak(MediaAttachment v) => v.truePeak;
  static const Field<MediaAttachment, double> _f$truePeak = Field(
    'truePeak',
    _$truePeak,
    key: r'true_peak',
    opt: true,
  );
  static int? _$durationMs(MediaAttachment v) => v.durationMs;
  static const Field<MediaAttachment, int> _f$durationMs = Field(
    'durationMs',
    _$durationMs,
    key: r'duration_ms',
    opt: true,
  );

  @override
  final MappableFields<MediaAttachment> fields = const {
    #fileName: _f$fileName,
    #_title: _f$_title,
    #attachmentId: _f$attachmentId,
    #artist: _f$artist,
    #album: _f$album,
    #track: _f$track,
    #trackTotal: _f$trackTotal,
    #disc: _f$disc,
    #discTotal: _f$discTotal,
    #lufs: _f$lufs,
    #lra: _f$lra,
    #truePeak: _f$truePeak,
    #durationMs: _f$durationMs,
  };
  @override
  final bool ignoreNull = true;

  static MediaAttachment _instantiate(DecodingData data) {
    return MediaAttachment(
      fileName: data.dec(_f$fileName),
      title: data.dec(_f$_title),
      attachmentId: data.dec(_f$attachmentId),
      artist: data.dec(_f$artist),
      album: data.dec(_f$album),
      track: data.dec(_f$track),
      trackTotal: data.dec(_f$trackTotal),
      disc: data.dec(_f$disc),
      discTotal: data.dec(_f$discTotal),
      lufs: data.dec(_f$lufs),
      lra: data.dec(_f$lra),
      truePeak: data.dec(_f$truePeak),
      durationMs: data.dec(_f$durationMs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MediaAttachment fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MediaAttachment>(map);
  }

  static MediaAttachment fromJson(String json) {
    return ensureInitialized().decodeJson<MediaAttachment>(json);
  }
}

mixin MediaAttachmentMappable {
  String toJson() {
    return MediaAttachmentMapper.ensureInitialized()
        .encodeJson<MediaAttachment>(this as MediaAttachment);
  }

  Map<String, dynamic> toMap() {
    return MediaAttachmentMapper.ensureInitialized().encodeMap<MediaAttachment>(
      this as MediaAttachment,
    );
  }

  MediaAttachmentCopyWith<MediaAttachment, MediaAttachment, MediaAttachment>
  get copyWith =>
      _MediaAttachmentCopyWithImpl<MediaAttachment, MediaAttachment>(
        this as MediaAttachment,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MediaAttachmentMapper.ensureInitialized().stringifyValue(
      this as MediaAttachment,
    );
  }

  @override
  bool operator ==(Object other) {
    return MediaAttachmentMapper.ensureInitialized().equalsValue(
      this as MediaAttachment,
      other,
    );
  }

  @override
  int get hashCode {
    return MediaAttachmentMapper.ensureInitialized().hashValue(
      this as MediaAttachment,
    );
  }
}

extension MediaAttachmentValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MediaAttachment, $Out> {
  MediaAttachmentCopyWith<$R, MediaAttachment, $Out> get $asMediaAttachment =>
      $base.as((v, t, t2) => _MediaAttachmentCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MediaAttachmentCopyWith<$R, $In extends MediaAttachment, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? fileName,
    String? title,
    String? attachmentId,
    String? artist,
    String? album,
    int? track,
    int? trackTotal,
    int? disc,
    int? discTotal,
    double? lufs,
    double? lra,
    double? truePeak,
    int? durationMs,
  });
  MediaAttachmentCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _MediaAttachmentCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MediaAttachment, $Out>
    implements MediaAttachmentCopyWith<$R, MediaAttachment, $Out> {
  _MediaAttachmentCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MediaAttachment> $mapper =
      MediaAttachmentMapper.ensureInitialized();
  @override
  $R call({
    String? fileName,
    Object? title = $none,
    String? attachmentId,
    Object? artist = $none,
    Object? album = $none,
    Object? track = $none,
    Object? trackTotal = $none,
    Object? disc = $none,
    Object? discTotal = $none,
    Object? lufs = $none,
    Object? lra = $none,
    Object? truePeak = $none,
    Object? durationMs = $none,
  }) => $apply(
    FieldCopyWithData({
      if (fileName != null) #fileName: fileName,
      if (title != $none) #title: title,
      if (attachmentId != null) #attachmentId: attachmentId,
      if (artist != $none) #artist: artist,
      if (album != $none) #album: album,
      if (track != $none) #track: track,
      if (trackTotal != $none) #trackTotal: trackTotal,
      if (disc != $none) #disc: disc,
      if (discTotal != $none) #discTotal: discTotal,
      if (lufs != $none) #lufs: lufs,
      if (lra != $none) #lra: lra,
      if (truePeak != $none) #truePeak: truePeak,
      if (durationMs != $none) #durationMs: durationMs,
    }),
  );
  @override
  MediaAttachment $make(CopyWithData data) => MediaAttachment(
    fileName: data.get(#fileName, or: $value.fileName),
    title: data.get(#title, or: $value._title),
    attachmentId: data.get(#attachmentId, or: $value.attachmentId),
    artist: data.get(#artist, or: $value.artist),
    album: data.get(#album, or: $value.album),
    track: data.get(#track, or: $value.track),
    trackTotal: data.get(#trackTotal, or: $value.trackTotal),
    disc: data.get(#disc, or: $value.disc),
    discTotal: data.get(#discTotal, or: $value.discTotal),
    lufs: data.get(#lufs, or: $value.lufs),
    lra: data.get(#lra, or: $value.lra),
    truePeak: data.get(#truePeak, or: $value.truePeak),
    durationMs: data.get(#durationMs, or: $value.durationMs),
  );

  @override
  MediaAttachmentCopyWith<$R2, MediaAttachment, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MediaAttachmentCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MediaTrackMapper extends SubClassMapperBase<MediaTrack> {
  MediaTrackMapper._();

  static MediaTrackMapper? _instance;
  static MediaTrackMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MediaTrackMapper._());
      CouchDocumentBaseMapper.ensureInitialized().addSubMapper(_instance!);
      AttachmentInfoMapper.ensureInitialized();
      RevisionsMapper.ensureInitialized();
      RevsInfoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'MediaTrack';

  static String _$parent(MediaTrack v) => v.parent;
  static const Field<MediaTrack, String> _f$parent = Field('parent', _$parent);
  static String _$contentType(MediaTrack v) => v.contentType;
  static const Field<MediaTrack, String> _f$contentType = Field(
    'contentType',
    _$contentType,
    key: r'content_type',
  );
  static String? _$id(MediaTrack v) => v.id;
  static const Field<MediaTrack, String> _f$id = Field(
    'id',
    _$id,
    key: r'_id',
    opt: true,
  );
  static Map<String, AttachmentInfo>? _$attachments(MediaTrack v) =>
      v.attachments;
  static const Field<MediaTrack, Map<String, AttachmentInfo>> _f$attachments =
      Field('attachments', _$attachments, key: r'_attachments', opt: true);
  static bool _$deleted(MediaTrack v) => v.deleted;
  static const Field<MediaTrack, bool> _f$deleted = Field(
    'deleted',
    _$deleted,
    key: r'_deleted',
    opt: true,
    def: false,
  );
  static String? _$rev(MediaTrack v) => v.rev;
  static const Field<MediaTrack, String> _f$rev = Field(
    'rev',
    _$rev,
    key: r'_rev',
    opt: true,
  );
  static Revisions? _$revisions(MediaTrack v) => v.revisions;
  static const Field<MediaTrack, Revisions> _f$revisions = Field(
    'revisions',
    _$revisions,
    key: r'_revisions',
    opt: true,
  );
  static List<RevsInfo>? _$revsInfo(MediaTrack v) => v.revsInfo;
  static const Field<MediaTrack, List<RevsInfo>> _f$revsInfo = Field(
    'revsInfo',
    _$revsInfo,
    key: r'_revs_info',
    opt: true,
  );
  static Map<String, dynamic> _$unmappedProps(MediaTrack v) => v.unmappedProps;
  static const Field<MediaTrack, Map<String, dynamic>> _f$unmappedProps = Field(
    'unmappedProps',
    _$unmappedProps,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<MediaTrack> fields = const {
    #parent: _f$parent,
    #contentType: _f$contentType,
    #id: _f$id,
    #attachments: _f$attachments,
    #deleted: _f$deleted,
    #rev: _f$rev,
    #revisions: _f$revisions,
    #revsInfo: _f$revsInfo,
    #unmappedProps: _f$unmappedProps,
  };
  @override
  final bool ignoreNull = true;

  @override
  final String discriminatorKey = '!doc_type';
  @override
  final dynamic discriminatorValue = "media_track";
  @override
  late final ClassMapperBase superMapper =
      CouchDocumentBaseMapper.ensureInitialized();

  @override
  final MappingHook superHook = const ChainedHook([
    CouchDocumentBaseRawHook(),
    UnmappedPropertiesHook('unmappedProps'),
  ]);

  static MediaTrack _instantiate(DecodingData data) {
    return MediaTrack(
      parent: data.dec(_f$parent),
      contentType: data.dec(_f$contentType),
      id: data.dec(_f$id),
      attachments: data.dec(_f$attachments),
      deleted: data.dec(_f$deleted),
      rev: data.dec(_f$rev),
      revisions: data.dec(_f$revisions),
      revsInfo: data.dec(_f$revsInfo),
      unmappedProps: data.dec(_f$unmappedProps),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MediaTrack fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MediaTrack>(map);
  }

  static MediaTrack fromJson(String json) {
    return ensureInitialized().decodeJson<MediaTrack>(json);
  }
}

mixin MediaTrackMappable {
  String toJson() {
    return MediaTrackMapper.ensureInitialized().encodeJson<MediaTrack>(
      this as MediaTrack,
    );
  }

  Map<String, dynamic> toMap() {
    return MediaTrackMapper.ensureInitialized().encodeMap<MediaTrack>(
      this as MediaTrack,
    );
  }

  MediaTrackCopyWith<MediaTrack, MediaTrack, MediaTrack> get copyWith =>
      _MediaTrackCopyWithImpl<MediaTrack, MediaTrack>(
        this as MediaTrack,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MediaTrackMapper.ensureInitialized().stringifyValue(
      this as MediaTrack,
    );
  }

  @override
  bool operator ==(Object other) {
    return MediaTrackMapper.ensureInitialized().equalsValue(
      this as MediaTrack,
      other,
    );
  }

  @override
  int get hashCode {
    return MediaTrackMapper.ensureInitialized().hashValue(this as MediaTrack);
  }
}

extension MediaTrackValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MediaTrack, $Out> {
  MediaTrackCopyWith<$R, MediaTrack, $Out> get $asMediaTrack =>
      $base.as((v, t, t2) => _MediaTrackCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MediaTrackCopyWith<$R, $In extends MediaTrack, $Out>
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
    String? parent,
    String? contentType,
    String? id,
    Map<String, AttachmentInfo>? attachments,
    bool? deleted,
    String? rev,
    Revisions? revisions,
    List<RevsInfo>? revsInfo,
    Map<String, dynamic>? unmappedProps,
  });
  MediaTrackCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MediaTrackCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MediaTrack, $Out>
    implements MediaTrackCopyWith<$R, MediaTrack, $Out> {
  _MediaTrackCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MediaTrack> $mapper =
      MediaTrackMapper.ensureInitialized();
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
    String? parent,
    String? contentType,
    Object? id = $none,
    Object? attachments = $none,
    bool? deleted,
    Object? rev = $none,
    Object? revisions = $none,
    Object? revsInfo = $none,
    Map<String, dynamic>? unmappedProps,
  }) => $apply(
    FieldCopyWithData({
      if (parent != null) #parent: parent,
      if (contentType != null) #contentType: contentType,
      if (id != $none) #id: id,
      if (attachments != $none) #attachments: attachments,
      if (deleted != null) #deleted: deleted,
      if (rev != $none) #rev: rev,
      if (revisions != $none) #revisions: revisions,
      if (revsInfo != $none) #revsInfo: revsInfo,
      if (unmappedProps != null) #unmappedProps: unmappedProps,
    }),
  );
  @override
  MediaTrack $make(CopyWithData data) => MediaTrack(
    parent: data.get(#parent, or: $value.parent),
    contentType: data.get(#contentType, or: $value.contentType),
    id: data.get(#id, or: $value.id),
    attachments: data.get(#attachments, or: $value.attachments),
    deleted: data.get(#deleted, or: $value.deleted),
    rev: data.get(#rev, or: $value.rev),
    revisions: data.get(#revisions, or: $value.revisions),
    revsInfo: data.get(#revsInfo, or: $value.revsInfo),
    unmappedProps: data.get(#unmappedProps, or: $value.unmappedProps),
  );

  @override
  MediaTrackCopyWith<$R2, MediaTrack, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MediaTrackCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

