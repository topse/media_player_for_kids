import 'hearing_constraint.dart';

/// Stateless utility that converts a [HearingConstraint] tree into a
/// German human-readable summary string.
///
/// Used by the companion editor chips and as a basis for [EvaluationResult]
/// messages in the player.
class ConstraintDescriptionGenerator {
  const ConstraintDescriptionGenerator();

  String describe(HearingConstraint constraint) {
    if (constraint is LogicalAndConstraint) {
      return constraint.nodes.map(describe).join(' und ');
    }
    if (constraint is LogicalOrConstraint) {
      return constraint.nodes.map(describe).join(' oder ');
    }
    if (constraint is LogicalNotConstraint) {
      return 'Nicht: ${describe(constraint.node)}';
    }
    if (constraint is PlayCountConstraint) {
      return _describePlayCount(constraint);
    }
    if (constraint is PlayDurationConstraint) {
      return _describePlayDuration(constraint);
    }
    if (constraint is FolderItemCountConstraint) {
      return _describeFolderItemCount(constraint);
    }
    if (constraint is TimeOfDayConstraint) {
      return 'Nur ${constraint.fromTime}–${constraint.toTime} Uhr';
    }
    if (constraint is DayOfWeekConstraint) {
      return _describeDayOfWeek(constraint);
    }
    if (constraint is DateRangeConstraint) {
      return _describeDateRange(constraint);
    }
    return 'Unbekannte Einschränkung';
  }

  // ── Leaf descriptions ────────────────────────────────────────────────────────

  String _describePlayCount(PlayCountConstraint c) {
    final w = _windowLabel(c.window);
    if (c.maxCount == 1) return 'Einmal $w';
    return 'Maximal ${c.maxCount}× $w';
  }

  String _describePlayDuration(PlayDurationConstraint c) {
    return 'Max. ${c.maxMinutes} Min. ${_windowLabel(c.window)}';
  }

  String _describeFolderItemCount(FolderItemCountConstraint c) {
    return 'Max. ${c.maxItems} verschiedene Einträge ${_windowLabel(c.window)}';
  }

  String _describeDayOfWeek(DayOfWeekConstraint c) {
    final sorted = [...c.allowedDays]..sort();
    // Common shorthand patterns.
    if (sorted.length == 5 &&
        sorted.first == 1 &&
        sorted.last == 5 &&
        sorted.every((d) => d <= 5)) {
      return 'Nur Mo–Fr';
    }
    if (sorted.length == 2 && sorted.first == 6 && sorted.last == 7) {
      return 'Nur am Wochenende';
    }
    const abbr = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return 'Nur ${sorted.map((d) => abbr[d - 1]).join(', ')}';
  }

  String _describeDateRange(DateRangeConstraint c) {
    if (c.fromDate != null && c.toDate != null) {
      return '${_fmtDate(c.fromDate!)} – ${_fmtDate(c.toDate!)}';
    }
    if (c.fromDate != null) return 'Ab ${_fmtDate(c.fromDate!)}';
    if (c.toDate != null) return 'Bis ${_fmtDate(c.toDate!)}';
    return '';
  }

  // ── Window label ─────────────────────────────────────────────────────────────

  String _windowLabel(TimeWindow w) {
    switch (w.type) {
      case TimeWindowType.perDay:
        return 'pro Tag';
      case TimeWindowType.perWeek:
        return 'pro Woche';
      case TimeWindowType.perMonth:
        return 'pro Monat';
      case TimeWindowType.sinceDate:
        return 'seit ${_fmtDate(w.sinceDate!)}';
      case TimeWindowType.rollingHours:
        return 'je ${w.rollingHours} Stunden';
    }
  }

  // ── Formatting ───────────────────────────────────────────────────────────────

  String _fmtDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}
