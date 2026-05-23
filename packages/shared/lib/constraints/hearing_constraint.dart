import 'package:dart_mappable/dart_mappable.dart';

part 'hearing_constraint.mapper.dart';

// ── Time window ───────────────────────────────────────────────────────────────

@MappableEnum()
enum TimeWindowType {
  perDay,       // calendar day, midnight to midnight local
  perWeek,      // ISO week: Monday 00:00 – Sunday 23:59 local
  perMonth,     // calendar month: 1st 00:00 – last day 23:59 local
  sinceDate,    // from a fixed ISO 8601 date-string forever forward
  rollingHours, // sliding window: last N hours ending at now
}

@MappableClass()
class TimeWindow with TimeWindowMappable {
  final TimeWindowType type;

  /// Required when type == sinceDate (ISO 8601 date string).
  @MappableField(key: 'since_date')
  final String? sinceDate;

  /// Required when type == rollingHours.
  @MappableField(key: 'rolling_hours')
  final int? rollingHours;

  const TimeWindow({
    required this.type,
    this.sinceDate,
    this.rollingHours,
  });
}

// ── Base class ────────────────────────────────────────────────────────────────

/// Sealed base class for the hearing constraint DSL.
///
/// The discriminator key is `!constraint_type`, mirroring the existing
/// `!doc_type` convention. Unknown values evaluate to `allowed` (fail-open).
@MappableClass(discriminatorKey: '!constraint_type')
abstract class HearingConstraint with HearingConstraintMappable {
  const HearingConstraint();
}

// ── Logical ───────────────────────────────────────────────────────────────────

@MappableClass(discriminatorValue: 'and')
class LogicalAndConstraint extends HearingConstraint
    with LogicalAndConstraintMappable {
  final List<HearingConstraint> nodes;
  const LogicalAndConstraint({required this.nodes});
}

@MappableClass(discriminatorValue: 'or')
class LogicalOrConstraint extends HearingConstraint
    with LogicalOrConstraintMappable {
  final List<HearingConstraint> nodes;
  const LogicalOrConstraint({required this.nodes});
}

@MappableClass(discriminatorValue: 'not')
class LogicalNotConstraint extends HearingConstraint
    with LogicalNotConstraintMappable {
  final HearingConstraint node;
  const LogicalNotConstraint({required this.node});
}

// ── Counting / duration ───────────────────────────────────────────────────────

@MappableClass(discriminatorValue: 'play_count')
class PlayCountConstraint extends HearingConstraint
    with PlayCountConstraintMappable {
  @MappableField(key: 'max_count')
  final int maxCount;
  final TimeWindow window;
  const PlayCountConstraint({
    required this.maxCount,
    required this.window,
  });
}

@MappableClass(discriminatorValue: 'play_duration')
class PlayDurationConstraint extends HearingConstraint
    with PlayDurationConstraintMappable {
  @MappableField(key: 'max_minutes')
  final int maxMinutes;
  final TimeWindow window;
  const PlayDurationConstraint({
    required this.maxMinutes,
    required this.window,
  });
}

@MappableClass(discriminatorValue: 'folder_item_count')
class FolderItemCountConstraint extends HearingConstraint
    with FolderItemCountConstraintMappable {
  @MappableField(key: 'max_items')
  final int maxItems;
  final TimeWindow window;
  const FolderItemCountConstraint({
    required this.maxItems,
    required this.window,
  });
}

// ── Schedule ──────────────────────────────────────────────────────────────────

@MappableClass(discriminatorValue: 'time_of_day')
class TimeOfDayConstraint extends HearingConstraint
    with TimeOfDayConstraintMappable {
  /// "HH:mm" 24-hour format. May be > toTime for overnight ranges.
  @MappableField(key: 'from_time')
  final String fromTime;
  @MappableField(key: 'to_time')
  final String toTime;
  const TimeOfDayConstraint({required this.fromTime, required this.toTime});
}

@MappableClass(discriminatorValue: 'day_of_week')
class DayOfWeekConstraint extends HearingConstraint
    with DayOfWeekConstraintMappable {
  /// ISO weekday numbers: 1 = Monday, 7 = Sunday.
  @MappableField(key: 'allowed_days')
  final List<int> allowedDays;
  const DayOfWeekConstraint({required this.allowedDays});
}

@MappableClass(discriminatorValue: 'date_range')
class DateRangeConstraint extends HearingConstraint
    with DateRangeConstraintMappable {
  /// ISO 8601 date string or null (= no lower bound).
  @MappableField(key: 'from_date')
  final String? fromDate;

  /// ISO 8601 date string or null (= no upper bound).
  @MappableField(key: 'to_date')
  final String? toDate;
  const DateRangeConstraint({this.fromDate, this.toDate});
}
