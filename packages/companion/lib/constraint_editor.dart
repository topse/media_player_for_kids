import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'constraint_templates.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tree manipulation utilities for drag-and-drop
// ─────────────────────────────────────────────────────────────────────────────

typedef _NodePath = List<int>;

class _DragNodeData {
  final HearingConstraint constraint;
  final _NodePath sourcePath;
  const _DragNodeData(this.constraint, this.sourcePath);
}

bool _pathEquals(_NodePath a, _NodePath b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Returns true if [prefix] is a prefix of (or equal to) [path].
bool _isPathPrefix(_NodePath prefix, _NodePath path) {
  if (prefix.length > path.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (prefix[i] != path[i]) return false;
  }
  return true;
}

HearingConstraint _getAtPath(HearingConstraint root, _NodePath path) {
  var node = root;
  for (final idx in path) {
    if (node is LogicalAndConstraint) {
      node = node.nodes[idx];
    } else if (node is LogicalOrConstraint) {
      node = node.nodes[idx];
    } else if (node is LogicalNotConstraint) {
      node = node.node;
    } else {
      throw StateError('Cannot descend into leaf');
    }
  }
  return node;
}

/// Removes the node at [path]. Returns null if the root itself was removed.
HearingConstraint? _removeAtPath(HearingConstraint root, _NodePath path) {
  if (path.isEmpty) return null;
  return _removeHelper(root, path, 0);
}

HearingConstraint? _removeHelper(
    HearingConstraint node, _NodePath path, int depth) {
  final idx = path[depth];
  final isLast = depth == path.length - 1;

  if (node is LogicalAndConstraint) {
    final nodes = List<HearingConstraint>.of(node.nodes);
    if (isLast) {
      nodes.removeAt(idx);
    } else {
      final result = _removeHelper(nodes[idx], path, depth + 1);
      if (result == null) {
        nodes.removeAt(idx);
      } else {
        nodes[idx] = result;
      }
    }
    return LogicalAndConstraint(nodes: nodes);
  }
  if (node is LogicalOrConstraint) {
    final nodes = List<HearingConstraint>.of(node.nodes);
    if (isLast) {
      nodes.removeAt(idx);
    } else {
      final result = _removeHelper(nodes[idx], path, depth + 1);
      if (result == null) {
        nodes.removeAt(idx);
      } else {
        nodes[idx] = result;
      }
    }
    return LogicalOrConstraint(nodes: nodes);
  }
  if (node is LogicalNotConstraint) {
    if (isLast) return null;
    final result = _removeHelper(node.node, path, depth + 1);
    if (result == null) return null;
    return LogicalNotConstraint(node: result);
  }
  throw StateError('Cannot descend into leaf');
}

/// Adds [child] as the last child of the container at [containerPath].
HearingConstraint _addChildAtPath(
  HearingConstraint root,
  _NodePath containerPath,
  HearingConstraint child,
) {
  if (containerPath.isEmpty) return _addToContainer(root, child);
  return _addChildHelper(root, containerPath, 0, child);
}

HearingConstraint _addToContainer(
    HearingConstraint container, HearingConstraint child) {
  if (container is LogicalAndConstraint) {
    return LogicalAndConstraint(nodes: [...container.nodes, child]);
  }
  if (container is LogicalOrConstraint) {
    return LogicalOrConstraint(nodes: [...container.nodes, child]);
  }
  if (container is LogicalNotConstraint) {
    return LogicalNotConstraint(node: child);
  }
  return LogicalAndConstraint(nodes: [container, child]);
}

HearingConstraint _addChildHelper(
  HearingConstraint node,
  _NodePath path,
  int depth,
  HearingConstraint child,
) {
  final idx = path[depth];
  final isLast = depth == path.length - 1;

  if (node is LogicalAndConstraint) {
    final nodes = List<HearingConstraint>.of(node.nodes);
    nodes[idx] =
        isLast ? _addToContainer(nodes[idx], child) : _addChildHelper(nodes[idx], path, depth + 1, child);
    return LogicalAndConstraint(nodes: nodes);
  }
  if (node is LogicalOrConstraint) {
    final nodes = List<HearingConstraint>.of(node.nodes);
    nodes[idx] =
        isLast ? _addToContainer(nodes[idx], child) : _addChildHelper(nodes[idx], path, depth + 1, child);
    return LogicalOrConstraint(nodes: nodes);
  }
  if (node is LogicalNotConstraint) {
    final inner = isLast
        ? _addToContainer(node.node, child)
        : _addChildHelper(node.node, path, depth + 1, child);
    return LogicalNotConstraint(node: inner);
  }
  throw StateError('Cannot descend into leaf');
}

/// Adjusts [targetPath] after a removal at [removedPath].
_NodePath _adjustPathAfterRemoval(_NodePath targetPath, _NodePath removedPath) {
  if (targetPath.isEmpty || removedPath.isEmpty) return targetPath;

  // Find common prefix length
  final limit =
      targetPath.length < removedPath.length ? targetPath.length : removedPath.length;
  int common = 0;
  while (common < limit - 1 &&
      targetPath[common] == removedPath[common]) {
    common++;
  }

  // If the removed node was a direct child of the same container and
  // its index was before the target index at the divergence level, adjust.
  if (common < targetPath.length &&
      common < removedPath.length &&
      removedPath.length == common + 1 &&
      removedPath[common] < targetPath[common]) {
    final adjusted = List<int>.of(targetPath);
    adjusted[common]--;
    return adjusted;
  }
  return targetPath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Root normalisation helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps any constraint into a root AND/OR so the editor always has a logical
/// root. Null → empty AND, non-logical → AND with one child, AND/OR pass through.
HearingConstraint _normalizeRoot(HearingConstraint? c) {
  if (c == null) return const LogicalAndConstraint(nodes: []);
  if (c is LogicalAndConstraint) return c;
  if (c is LogicalOrConstraint) return c;
  return LogicalAndConstraint(nodes: [c]);
}

/// Inverse of [_normalizeRoot]: unwraps single-child AND/OR, empty → null.
HearingConstraint? _denormalizeRoot(HearingConstraint root) {
  final List<HearingConstraint> children;
  if (root is LogicalAndConstraint) {
    children = root.nodes;
  } else if (root is LogicalOrConstraint) {
    children = root.nodes;
  } else {
    return root;
  }
  if (children.isEmpty) return null;
  if (children.length == 1) return children.first;
  return root;
}

// ─────────────────────────────────────────────────────────────────────────────
// InheritedWidget for tree-wide drag-and-drop operations
// ─────────────────────────────────────────────────────────────────────────────

class _TreeScope extends InheritedWidget {
  final void Function(_NodePath sourcePath, _NodePath targetContainerPath)
      moveNodeInto;
  final void Function(_NodePath sourcePath) moveNodeToRoot;

  /// Adds a brand-new constraint (e.g. from a preset drag) into the container
  /// at [containerPath].
  final void Function(HearingConstraint node, _NodePath containerPath)
      addNewNodeTo;

  final bool isFolder;

  /// Bumped on each collapse/expand-all action.
  final int collapseGeneration;

  /// Target state for the current generation (true = collapsed).
  final bool collapseState;

  const _TreeScope({
    required this.moveNodeInto,
    required this.moveNodeToRoot,
    required this.addNewNodeTo,
    required this.isFolder,
    this.collapseGeneration = 0,
    this.collapseState = false,
    required super.child,
  });

  static _TreeScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TreeScope>()!;

  @override
  bool updateShouldNotify(_TreeScope old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Constraint editor page
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen page for editing hearing constraints.
///
/// Two-column layout: custom tree editor on the left, preset list on the right.
/// OK saves, Cancel reverts.
class ConstraintEditorPage extends StatefulWidget {
  final HearingConstraint? initialConstraint;
  final bool isFolder;
  final void Function(HearingConstraint?) onChanged;

  /// When non-null, the item has no own constraint but inherits this one from
  /// an ancestor folder. Enables the "import" button.
  final HearingConstraint? inheritedConstraint;

  /// Display name of the ancestor folder that owns [inheritedConstraint].
  final String? inheritedFromName;

  const ConstraintEditorPage({
    super.key,
    required this.initialConstraint,
    required this.isFolder,
    required this.onChanged,
    this.inheritedConstraint,
    this.inheritedFromName,
  });

  @override
  State<ConstraintEditorPage> createState() => _ConstraintEditorPageState();
}

class _ConstraintEditorPageState extends State<ConstraintEditorPage> {
  /// Always a [LogicalAndConstraint] or [LogicalOrConstraint].
  late HearingConstraint _constraint;

  int _collapseGeneration = 0;
  bool _collapseState = false;

  @override
  void initState() {
    super.initState();
    _constraint = _normalizeRoot(widget.initialConstraint);
  }

  bool get _isAnd => _constraint is LogicalAndConstraint;

  bool get _isTreeEmpty {
    if (_constraint is LogicalAndConstraint) {
      return (_constraint as LogicalAndConstraint).nodes.isEmpty;
    }
    if (_constraint is LogicalOrConstraint) {
      return (_constraint as LogicalOrConstraint).nodes.isEmpty;
    }
    return false;
  }

  void _collapseAll() => setState(() {
        _collapseState = true;
        _collapseGeneration++;
      });

  void _expandAll() => setState(() {
        _collapseState = false;
        _collapseGeneration++;
      });

  void _cancel() => Navigator.of(context).pop();

  void _confirm() {
    widget.onChanged(_denormalizeRoot(_constraint));
    Navigator.of(context).pop();
  }

  void _toggleRootMode() {
    final children = _isAnd
        ? (_constraint as LogicalAndConstraint).nodes
        : (_constraint as LogicalOrConstraint).nodes;
    setState(() {
      _constraint = _isAnd
          ? LogicalOrConstraint(nodes: children)
          : LogicalAndConstraint(nodes: children);
    });
  }

  /// Atomically moves a node from [sourcePath] into the container at
  /// [targetContainerPath] (appends as last child).
  void _moveNodeInto(_NodePath sourcePath, _NodePath targetContainerPath) {
    if (_isPathPrefix(sourcePath, targetContainerPath)) return;
    if (_pathEquals(sourcePath, targetContainerPath)) return;

    final node = _getAtPath(_constraint, sourcePath);
    var tree = _removeAtPath(_constraint, sourcePath);
    if (tree == null) {
      setState(() => _constraint = _normalizeRoot(node));
      return;
    }
    final adjusted =
        _adjustPathAfterRemoval(targetContainerPath, sourcePath);
    tree = _addChildAtPath(tree, adjusted, node);
    setState(() => _constraint = tree!);
  }

  /// Adds a brand-new constraint (e.g. from a preset drag) into the container
  /// at [containerPath].
  void _addNewNodeTo(HearingConstraint node, _NodePath containerPath) {
    setState(() {
      _constraint = _addChildAtPath(_constraint, containerPath, node);
    });
  }

  /// Atomically moves a node from [sourcePath] to root level (appends to
  /// the implicit root AND/OR).
  void _moveNodeToRoot(_NodePath sourcePath) {
    if (sourcePath.isEmpty) return;

    final node = _getAtPath(_constraint, sourcePath);
    var tree = _removeAtPath(_constraint, sourcePath);
    if (tree == null) {
      setState(() => _constraint = _normalizeRoot(node));
      return;
    }
    // tree is still the root AND/OR — append node to its children.
    setState(() => _constraint = _addToContainer(tree, node));
  }

  @override
  Widget build(BuildContext context) {
    return _TreeScope(
      moveNodeInto: _moveNodeInto,
      moveNodeToRoot: _moveNodeToRoot,
      addNewNodeTo: _addNewNodeTo,
      isFolder: widget.isFolder,
      collapseGeneration: _collapseGeneration,
      collapseState: _collapseState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hörregeln bearbeiten'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Abbrechen',
            onPressed: _cancel,
          ),
          actions: [
            TextButton.icon(
              onPressed: () => setState(() {
                _constraint = const LogicalAndConstraint(nodes: []);
              }),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Zurücksetzen'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _cancel,
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Übernehmen'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            // ── Import banner when inherited constraint available ──
            if (widget.inheritedConstraint != null && _isTreeEmpty)
              MaterialBanner(
                content: Text(
                  'Dieses Element erbt Hörregeln von „${widget.inheritedFromName}". '
                  'Du kannst sie als eigene Regeln übernehmen und anpassen.',
                ),
                leading: const Icon(Icons.info_outline),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Regeln übernehmen'),
                    onPressed: () {
                      setState(() {
                        _constraint =
                            _normalizeRoot(widget.inheritedConstraint);
                      });
                    },
                  ),
                ],
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Left: Custom tree editor ──
                  Expanded(
                    flex: 3,
                    child: _EditorPane(
                      constraint: _constraint,
                      isAnd: _isAnd,
                      isFolder: widget.isFolder,
                      onChanged: (c) => setState(() => _constraint = c),
                      onToggleMode: _toggleRootMode,
                      onCollapseAll: _collapseAll,
                      onExpandAll: _expandAll,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // ── Right: Preset list ──
                  Expanded(
                    flex: 2,
                    child: _PresetPane(isFolder: widget.isFolder),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Left pane: tree editor with root-level drop zone
// ─────────────────────────────────────────────────────────────────────────────

class _EditorPane extends StatelessWidget {
  /// Always a [LogicalAndConstraint] or [LogicalOrConstraint].
  final HearingConstraint constraint;
  final bool isAnd;
  final bool isFolder;
  final void Function(HearingConstraint) onChanged;
  final VoidCallback onToggleMode;
  final VoidCallback onCollapseAll;
  final VoidCallback onExpandAll;

  const _EditorPane({
    required this.constraint,
    required this.isAnd,
    required this.isFolder,
    required this.onChanged,
    required this.onToggleMode,
    required this.onCollapseAll,
    required this.onExpandAll,
  });

  List<HearingConstraint> get _children => isAnd
      ? (constraint as LogicalAndConstraint).nodes
      : (constraint as LogicalOrConstraint).nodes;

  void _updateChildren(List<HearingConstraint> nodes) {
    onChanged(isAnd
        ? LogicalAndConstraint(nodes: nodes)
        : LogicalOrConstraint(nodes: nodes));
  }

  @override
  Widget build(BuildContext context) {
    final children = _children;

    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        if (details.data is HearingConstraint) return true;
        if (details.data is _DragNodeData) {
          return (details.data as _DragNodeData).sourcePath.isNotEmpty;
        }
        return false;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is HearingConstraint) {
          _updateChildren([...children, data]);
        } else if (data is _DragNodeData) {
          _TreeScope.of(context).moveNodeToRoot(data.sourcePath);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: isHovering
              ? BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  color: Colors.blue.withValues(alpha: 0.05),
                )
              : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Regel-Editor',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    if (children.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.unfold_less, size: 20),
                        tooltip: 'Alle einklappen',
                        onPressed: onCollapseAll,
                      ),
                      IconButton(
                        icon: const Icon(Icons.unfold_more, size: 20),
                        tooltip: 'Alle ausklappen',
                        onPressed: onExpandAll,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // ── AND / OR toggle ──
                _RootModeToggle(isAnd: isAnd, onToggle: onToggleMode),
                const SizedBox(height: 12),
                if (children.isEmpty) ...[
                  Card(
                    color: Colors.green[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Keine Einschränkung — frei abspielbar.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    _ConstraintNodeEditor(
                      constraint: children[i],
                      isFolder: isFolder,
                      depth: 0,
                      path: [i],
                      onChanged: (updated) {
                        final copy = List<HearingConstraint>.of(children);
                        copy[i] = updated;
                        _updateChildren(copy);
                      },
                      onRemove: () {
                        final copy = List<HearingConstraint>.of(children);
                        copy.removeAt(i);
                        _updateChildren(copy);
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                _AddNodeDropZone(
                  isFolder: isFolder,
                  containerPath: const [],
                  onSelected: (c) => _updateChildren([...children, c]),
                ),
                if (children.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Builder(builder: (context) {
                    final desc = children.length == 1
                        ? children.first
                        : constraint;
                    return Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                const ConstraintDescriptionGenerator()
                                    .describe(desc),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AND / OR root mode toggle
// ─────────────────────────────────────────────────────────────────────────────

class _RootModeToggle extends StatelessWidget {
  final bool isAnd;
  final VoidCallback onToggle;

  const _RootModeToggle({required this.isAnd, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Verknüpfung:',
            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(width: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('UND (alle gelten)')),
            ButtonSegment(value: false, label: Text('ODER (eins genügt)')),
          ],
          selected: {isAnd},
          onSelectionChanged: (_) => onToggle(),
          showSelectedIcon: false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Right pane: preset list
// ─────────────────────────────────────────────────────────────────────────────

class _PresetPane extends StatelessWidget {
  final bool isFolder;

  const _PresetPane({required this.isFolder});

  @override
  Widget build(BuildContext context) {
    final templates = kConstraintTemplates
        .where((t) => !t.folderOnly || isFolder)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Bausteine',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Per Drag & Drop in den Editor ziehen',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: templates
                .map((tpl) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _PresetCard(
                        emoji: tpl.emoji,
                        label: tpl.label,
                        description: tpl.description,
                        constraint: tpl.constraint,
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final HearingConstraint constraint;

  const _PresetCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.constraint,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<HearingConstraint>(
      data: constraint,
      delay: const Duration(milliseconds: 100),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildCard(),
      ),
      child: _buildCard(),
    );
  }

  Widget _buildCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.drag_indicator, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recursive constraint node editor
// ─────────────────────────────────────────────────────────────────────────────

/// Available constraint type keys for the dropdown.
const _kConstraintTypes = <String, String>{
  'and': 'UND (alle müssen gelten)',
  'or': 'ODER (mindestens eins)',
  'not': 'NICHT (Umkehrung)',
  'play_count': 'Abspielhäufigkeit',
  'play_duration': 'Hördauer',
  'folder_item_count': 'Verschiedene Einträge im Ordner',
  'time_of_day': 'Tageszeit',
  'day_of_week': 'Wochentag',
  'date_range': 'Zeitraum',
};

String _typeKeyOf(HearingConstraint c) {
  if (c is LogicalAndConstraint) return 'and';
  if (c is LogicalOrConstraint) return 'or';
  if (c is LogicalNotConstraint) return 'not';
  if (c is PlayCountConstraint) return 'play_count';
  if (c is PlayDurationConstraint) return 'play_duration';
  if (c is FolderItemCountConstraint) return 'folder_item_count';
  if (c is TimeOfDayConstraint) return 'time_of_day';
  if (c is DayOfWeekConstraint) return 'day_of_week';
  if (c is DateRangeConstraint) return 'date_range';
  return 'play_count';
}

HearingConstraint _defaultForType(String typeKey) {
  switch (typeKey) {
    case 'and':
      return const LogicalAndConstraint(nodes: []);
    case 'or':
      return const LogicalOrConstraint(nodes: []);
    case 'not':
      return const LogicalNotConstraint(
        node: PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      );
    case 'play_count':
      return const PlayCountConstraint(
        maxCount: 1,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
    case 'play_duration':
      return const PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perWeek),
      );
    case 'folder_item_count':
      return const FolderItemCountConstraint(
        maxItems: 2,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
    case 'time_of_day':
      return const TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
    case 'day_of_week':
      return const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]);
    case 'date_range':
      return const DateRangeConstraint();
    default:
      return const PlayCountConstraint(
        maxCount: 1,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
  }
}

class _ConstraintNodeEditor extends StatefulWidget {
  final HearingConstraint constraint;
  final bool isFolder;
  final int depth;
  final _NodePath path;
  final void Function(HearingConstraint) onChanged;
  final VoidCallback onRemove;

  const _ConstraintNodeEditor({
    required this.constraint,
    required this.isFolder,
    required this.depth,
    required this.path,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_ConstraintNodeEditor> createState() => _ConstraintNodeEditorState();
}

class _ConstraintNodeEditorState extends State<_ConstraintNodeEditor> {
  bool _collapsed = false;
  int _syncedGeneration = 0;

  bool get _isLogical =>
      widget.constraint is LogicalAndConstraint ||
      widget.constraint is LogicalOrConstraint ||
      widget.constraint is LogicalNotConstraint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _TreeScope.of(context);
    if (scope.collapseGeneration != _syncedGeneration) {
      _syncedGeneration = scope.collapseGeneration;
      _collapsed = scope.collapseState;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeKey = _typeKeyOf(widget.constraint);
    final availableTypes = Map.of(_kConstraintTypes);
    if (!widget.isFolder) availableTypes.remove('folder_item_count');

    // The core node card
    Widget nodeCard = Container(
      margin: EdgeInsets.only(left: widget.depth > 0 ? 16.0 : 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: widget.depth.isEven ? Colors.white : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector + collapse toggle + delete button
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _collapsed = !_collapsed),
                borderRadius: BorderRadius.circular(4),
                child: Icon(
                  _collapsed ? Icons.expand_more : Icons.expand_less,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: typeKey,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                    labelText: 'Typ',
                  ),
                  items: availableTypes.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (newType) {
                    if (newType != null && newType != typeKey) {
                      widget.onChanged(_defaultForType(newType));
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red[700],
                tooltip: 'Entfernen',
                onPressed: widget.onRemove,
              ),
            ],
          ),
          // Type-specific parameter editors (hidden when collapsed)
          if (!_collapsed) ...[
            const SizedBox(height: 8),
            _buildParameterEditor(context),
          ],
        ],
      ),
    );

    // Wrap logical nodes in a DragTarget so other nodes can be dropped into them.
    // Capture the current value before reassigning — the builder closure must
    // reference the original card, not the DragTarget itself.
    if (_isLogical) {
      final innerCard = nodeCard;
      nodeCard = DragTarget<Object>(
        onWillAcceptWithDetails: (details) {
          if (details.data is HearingConstraint) return true;
          if (details.data is _DragNodeData) {
            final d = details.data as _DragNodeData;
            if (_pathEquals(d.sourcePath, widget.path)) return false;
            if (_isPathPrefix(widget.path, d.sourcePath)) return true;
            if (_isPathPrefix(d.sourcePath, widget.path)) return false;
            return true;
          }
          return false;
        },
        onAcceptWithDetails: (details) {
          final scope = _TreeScope.of(context);
          final data = details.data;
          if (data is HearingConstraint) {
            scope.addNewNodeTo(data, widget.path);
          } else if (data is _DragNodeData) {
            scope.moveNodeInto(data.sourcePath, widget.path);
          }
        },
        builder: (context, candidateData, rejectedData) {
          if (candidateData.isNotEmpty) {
            return Container(
              margin: EdgeInsets.only(left: widget.depth > 0 ? 16.0 : 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withValues(alpha: 0.05),
              ),
              child: innerCard,
            );
          }
          return innerCard;
        },
      );
    }

    // Wrap everything in a Draggable via the drag handle row
    return _DraggableNode(
      data: _DragNodeData(widget.constraint, widget.path),
      typeLabel: _kConstraintTypes[typeKey] ?? typeKey,
      child: nodeCard,
    );
  }

  Widget _buildParameterEditor(BuildContext context) {
    final c = widget.constraint;
    if (c is LogicalAndConstraint) {
      return _LogicalChildrenEditor(
        nodes: c.nodes,
        isFolder: widget.isFolder,
        depth: widget.depth,
        parentPath: widget.path,
        onChanged: (nodes) =>
            widget.onChanged(LogicalAndConstraint(nodes: nodes)),
      );
    }
    if (c is LogicalOrConstraint) {
      return _LogicalChildrenEditor(
        nodes: c.nodes,
        isFolder: widget.isFolder,
        depth: widget.depth,
        parentPath: widget.path,
        onChanged: (nodes) =>
            widget.onChanged(LogicalOrConstraint(nodes: nodes)),
      );
    }
    if (c is LogicalNotConstraint) {
      return _ConstraintNodeEditor(
        constraint: c.node,
        isFolder: widget.isFolder,
        depth: widget.depth + 1,
        path: [...widget.path, 0],
        onChanged: (inner) =>
            widget.onChanged(LogicalNotConstraint(node: inner)),
        onRemove: () => widget.onChanged(
          const PlayCountConstraint(
            maxCount: 1,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ),
      );
    }
    if (c is PlayCountConstraint) {
      return _PlayCountEditor(constraint: c, onChanged: widget.onChanged);
    }
    if (c is PlayDurationConstraint) {
      return _PlayDurationEditor(constraint: c, onChanged: widget.onChanged);
    }
    if (c is FolderItemCountConstraint) {
      return _FolderItemCountEditor(
          constraint: c, onChanged: widget.onChanged);
    }
    if (c is TimeOfDayConstraint) {
      return _TimeOfDayEditor(constraint: c, onChanged: widget.onChanged);
    }
    if (c is DayOfWeekConstraint) {
      return _DayOfWeekEditor(constraint: c, onChanged: widget.onChanged);
    }
    if (c is DateRangeConstraint) {
      return _DateRangeEditor(constraint: c, onChanged: widget.onChanged);
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Draggable wrapper – uses a drag handle so taps on dropdowns/fields work
// ─────────────────────────────────────────────────────────────────────────────

class _DraggableNode extends StatelessWidget {
  final _DragNodeData data;
  final String typeLabel;
  final Widget child;

  const _DraggableNode({
    required this.data,
    required this.typeLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<_DragNodeData>(
      data: data,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.drag_indicator,
                  size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Text(typeLabel,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logical children list editor (AND / OR)
// ─────────────────────────────────────────────────────────────────────────────

class _LogicalChildrenEditor extends StatelessWidget {
  final List<HearingConstraint> nodes;
  final bool isFolder;
  final int depth;
  final _NodePath parentPath;
  final void Function(List<HearingConstraint>) onChanged;

  const _LogicalChildrenEditor({
    required this.nodes,
    required this.isFolder,
    required this.depth,
    required this.parentPath,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < nodes.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _ConstraintNodeEditor(
            constraint: nodes[i],
            isFolder: isFolder,
            depth: depth + 1,
            path: [...parentPath, i],
            onChanged: (updated) {
              final copy = List<HearingConstraint>.of(nodes);
              copy[i] = updated;
              onChanged(copy);
            },
            onRemove: () {
              final copy = List<HearingConstraint>.of(nodes);
              copy.removeAt(i);
              onChanged(copy);
            },
          ),
        ],
        const SizedBox(height: 6),
        _AddNodeDropZone(
          isFolder: isFolder,
          containerPath: parentPath,
          onSelected: (c) => onChanged([...nodes, c]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add-node button
// ─────────────────────────────────────────────────────────────────────────────

/// A small card that acts as both a click-to-add menu and a drag-and-drop
/// target. Every AND/OR group (including the implicit root) shows one of
/// these at the bottom of its children list.
class _AddNodeDropZone extends StatelessWidget {
  final bool isFolder;

  /// Path of the container (AND/OR) this zone belongs to.
  /// Dropped nodes are moved into that container.
  final _NodePath containerPath;

  /// Called when the user picks a new constraint type from the popup menu.
  final void Function(HearingConstraint) onSelected;

  const _AddNodeDropZone({
    required this.isFolder,
    required this.containerPath,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Object>(
      onWillAcceptWithDetails: (details) {
        if (details.data is HearingConstraint) return true;
        if (details.data is _DragNodeData) {
          final d = details.data as _DragNodeData;
          if (_pathEquals(d.sourcePath, containerPath)) return false;
          if (_isPathPrefix(d.sourcePath, containerPath)) return false;
          return true;
        }
        return false;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data is HearingConstraint) {
          onSelected(data);
        } else if (data is _DragNodeData) {
          _TreeScope.of(context)
              .moveNodeInto(data.sourcePath, containerPath);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return PopupMenuButton<String>(
          tooltip: 'Bedingung hinzufügen oder hierher ziehen',
          onSelected: (typeKey) => onSelected(_defaultForType(typeKey)),
          itemBuilder: (ctx) {
            final types = Map.of(_kConstraintTypes);
            if (!isFolder) types.remove('folder_item_count');
            return types.entries
                .map(
                    (e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                .toList();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHovering ? Colors.blue : Colors.grey[300]!,
                width: isHovering ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isHovering
                  ? Colors.blue.withValues(alpha: 0.08)
                  : Colors.grey[50],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline,
                    size: 18,
                    color: isHovering ? Colors.blue : Colors.blue[700]),
                const SizedBox(width: 6),
                Text(
                  'Bedingung hinzufügen',
                  style: TextStyle(
                    color: isHovering ? Colors.blue : Colors.blue[700],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaf parameter editors
// ─────────────────────────────────────────────────────────────────────────────

class _TimeWindowEditor extends StatelessWidget {
  final TimeWindow window;
  final void Function(TimeWindow) onChanged;

  const _TimeWindowEditor({required this.window, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<TimeWindowType>(
          initialValue: window.type,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(),
            labelText: 'Zeitfenster',
          ),
          items: const [
            DropdownMenuItem(
                value: TimeWindowType.perDay, child: Text('Pro Tag')),
            DropdownMenuItem(
                value: TimeWindowType.perWeek, child: Text('Pro Woche')),
            DropdownMenuItem(
                value: TimeWindowType.perMonth, child: Text('Pro Monat')),
            DropdownMenuItem(
                value: TimeWindowType.sinceDate, child: Text('Seit Datum')),
            DropdownMenuItem(
                value: TimeWindowType.rollingHours,
                child: Text('Letzte N Stunden')),
          ],
          onChanged: (type) {
            if (type == null) return;
            onChanged(TimeWindow(
              type: type,
              sinceDate: type == TimeWindowType.sinceDate
                  ? (window.sinceDate ??
                      DateTime.now()
                          .toIso8601String()
                          .substring(0, 10))
                  : null,
              rollingHours: type == TimeWindowType.rollingHours
                  ? (window.rollingHours ?? 24)
                  : null,
            ));
          },
        ),
        if (window.type == TimeWindowType.sinceDate) ...[
          const SizedBox(height: 8),
          _DateField(
            label: 'Seit',
            value: window.sinceDate,
            onChanged: (d) =>
                onChanged(TimeWindow(type: window.type, sinceDate: d)),
          ),
        ],
        if (window.type == TimeWindowType.rollingHours) ...[
          const SizedBox(height: 8),
          _IntField(
            label: 'Stunden',
            value: window.rollingHours ?? 24,
            min: 1,
            max: 744,
            onChanged: (v) =>
                onChanged(TimeWindow(type: window.type, rollingHours: v)),
          ),
        ],
      ],
    );
  }
}

class _PlayCountEditor extends StatelessWidget {
  final PlayCountConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _PlayCountEditor({required this.constraint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IntField(
          label: 'Maximal',
          value: constraint.maxCount,
          min: 1,
          max: 999,
          onChanged: (v) => onChanged(PlayCountConstraint(
            maxCount: v,
            window: constraint.window,
          )),
        ),
        const SizedBox(height: 8),
        _TimeWindowEditor(
          window: constraint.window,
          onChanged: (w) => onChanged(PlayCountConstraint(
            maxCount: constraint.maxCount,
            window: w,
          )),
        ),
      ],
    );
  }
}

class _PlayDurationEditor extends StatelessWidget {
  final PlayDurationConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _PlayDurationEditor(
      {required this.constraint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IntField(
          label: 'Max. Minuten',
          value: constraint.maxMinutes,
          min: 1,
          max: 9999,
          onChanged: (v) => onChanged(PlayDurationConstraint(
            maxMinutes: v,
            window: constraint.window,
          )),
        ),
        const SizedBox(height: 8),
        _TimeWindowEditor(
          window: constraint.window,
          onChanged: (w) => onChanged(PlayDurationConstraint(
            maxMinutes: constraint.maxMinutes,
            window: w,
          )),
        ),
      ],
    );
  }
}

class _FolderItemCountEditor extends StatelessWidget {
  final FolderItemCountConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _FolderItemCountEditor(
      {required this.constraint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IntField(
          label: 'Max. Einträge',
          value: constraint.maxItems,
          min: 1,
          max: 999,
          onChanged: (v) => onChanged(FolderItemCountConstraint(
            maxItems: v,
            window: constraint.window,
          )),
        ),
        const SizedBox(height: 8),
        _TimeWindowEditor(
          window: constraint.window,
          onChanged: (w) => onChanged(FolderItemCountConstraint(
            maxItems: constraint.maxItems,
            window: w,
          )),
        ),
      ],
    );
  }
}

class _TimeOfDayEditor extends StatelessWidget {
  final TimeOfDayConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _TimeOfDayEditor({required this.constraint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: 'Von',
            value: constraint.fromTime,
            onChanged: (v) => onChanged(TimeOfDayConstraint(
              fromTime: v,
              toTime: constraint.toTime,
            )),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TimeField(
            label: 'Bis',
            value: constraint.toTime,
            onChanged: (v) => onChanged(TimeOfDayConstraint(
              fromTime: constraint.fromTime,
              toTime: v,
            )),
          ),
        ),
      ],
    );
  }
}

class _DayOfWeekEditor extends StatelessWidget {
  final DayOfWeekConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _DayOfWeekEditor({required this.constraint, required this.onChanged});

  static const _dayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(7, (i) {
        final day = i + 1;
        final selected = constraint.allowedDays.contains(day);
        return FilterChip(
          label: Text(_dayLabels[i]),
          selected: selected,
          onSelected: (on) {
            final days = List<int>.of(constraint.allowedDays);
            if (on) {
              days.add(day);
            } else {
              days.remove(day);
            }
            days.sort();
            onChanged(DayOfWeekConstraint(allowedDays: days));
          },
        );
      }),
    );
  }
}

class _DateRangeEditor extends StatelessWidget {
  final DateRangeConstraint constraint;
  final void Function(HearingConstraint) onChanged;

  const _DateRangeEditor({required this.constraint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            label: 'Von',
            value: constraint.fromDate,
            onChanged: (v) => onChanged(DateRangeConstraint(
              fromDate: v,
              toDate: constraint.toDate,
            )),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DateField(
            label: 'Bis',
            value: constraint.toDate,
            onChanged: (v) => onChanged(DateRangeConstraint(
              fromDate: constraint.fromDate,
              toDate: v,
            )),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable form fields
// ─────────────────────────────────────────────────────────────────────────────

class _IntField extends StatefulWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _IntField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_IntField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
        labelText: widget.label,
      ),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final v = int.tryParse(text);
        if (v != null && v >= widget.min && v <= widget.max) {
          widget.onChanged(v);
        }
      },
    );
  }
}

class _TimeField extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TimeField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
        labelText: widget.label,
        hintText: 'HH:mm',
      ),
      onChanged: (text) {
        if (RegExp(r'^\d{2}:\d{2}$').hasMatch(text)) {
          widget.onChanged(text);
        }
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final void Function(String?) onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: const OutlineInputBorder(),
              labelText: label,
            ),
            child: Text(
              value != null ? _fmtDate(value!) : 'Nicht gesetzt',
              style: TextStyle(
                color: value != null ? null : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.calendar_today, size: 18),
          tooltip: 'Datum wählen',
          onPressed: () async {
            final initial = value != null
                ? DateTime.tryParse(value!) ?? DateTime.now()
                : DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onChanged(picked.toIso8601String().substring(0, 10));
            }
          },
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            tooltip: 'Entfernen',
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }

  String _fmtDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}
