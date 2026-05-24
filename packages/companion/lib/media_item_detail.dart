import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:logging/logging.dart';
import 'package:watch_it/watch_it.dart';

import 'package:shared/shared.dart';
import 'audio_import_util.dart';
import 'media_base_header.dart';
import 'audio_player_service.dart';

class MediaItemDetail extends StatefulWidget {
  final MediaItem item;

  const MediaItemDetail({super.key, required this.item});

  @override
  State<MediaItemDetail> createState() => _MediaItemDetailState();
}

class _MediaItemDetailState extends State<MediaItemDetail> {
  static final _log = Logger('MediaItemDetail');
  bool _dragging = false;
  bool _reordering = false;
  late List<MediaAttachment> _mediaList;

  @override
  void initState() {
    super.initState();
    _mediaList = List.from(widget.item.media);
  }

  @override
  void didUpdateWidget(MediaItemDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.rev != oldWidget.item.rev) {
      setState(() {
        _mediaList = List.from(widget.item.media);
      });
    }
  }

  Widget _getLeadingWidget(MediaAttachment mediaAttachment) {
    // Load cover from the MediaTrack doc (null if no cover attachment).
    return FutureBuilder<Uint8List?>(
      future: di<DartCouchDb>().getAttachment(
        mediaAttachment.attachmentId,
        MediaTrack.coverAttachmentName,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              snapshot.data!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          );
        }
        return _getFallbackIcon(mediaAttachment);
      },
    );
  }

  Icon _getFallbackIcon(MediaAttachment mediaAttachment) {
    final contentType = getContentTypeFromExtension(mediaAttachment.fileName);
    if (contentType.startsWith('audio/')) {
      return const Icon(Icons.audiotrack);
    } else if (contentType.startsWith('video/')) {
      return const Icon(Icons.video_file);
    }
    return const Icon(Icons.insert_drive_file);
  }

  String _getDisplayName(MediaAttachment mediaAttachment) {
    return mediaAttachment.title;
  }

  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    // On Windows, desktop_drop never sets isDirectory on the native side, so
    // dropped folders arrive as plain DropItemFile entries. We therefore check
    // both the runtime type AND whether the path is a filesystem directory.
    final regularFiles = <XFile>[];
    final directoryPaths = <String>[];
    for (final item in details.files) {
      if (item is DropItemDirectory || Directory(item.path).existsSync()) {
        directoryPaths.add(item.path);
      } else {
        regularFiles.add(item);
      }
    }

    // Enumerate audio files from any dropped directories.
    final directoryFiles = <XFile>[];
    if (directoryPaths.isNotEmpty) {
      for (final dirPath in directoryPaths) {
        final entities = await Directory(
          dirPath,
        ).list(recursive: false).toList();
        final audioFiles = entities
            .whereType<File>()
            .where((f) {
              final ext = f.path
                  .split(RegExp(r'[/\\]'))
                  .last
                  .split('.')
                  .last
                  .toLowerCase();
              return audioExtensions.contains(ext);
            })
            .map((f) => XFile(f.path))
            .toList();
        directoryFiles.addAll(audioFiles);
      }

      if (directoryFiles.isEmpty && regularFiles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(SharedL10n.of(context).itemDetailNoFilesFound)),
          );
        }
        return;
      }

      if (directoryFiles.isNotEmpty) {
        if (!mounted) return;
        final l10n = SharedL10n.of(context);
        final count = directoryFiles.length;
        final folderName = directoryPaths.length == 1
            ? directoryPaths.first.split(RegExp(r'[/\\]')).last
            : l10n.itemDetailFoldersCount(directoryPaths.length);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.itemDetailImportTitle),
            content:
                Text(l10n.itemDetailImportConfirm(count, folderName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.commonImport),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
    }

    final allFiles = [...regularFiles, ...directoryFiles];
    if (allFiles.isEmpty) return;

    if (!mounted) return;

    final result = await importAudioFilesToDocument(
      context: context,
      files: allFiles,
      docId: widget.item.id!,
      docRev: widget.item.rev!,
    );

    if (result == null) return;

    if (result.attachments.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(SharedL10n.of(context).itemDetailNoFilesAdded)),
        );
      }
      return;
    }

    setState(() {
      _mediaList.addAll(result.attachments);
    });

    // Fetch the latest document so _attachments reflects all newly saved
    // attachments. Without this, put() would send the stale _attachments map
    // from widget.item, causing CouchDB to delete the new attachments.
    final freshDoc = await di<DartCouchDb>().get(widget.item.id!) as MediaItem?;
    if (freshDoc == null) {
      throw StateError(
        'Document ${widget.item.id} vanished after saving attachments',
      );
    }
    await di<DartCouchDb>().put(freshDoc.copyWith(media: _mediaList));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(SharedL10n.of(context)
            .itemDetailAddedSnack(result.attachments.length)),
      ),
    );
  }

  Future<void> _playMediaFile(MediaAttachment mediaAttachment) async {
    try {
      await di<AudioPlayerService>().play(widget.item, mediaAttachment);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                SharedL10n.of(context).itemDetailErrorPlaying(e.toString()))),
      );
    }
  }

  Future<void> _deleteMediaFile(MediaAttachment mediaAttachment) async {
    final l10n = SharedL10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itemDetailDeleteFileTitle),
        content: Text(
          l10n.itemDetailDeleteFileConfirm(_getDisplayName(mediaAttachment)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Fetch the MediaTrack document to get its current revision.
        final trackDoc = await di<DartCouchDb>().get(
          mediaAttachment.attachmentId,
        );
        if (trackDoc == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(l10n.itemDetailErrorTrackNotFound)),
          );
          return;
        }

        // Remove the entire MediaTrack doc (deletes audio + cover atomically).
        await di<DartCouchDb>().remove(trackDoc.id!, trackDoc.rev!);

        // Remove from media list and update the MediaItem.
        setState(() {
          _mediaList.remove(mediaAttachment);
        });

        await di<DartCouchDb>().put(widget.item.copyWith(media: _mediaList));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.itemDetailFileRemoved)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(l10n.itemDetailErrorRemovingFile(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaBaseHeader(
          key: ValueKey('${widget.item.id}_${widget.item.rev}'),
          media: widget.item,
        ),
        Expanded(
          child: DropTarget(
            onDragEntered: (_) => setState(() => _dragging = true),
            onDragExited: (_) => setState(() => _dragging = false),
            onDragDone: (details) async {
              setState(() => _dragging = false);
              await _handleDroppedFiles(details);
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 0,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.item.isAudioBook,
                                onChanged: (value) async {
                                  final isAudioBook = value ?? false;
                                  await di<DartCouchDb>().put(
                                    widget.item.copyWith(
                                      isAudioBook: isAudioBook,
                                      shuffle: isAudioBook
                                          ? false
                                          : widget.item.shuffle,
                                    ),
                                  );
                                },
                              ),
                              Text(SharedL10n.of(context).folderDetailAudioBook),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.item.shuffle,
                                onChanged: (value) async {
                                  final shuffle = value ?? false;
                                  await di<DartCouchDb>().put(
                                    widget.item.copyWith(
                                      shuffle: shuffle,
                                      isAudioBook: shuffle
                                          ? false
                                          : widget.item.isAudioBook,
                                    ),
                                  );
                                },
                              ),
                              Text(SharedL10n.of(context).itemDetailShuffle),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.item.repeat,
                                onChanged: (value) async {
                                  await di<DartCouchDb>().put(
                                    widget.item.copyWith(
                                      repeat: value ?? false,
                                    ),
                                  );
                                },
                              ),
                              Text(SharedL10n.of(context).itemDetailRepeat),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget
                                    .item
                                    .showTrackCoverRatherThanItemCover,
                                onChanged: (value) async {
                                  await di<DartCouchDb>().put(
                                    widget.item.copyWith(
                                      showTrackCoverRatherThanItemCover:
                                          value ?? false,
                                    ),
                                  );
                                },
                              ),
                              Text(
                                SharedL10n.of(context)
                                    .itemDetailUseTrackCovers,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.item.isNew,
                                onChanged: (value) async {
                                  await di<DartCouchDb>().put(
                                    widget.item.copyWith(isNew: value ?? false),
                                  );
                                },
                              ),
                              Text(SharedL10n.of(context).itemDetailNewFlag),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        "Media Files:",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_mediaList.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.audiotrack,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Drop audio/video files here',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Text(
                                  'Supported: mp3, ogg, flac, m4a, mp4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: _mediaList.length,
                            onReorderItem: (oldIndex, newIndex) async {
                              final sw = Stopwatch()..start();
                              _log.fine(
                                'onReorder start: $oldIndex -> $newIndex',
                              );
                              setState(() {
                                final item = _mediaList.removeAt(oldIndex);
                                _mediaList.insert(newIndex, item);
                                _reordering = true;
                              });
                              _log.fine(
                                'setState done: ${sw.elapsedMilliseconds}ms',
                              );
                              try {
                                final docToSave = widget.item.copyWith(
                                  media: _mediaList,
                                );
                                final bodyJson = jsonEncode(docToSave.toMap());
                                _log.fine(
                                  'PUT body size: ${bodyJson.length} bytes, '
                                  'attachments: ${docToSave.attachments?.length ?? 0}, '
                                  'media items: ${_mediaList.length}',
                                );
                                await di<DartCouchDb>().put(docToSave);
                                _log.fine(
                                  'put done: ${sw.elapsedMilliseconds}ms',
                                );
                              } finally {
                                _log.fine(
                                  'onReorder total: ${sw.elapsedMilliseconds}ms',
                                );
                                if (mounted) {
                                  setState(() => _reordering = false);
                                }
                              }
                            },
                            itemBuilder: (context, index) {
                              final mediaAttachment = _mediaList[index];
                              return ListTile(
                                key: ValueKey(mediaAttachment.attachmentId),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '${index + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.6),
                                            ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _getLeadingWidget(mediaAttachment),
                                  ],
                                ),
                                title: Text(_getDisplayName(mediaAttachment)),
                                subtitle: Text(
                                  "${mediaAttachment.track != null ? 'Track ${mediaAttachment.track!}: ' : ''}${mediaAttachment.album ?? ''}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      onPressed: () =>
                                          _playMediaFile(mediaAttachment),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                      onPressed: () =>
                                          _deleteMediaFile(mediaAttachment),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_reordering)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_dragging)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle,
                              size: 64,
                              color: Colors.blue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Drop files to add',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
