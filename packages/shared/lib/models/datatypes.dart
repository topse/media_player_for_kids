import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:dart_couch/dart_couch.dart';
import '../constraints/hearing_constraint.dart';
import '../constraints/play_log.dart';

part 'datatypes.mapper.dart';

/// Reference to a cover image, including which document it belongs to
class CoverImageReference {
  final String documentId;
  final String attachmentId;

  const CoverImageReference({
    required this.documentId,
    required this.attachmentId,
  });
}

@MappableClass(discriminatorValue: "media_base", ignoreNull: true)
abstract class MediaBase extends CouchDocumentBase with MediaBaseMappable {
  static const String coverAttachmentName = 'cover';

  final String? parent;
  final int sortHint;

  final String name;

  /// Optional date range for this media item/folder, in ISO 8601 format. Used for filtering and display purposes,
  /// for example prepare an "audio Adventskalender" playlist that only shows items with a date range covering the current date.
  /// The fromDateTime and toDateTime fields are independent (e.g. an item with only fromDateTime is valid from that date until indefinitely).
  @MappableField(key: 'from_date_time')
  final String? fromDateTime;
  @MappableField(key: 'to_date_time')
  final String? toDateTime;

  final bool hidden;

  @MappableField(key: 'hearing_constraint')
  final HearingConstraint? hearingConstraint;

  MediaBase({
    this.parent,
    required this.sortHint,
    required this.name,
    this.fromDateTime,
    this.toDateTime,
    this.hidden = false,
    this.hearingConstraint,
    super.id,
    super.attachments,
    super.deleted,
    super.rev,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });

  bool get hasCoverImage =>
      attachments?.containsKey(coverAttachmentName) ?? false;

  AttachmentInfo? get coverImage => attachments?[coverAttachmentName];

  void setCoverImage(AttachmentInfo info) {
    attachments?[coverAttachmentName] = info;
  }

  void removeCoverImage() {
    attachments?.remove(coverAttachmentName);
  }

  /// Deletes this folder/item together with everything that cascades from it,
  /// then purges the matching per-device play-position entries in one pass.
  ///
  /// Cascade rules (all required behaviour — see root CLAUDE.md "Catalog
  /// deletion"):
  ///  * [MediaFolder] → every descendant folder/item recursively, and for each
  ///    item its [MediaTrack] documents.
  ///  * [MediaItem] → the [MediaTrack] documents it references.
  ///  * The cover image of a folder/item, and the audio + cover of a track, are
  ///    attachments stored *on the document itself*, so CouchDB drops them with
  ///    the deletion tombstone — there is no separate attachment step.
  ///  * Every removed item id is purged from all `playposition-<uuid>`
  ///    documents (the "delete must drop the resume position immediately"
  ///    contract).
  ///
  /// The recent `playlog-<uuid>` is intentionally NOT touched here: its
  /// orphaned entries are swept on the companion's next startup so recent
  /// statistics remain available until then.
  ///
  /// Prefer this over [removeCascade] unless you are batching several deletions
  /// and want to run the play-position purge only once at the end.
  Future<void> delete(DartCouchDb db) async {
    final removedIds = await removeCascade(db);
    await PlayPosition.purgeItems(db, removedIds);
  }

  /// Removes this document and its in-tree / track dependents, returning the
  /// set of removed [MediaBase] ids. Does NOT touch the per-device side
  /// documents — [delete] does that once for the whole cascade. Subclasses
  /// implement the type-specific traversal.
  Future<Set<String>> removeCascade(DartCouchDb db);

  static const _weekdayAbbr = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static String _formatDate(DateTime dt) {
    final day = _weekdayAbbr[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$day, $d.$m.${dt.year}';
  }

  /// Returns a human-readable visibility restriction string, or null if there
  /// are no restrictions on this item.
  ///
  /// Examples:
  ///   fromDateTime only  → "Ab Mo, 03.03.2026"
  ///   toDateTime only    → "Bis So, 31.12.2026"
  ///   both               → "Mo, 03.03.2026 – So, 31.12.2026"
  String? get visibilityInfo {
    if (fromDateTime == null && toDateTime == null) return null;
    final from = fromDateTime != null ? DateTime.parse(fromDateTime!) : null;
    final to = toDateTime != null ? DateTime.parse(toDateTime!) : null;
    if (from != null && to != null) {
      return '${_formatDate(from)} – ${_formatDate(to)}';
    } else if (from != null) {
      return 'Ab ${_formatDate(from)}';
    } else {
      return 'Bis ${_formatDate(to!)}';
    }
  }

  /// Returns true if this item should be visible at the given [now].
  ///
  /// - [fromDateTime]: if set, the item is hidden until [now] has reached or passed it.
  /// - [toDateTime]: if set, the item is hidden once [now] has passed it.
  bool isVisibleAt(DateTime now) {
    if (fromDateTime != null) {
      final from = DateTime.parse(fromDateTime!);
      if (now.isBefore(from)) return false;
    }
    if (toDateTime != null) {
      final to = DateTime.parse(toDateTime!);
      if (now.isAfter(to)) return false;
    }
    return true;
  }

  /// Resolves the cover image to display for this media item/folder.
  ///
  /// This method implements a fallback chain to determine which image to show.
  /// Returns null if no image is available (caller should show a fallback icon).
  ///
  /// [allDocuments] - Map of all MediaBase documents by ID, needed for recursive
  /// resolution in folders.
  CoverImageReference? resolveCoverImageAttachmentId(
    Map<String, MediaBase> allDocuments,
  );

  static final fromMap = MediaBaseMapper.fromMap;
  static final fromJson = MediaBaseMapper.fromJson;
}

@MappableClass(discriminatorValue: "media_folder", ignoreNull: true)
class MediaFolder extends MediaBase with MediaFolderMappable {
  final bool showItemNumbering;

  MediaFolder({
    required this.showItemNumbering,
    super.parent,
    required super.sortHint,
    required super.name,
    super.fromDateTime,
    super.toDateTime,
    super.hidden,
    super.hearingConstraint,
    super.id,
    super.attachments,
    super.deleted,
    super.rev,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });

  static final fromMap = MediaFolderMapper.fromMap;
  static final fromJson = MediaFolderMapper.fromJson;

  /// Resolves cover image for folders.
  ///
  /// Selection algorithm:
  /// 1. Otherwise, use this folder's own cover image (_cover) if it exists
  /// 2. Otherwise, try to get the first child's cover image
  /// 3. Otherwise, return null (caller should show folder icon)
  @override
  CoverImageReference? resolveCoverImageAttachmentId(
    Map<String, MediaBase> allDocuments,
  ) {
    // Fall back to folder's own cover image (has priority over children's covers)
    if (hasCoverImage) {
      return CoverImageReference(
        documentId: id!,
        attachmentId: MediaBase.coverAttachmentName,
      );
    }

    // Fall back to first child's cover (first one that has a cover)
    final children =
        allDocuments.values.where((doc) => doc.parent == id).toList()
          ..sort((a, b) => a.sortHint.compareTo(b.sortHint));

    for (final child in children) {
      final childCover = child.resolveCoverImageAttachmentId(allDocuments);
      if (childCover != null) {
        return childCover;
      }
    }

    // No cover available
    return null;
  }

  /// Deletes every direct child (which recurses into their own cascade), then
  /// this folder. Children are read from the authoritative `mediatree/by_parent`
  /// view rather than any in-memory tree, so the cascade is complete regardless
  /// of what the caller has loaded. The view excludes `media_track` docs, so
  /// only child folders/items come back here.
  @override
  Future<Set<String>> removeCascade(DartCouchDb db) async {
    final removed = <String>{};
    final children = await db.query(
      'mediatree/by_parent',
      includeDocs: true,
      startkey: '[${jsonEncode(id)}]',
      endkey: '[${jsonEncode(id)},{}]',
    );
    if (children != null) {
      for (final row in children.rows) {
        final child = row.doc;
        if (child is MediaBase) {
          removed.addAll(await child.removeCascade(db));
        }
      }
    }
    await db.remove(id!, rev!);
    removed.add(id!);
    return removed;
  }

  @override
  String toString() {
    return 'MediaFolder(name: $name, parent: $parent, sortHint: $sortHint)';
  }
}

/// The attachments contain the media files
/// The contentType gives us the stored type:
/// | Format                 | File extension | `content_type`                          |
/// | ---------------------- | -------------- | --------------------------------------- |
/// | MP3                    | `.mp3`         | `audio/mpeg`                            |
/// | WAV                    | `.wav`         | `audio/wav` *(sometimes `audio/x-wav`)* |
/// | FLAC                   | `.flac`        | `audio/flac`                            |
/// | AAC                    | `.aac`         | `audio/aac`                             |
/// | AAC (in MP4 container) | `.m4a`         | `audio/mp4`                             |
///
/// The media-List gives the order in which the attachments should be used.
/// The Attachments have uuids as names.
@MappableClass(discriminatorValue: "media_item", ignoreNull: true)
class MediaItem extends MediaBase with MediaItemMappable {
  /// stores meta data of attached media files. Media files itself are stored as attachments.
  final List<MediaAttachment> media;

  final bool repeat;
  final bool shuffle;

  @MappableField(key: 'show_track_cover_rather_than_item_cover')
  final bool showTrackCoverRatherThanItemCover;

  @MappableField(key: 'is_audio_book')
  final bool isAudioBook;

  @MappableField(key: 'is_new')
  final bool isNew;

  MediaItem({
    super.parent,
    required super.sortHint,
    required super.name,
    required this.media,
    required this.repeat,
    required this.shuffle,
    required this.showTrackCoverRatherThanItemCover,
    required this.isAudioBook,
    required this.isNew,
    super.fromDateTime,
    super.toDateTime,
    super.hidden,
    super.hearingConstraint,
    super.id,
    super.attachments,
    super.deleted,
    super.rev,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });

  /// Resolves cover image for media items.
  ///
  /// Selection algorithm:
  /// 1. Use the base cover image (_cover) on this MediaItem if it exists
  /// 2. Otherwise, use the first track's cover image (from its MediaTrack doc)
  /// 3. Otherwise, return null (caller should show audio/video icon)
  @override
  CoverImageReference? resolveCoverImageAttachmentId(
    Map<String, MediaBase> allDocuments,
  ) {
    // Use the MediaItem's own cover image if present
    if (hasCoverImage) {
      return CoverImageReference(
        documentId: id!,
        attachmentId: MediaBase.coverAttachmentName,
      );
    }

    // Fall back to first track's cover image (attachmentId = MediaTrack doc ID)
    if (media.isNotEmpty) {
      return CoverImageReference(
        documentId: media.first.attachmentId,
        attachmentId: MediaTrack.coverAttachmentName,
      );
    }

    // No cover available
    return null;
  }

  /// Deletes every [MediaTrack] this item references (each track's audio + cover
  /// attachments go with it), then this item. Tracks that are orphaned outside
  /// the [media] list (e.g. a crash mid-import) are not visible here and are
  /// instead reclaimed by the companion's startup repair sweep.
  @override
  Future<Set<String>> removeCascade(DartCouchDb db) async {
    for (final m in media) {
      final track = await db.get(m.attachmentId);
      if (track is MediaTrack) {
        await track.delete(db);
      }
    }
    await db.remove(id!, rev!);
    return {id!};
  }

  static final fromMap = MediaItemMapper.fromMap;
  static final fromJson = MediaItemMapper.fromJson;
}

/// A single audio track document.
///
/// Each [MediaTrack] holds exactly one audio file as a CouchDB attachment
/// (attachment name: [audioAttachmentName]) and optionally a cover image
/// (attachment name: [coverAttachmentName]).
///
/// The [parent] field references the [MediaItem] document ID that owns this
/// track. The track is ordered via the [MediaItem.media] list — the
/// [MediaAttachment.attachmentId] in that list equals this document's [id].
///
/// This type intentionally does NOT extend [MediaBase] so that it never
/// appears as a node in the media tree view.
@MappableClass(discriminatorValue: "media_track", ignoreNull: true)
class MediaTrack extends CouchDocumentBase with MediaTrackMappable {
  /// Attachment name for the audio file stored on this document.
  static const String audioAttachmentName = 'audio';

  /// Attachment name for the cover image stored on this document.
  static const String coverAttachmentName = 'cover';

  /// ID of the parent [MediaItem] document.
  final String parent;

  /// MIME content-type of the audio attachment (e.g. `audio/mpeg`).
  @MappableField(key: 'content_type')
  final String contentType;

  MediaTrack({
    required this.parent,
    required this.contentType,
    super.id,
    super.attachments,
    super.deleted,
    super.rev,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });

  /// Deletes this track document. The audio and cover files are attachments on
  /// this document, so CouchDB removes them with the deletion tombstone — there
  /// is nothing further down the tree to cascade.
  ///
  /// Note: this does NOT update the owning [MediaItem.media] list. When you
  /// delete a single track in isolation (not as part of deleting its parent
  /// item via [MediaItem.delete]), also remove the matching [MediaAttachment]
  /// from the parent item and persist it, or the reference dangles until the
  /// companion's next startup repair.
  Future<void> delete(DartCouchDb db) async {
    await db.remove(id!, rev!);
  }

  static final fromMap = MediaTrackMapper.fromMap;
  static final fromJson = MediaTrackMapper.fromJson;
}

@MappableClass(ignoreNull: true)
class MediaAttachment with MediaAttachmentMappable {
  final String fileName;

  @MappableField(key: 'title')
  final String? _title;
  final String? artist;
  final String? album;
  final int? track;
  final int? trackTotal;
  final int? disc;
  final int? discTotal;

  /// EBU R128 Integrated Loudness in LUFS (full-file average).
  final double lufs;

  /// Maximum EBU R128 Momentary Loudness in LUFS (400 ms window) over the
  /// whole file. Null for files shorter than 400 ms or where every measurement
  /// frame was silence (ffmpeg reports 'nan' in those cases).
  final double? momentary;

  /// Maximum EBU R128 Short-Term Loudness in LUFS (3 s window) over the whole
  /// file. Null for files shorter than 3 s or where every measurement frame
  /// was silence (ffmpeg reports 'nan' in those cases).
  @MappableField(key: 'short_term')
  final double? shortTerm;

  /// EBU R128 Loudness Range in LU.
  final double lra;

  /// Maximum EBU R128 True Peak in dBTP across all channels and all frames.
  @MappableField(key: 'true_peak')
  final double truePeak;

  /// Audio duration in milliseconds.
  @MappableField(key: 'duration_ms')
  final int durationMs;

  /// The attachmentId is the _id of the MediaTrack document that holds this media file as an attachment.
  @MappableField(key: 'attachment_id')
  final String attachmentId;

  MediaAttachment({
    required this.fileName,
    String? title,
    required this.attachmentId,
    this.artist,
    this.album,
    this.track,
    this.trackTotal,
    this.disc,
    this.discTotal,
    this.lufs = 0.0,
    this.momentary,
    this.shortTerm,
    this.lra = 0.0,
    this.truePeak = 0.0,
    this.durationMs = 0,
  }) : _title = title;

  String get title {
    if (_title != null) return _title;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  }
}
