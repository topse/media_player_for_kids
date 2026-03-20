import 'dart:convert';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import 'audio_import_util.dart';
import 'media_base_header.dart';
import 'package:shared/shared.dart';

typedef ImportModeOption = ({
  String value,
  IconData icon,
  String title,
  String subtitle,
});

typedef ImportModeSelection = ({
  String mode,
  String? fromDateTime,
  String? toDateTime,
  bool isAudioBook,
  bool isNew,
});

class MediaFolderDetail extends StatefulWidget {
  final MediaFolder folder;
  final ViewResult? lastViewResult;
  final Function(MediaBase item)? selectNode;

  const MediaFolderDetail({
    super.key,
    required this.folder,
    this.lastViewResult,
    this.selectNode,
  });

  @override
  State<MediaFolderDetail> createState() => _MediaFolderDetailState();
}

class _MediaFolderDetailState extends State<MediaFolderDetail> {
  static const _weekdayAbbr = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  bool _dragging = false;
  List<ViewEntry>? _localChildren;

  @override
  void didUpdateWidget(covariant MediaFolderDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lastViewResult != widget.lastViewResult) {
      _localChildren = null;
    }
  }

  List<ViewEntry> get _children {
    if (widget.lastViewResult == null) return [];
    return widget.lastViewResult!.rows
        .where((row) => row.key[0] == widget.folder.id)
        .toList()
      ..sort((a, b) {
        final docA = a.doc as MediaBase;
        final docB = b.doc as MediaBase;
        return docA.sortHint.compareTo(docB.sortHint);
      });
  }

  Map<String, MediaBase> get _allDocuments {
    if (widget.lastViewResult == null) return {};
    return Map.fromEntries(
      widget.lastViewResult!.rows
          .where((row) => row.doc is MediaBase)
          .map((row) => MapEntry(row.id!, row.doc as MediaBase)),
    );
  }

  int _nextSortHint() {
    final children = _children;
    if (children.isEmpty) return 1;
    return children
            .map((r) => (r.doc as MediaBase).sortHint)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  String _stemName(String filePath) {
    final fn = filePath.split(RegExp(r'[/\\]')).last;
    final dot = fn.lastIndexOf('.');
    return dot > 0 ? fn.substring(0, dot) : fn;
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<ImportModeSelection?> _showImportOptionsDialog({
    required String title,
    required List<ImportModeOption> options,
  }) => showDialog<ImportModeSelection>(
    context: context,
    builder: (ctx) {
      DateTime? fromDate;
      DateTime? toDate;
      bool isAudioBook = false;
      bool isNew = true;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> pickFromDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: fromDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() => fromDate = picked);
            }
          }

          Future<void> pickToDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: toDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() => toDate = picked);
            }
          }

          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options) ...[
                    ListTile(
                      leading: Icon(option.icon),
                      title: Text(option.title),
                      subtitle: Text(option.subtitle),
                      onTap: () => Navigator.of(ctx).pop((
                        mode: option.value,
                        fromDateTime: fromDate?.toIso8601String(),
                        toDateTime: toDate?.toIso8601String(),
                        isAudioBook: isAudioBook,
                        isNew: isNew,
                      )),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Divider(),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isAudioBook,
                    onChanged: (value) {
                      setDialogState(() => isAudioBook = value ?? false);
                    },
                    title: const Text('Audio Book'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isNew,
                    onChanged: (value) {
                      setDialogState(() => isNew = value ?? true);
                    },
                    title: const Text('Is New'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Visible Date Range:'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 16),
                        const Text('From Date:'),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: pickFromDate,
                          child: Text(
                            fromDate != null
                                ? _formatDate(fromDate!)
                                : '*Not set*',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: fromDate != null
                              ? () => setDialogState(() => fromDate = null)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 16),
                        const Text('To Date:'),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: pickToDate,
                          child: Text(
                            toDate != null ? _formatDate(toDate!) : '*Not set*',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: toDate != null
                              ? () => setDialogState(() => toDate = null)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    },
  );

  Future<ImportModeSelection?> _showImportModeDialog(int fileCount) =>
      _showImportOptionsDialog(
        title: 'Import $fileCount audio files',
        options: [
          (
            value: 'single',
            icon: Icons.queue_music,
            title: 'Import all into a Single Media Item',
            subtitle: 'All files go into one item',
          ),
          (
            value: 'each',
            icon: Icons.audio_file,
            title: 'Each as a Separate Media Item',
            subtitle: 'One item per file',
          ),
        ],
      );

  Future<ImportModeSelection?> _showSingleFileImportModeDialog(
    String fileName,
  ) => _showImportOptionsDialog(
    title: 'Import audio file',
    options: [
      (
        value: 'single',
        icon: Icons.audio_file,
        title: 'Import as a Media Item',
        subtitle: fileName,
      ),
    ],
  );

  Future<ImportModeSelection?> _showFolderImportModeDialog(
    int folderCount,
    int fileCount,
  ) => _showImportOptionsDialog(
    title: 'Import $folderCount folders ($fileCount audio files)',
    options: [
      (
        value: 'each_folder',
        icon: Icons.folder,
        title: 'Each Folder as a Separate Media Item',
        subtitle: 'One item per folder, containing all its files',
      ),
      (
        value: 'single',
        icon: Icons.queue_music,
        title: 'Import all into a Single Media Item',
        subtitle: 'All files go into one item',
      ),
      (
        value: 'each',
        icon: Icons.audio_file,
        title: 'Each File as a Separate Media Item',
        subtitle: 'One item per audio file',
      ),
    ],
  );

  Future<String?> _showNameDialog(String defaultName) => showDialog<String>(
    context: context,
    builder: (ctx) {
      final ctrl = TextEditingController(text: defaultName);
      return AlertDialog(
        title: const Text('Name for new media item'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Item name'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );

  Future<String?> _showEditNameDialog(String currentName) => showDialog<String>(
    context: context,
    builder: (ctx) {
      final ctrl = TextEditingController(text: currentName);
      return AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.of(ctx).pop(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) Navigator.of(ctx).pop(t);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );

  Future<void> _editNameInline(MediaBase doc) async {
    final updatedName = await _showEditNameDialog(doc.name);
    if (updatedName == null || updatedName == doc.name) return;

    if (doc is MediaFolder) {
      await di<DartCouchDb>().put(doc.copyWith(name: updatedName));
    } else if (doc is MediaItem) {
      await di<DartCouchDb>().put(doc.copyWith(name: updatedName));
    }
  }

  String _formatIsoDate(String isoString) {
    final dt = DateTime.parse(isoString);
    final day = _weekdayAbbr[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$day $d.$m';
  }

  Future<void> _setFromDate(MediaBase media, DateTime? date) async {
    final iso = date?.toIso8601String();
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(fromDateTime: iso));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(fromDateTime: iso));
    }
  }

  Future<void> _setToDate(MediaBase media, DateTime? date) async {
    final iso = date?.toIso8601String();
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(toDateTime: iso));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(toDateTime: iso));
    }
  }

  Future<void> _pickFromDate(MediaBase media) async {
    final initial = media.fromDateTime != null
        ? DateTime.parse(media.fromDateTime!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) await _setFromDate(media, picked);
  }

  Future<void> _pickToDate(MediaBase media) async {
    final initial = media.toDateTime != null
        ? DateTime.parse(media.toDateTime!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) await _setToDate(media, picked);
  }

  Future<void> _toggleAudioBook(MediaItem item) async {
    final isAudioBook = !item.isAudioBook;
    await di<DartCouchDb>().put(
      item.copyWith(
        isAudioBook: isAudioBook,
        shuffle: isAudioBook ? false : item.shuffle,
      ),
    );
  }

  Future<void> _toggleIsNew(MediaItem item) async {
    await di<DartCouchDb>().put(item.copyWith(isNew: !item.isNew));
  }

  Widget _tinyLetterButton({
    required String label,
    required bool active,
    required String tooltip,
    required VoidCallback onPressed,
    IconData? leadingIcon,
    VoidCallback? onLongPress,
  }) {
    final textColor = active ? Colors.red.shade700 : Colors.grey.shade700;
    final bgColor = active
        ? Colors.red.withValues(alpha: 0.16)
        : Colors.grey.withValues(alpha: 0.2);
    final buttonWidth = leadingIcon != null
        ? label.length > 8
              ? 118.0
              : label.length > 2
              ? 104.0
              : 40.0
        : label.length > 8
        ? 106.0
        : label.length > 2
        ? 92.0
        : 26.0;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: buttonWidth,
        height: 22,
        child: TextButton(
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size(buttonWidth, 22),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: textColor,
            backgroundColor: bgColor,
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: leadingIcon == null
              ? Text(label)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(leadingIcon, size: 10),
                    const SizedBox(width: 2),
                    Text(label),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _tinyIconToggleButton({
    required IconData icon,
    required bool active,
    required VoidCallback onPressed,
  }) {
    final iconColor = active ? Colors.red.shade700 : Colors.grey.shade700;
    final bgColor = active
        ? Colors.red.withValues(alpha: 0.16)
        : Colors.grey.withValues(alpha: 0.2);
    return SizedBox(
      width: 26,
      height: 22,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 26, height: 22),
        visualDensity: VisualDensity.compact,
        splashRadius: 12,
        iconSize: 16,
        color: iconColor,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: bgColor,
        ),
        icon: Icon(icon),
      ),
    );
  }

  Widget _buildDateButtonsColumn(MediaBase doc) {
    final hasFromDate = doc.fromDateTime != null;
    final hasToDate = doc.toDateTime != null;
    final fromLabel = hasFromDate
        ? 'F: ${_formatIsoDate(doc.fromDateTime!)}'
        : 'F';
    final toLabel = hasToDate ? 'T: ${_formatIsoDate(doc.toDateTime!)}' : 'T';

    final fromTooltip = hasFromDate
        ? 'From: ${_formatIsoDate(doc.fromDateTime!)} (long press to clear)'
        : 'Set From date';
    final toTooltip = hasToDate
        ? 'To: ${_formatIsoDate(doc.toDateTime!)} (long press to clear)'
        : 'Set To date';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tinyLetterButton(
          label: fromLabel,
          active: hasFromDate,
          tooltip: fromTooltip,
          onPressed: () => _pickFromDate(doc),
          leadingIcon: Icons.calendar_today,
          onLongPress: hasFromDate ? () => _setFromDate(doc, null) : null,
        ),
        const SizedBox(height: 4),
        _tinyLetterButton(
          label: toLabel,
          active: hasToDate,
          tooltip: toTooltip,
          onPressed: () => _pickToDate(doc),
          leadingIcon: Icons.calendar_today,
          onLongPress: hasToDate ? () => _setToDate(doc, null) : null,
        ),
      ],
    );
  }

  Widget _buildFlagsColumn(MediaBase doc) {
    if (doc is! MediaItem) {
      return const SizedBox(width: 26, height: 48);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tinyIconToggleButton(
          icon: Icons.menu_book,
          active: doc.isAudioBook,
          onPressed: () => _toggleAudioBook(doc),
        ),
        const SizedBox(height: 4),
        _tinyIconToggleButton(
          icon: Icons.fiber_new,
          active: doc.isNew,
          onPressed: () => _toggleIsNew(doc),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(MediaBase doc) async {
    final isFolder = doc is MediaFolder;
    final label = isFolder ? 'folder' : 'item';
    final extra = isFolder ? ' This will also delete all its contents.' : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $label?'),
        content: Text('Really delete $label "${doc.name}"?$extra'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _deleteNodeRecursive(di<DartCouchDb>(), doc);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "${doc.name}"')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  /// Recursively deletes [node] and all its descendants.
  /// For [MediaItem] nodes, also deletes associated [MediaTrack] documents.
  Future<void> _deleteNodeRecursive(DartCouchDb db, MediaBase node) async {
    if (node is MediaFolder) {
      // Query all direct children from the view.
      final childrenResult = await db.query(
        'mediatree/by_parent',
        includeDocs: true,
        startkey: '[${jsonEncode(node.id)}]',
        endkey: '[${jsonEncode(node.id)},{}]',
      );
      if (childrenResult != null) {
        for (final row in childrenResult.rows) {
          if (row.doc is MediaBase) {
            await _deleteNodeRecursive(db, row.doc as MediaBase);
          }
        }
      }
    } else if (node is MediaItem) {
      // Delete all MediaTrack docs referenced by this item.
      for (final media in node.media) {
        final trackDoc = await db.get(media.attachmentId);
        if (trackDoc != null) {
          await db.remove(trackDoc.id!, trackDoc.rev!);
        }
      }
    }
    // Delete the node itself.
    await db.remove(node.id!, node.rev!);
  }

  Future<void> _handleDroppedFiles(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    // Separate dropped folders (with their audio files) from standalone files.
    final droppedFolders = <({String name, List<XFile> files})>[];
    final standaloneFiles = <XFile>[];

    for (final item in details.files) {
      if (Directory(item.path).existsSync()) {
        final folderName = item.path.split(RegExp(r'[/\\]')).last;
        final entities = await Directory(
          item.path,
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
        audioFiles.sort((a, b) => a.path.compareTo(b.path));
        if (audioFiles.isNotEmpty) {
          droppedFolders.add((name: folderName, files: audioFiles));
        }
      } else {
        standaloneFiles.add(item);
      }
    }

    final allFiles = [
      ...droppedFolders.expand((f) => f.files),
      ...standaloneFiles,
    ];

    if (allFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No audio files found')));
      }
      return;
    }

    // When multiple folders are dropped offer the folder-per-item option.
    if (droppedFolders.length >= 2) {
      final selection = await _showFolderImportModeDialog(
        droppedFolders.length,
        allFiles.length,
      );
      if (selection == null || !mounted) return;
      if (selection.mode == 'each_folder') {
        await _importFoldersAsItems(
          droppedFolders,
          fromDateTime: selection.fromDateTime,
          toDateTime: selection.toDateTime,
          isAudioBook: selection.isAudioBook,
          isNew: selection.isNew,
        );
      } else if (selection.mode == 'single') {
        final name = await _showNameDialog(droppedFolders.first.name);
        if (name == null || !mounted) return;
        await _importAsSingle(
          allFiles,
          nameFromDialog: name,
          fromDateTime: selection.fromDateTime,
          toDateTime: selection.toDateTime,
          isAudioBook: selection.isAudioBook,
          isNew: selection.isNew,
        );
      } else {
        await _importAsEach(
          allFiles,
          fromDateTime: selection.fromDateTime,
          toDateTime: selection.toDateTime,
          isAudioBook: selection.isAudioBook,
          isNew: selection.isNew,
        );
      }
      return;
    }

    // Original behaviour for a single folder or plain file drops.
    final folderSuggestedName = droppedFolders.isNotEmpty
        ? droppedFolders.first.name
        : null;
    final suggestedName = folderSuggestedName ?? _stemName(allFiles.first.path);

    if (allFiles.length == 1) {
      final singleFileName = allFiles.first.path.split(RegExp(r'[/\\]')).last;
      final selection = await _showSingleFileImportModeDialog(singleFileName);
      if (selection == null || !mounted) return;
      await _importAsSingle(
        allFiles,
        nameFromDialog: folderSuggestedName,
        fromDateTime: selection.fromDateTime,
        toDateTime: selection.toDateTime,
        isAudioBook: selection.isAudioBook,
        isNew: selection.isNew,
      );
    } else {
      final selection = await _showImportModeDialog(allFiles.length);
      if (selection == null || !mounted) return;
      if (selection.mode == 'single') {
        final name = await _showNameDialog(suggestedName);
        if (name == null || !mounted) return;
        await _importAsSingle(
          allFiles,
          nameFromDialog: name,
          fromDateTime: selection.fromDateTime,
          toDateTime: selection.toDateTime,
          isAudioBook: selection.isAudioBook,
          isNew: selection.isNew,
        );
      } else {
        await _importAsEach(
          allFiles,
          fromDateTime: selection.fromDateTime,
          toDateTime: selection.toDateTime,
          isAudioBook: selection.isAudioBook,
          isNew: selection.isNew,
        );
      }
    }
  }

  Future<void> _importAsSingle(
    List<XFile> files, {
    required String? nameFromDialog,
    String? fromDateTime,
    String? toDateTime,
    bool isAudioBook = false,
    bool isNew = true,
  }) async {
    final tentativeName = nameFromDialog ?? _stemName(files.first.path);

    final newItem = MediaItem(
      name: tentativeName,
      parent: widget.folder.id,
      sortHint: _nextSortHint(),
      media: [],
      repeat: false,
      shuffle: false,
      showTrackCoverRatherThanItemCover: false,
      isAudioBook: isAudioBook,
      isNew: isNew,
      fromDateTime: fromDateTime,
      toDateTime: toDateTime,
    );
    final postResult = await di<DartCouchDb>().post(newItem);
    if (!mounted) return;
    final newId = postResult.id;
    final newRev = postResult.rev;
    if (newId == null || newRev == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating media item')),
      );
      return;
    }

    final result = await importAudioFilesToDocument(
      context: context,
      files: files,
      docId: newId,
      docRev: newRev,
    );
    if (result == null || !mounted) return;

    if (result.attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid audio files were imported')),
      );
      return;
    }

    // For single-file drop: prefer metadata title as item name;
    // title is always non-null (falls back to fileName in the model)
    final finalName = nameFromDialog ?? result.attachments.first.title;

    // Fetch fresh doc so the _attachments map includes all saved attachments
    final freshDoc = await di<DartCouchDb>().get(newId) as MediaItem?;
    if (freshDoc == null) return;
    await di<DartCouchDb>().put(
      freshDoc.copyWith(name: finalName, media: result.attachments),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Created "$finalName" with ${result.attachments.length} file(s)',
        ),
      ),
    );
  }

  Future<void> _importAsEach(
    List<XFile> files, {
    String? fromDateTime,
    String? toDateTime,
    bool isAudioBook = false,
    bool isNew = true,
  }) async {
    int sortHint = _nextSortHint();
    int successCount = 0;

    final progress = ImportProgressDialog(
      context: context,
      totalFiles: files.length,
    );
    progress.show();

    for (final file in files) {
      final stem = _stemName(file.path);
      final newItem = MediaItem(
        name: stem,
        parent: widget.folder.id,
        sortHint: sortHint,
        media: [],
        repeat: false,
        shuffle: false,
        showTrackCoverRatherThanItemCover: false,
        isAudioBook: isAudioBook,
        isNew: true,
        fromDateTime: fromDateTime,
        toDateTime: toDateTime,
      );
      final postResult = await di<DartCouchDb>().post(newItem);
      if (!mounted) {
        progress.close();
        return;
      }
      final newId = postResult.id;
      final newRev = postResult.rev;
      if (newId == null || newRev == null) {
        sortHint++;
        continue;
      }

      // Wrap single file in a list for the shared utility
      final result = await importAudioFilesToDocument(
        context: context,
        files: [file],
        docId: newId,
        docRev: newRev,
        progress: progress,
      );
      if (result == null || !mounted) {
        progress.close();
        return;
      }

      if (result.attachments.isNotEmpty) {
        // title is always non-null (falls back to fileName in the model)
        final finalName = result.attachments.first.title;
        final freshDoc = await di<DartCouchDb>().get(newId) as MediaItem?;
        if (freshDoc != null) {
          await di<DartCouchDb>().put(
            freshDoc.copyWith(name: finalName, media: result.attachments),
          );
          successCount++;
        }
      }
      sortHint++;
    }

    progress.close();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Imported $successCount item(s)')));
  }

  Future<void> _importFoldersAsItems(
    List<({String name, List<XFile> files})> folders, {
    String? fromDateTime,
    String? toDateTime,
    bool isAudioBook = false,
    bool isNew = true,
  }) async {
    int sortHint = _nextSortHint();
    int successCount = 0;

    final totalFiles = folders.fold<int>(0, (sum, f) => sum + f.files.length);
    final progress = ImportProgressDialog(
      context: context,
      totalFiles: totalFiles,
    );
    progress.show();

    for (final folder in folders) {
      final newItem = MediaItem(
        name: folder.name,
        parent: widget.folder.id,
        sortHint: sortHint,
        media: [],
        repeat: false,
        shuffle: false,
        showTrackCoverRatherThanItemCover: false,
        isAudioBook: isAudioBook,
        isNew: true,
        fromDateTime: fromDateTime,
        toDateTime: toDateTime,
      );
      final postResult = await di<DartCouchDb>().post(newItem);
      if (!mounted) {
        progress.close();
        return;
      }
      final newId = postResult.id;
      final newRev = postResult.rev;
      if (newId == null || newRev == null) {
        sortHint++;
        continue;
      }

      final result = await importAudioFilesToDocument(
        context: context,
        files: folder.files,
        docId: newId,
        docRev: newRev,
        progress: progress,
      );
      if (result == null || !mounted) {
        progress.close();
        return;
      }

      if (result.attachments.isNotEmpty) {
        final freshDoc = await di<DartCouchDb>().get(newId) as MediaItem?;
        if (freshDoc != null) {
          await di<DartCouchDb>().put(
            freshDoc.copyWith(name: folder.name, media: result.attachments),
          );
          successCount++;
        }
      }
      sortHint++;
    }

    progress.close();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported $successCount folder(s) as media items'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = _localChildren ?? _children;
    final effectivelyNewById = buildEffectiveIsNewMap(_allDocuments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaBaseHeader(
          key: ValueKey('${widget.folder.id}_${widget.folder.rev}'),
          media: widget.folder,
          showChildrenCount: true,
          allDocuments: _allDocuments,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Checkbox(
                value: widget.folder.showItemNumbering,
                onChanged: (value) async {
                  await di<DartCouchDb>().put(
                    widget.folder.copyWith(showItemNumbering: value ?? false),
                  );
                },
              ),
              const Text('Show child numbering in Players Directory View'),
            ],
          ),
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
                children.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.audio_file,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Drop audio files here',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: children.length,
                        onReorder: (oldIndex, newIndex) async {
                          setState(() {
                            _localChildren ??= List<ViewEntry>.from(_children);
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = _localChildren!.removeAt(oldIndex);
                            _localChildren!.insert(newIndex, item);
                          });
                          final updated = _localChildren!;
                          for (int i = 0; i < updated.length; i++) {
                            final doc = updated[i].doc as MediaBase;
                            final newSortHint = i + 1;
                            if (doc.sortHint != newSortHint) {
                              if (doc is MediaItem) {
                                await di<DartCouchDb>().put(
                                  doc.copyWith(sortHint: newSortHint),
                                );
                              } else if (doc is MediaFolder) {
                                await di<DartCouchDb>().put(
                                  doc.copyWith(sortHint: newSortHint),
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context, index) {
                          final row = children[index];
                          final doc = row.doc as MediaBase;

                          final isRestricted = !doc.isVisibleAt(DateTime.now());
                          final visibilityInfo = doc.visibilityInfo;
                          final baseSubtitle = doc is MediaItem
                              ? '${doc.media.length} media file(s)'
                              : 'Folder';
                          final subtitleText = visibilityInfo != null
                              ? '$baseSubtitle · $visibilityInfo'
                              : baseSubtitle;
                          final textColor = isRestricted ? Colors.grey : null;

                          return ListTile(
                            key: ValueKey(row.id ?? doc.id),
                            onTap: () => widget.selectNode?.call(doc),
                            leading: SizedBox(
                              width: 48,
                              height: 48,
                              child: MediaBaseIcon(
                                media: doc,
                                allDocuments: _allDocuments,
                                iconSize: 48,
                                borderRadius: BorderRadius.circular(4),
                                showTypeBadge: true,
                                isNew: effectivelyNewById[doc.id] ?? false,
                                showNewStar: false,
                              ),
                            ),
                            title: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: IconButton(
                                    onPressed: () => _editNameInline(doc),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 24,
                                      height: 24,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    splashRadius: 12,
                                    iconSize: 16,
                                    icon: const Icon(Icons.edit),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    doc.name,
                                    style: TextStyle(color: textColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: TextStyle(color: textColor),
                            ),
                            trailing: SizedBox(
                              width: 198,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _buildDateButtonsColumn(doc),
                                  const SizedBox(width: 4),
                                  _buildFlagsColumn(doc),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () => _confirmAndDelete(doc),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                              'Drop to import',
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
