import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class MediaFolderDialog extends StatefulWidget {
  final MediaFolder? folder;
  final String? parent;

  const MediaFolderDialog({super.key, this.folder, this.parent});

  static Future<MediaFolder?> show(
    BuildContext context, {
    MediaFolder? folder,
    String? parent,
  }) {
    return showDialog<MediaFolder>(
      context: context,
      builder: (context) => MediaFolderDialog(folder: folder, parent: parent),
    );
  }

  @override
  State<MediaFolderDialog> createState() => _MediaFolderDialogState();
}

class _MediaFolderDialogState extends State<MediaFolderDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder?.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final result = widget.folder != null
        ? MediaFolder(
            id: widget.folder!.id,
            rev: widget.folder!.rev,
            parent: widget.folder!.parent,
            sortHint: widget.folder!.sortHint,
            name: text,
            showItemNumbering: false
          )
        : MediaFolder(name: text, parent: widget.parent, sortHint: 0, showItemNumbering: false);

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.folder == null ? 'Create Folder' : 'Edit Folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Folder name'),
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
