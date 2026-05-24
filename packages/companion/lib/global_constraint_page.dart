import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

import 'constraint_editor.dart';

/// Admin page for managing the global hearing constraint.
///
/// Loads the `global-config` CouchDB document, shows the current constraint
/// (if any), and allows opening the full constraint editor to create, modify
/// or remove it.
class GlobalConstraintPage extends StatefulWidget {
  const GlobalConstraintPage({super.key});

  @override
  State<GlobalConstraintPage> createState() => _GlobalConstraintPageState();
}

class _GlobalConstraintPageState extends State<GlobalConstraintPage> {
  HearingConstraint? _constraint;
  String? _rev;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final doc = await di<DartCouchDb>().get(GlobalConstraints.docId);
      if (doc != null) {
        final config = doc as GlobalConstraints;
        _constraint = config.hearingConstraint;
        _rev = config.rev;
      }
    } catch (_) {
      // Document doesn't exist yet — that's fine.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveConstraint(HearingConstraint? constraint) async {
    final config = GlobalConstraints(
      id: GlobalConstraints.docId,
      hearingConstraint: constraint,
      rev: _rev,
    );
    final saved = await di<DartCouchDb>().put(config);
    _rev = saved.rev;
    if (mounted) {
      setState(() => _constraint = constraint);
    }
  }

  void _openEditor() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConstraintEditorPage(
        initialConstraint: _constraint,
        isFolder: false,
        onChanged: _saveConstraint,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SharedL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companionGlobalConstraintsMenu),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.public, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.globalConstraintsHeading,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.globalConstraintsDescription,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          if (_constraint != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      Colors.purple.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer,
                                      color: Colors.purple),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      ConstraintDescriptionGenerator(l10n)
                                          .describe(_constraint!),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    tooltip:
                                        l10n.globalConstraintsRemoveTooltip,
                                    onPressed: () =>
                                        _saveConstraint(null),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          FilledButton.icon(
                            onPressed: _openEditor,
                            icon: Icon(_constraint != null
                                ? Icons.edit
                                : Icons.add),
                            label: Text(_constraint != null
                                ? l10n.commonEdit
                                : l10n.globalConstraintsCreate),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
