import 'package:dart_couch/dart_couch.dart';
import 'package:dart_mappable/dart_mappable.dart';

import 'hearing_constraint.dart';

part 'global_constraints.mapper.dart';

/// Global hearing constraint configuration document.
///
/// Stored in CouchDB with a deterministic ID (`global-constraints`). Managed
/// exclusively by the companion app — the player only reads and subscribes
/// to changes.
///
/// The [hearingConstraint] field holds an arbitrary constraint tree (e.g.
/// a `LogicalOr` combining weekday and weekend `PlayDurationConstraint`s).
/// The player evaluates this constraint against **aggregated** play stats
/// from all items. The result is combined with per-item constraints using
/// most-restrictive-wins semantics.
@MappableClass(discriminatorValue: 'global_constraints', ignoreNull: true)
class GlobalConstraints extends CouchDocumentBase with GlobalConstraintsMappable {
  static const String docId = 'global-constraints';

  @MappableField(key: 'hearing_constraint')
  final HearingConstraint? hearingConstraint;

  GlobalConstraints({
    this.hearingConstraint,
    super.id,
    super.rev,
    super.attachments,
    super.deleted,
    super.revisions,
    super.revsInfo,
    super.unmappedProps,
  });
}
