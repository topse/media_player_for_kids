import 'package:intl/intl.dart';

import '../l10n/shared_l10n.dart';
import 'hearing_constraint.dart';

/// Stateless utility that converts a [HearingConstraint] tree into a
/// human-readable summary string in the locale carried by [loc].
///
/// Used by the companion editor chips and as a basis for [EvaluationResult]
/// messages in the player.
class ConstraintDescriptionGenerator {
  final SharedL10n loc;

  const ConstraintDescriptionGenerator(this.loc);

  String describe(HearingConstraint constraint) {
    if (constraint is LogicalAndConstraint) {
      return constraint.nodes.map(describe).join(loc.constraintAnd);
    }
    if (constraint is LogicalOrConstraint) {
      return constraint.nodes.map(describe).join(loc.constraintOr);
    }
    if (constraint is LogicalNotConstraint) {
      return loc.constraintNotPrefix(describe(constraint.node));
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
      return loc.constraintTimeOfDayOnly(constraint.fromTime, constraint.toTime);
    }
    if (constraint is DayOfWeekConstraint) {
      return _describeDayOfWeek(constraint);
    }
    if (constraint is DateRangeConstraint) {
      return _describeDateRange(constraint);
    }
    return loc.constraintUnknown;
  }

  String _describePlayCount(PlayCountConstraint c) {
    final w = _windowLabel(c.window);
    if (c.maxCount == 1) return loc.constraintPlayCountOnce(w);
    return loc.constraintPlayCountTimes(c.maxCount, w);
  }

  String _describePlayDuration(PlayDurationConstraint c) {
    return loc.constraintPlayDuration(c.maxMinutes, _windowLabel(c.window));
  }

  String _describeFolderItemCount(FolderItemCountConstraint c) {
    return loc.constraintFolderItemCount(c.maxItems, _windowLabel(c.window));
  }

  String _describeDayOfWeek(DayOfWeekConstraint c) {
    final sorted = [...c.allowedDays]..sort();
    if (sorted.length == 5 &&
        sorted.first == 1 &&
        sorted.last == 5 &&
        sorted.every((d) => d <= 5)) {
      return loc.constraintDayOfWeekWeekdaysOnly;
    }
    if (sorted.length == 2 && sorted.first == 6 && sorted.last == 7) {
      return loc.constraintDayOfWeekWeekendOnly;
    }
    final abbr = [
      loc.dayAbbrMon,
      loc.dayAbbrTue,
      loc.dayAbbrWed,
      loc.dayAbbrThu,
      loc.dayAbbrFri,
      loc.dayAbbrSat,
      loc.dayAbbrSun,
    ];
    return loc.constraintDayOfWeekList(
      sorted.map((d) => abbr[d - 1]).join(', '),
    );
  }

  String _describeDateRange(DateRangeConstraint c) {
    if (c.fromDate != null && c.toDate != null) {
      return loc.constraintDateRangeFromTo(
        _fmtDate(c.fromDate!),
        _fmtDate(c.toDate!),
      );
    }
    if (c.fromDate != null) return loc.constraintDateRangeFrom(_fmtDate(c.fromDate!));
    if (c.toDate != null) return loc.constraintDateRangeTo(_fmtDate(c.toDate!));
    return '';
  }

  String _windowLabel(TimeWindow w) {
    switch (w.type) {
      case TimeWindowType.perDay:
        return loc.windowPerDay;
      case TimeWindowType.perWeek:
        return loc.windowPerWeek;
      case TimeWindowType.perMonth:
        return loc.windowPerMonth;
      case TimeWindowType.sinceDate:
        return loc.windowSinceDate(_fmtDate(w.sinceDate!));
      case TimeWindowType.rollingHours:
        return loc.windowRollingHours(w.rollingHours!);
    }
  }

  String _fmtDate(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return DateFormat.yMd(loc.localeName).format(dt);
  }
}
