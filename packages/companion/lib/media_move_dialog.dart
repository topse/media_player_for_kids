import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

/// Result of [MediaMoveDialog]. [parentId] `null` means the top level (root),
/// i.e. the moved entry becomes a root-level folder/item.
class MoveTarget {
  final String? parentId;
  const MoveTarget(this.parentId);
}

/// Modal that lets the parent pick a new parent folder for one or more media
/// entries. It renders the folder tree (the same folders shown in the main tree
/// view) plus a top-level "root" row.
///
/// A target is offered as selectable unless it is:
///  * the entries' current shared parent (greyed out — moving there is a no-op),
///  * a folder that is itself being moved, or
///  * a descendant of a folder being moved (would create a cycle).
///
/// Returns the chosen [MoveTarget] via [Navigator.pop], or `null` when cancelled.
class MediaMoveDialog extends StatefulWidget {
  final List<MediaBase> itemsToMove;
  final Map<String, MediaBase> allDocuments;

  const MediaMoveDialog({
    super.key,
    required this.itemsToMove,
    required this.allDocuments,
  });

  static Future<MoveTarget?> show(
    BuildContext context, {
    required List<MediaBase> itemsToMove,
    required Map<String, MediaBase> allDocuments,
  }) {
    return showDialog<MoveTarget>(
      context: context,
      builder: (_) => MediaMoveDialog(
        itemsToMove: itemsToMove,
        allDocuments: allDocuments,
      ),
    );
  }

  @override
  State<MediaMoveDialog> createState() => _MediaMoveDialogState();
}

class _MediaMoveDialogState extends State<MediaMoveDialog> {
  MoveTarget? _selected;
  final Set<String> _expanded = {};

  /// Folder ids that cannot be a target: the moved folders themselves plus every
  /// folder beneath them (moving a folder into its own subtree is a cycle).
  final Set<String> _blockedIds = {};

  /// When every moved entry shares one parent, that parent (folder id, or `null`
  /// for root) is the "current" location and is shown greyed / non-selectable.
  bool _hasCommonParent = false;
  String? _commonParentId;

  /// Child folders grouped by parent id (`null` => top level), each sorted by
  /// sortHint. Built once from [MediaMoveDialog.allDocuments].
  final Map<String?, List<MediaFolder>> _childFolders = {};

  @override
  void initState() {
    super.initState();

    for (final doc in widget.allDocuments.values) {
      if (doc is MediaFolder) {
        (_childFolders[doc.parent] ??= []).add(doc);
      }
    }
    for (final list in _childFolders.values) {
      list.sort((a, b) => a.sortHint.compareTo(b.sortHint));
    }

    for (final item in widget.itemsToMove) {
      if (item is MediaFolder && item.id != null) {
        _blockedIds.add(item.id!);
        _collectDescendantFolders(item.id!, _blockedIds);
      }
    }

    final parents = widget.itemsToMove.map((e) => e.parent).toSet();
    _hasCommonParent = parents.length == 1;
    _commonParentId = _hasCommonParent ? parents.first : null;

    // Expand everything so the whole tree is visible by default.
    for (final f in _childFolders.values.expand((l) => l)) {
      if (f.id != null) _expanded.add(f.id!);
    }
  }

  void _collectDescendantFolders(String parentId, Set<String> out) {
    for (final child in _childFolders[parentId] ?? const <MediaFolder>[]) {
      final id = child.id;
      if (id != null && out.add(id)) {
        _collectDescendantFolders(id, out);
      }
    }
  }

  bool _isCurrent(String? parentId) =>
      _hasCommonParent && _commonParentId == parentId;

  bool _isSelected(String? parentId) =>
      _selected != null && _selected!.parentId == parentId;

  @override
  Widget build(BuildContext context) {
    final l10n = SharedL10n.of(context);
    final title = widget.itemsToMove.length == 1
        ? l10n.moveDialogTitleOne(widget.itemsToMove.first.name)
        : l10n.moveDialogTitleMany(widget.itemsToMove.length);

    final rows = <Widget>[
      _buildRootRow(l10n),
      ..._buildFolderRows(null, 1),
    ];

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Scrollbar(
          child: ListView(children: rows),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ElevatedButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }

  Widget _buildRootRow(SharedL10n l10n) {
    final disabled = _isCurrent(null);
    return _row(
      depth: 0,
      icon: Icons.home,
      label: l10n.moveDialogRootLevel,
      disabled: disabled,
      selected: _isSelected(null),
      showChevron: false,
      expanded: true,
      onTapExpand: null,
      onTapSelect: disabled
          ? null
          : () => setState(() => _selected = const MoveTarget(null)),
    );
  }

  List<Widget> _buildFolderRows(String? parentId, int depth) {
    final rows = <Widget>[];
    for (final folder in _childFolders[parentId] ?? const <MediaFolder>[]) {
      final id = folder.id!;
      final disabled = _blockedIds.contains(id) || _isCurrent(id);
      final hasChildren =
          (_childFolders[id] ?? const <MediaFolder>[]).isNotEmpty;
      final expanded = _expanded.contains(id);

      rows.add(
        _row(
          depth: depth,
          icon: Icons.folder,
          label: folder.name,
          disabled: disabled,
          selected: _isSelected(id),
          showChevron: hasChildren,
          expanded: expanded,
          onTapExpand: hasChildren
              ? () => setState(() {
                  if (!_expanded.remove(id)) _expanded.add(id);
                })
              : null,
          onTapSelect:
              disabled ? null : () => setState(() => _selected = MoveTarget(id)),
        ),
      );

      if (hasChildren && expanded) {
        rows.addAll(_buildFolderRows(id, depth + 1));
      }
    }
    return rows;
  }

  Widget _row({
    required int depth,
    required IconData icon,
    required String label,
    required bool disabled,
    required bool selected,
    required bool showChevron,
    required bool expanded,
    required VoidCallback? onTapExpand,
    required VoidCallback? onTapSelect,
  }) {
    final theme = Theme.of(context);
    final iconColor = disabled ? theme.disabledColor : Colors.amber[700];
    final textColor = disabled ? theme.disabledColor : null;

    return InkWell(
      onTap: onTapSelect,
      child: Container(
        color: selected ? theme.colorScheme.primaryContainer : null,
        padding: EdgeInsets.only(
          left: 8.0 + depth * 20,
          right: 8,
          top: 6,
          bottom: 6,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: showChevron
                  ? InkWell(
                      onTap: onTapExpand,
                      child: Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reparents [items] to become children of [newParentId] (`null` => root).
///
/// The moved entries are appended after the target parent's existing children
/// (keeping their current relative order), so they land as the last entries of
/// the new parent. Afterwards the remaining children of every old parent are
/// re-sequenced to 1..N so their order numbers stay gap-free.
///
/// [allDocuments] must reflect the current DB state (id -> doc, with revs); it
/// is used to compute sibling sets and is not mutated.
Future<void> moveMediaBases({
  required DartCouchDb db,
  required List<MediaBase> items,
  required String? newParentId,
  required Map<String, MediaBase> allDocuments,
}) async {
  if (items.isEmpty) return;
  final movedIds = items.map((e) => e.id).whereType<String>().toSet();

  // Highest sortHint already used among the target parent's other children.
  int nextHint = 0;
  for (final doc in allDocuments.values) {
    if (doc.parent == newParentId &&
        !movedIds.contains(doc.id) &&
        doc.sortHint > nextHint) {
      nextHint = doc.sortHint;
    }
  }

  // Append the moved entries, preserving their previous relative order.
  final ordered = [...items]..sort((a, b) => a.sortHint.compareTo(b.sortHint));
  final oldParents = <String?>{};
  for (final item in ordered) {
    oldParents.add(item.parent);
    nextHint++;
    await db.put(_withParentAndSort(item, newParentId, nextHint));
  }

  // Compact each source parent's remaining children back to 1..N.
  for (final oldParent in oldParents) {
    if (oldParent == newParentId) continue;
    final remaining =
        allDocuments.values
            .where((d) => d.parent == oldParent && !movedIds.contains(d.id))
            .toList()
          ..sort((a, b) => a.sortHint.compareTo(b.sortHint));
    for (int i = 0; i < remaining.length; i++) {
      final want = i + 1;
      if (remaining[i].sortHint != want) {
        await db.put(_withSort(remaining[i], want));
      }
    }
  }
}

/// Creates a new subfolder named [name] inside [parentId] (the shared parent of
/// [items]) and moves [items] into it. Returns the new folder's id.
///
/// The subfolder is appended at the end of [parentId]; the moved entries then
/// leave [parentId], so its remaining children are compacted by [moveMediaBases].
Future<String> moveIntoNewSubfolder({
  required DartCouchDb db,
  required List<MediaBase> items,
  required String? parentId,
  required String name,
  required Map<String, MediaBase> allDocuments,
}) async {
  int nextHint = 0;
  for (final doc in allDocuments.values) {
    if (doc.parent == parentId && doc.sortHint > nextHint) {
      nextHint = doc.sortHint;
    }
  }

  final res = await db.post(
    MediaFolder(
      name: name,
      parent: parentId,
      sortHint: nextHint + 1,
      showItemNumbering: false,
    ),
  );
  final newId = res.id;
  if (newId == null) {
    throw StateError('Failed to create subfolder "$name"');
  }

  await moveMediaBases(
    db: db,
    items: items,
    newParentId: newId,
    allDocuments: allDocuments,
  );
  return newId;
}

MediaBase _withParentAndSort(MediaBase doc, String? parent, int sortHint) {
  if (doc is MediaFolder) {
    return doc.copyWith(parent: parent, sortHint: sortHint);
  }
  if (doc is MediaItem) {
    return doc.copyWith(parent: parent, sortHint: sortHint);
  }
  throw ArgumentError('Unsupported MediaBase subtype: ${doc.runtimeType}');
}

MediaBase _withSort(MediaBase doc, int sortHint) {
  if (doc is MediaFolder) return doc.copyWith(sortHint: sortHint);
  if (doc is MediaItem) return doc.copyWith(sortHint: sortHint);
  throw ArgumentError('Unsupported MediaBase subtype: ${doc.runtimeType}');
}
