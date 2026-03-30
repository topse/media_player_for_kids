import 'dart:async';
import 'dart:io';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'media_folder_dialog.dart';
import 'media_item_dialog.dart';

extension _ReadFile on DataReader {
  Future<Uint8List?> readFile(FileFormat format) {
    final c = Completer<Uint8List?>();
    final progress = getFile(
      format,
      (file) async {
        try {
          final all = await file.readAll();
          c.complete(all);
        } catch (e) {
          c.completeError(e);
        }
      },
      onError: (e) {
        c.completeError(e);
      },
    );
    if (progress == null) {
      c.complete(null);
    }
    return c.future;
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

  String _getContentTypeFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'webp') return 'image/webp';
    return 'application/octet-stream';
  }

  Future<void> _pasteFromClipboard() async {
    try {
      // Use super_clipboard for better cross-platform support
      final clipboard = SystemClipboard.instance;
      if (clipboard == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard not available')),
        );
        return;
      }

      // Read clipboard data
      final reader = await clipboard.read();
      if (reader.items.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data in clipboard')));
        return;
      }

      // Check each item for supported image formats
      for (final item in reader.items) {
        // Get available formats for this item
        final formats = item.getFormats([
          Formats.png,
          Formats.jpeg,
          Formats.gif,
          Formats.webp,
        ]);

        // Try to read image data for each supported format
        for (final format in formats) {
          if (format is FileFormat) {
            // For file-based image formats
            final bytes = await item.readFile(format);
            if (bytes != null && bytes.isNotEmpty) {
              String contentType;
              if (format == Formats.png) {
                contentType = 'image/png';
              } else if (format == Formats.jpeg) {
                contentType = 'image/jpeg';
              } else if (format == Formats.gif) {
                contentType = 'image/gif';
              } else if (format == Formats.webp) {
                contentType = 'image/webp';
              } else {
                contentType = 'image/png'; // default
              }
              await _saveImageHelper(bytes, contentType);
              return;
            }
          }
        }
      }

      // If we get here, no supported image format was found
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No supported image format in clipboard')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading clipboard: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (bytes.isNotEmpty) {
      final contentType = _getContentTypeFromExtension(pickedFile.name);
      await _saveImageHelper(bytes, contentType);
    }
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
                        '${(widget.media as MediaFolder).sortHint} children',
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
              const Text('Visisble Date Range:'),
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
                    const Text('From Date:'),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _pickFromDate,
                      child: Text(
                        widget.media.fromDateTime != null
                            ? _formatDate(widget.media.fromDateTime!)
                            : '*Not set*',
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
                    const Text('To Date:'),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: _pickToDate,
                      child: Text(
                        widget.media.toDateTime != null
                            ? _formatDate(widget.media.toDateTime!)
                            : '*Not set*',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: widget.media.hidden,
                onChanged: (_) => _toggleHidden(),
              ),
              const Text('Hidden'),
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
                    try {
                      if (details.files.isEmpty) return;
                      final file = details.files.first;
                      Uint8List? bytes;
                      String path = '';
                      try {
                        bytes = await file.readAsBytes();
                        path = file.path;
                      } catch (_) {
                        if (file.path.isNotEmpty) {
                          final f = File(file.path);
                          if (await f.exists()) bytes = await f.readAsBytes();
                          path = file.path;
                        }
                      }

                      if (bytes != null && bytes.isNotEmpty) {
                        final contentType = _getContentTypeFromExtension(path);
                        await _saveImageHelper(bytes, contentType);
                      }
                    } catch (_) {}
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
                    label: const Text('Remove Image'),
                  ),
                  FilledButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: const Text('Paste Image From Clipboard'),
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
}
