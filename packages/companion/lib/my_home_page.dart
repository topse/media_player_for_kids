import 'dart:async';

import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:watch_it/watch_it.dart';

import 'expandable_fab.dart';
import 'media_folder_detail.dart';
import 'media_folder_dialog.dart';
import 'media_item_detail.dart';
import 'media_item_dialog.dart';
import 'package:shared/shared.dart';
import 'split_view.dart';
import 'audio_playback_controls.dart';

class MyHomePage extends StatefulWidget {
  final Future<void> Function() onLogout;

  const MyHomePage({super.key, required this.onLogout});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MediaBase? _selectedMediaBase;
  late final IndexedTreeNode<dynamic> treeRoot = IndexedTreeNode.root();
  bool _isReordering = false;

  IndexedTreeNode<dynamic>? get _selectedNode {
    if (_selectedMediaBase == null) return null;
    final lookupId = _selectedMediaBase is MediaItem
        ? (_selectedMediaBase as MediaItem).parent
        : _selectedMediaBase!.id;
    return _nodeById[lookupId];
  }

  ViewResult? _lastViewResult;
  Map<String, MediaBase> _allDocumentsMap = {};
  final Map<String, IndexedTreeNode> _nodeById = {};
  String? _pendingSelectionId; // ID of node to select when it appears

  void _registerNode(IndexedTreeNode node) {
    _nodeById[node.key] = node;
    for (final child in node.children.cast<IndexedTreeNode>()) {
      _registerNode(child);
    }
  }

  void _unregisterNode(String id) {
    _nodeById.remove(id);
  }

  void _mergeTree(ViewResult res) {
    final docIds = res.rows.map((r) => r.id!).toSet();
    final nodesToRemove = <String>[];

    for (final entry in _nodeById.entries) {
      if (entry.key != 'root' && !docIds.contains(entry.key)) {
        nodesToRemove.add(entry.key);
      }
    }

    for (final id in nodesToRemove) {
      final node = _nodeById[id];
      if (node != null) {
        node.parent?.remove(node);
        _unregisterNode(id);
        if (_selectedNode == node) {
          _selectedMediaBase = null;
        }
        if (_pendingSelectionId == id) {
          _pendingSelectionId = null;
        }
      }
    }

    _mergeChildren(res, null, treeRoot);

    if (_selectedMediaBase == null && treeRoot.children.isNotEmpty) {
      _selectedMediaBase =
          (treeRoot.children.first as IndexedTreeNode).data as MediaBase;
    }
  }

  void _mergeChildren(
    ViewResult res,
    String? parentId,
    IndexedTreeNode parentNode,
  ) {
    final filtered =
        res.rows
            .where((r) => r.key[0] == parentId && r.doc is MediaFolder)
            .toList()
          ..sort(
            (a, b) => (a.doc as MediaBase).sortHint.compareTo(
              (b.doc as MediaBase).sortHint,
            ),
          );

    for (final row in filtered) {
      final docId = row.id!;
      IndexedTreeNode? existingNode;

      for (final child in parentNode.children.cast<IndexedTreeNode>()) {
        if (child.key == docId) {
          existingNode = child;
          break;
        }
      }

      if (existingNode != null) {
        existingNode.data = row.doc as MediaBase;
        _mergeChildren(res, docId, existingNode);
      } else {
        final newNode = _createNode(row);
        parentNode.add(newNode);
        _registerNode(newNode);
        _mergeChildren(res, docId, newNode);

        // Check if this is the node we're waiting to select
        if (_pendingSelectionId == docId) {
          _selectedMediaBase = newNode.data as MediaBase;
          _pendingSelectionId = null;
        }
      }
    }

    // Reorder existing children to match the sortHint order from the DB.
    // New nodes are appended by add() above; existing nodes keep their old
    // position unless we explicitly reorder them here.
    final orderedIds = filtered.map((r) => r.id!).toList();
    if (orderedIds.isEmpty) return;

    final currentChildren = parentNode.children
        .cast<IndexedTreeNode>()
        .toList();
    final currentIds = currentChildren.map((c) => c.key).toList();

    bool needsReorder = orderedIds.length != currentIds.length;
    if (!needsReorder) {
      for (int i = 0; i < orderedIds.length; i++) {
        if (orderedIds[i] != currentIds[i]) {
          needsReorder = true;
          break;
        }
      }
    }

    if (needsReorder) {
      // Reorder using individual remove+insert operations so the parent node
      // is never emptied. Calling clear() fires notifications that cause
      // animated_tree_view to null-out the children's parent references; any
      // subsequent add() can then re-parent them to the wrong ancestor.
      for (int targetIdx = 0; targetIdx < orderedIds.length; targetIdx++) {
        final id = orderedIds[targetIdx];
        final node = currentChildren.firstWhere((c) => c.key == id);
        final liveList = parentNode.children.cast<IndexedTreeNode>().toList();
        final liveIdx = liveList.indexWhere((c) => c.key == id);
        if (liveIdx != targetIdx) {
          parentNode.removeAt(liveIdx);
          parentNode.insert(targetIdx, node);
        }
      }
    }
  }

  IndexedTreeNode _createNode(ViewEntry row) {
    if (row.doc is MediaFolder) {
      final folder = row.doc as MediaFolder;
      return IndexedTreeNode<MediaFolder>(key: row.id, data: folder);
    } else if (row.doc is MediaItem) {
      final item = row.doc as MediaItem;
      return IndexedTreeNode<MediaItem>(key: row.id, data: item);
    }
    throw ArgumentError('Unknown document type');
  }

  @override
  void initState() {
    super.initState();
    _registerNode(treeRoot);

    Stream<ViewResult?> treeView = di<DartCouchDb>().useView(
      'mediatree/by_parent',
      includeDocs: true,
    );

    treeView.listen((ViewResult? res) async {
      if (!mounted) return;
      if (res != null) {
        _mergeTree(res);
        setState(() {
          _lastViewResult = res;
          _allDocumentsMap = {
            for (final r in _lastViewResult?.rows ?? const [])
              if (r.doc is MediaBase) r.id!: r.doc as MediaBase,
          };
          // Refresh _selectedMediaBase so MediaItemDetail receives the
          // latest rev after a put triggers the changes feed. Without this,
          // _selectedMediaBase keeps the stale rev object even though the
          // tree node was already updated by _mergeTree, causing didUpdateWidget
          // to see no rev change and leaving widget.item with a stale rev.
          final selectedId = _selectedMediaBase?.id;
          if (selectedId != null && _allDocumentsMap.containsKey(selectedId)) {
            _selectedMediaBase = _allDocumentsMap[selectedId];
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectivelyNewById = buildEffectiveIsNewMap(_allDocumentsMap);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Player for kids Companion'),
        actions: [
          const AudioPlaybackControls(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SplitView(
        initialLeftWidth: 500,
        left: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: TreeView.indexed(
                tree: treeRoot,
                showRootNode: false,
                indentation: const Indentation(width: 16, style: .squareJoint),
                expansionIndicatorBuilder: (context, node) =>
                    ChevronIndicator.rightDown(
                      tree: node,
                      color: Colors.blue[700],
                      padding: const EdgeInsets.all(8),
                    ),
                onTreeReady: (controller) {
                  // _treeController = controller; --- IGNORE ---
                },
                builder: (context, node) {
                  final media = node.data as MediaBase;
                  final isRestricted = !media.isVisibleAt(DateTime.now());
                  final visibilityInfo = media.visibilityInfo;
                  final textColor = isRestricted ? Colors.grey : null;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMediaBase = media;
                        _pendingSelectionId = null;
                      });
                    },
                    child: ListTile(
                      title: Text(
                        media.name,
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: visibilityInfo != null
                          ? Text(
                              visibilityInfo,
                              style: TextStyle(color: textColor),
                            )
                          : null,
                      selected: node == _selectedNode,
                      leading: SizedBox(
                        width: 40,
                        height: 40,
                        child: MediaBaseIcon(
                          media: media,
                          allDocuments: _allDocumentsMap,
                          iconSize: 40,
                          isNew: effectivelyNewById[media.id] ?? false,
                          showNewStar: false,
                        ),
                      ),
                      trailing: IntrinsicWidth(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_drop_up),
                              onPressed:
                                  _isReordering ||
                                      node.parent == null ||
                                      node.parent!.children.isEmpty ||
                                      node.parent!.children.first == node
                                  ? null
                                  : () => _moveNodeUp(node),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_drop_down),
                              onPressed:
                                  _isReordering ||
                                      node.parent == null ||
                                      node.parent!.children.isEmpty ||
                                      node.parent!.children.last == node
                                  ? null
                                  : () => _moveNodeDown(node),
                            ),

                            IconButton(
                              icon: const Icon(Icons.library_add),
                              onPressed: () => _showCreateDialog(node.key),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _deleteItem(node),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isReordering)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: SizedBox(
                width: 200,
                height: 200,
                child: ExpandableFab(
                  distance: 80.0,
                  closedStateIcon: Icons.add,
                  children: [
                    ActionButton(
                      onPressed: _addFolder,
                      icon: const Icon(Icons.create_new_folder),
                    ),
                    ActionButton(
                      onPressed: _addItem,
                      icon: const Icon(Icons.insert_drive_file),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        right: _buildDetailView(),
      ),
    );
  }

  Future<void> _moveNodeUp(IndexedTreeNode node) async {
    final parent = node.parent;
    if (parent == null) return;

    final children = parent.children.cast<IndexedTreeNode>().toList();
    final index = children.indexOf(node);
    if (index <= 0) return;

    final reordered = List<IndexedTreeNode>.from(children);
    final temp = reordered[index - 1];
    reordered[index - 1] = reordered[index];
    reordered[index] = temp;

    setState(() => _isReordering = true);
    try {
      await _persistReorder(reordered);
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  Future<void> _moveNodeDown(IndexedTreeNode node) async {
    final parent = node.parent;
    if (parent == null) return;

    final children = parent.children.cast<IndexedTreeNode>().toList();
    final index = children.indexOf(node);
    if (index < 0 || index >= children.length - 1) return;

    final reordered = List<IndexedTreeNode>.from(children);
    final temp = reordered[index + 1];
    reordered[index + 1] = reordered[index];
    reordered[index] = temp;

    setState(() => _isReordering = true);
    try {
      await _persistReorder(reordered);
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  /// Assigns sequential sortHints (1, 2, 3, …) to [orderedChildren] and saves
  /// only the changed documents to the database. The tree is NOT touched here;
  /// the DB change-stream will fire and _mergeChildren will reorder the tree
  /// once the new sortHints arrive, avoiding double-manipulation corruption.
  Future<void> _persistReorder(List<IndexedTreeNode> orderedChildren) async {
    final docsToUpdate = <MediaBase>[];

    for (int i = 0; i < orderedChildren.length; i++) {
      final child = orderedChildren[i];
      final newSortHint = i + 1;

      if (child.data.sortHint != newSortHint) {
        final updated = child.data is MediaFolder
            ? (child.data as MediaFolder).copyWith(sortHint: newSortHint)
            : (child.data as MediaItem).copyWith(sortHint: newSortHint);
        docsToUpdate.add(updated);
      }
    }

    for (final doc in docsToUpdate) {
      await di<DartCouchDb>().put(doc);
    }
  }

  Widget _buildDetailView() {
    if (_selectedMediaBase is MediaItem) {
      final item = _selectedMediaBase as MediaItem;
      return MediaItemDetail(key: Key(item.id!), item: item);
    }

    if (_selectedMediaBase is MediaFolder) {
      final folder = _selectedMediaBase as MediaFolder;
      return MediaFolderDetail(
        key: Key(folder.id!),
        folder: folder,
        lastViewResult: _lastViewResult,
        selectNode: _selectNode,
      );
    }

    return const Center(
      child: Text(
        'Select an item from the tree',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }

  void _showCreateDialog(String? parentId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CreateNewDialog(),
    );

    if (result == 'folder') {
      _addFolder(parentId);
    } else if (result == 'item') {
      _addItem(parentId);
    }
  }

  void _selectNode(MediaBase item) {
    setState(() => _selectedMediaBase = item);
  }

  /// Calculate the next sortHint value for a new item being added to a parent
  int _calculateNextSortHint(String? parentId) {
    final parent = parentId == null ? treeRoot : _nodeById[parentId];
    if (parent == null) return 1;

    // Find the maximum sortHint among existing children
    int maxSortHint = 0;
    for (final child in parent.children.cast<IndexedTreeNode>()) {
      if (child.data.sortHint > maxSortHint) {
        maxSortHint = child.data.sortHint;
      }
    }

    return maxSortHint + 1;
  }

  void _addFolder([String? parentId]) async {
    final result = await MediaFolderDialog.show(context, parent: parentId);
    if (result == null) return;

    // Calculate correct sortHint based on existing siblings
    final correctSortHint = _calculateNextSortHint(parentId);
    final folderWithCorrectSort = result.copyWith(sortHint: correctSortHint);

    final postResult = await di<DartCouchDb>().post(folderWithCorrectSort);

    // Wait for the new node to appear in the tree and select it
    if (postResult.id != null) {
      _selectNodeWhenReady(postResult.id!);
    }
  }

  void _addItem([String? parentId]) async {
    final result = await MediaItemDialog.show(context, parent: parentId);
    if (result == null) return;

    // Calculate correct sortHint based on existing siblings
    final correctSortHint = _calculateNextSortHint(parentId);
    final itemWithCorrectSort = result.copyWith(sortHint: correctSortHint);

    final postResult = await di<DartCouchDb>().post(itemWithCorrectSort);

    // Wait for the new node to appear in the tree and select it
    if (postResult.id != null) {
      _selectNodeWhenReady(postResult.id!);
    }
  }

  /// Marks a node ID to be selected when it appears in the tree
  void _selectNodeWhenReady(String nodeId) {
    // Check if node already exists
    if (_nodeById.containsKey(nodeId)) {
      setState(() {
        _selectedMediaBase = _nodeById[nodeId]!.data as MediaBase;
      });
      return;
    }

    // Set pending selection - will be selected when tree update arrives
    _pendingSelectionId = nodeId;
  }

  /// Recursively collects all descendant nodes (children and their children)
  List<IndexedTreeNode> _collectAllDescendants(IndexedTreeNode node) {
    final descendants = <IndexedTreeNode>[];

    for (final child in node.children.cast<IndexedTreeNode>()) {
      descendants.add(child);
      descendants.addAll(_collectAllDescendants(child));
    }

    return descendants;
  }

  void _deleteItem(IndexedTreeNode node) async {
    // Collect all descendants to be deleted
    final descendants = _collectAllDescendants(node);
    final descendantCount = descendants.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text(
          descendantCount == 0
              ? 'Really delete ${node is IndexedTreeNode<MediaFolder> ? 'folder' : 'item'} "${node.data.name}"?'
              : 'Really delete ${node is IndexedTreeNode<MediaFolder> ? 'folder' : 'item'} "${node.data.name}" and its $descendantCount child${descendantCount == 1 ? '' : 'ren'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete all descendants first (bottom-up)
      for (final descendant in descendants.reversed) {
        await di<DartCouchDb>().remove(
          descendant.data.id!,
          descendant.data.rev!,
        );
      }

      // Finally delete the node itself
      await di<DartCouchDb>().remove(node.data.id!, node.data.rev!);
    }
  }
}

/// Dialog for creating new folders or media items with keyboard navigation
class _CreateNewDialog extends StatefulWidget {
  const _CreateNewDialog();

  @override
  State<_CreateNewDialog> createState() => _CreateNewDialogState();
}

class _CreateNewDialogState extends State<_CreateNewDialog> {
  int _selectedIndex = 0; // 0 = folder, 1 = item
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % 2;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % 2;
          if (_selectedIndex < 0) _selectedIndex = 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        _confirmSelection();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  void _confirmSelection() {
    final result = _selectedIndex == 0 ? 'folder' : 'item';
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        title: const Text('Create new'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Folder'),
              selected: _selectedIndex == 0,
              onTap: () => setState(() => _selectedIndex = 0),
              tileColor: _selectedIndex == 0
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.audio_file),
              title: const Text('Media Item'),
              selected: _selectedIndex == 1,
              onTap: () => setState(() => _selectedIndex = 1),
              tileColor: _selectedIndex == 1
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _confirmSelection, child: const Text('OK')),
        ],
      ),
    );
  }
}
