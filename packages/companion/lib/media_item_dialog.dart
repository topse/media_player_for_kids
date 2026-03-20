import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class MediaItemDialog extends StatefulWidget {
  final MediaItem? item;
  final String? parent;

  const MediaItemDialog({super.key, this.item, this.parent});

  static Future<MediaItem?> show(
    BuildContext context, {
    MediaItem? item,
    String? parent,
  }) {
    return showDialog<MediaItem>(
      context: context,
      builder: (context) => MediaItemDialog(item: item, parent: parent),
    );
  }

  @override
  State<MediaItemDialog> createState() => _MediaItemDialogState();
}

class _MediaItemDialogState extends State<MediaItemDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item?.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = widget.item != null
        ? widget.item!.copyWith(name: text)
        : MediaItem(
            name: text,
            parent: widget.parent,
            sortHint: 0, // Will be corrected by _addItem
            media: [], // Empty list - media files added later
            repeat: false,
            shuffle: false,
            showTrackCoverRatherThanItemCover: false,
            isAudioBook: false,
            isNew: true,
          );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null ? 'Create Media Item' : 'Edit Media Item',
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Item name'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
