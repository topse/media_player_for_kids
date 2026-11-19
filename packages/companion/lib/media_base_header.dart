import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:pasteboard/pasteboard.dart';

import 'constraint_editor.dart';
import 'media_folder_dialog.dart';
import 'media_item_dialog.dart';

/// Content type of [bytes] by magic number, for the formats a cover may be
/// stored in as-is. `null` for anything else (e.g. BMP).
String? _sniffImageContentType(Uint8List bytes) {
  bool startsWith(List<int> sig, [int offset = 0]) {
    if (bytes.length < offset + sig.length) return false;
    for (var i = 0; i < sig.length; i++) {
      if (bytes[offset + i] != sig[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
  if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif'; // GIF8
  if (startsWith(const [0x52, 0x49, 0x46, 0x46]) && // RIFF....WEBP
      startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}

/// Re-encodes any image Flutter can decode (notably the BMP that `pasteboard`
/// returns on Windows) as PNG. Returns `null` if [bytes] is not an image.
Future<Uint8List?> _toPng(Uint8List bytes) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

class MediaBaseHeader extends StatefulWidget {
  final MediaBase media;
  final bool showChildrenCount;
  final Map<String, MediaBase> allDocuments;

  const MediaBaseHeader({
    super.key,
    required this.media,
    this.showChildrenCount = false,
    this.allDocuments = const {},
  });

  @override
  State<MediaBaseHeader> createState() => _MediaBaseHeaderState();
}

class _MediaBaseHeaderState extends State<MediaBaseHeader> {
  Uint8List? _coverImageBytes; // The _cover attachment only
  bool _dragging = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCoverImage();
  }

  /// Loads the base cover image (_cover attachment only, no fallback)
  void _loadCoverImage() async {
    if (!widget.media.hasCoverImage) return;
    setState(() => _isLoading = true);
    final attachment = await di<DartCouchDb>().getAttachment(
      widget.media.id!,
      MediaBase.coverAttachmentName,
    );
    if (mounted) {
      setState(() {
        _coverImageBytes = attachment;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    final dt = DateTime.parse(isoString);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleHidden() async {
    final media = widget.media;
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(hidden: !media.hidden));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(hidden: !media.hidden));
    }
  }

  Future<void> _setFromDate(DateTime? date) async {
    final iso = date?.toIso8601String();
    final media = widget.media;
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(fromDateTime: iso));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(fromDateTime: iso));
    }
  }

  Future<void> _setToDate(DateTime? date) async {
    final iso = date?.toIso8601String();
    final media = widget.media;
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(toDateTime: iso));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(toDateTime: iso));
    }
  }

  Future<void> _pickFromDate() async {
    final initial = widget.media.fromDateTime != null
        ? DateTime.parse(widget.media.fromDateTime!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) await _setFromDate(picked);
  }

  Future<void> _pickToDate() async {
    final initial = widget.media.toDateTime != null
        ? DateTime.parse(widget.media.toDateTime!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) await _setToDate(picked);
  }

  void _editName() async {
    if (widget.media is MediaFolder) {
      final updated = await MediaFolderDialog.show(
        context,
        folder: widget.media as MediaFolder,
      );
      if (updated != null) {
        await di<DartCouchDb>().put(updated);
      }
    } else if (widget.media is MediaItem) {
      final updated = await MediaItemDialog.show(
        context,
        item: widget.media as MediaItem,
      );
      if (updated != null) {
        await di<DartCouchDb>().put(updated);
      }
    }
  }

  void _deleteCoverImage() async {
    if (widget.media.hasCoverImage == false) return;
    await di<DartCouchDb>().deleteAttachment(
      widget.media.id!,
      widget.media.rev!,
      MediaBase.coverAttachmentName,
    );
    setState(() {
      _coverImageBytes = null;
    });
  }

  /// The only path that writes the cover attachment. Callers must go through
  /// [_saveCoverImage], which guarantees [bytes] is a displayable image whose
  /// [contentType] matches its content.
  Future<void> _saveImageHelper(Uint8List bytes, String contentType) async {
    await di<DartCouchDb>().saveAttachment(
      widget.media.id!,
      widget.media.rev!,
      MediaBase.coverAttachmentName,
      bytes,
      contentType: contentType,
    );
    setState(() {
      _coverImageBytes = bytes;
    });
  }

  /// Validates and stores [bytes] as the cover image (clipboard, drag & drop,
  /// file picker). PNG/JPEG/GIF/WebP are stored as-is; anything else Flutter
  /// can decode (e.g. BMP) is re-encoded as PNG. The content type is always
  /// derived from the bytes, never from a file name. Non-images are rejected
  /// with a message and nothing is written — a cover the player cannot
  /// display must never reach the database. Write errors are shown, not
  /// swallowed.
  Future<void> _saveCoverImage(Uint8List? bytes) async {
    try {
      if (bytes != null && bytes.isNotEmpty) {
        final contentType = _sniffImageContentType(bytes);
        if (contentType != null) {
          await _saveImageHelper(bytes, contentType);
          return;
        }
        final png = await _toPng(bytes);
        if (png != null) {
          await _saveImageHelper(png, 'image/png');
          return;
        }
      }
      _showMessage((l) => l.headerImageUnsupported);
    } catch (e) {
      _showMessage((l) => l.headerImageSaveError(e.toString()));
    }
  }

  /// Shows a snackbar; [text] is built only after the `mounted` check, so
  /// callers may use it after async gaps.
  void _showMessage(String Function(SharedL10n l10n) text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text(SharedL10n.of(context)))),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final Uint8List? bytes;
    try {
      // pasteboard returns PNG on macOS/Linux but BMP on Windows (CF_DIB).
      bytes = await Pasteboard.image;
    } catch (e) {
      _showMessage((l) => l.headerClipboardError(e.toString()));
      return;
    }
    if (bytes == null || bytes.isEmpty) {
      _showMessage((l) => l.headerClipboardUnsupported);
      return;
    }
    await _saveCoverImage(bytes);
  }

  Future<void> _pickImage() async {
    final Uint8List bytes;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      bytes = await pickedFile.readAsBytes();
    } catch (e) {
      _showMessage((l) => l.headerImageSaveError(e.toString()));
      return;
    }
    await _saveCoverImage(bytes);
  }

  Widget _buildDropPlaceholder() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Drop image',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: MediaBaseIcon(
                  media: widget.media,
                  allDocuments: widget.allDocuments,
                  iconSize: 48,
                  borderRadius: BorderRadius.circular(4),
                  showTypeBadge: true,
                  showNewStar: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.media.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (widget.showChildrenCount &&
                        widget.media is MediaFolder) ...[
                      Text(
                        SharedL10n.of(context).headerChildrenCount(
                            (widget.media as MediaFolder).sortHint),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit), onPressed: _editName),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(SharedL10n.of(context).headerVisibleDateRange),
              const SizedBox(width: 32),
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
                    Text(SharedL10n.of(context).headerFromDate),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _pickFromDate,
                      child: Text(
                        widget.media.fromDateTime != null
                            ? _formatDate(widget.media.fromDateTime!)
                            : SharedL10n.of(context).headerNotSetPlaceholder,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: widget.media.fromDateTime != null
                          ? () => _setFromDate(null)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
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
                    Text(SharedL10n.of(context).headerToDate),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _pickToDate,
                      child: Text(
                        widget.media.toDateTime != null
                            ? _formatDate(widget.media.toDateTime!)
                            : SharedL10n.of(context).headerNotSetPlaceholder,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: widget.media.toDateTime != null
                          ? () => _setToDate(null)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Builder(builder: (context) {
          final l10n = SharedL10n.of(context);
          final ownConstraint = widget.media.hearingConstraint;
          final inheritedHolder = ownConstraint == null
              ? ConstraintEvaluator.findNearestConstraintHolder(
                  item: widget.media,
                  allDocuments: widget.allDocuments,
                )
              : null;

          return ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Row(
              children: [
                Text(l10n.headerHearingRules),
                if (inheritedHolder != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(l10n.headerInheritedFrom(inheritedHolder.name)),
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              ownConstraint != null
                  ? ConstraintDescriptionGenerator(l10n)
                      .describe(ownConstraint)
                  : inheritedHolder?.hearingConstraint != null
                      ? ConstraintDescriptionGenerator(l10n)
                          .describe(inheritedHolder!.hearingConstraint!)
                      : l10n.headerNoRules,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ownConstraint != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[700],
                    tooltip: l10n.headerRemoveRulesTooltip,
                    onPressed: () => _setHearingConstraint(null),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _openConstraintEditor(
              context,
              inheritedConstraint: inheritedHolder?.hearingConstraint,
              inheritedFromName: inheritedHolder?.name,
            ),
          );
        }),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: widget.media.hidden,
                onChanged: (_) => _toggleHidden(),
              ),
              Text(SharedL10n.of(context).headerHiddenLabel),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: DropTarget(
                  onDragEntered: (_) => setState(() => _dragging = true),
                  onDragExited: (_) => setState(() => _dragging = false),
                  onDragDone: (details) async {
                    setState(() => _dragging = false);
                    if (details.files.isEmpty) return;
                    final file = details.files.first;
                    Uint8List? bytes;
                    try {
                      try {
                        bytes = await file.readAsBytes();
                      } catch (_) {
                        // Some platforms only deliver a path.
                        if (file.path.isNotEmpty) {
                          final f = File(file.path);
                          if (await f.exists()) bytes = await f.readAsBytes();
                        }
                      }
                    } catch (e) {
                      _showMessage((l) => l.headerImageSaveError(e.toString()));
                      return;
                    }
                    await _saveCoverImage(bytes);
                  },
                  child: Stack(
                    children: [
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_coverImageBytes != null)
                        Image.memory(
                          _coverImageBytes!,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              widget.media is MediaFolder
                                  ? Icons.folder
                                  : Icons.audio_file,
                              size: 48,
                            ),
                          ),
                        )
                      else
                        _buildDropPlaceholder(),
                      if (_dragging)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'Drop image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_coverImageBytes != null ||
                          widget.media.hasCoverImage)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 24),
                            color: Colors.red,
                            onPressed: _deleteCoverImage,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: .start,
                spacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: widget.media.hasCoverImage
                        ? _deleteCoverImage
                        : null,
                    icon: const Icon(Icons.delete),
                    label: Text(SharedL10n.of(context).headerRemoveImage),
                  ),
                  FilledButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: Text(SharedL10n.of(context).headerPasteImage),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  void _openConstraintEditor(
    BuildContext context, {
    HearingConstraint? inheritedConstraint,
    String? inheritedFromName,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConstraintEditorPage(
        initialConstraint: widget.media.hearingConstraint,
        isFolder: widget.media is MediaFolder,
        onChanged: _setHearingConstraint,
        inheritedConstraint: inheritedConstraint,
        inheritedFromName: inheritedFromName,
      ),
    ));
  }

  Future<void> _setHearingConstraint(HearingConstraint? constraint) async {
    final media = widget.media;
    if (media is MediaFolder) {
      await di<DartCouchDb>().put(media.copyWith(hearingConstraint: constraint));
    } else if (media is MediaItem) {
      await di<DartCouchDb>().put(media.copyWith(hearingConstraint: constraint));
    }
  }
}
