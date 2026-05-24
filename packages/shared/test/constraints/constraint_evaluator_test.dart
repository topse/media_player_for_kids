import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared/constraints/constraint_evaluator.dart';
import 'package:shared/constraints/hearing_constraint.dart';
import 'package:shared/constraints/hearing_stats.dart';
import 'package:shared/l10n/shared_l10n.dart';
import 'package:shared/models/datatypes.dart';

// ── Test helpers ──────────────────────────────────────────────────────────────

const _eval = ConstraintEvaluator();

/// German [SharedL10n] used so legacy assertions on `humanReadableReason`
/// keep matching their German fixtures. Populated by [setUpAll] in [main].
late SharedL10n _loc;

PlayEvent _event(String startedAt, {int durationMs = 0, double playCountFraction = 1.0}) =>
    PlayEvent(startedAt: startedAt, durationMs: durationMs, playCountFraction: playCountFraction);

HearingStats _stats(String itemId, List<PlayEvent> events) =>
    HearingStats(itemId: itemId, playEvents: events);

EvaluationResult _run(
  HearingConstraint c, {
  HearingStats? stats,
  Map<String, HearingStats> allStats = const {},
  List<String> folderChildIds = const [],
  required DateTime now,
}) =>
    _eval.evaluate(
      constraint: c,
      itemId: 'item-1',
      stats: stats,
      allStats: allStats,
      folderChildIds: folderChildIds,
      now: now,
      loc: _loc,
    );

// Fixed reference times used across tests.
final _monday = DateTime(2026, 3, 2, 10, 0); // 2026-03-02 is a Monday, 10:00
final _tuesday = DateTime(2026, 3, 3, 10, 0);
final _saturday = DateTime(2026, 3, 7, 10, 0);
final _sunday = DateTime(2026, 3, 8, 10, 0);

// ── PlayCountConstraint ───────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    _loc = await SharedL10n.delegate.load(const Locale('de'));
  });

  group('PlayCountConstraint', () {
    group('perDay', () {
      const c = PlayCountConstraint(
        maxCount: 3,
        window: TimeWindow(type: TimeWindowType.perDay),
      );

      test('allowed when no stats', () {
        expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
      });

      test('allowed when under limit', () {
        // 1 event with maxCount:3 → count(1) < maxCount-1(2), so allowed.
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
        ]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.allowed);
      });

      test('partial listens sum fractionally (regression)', () {
        // 4 events but fractions 0.077+0.110+1.0+1.0 = 2.187 < maxCount(3)
        // → allowed, not blocked. Matches the reported scenario:
        // a folder with maxCount=4 and total fraction 2.187 should still allow play.
        const c4 = PlayCountConstraint(
          maxCount: 3,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00', playCountFraction: 0.077),
          _event('2026-03-02T09:30:00', playCountFraction: 0.110),
          _event('2026-03-02T10:00:00', playCountFraction: 1.0),
          _event('2026-03-02T10:30:00', playCountFraction: 1.0),
        ]);
        // sum = 2.187; 2.187 >= maxCount-1(2) → warning, 2.187 < maxCount(3) → not blocked
        expect(_run(c4, stats: s, now: _monday).status, ConstraintStatus.warning);
      });

      test('warning when one remaining (count == maxCount - 1)', () {
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-02T09:30:00'),
        ]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.warning);
      });

      test('blocked when at limit', () {
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-02T09:30:00'),
          _event('2026-03-02T10:00:00'),
        ]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.blocked);
      });

      test('events from yesterday are outside the window', () {
        final s = _stats('item-1', [
          _event('2026-03-01T23:00:00'), // yesterday
          _event('2026-03-01T22:00:00'), // yesterday
          _event('2026-03-01T21:00:00'), // yesterday
        ]);
        // 0 events today → allowed (not even warning)
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.allowed);
      });

      test('resetsIn is time until midnight', () {
        final now = DateTime(2026, 3, 2, 22, 0); // 22:00
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-02T09:30:00'),
          _event('2026-03-02T10:00:00'),
        ]);
        final result = _run(c, stats: s, now: now);
        expect(result.status, ConstraintStatus.blocked);
        expect(result.resetsIn, const Duration(hours: 2));
      });
    });

    group('perWeek', () {
      const c = PlayCountConstraint(
        maxCount: 2,
        window: TimeWindow(type: TimeWindowType.perWeek),
      );

      test('events from last week excluded', () {
        // Last Monday: 2026-02-23
        final s = _stats('item-1', [
          _event('2026-02-23T09:00:00'),
          _event('2026-02-24T09:00:00'),
        ]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.allowed);
      });

      test('blocked when limit reached this week', () {
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'), // Monday this week
          _event('2026-03-03T09:00:00'), // Tuesday this week
        ]);
        expect(_run(c, stats: s, now: _tuesday).status, ConstraintStatus.blocked);
      });

      test('resetsIn is time until next Monday', () {
        // now = Tuesday 10:00; next Monday is 2026-03-09 00:00
        final now = DateTime(2026, 3, 3, 10, 0); // Tuesday
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-03T09:00:00'),
        ]);
        final result = _run(c, stats: s, now: now);
        expect(result.status, ConstraintStatus.blocked);
        // 6 days and 14 hours until next Monday 00:00
        final expected =
            DateTime(2026, 3, 9).difference(DateTime(2026, 3, 3, 10, 0));
        expect(result.resetsIn, expected);
      });
    });

    group('perMonth', () {
      const c = PlayCountConstraint(
        maxCount: 1,
        window: TimeWindow(type: TimeWindowType.perMonth),
      );

      test('event from last month excluded', () {
        final s = _stats('item-1', [_event('2026-02-28T10:00:00')]);
        // now is in March → allowed
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.warning);
      });

      test('blocked after single play this month', () {
        final s = _stats('item-1', [_event('2026-03-01T10:00:00')]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.blocked);
      });
    });

    group('sinceDate', () {
      test('EC-03: sinceDate in future → 0 events → allowed', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.sinceDate, sinceDate: '2026-12-01'),
        );
        // Events before sinceDate are outside the window.
        final s = _stats('item-1', [_event('2026-03-02T09:00:00')]);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.warning);
      });

      test('sinceDate: events before date not counted', () {
        const c = PlayCountConstraint(
          maxCount: 2,
          window: TimeWindow(type: TimeWindowType.sinceDate, sinceDate: '2026-03-01'),
        );
        final s = _stats('item-1', [
          _event('2026-02-28T09:00:00'), // before sinceDate
          _event('2026-03-01T09:00:00'), // on sinceDate
          _event('2026-03-02T09:00:00'), // after
        ]);
        // Only 2 events since 2026-03-01 → blocked
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.blocked);
      });

      test('sinceDate: resetsIn is null (cumulative, never resets)', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.sinceDate, sinceDate: '2026-01-01'),
        );
        final s = _stats('item-1', [_event('2026-03-02T09:00:00')]);
        final result = _run(c, stats: s, now: _monday);
        expect(result.status, ConstraintStatus.blocked);
        expect(result.resetsIn, isNull);
      });
    });

    group('rollingHours', () {
      test('EC-02: rolling window uses timestamps, not daily buckets', () {
        // maxCount: 1, rolling 24 hours. Event 25 hours ago → outside window.
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.rollingHours, rollingHours: 24),
        );
        final now = DateTime(2026, 3, 2, 10, 0);
        final s = _stats('item-1', [
          _event('2026-03-01T09:00:00'), // 25 hours ago → outside
        ]);
        // 0 events in window → warning (maxCount==1, count==0, 0 >= 0)
        expect(_run(c, stats: s, now: now).status, ConstraintStatus.warning);
      });

      test('blocked when event inside rolling window', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.rollingHours, rollingHours: 24),
        );
        final now = DateTime(2026, 3, 2, 10, 0);
        final s = _stats('item-1', [
          _event('2026-03-01T11:00:00'), // 23 hours ago → inside
        ]);
        expect(_run(c, stats: s, now: now).status, ConstraintStatus.blocked);
      });

      test('resetsIn for rollingHours is time until oldest event falls out', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.rollingHours, rollingHours: 24),
        );
        final now = DateTime(2026, 3, 2, 10, 0);
        // Event at 2026-03-01T12:00 → expires at 2026-03-02T12:00 → 2 h from now
        final s = _stats('item-1', [_event('2026-03-01T12:00:00')]);
        final result = _run(c, stats: s, now: now);
        expect(result.status, ConstraintStatus.blocked);
        expect(result.resetsIn, const Duration(hours: 2));
      });
    });

    group('warning threshold', () {
      test('warning when one remaining (maxCount-1 used)', () {
        const c = PlayCountConstraint(
          maxCount: 3,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        final s = _stats('item-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-02T09:30:00'),
        ]);
        final result = _run(c, stats: s, now: _monday);
        expect(result.status, ConstraintStatus.warning);
        expect(result.humanReadableReason, contains('1×'));
      });

      test('maxCount==1: warning when 0 plays (one play remaining)', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        final s = _stats('item-1', []);
        expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.warning);
      });
    });
  });

  // ── PlayDurationConstraint ──────────────────────────────────────────────────

  group('PlayDurationConstraint', () {
    const c = PlayDurationConstraint(
      maxMinutes: 30,
      window: TimeWindow(type: TimeWindowType.perDay),
    );

    test('EC-08: null stats → allowed', () {
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });

    test('allowed when under limit', () {
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 900000), // 15 min
      ]);
      expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.allowed);
    });

    test('warning within 10% of limit (>= 27 min)', () {
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 1680000), // 28 min
      ]);
      expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.warning);
    });

    test('blocked at limit', () {
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 1800000), // 30 min
      ]);
      expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.blocked);
    });

    test('EC-04: durationMs field used (not wall-clock)', () {
      // Two events each lasting 15 min = 30 min total → blocked.
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 900000),
        _event('2026-03-02T11:00:00', durationMs: 900000),
      ]);
      expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.blocked);
    });

    test('events outside window not summed', () {
      final s = _stats('item-1', [
        _event('2026-03-01T09:00:00', durationMs: 3600000), // yesterday
        _event('2026-03-02T09:00:00', durationMs: 900000), // today: 15 min
      ]);
      expect(_run(c, stats: s, now: _monday).status, ConstraintStatus.allowed);
    });
  });

  // ── FolderItemCountConstraint ───────────────────────────────────────────────

  group('FolderItemCountConstraint', () {
    const c = FolderItemCountConstraint(
      maxItems: 2,
      window: TimeWindow(type: TimeWindowType.perDay),
    );

    test('allowed when no children have plays today', () {
      final allStats = {
        'child-1': _stats('child-1', [_event('2026-03-01T09:00:00')]), // yesterday
        'child-2': _stats('child-2', []),
      };
      final result = _run(c,
          allStats: allStats,
          folderChildIds: ['child-1', 'child-2'],
          now: _monday);
      expect(result.status, ConstraintStatus.allowed);
    });

    test('blocked when limit of distinct items reached', () {
      final allStats = {
        'child-1': _stats('child-1', [_event('2026-03-02T09:00:00')]),
        'child-2': _stats('child-2', [_event('2026-03-02T10:00:00')]),
        'child-3': _stats('child-3', []),
      };
      final result = _run(c,
          allStats: allStats,
          folderChildIds: ['child-1', 'child-2', 'child-3'],
          now: _monday);
      expect(result.status, ConstraintStatus.blocked);
    });

    test('warning when one slot remaining', () {
      final allStats = {
        'child-1': _stats('child-1', [_event('2026-03-02T09:00:00')]),
        'child-2': _stats('child-2', []),
      };
      final result = _run(c,
          allStats: allStats,
          folderChildIds: ['child-1', 'child-2'],
          now: _monday);
      expect(result.status, ConstraintStatus.warning);
    });

    test('multiple plays for same child count as one distinct item', () {
      // Use maxItems:3 so 1 started item is below the warning threshold (2).
      const c3 = FolderItemCountConstraint(
        maxItems: 3,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final allStats = {
        'child-1': _stats('child-1', [
          _event('2026-03-02T09:00:00'),
          _event('2026-03-02T11:00:00'),
          _event('2026-03-02T13:00:00'),
        ]),
      };
      // Only 1 distinct item started → well below limit of 3 → allowed.
      final result = _run(c3,
          allStats: allStats,
          folderChildIds: ['child-1'],
          now: _monday);
      expect(result.status, ConstraintStatus.allowed);
    });

    test('children without stats do not count', () {
      // child-2 has no entry in allStats.
      final allStats = {
        'child-1': _stats('child-1', [_event('2026-03-02T09:00:00')]),
      };
      final result = _run(c,
          allStats: allStats,
          folderChildIds: ['child-1', 'child-2'],
          now: _monday);
      expect(result.status, ConstraintStatus.warning); // 1 of 2 used
    });
  });

  // ── TimeOfDayConstraint ─────────────────────────────────────────────────────

  group('TimeOfDayConstraint', () {
    test('allowed inside normal range', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 14, 0); // 14:00
      expect(_run(c, now: now).status, ConstraintStatus.allowed);
    });

    test('blocked before range start', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 7, 30); // 07:30
      expect(_run(c, now: now).status, ConstraintStatus.blocked);
    });

    test('blocked after range end', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 21, 0); // 21:00
      expect(_run(c, now: now).status, ConstraintStatus.blocked);
    });

    test('allowed inside overnight range', () {
      const c = TimeOfDayConstraint(fromTime: '22:00', toTime: '06:00');
      final now = DateTime(2026, 3, 2, 23, 0); // 23:00
      expect(_run(c, now: now).status, ConstraintStatus.allowed);
    });

    test('blocked inside daytime during overnight range', () {
      const c = TimeOfDayConstraint(fromTime: '22:00', toTime: '06:00');
      final now = DateTime(2026, 3, 2, 10, 0); // 10:00
      expect(_run(c, now: now).status, ConstraintStatus.blocked);
    });

    test('EC-05: NOT(TimeOfDay) — blocked during range, allowed outside', () {
      const c = LogicalNotConstraint(
        node: TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
      );
      final insideRange = DateTime(2026, 3, 2, 14, 0);
      final outsideRange = DateTime(2026, 3, 2, 21, 0);
      expect(_run(c, now: insideRange).status, ConstraintStatus.blocked);
      expect(_run(c, now: outsideRange).status, ConstraintStatus.allowed);
    });

    test('resetsIn is minutes until fromTime when blocked', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 6, 0); // 06:00 → 120 min until 08:00
      final result = _run(c, now: now);
      expect(result.status, ConstraintStatus.blocked);
      expect(result.resetsIn, const Duration(minutes: 120));
    });

    test('resetsIn wraps past midnight when blocked after range end', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 22, 0); // 22:00 → 600 min until 08:00
      final result = _run(c, now: now);
      expect(result.resetsIn, const Duration(minutes: 600));
    });
  });

  // ── DayOfWeekConstraint ─────────────────────────────────────────────────────

  group('DayOfWeekConstraint', () {
    const weekdays = DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]);
    const weekends = DayOfWeekConstraint(allowedDays: [6, 7]);

    test('allowed on Monday for weekday constraint', () {
      expect(_run(weekdays, now: _monday).status, ConstraintStatus.allowed);
    });

    test('blocked on Saturday for weekday constraint', () {
      expect(_run(weekdays, now: _saturday).status, ConstraintStatus.blocked);
    });

    test('allowed on Saturday for weekend constraint', () {
      expect(_run(weekends, now: _saturday).status, ConstraintStatus.allowed);
    });

    test('blocked on Tuesday for weekend constraint', () {
      expect(_run(weekends, now: _tuesday).status, ConstraintStatus.blocked);
    });

    test('reason says "Heute nicht verfügbar"', () {
      final result = _run(weekdays, now: _saturday);
      expect(result.humanReadableReason, 'Heute nicht verfügbar');
    });
  });

  // ── DateRangeConstraint ─────────────────────────────────────────────────────

  group('DateRangeConstraint', () {
    test('blocked before fromDate', () {
      const c = DateRangeConstraint(fromDate: '2026-12-01');
      expect(_run(c, now: _monday).status, ConstraintStatus.blocked);
    });

    test('EC-03 analogue: resetsIn until fromDate', () {
      const c = DateRangeConstraint(fromDate: '2026-03-05');
      final now = DateTime(2026, 3, 2, 10, 0); // 3 days before
      final result = _run(c, now: now);
      expect(result.status, ConstraintStatus.blocked);
      expect(result.resetsIn?.inDays, 3);
    });

    test('allowed between fromDate and toDate', () {
      const c = DateRangeConstraint(fromDate: '2026-01-01', toDate: '2026-12-31');
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });

    test('blocked after toDate', () {
      const c = DateRangeConstraint(toDate: '2026-01-01');
      expect(_run(c, now: _monday).status, ConstraintStatus.blocked);
    });

    test('no bounds → always allowed', () {
      const c = DateRangeConstraint();
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });

    test('humanReadableReason contains formatted date', () {
      const c = DateRangeConstraint(fromDate: '2026-12-01');
      final result = _run(c, now: _monday);
      expect(result.humanReadableReason, contains('1.12.2026'));
    });
  });

  // ── Logical operators ───────────────────────────────────────────────────────

  group('LogicalAndConstraint', () {
    test('allowed when all children allowed', () {
      const c = LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
        TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
      ]);
      final now = DateTime(2026, 3, 2, 14, 0); // Monday 14:00
      expect(_run(c, now: now).status, ConstraintStatus.allowed);
    });

    test('blocked when one child is blocked', () {
      const c = LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
        TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
      ]);
      final now = DateTime(2026, 3, 7, 14, 0); // Saturday → blocked
      expect(_run(c, now: now).status, ConstraintStatus.blocked);
    });

    test('returns worst-case (blocked > warning > allowed)', () {
      const c = LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]), // allowed on Monday
        PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perDay),
        ), // warning with 0 events and maxCount==1
      ]);
      final s = _stats('item-1', []);
      final result = _run(c, stats: s, now: _monday);
      expect(result.status, ConstraintStatus.warning);
    });

    test('empty AND is allowed', () {
      const c = LogicalAndConstraint(nodes: []);
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });
  });

  group('LogicalOrConstraint', () {
    test('allowed when one child is allowed', () {
      const c = LogicalOrConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [6, 7]), // blocked Monday
        TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'), // allowed 10:00
      ]);
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });

    test('blocked when all children blocked', () {
      const c = LogicalOrConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [6, 7]), // blocked Monday
        TimeOfDayConstraint(fromTime: '21:00', toTime: '22:00'), // blocked 10:00
      ]);
      expect(_run(c, now: _monday).status, ConstraintStatus.blocked);
    });

    test('empty OR is allowed', () {
      const c = LogicalOrConstraint(nodes: []);
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });
  });

  group('LogicalNotConstraint', () {
    test('allowed becomes blocked', () {
      const c = LogicalNotConstraint(
        node: DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
      );
      expect(_run(c, now: _monday).status, ConstraintStatus.blocked);
    });

    test('blocked becomes allowed', () {
      const c = LogicalNotConstraint(
        node: DayOfWeekConstraint(allowedDays: [6, 7]),
      );
      expect(_run(c, now: _monday).status, ConstraintStatus.allowed);
    });

    test('warning stays warning (near inversion)', () {
      const c = LogicalNotConstraint(
        node: PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      );
      final s = _stats('item-1', []);
      // inner = warning (0 of 1 plays, warning threshold) → NOT → warning
      final result = _run(c, stats: s, now: _monday);
      expect(result.status, ConstraintStatus.warning);
    });
  });

  // ── NFR-04: Unknown constraint type ─────────────────────────────────────────

  group('fail-open for unknown types', () {
    test('EC-08: null stats → allowed for count constraint', () {
      const c = PlayCountConstraint(
        maxCount: 1,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      expect(
        _eval.evaluate(constraint: c, itemId: 'x', stats: null, now: _monday)
            .status,
        ConstraintStatus.allowed,
      );
    });
  });

  // ── evaluateWithAncestors (nearest-wins) ─────────────────────────────────────

  group('evaluateWithAncestors', () {
    MediaFolder _folder(String id, {String? parent, HearingConstraint? c}) =>
        MediaFolder(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          showItemNumbering: false,
          hearingConstraint: c,
        );

    MediaItem _item(String id, {String? parent, HearingConstraint? c}) =>
        MediaItem(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          media: const [],
          repeat: false,
          shuffle: false,
          showTrackCoverRatherThanItemCover: false,
          isAudioBook: false,
          isNew: false,
          hearingConstraint: c,
        );

    test('nearest ancestor constraint blocks item without own constraint', () {
      final root = _folder(
        'root',
        c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
      );
      final item = _item('item', parent: 'root');
      final allDocs = {'root': root, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      expect(result.status, ConstraintStatus.blocked);
    });

    test('item allowed when nearest constraint passes', () {
      final root = _folder(
        'root',
        c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
      );
      final item = _item('item', parent: 'root');
      final allDocs = {'root': root, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _monday,
      );
      expect(result.status, ConstraintStatus.allowed);
    });

    test('item blocked by own constraint when folder has none', () {
      final root = _folder('root');
      final item = _item('item',
          parent: 'root',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final allDocs = {'root': root, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      expect(result.status, ConstraintStatus.blocked);
    });

    test('grandparent constraint inherited when parent/item have none', () {
      final grandparent = _folder('gp',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final parent = _folder('parent', parent: 'gp');
      final item = _item('item', parent: 'parent');
      final allDocs = {'gp': grandparent, 'parent': parent, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      expect(result.status, ConstraintStatus.blocked);
    });

    test('item with no constraints at any level → allowed', () {
      final root = _folder('root');
      final item = _item('item', parent: 'root');
      final allDocs = {'root': root, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      expect(result.status, ConstraintStatus.allowed);
    });

    test('nearest-wins: item own constraint overrides folder constraint', () {
      // Folder blocks on weekends, but item allows all days.
      // With nearest-wins, item's own constraint is evaluated → allowed.
      final folder = _folder('f',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final item = _item('item',
          parent: 'f',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5, 6, 7]));
      final allDocs = <String, MediaBase>{'f': folder, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      // Item allows Saturday even though folder would block it.
      expect(result.status, ConstraintStatus.allowed);
    });

    test('nearest-wins: parent constraint stops walk — grandparent ignored', () {
      // Grandparent blocks weekends, parent allows all days, item has no constraint.
      // Nearest is parent → allowed.
      final grandparent = _folder('gp',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final parent = _folder('p',
          parent: 'gp',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5, 6, 7]));
      final item = _item('item', parent: 'p');
      final allDocs = <String, MediaBase>{
        'gp': grandparent,
        'p': parent,
        'item': item,
      };
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      // Parent allows Saturday; grandparent's restriction is never checked.
      expect(result.status, ConstraintStatus.allowed);
    });

    test('nearest-wins: item constraint used even when ancestor would allow', () {
      // Folder has no constraint (or allows all), item blocks weekends.
      // Item's own constraint is nearest → blocked on Saturday.
      final folder = _folder('f');
      final item = _item('item',
          parent: 'f',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final allDocs = <String, MediaBase>{'f': folder, 'item': item};
      final result = _eval.evaluateWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _saturday,
      );
      expect(result.status, ConstraintStatus.blocked);
    });

    test(
        'inherited PlayCountConstraint aggregates all folder children '
        '(regression: folder-level pool, not per-item limit)', () {
      // When a folder has a PlayCountConstraint and a child inherits it via
      // nearest-wins, plays from ALL direct children are pooled. After 2 total
      // plays from any child, all siblings are also blocked.
      const constraint = PlayCountConstraint(
        maxCount: 2,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final folder = _folder('folder', c: constraint);
      final item1 = _item('item1', parent: 'folder');
      final item2 = _item('item2', parent: 'folder');
      final allDocs = <String, MediaBase>{
        'folder': folder,
        'item1': item1,
        'item2': item2,
      };

      // item1 has been played twice — folder pool is exhausted.
      final allStats = <String, HearingStats?>{
        'folder': null,
        'item1': _stats('item1', [
          _event('2026-03-03T09:00:00'),
          _event('2026-03-03T09:30:00'),
        ]),
        'item2': null,
      };

      // item1 itself must be blocked.
      expect(
        _eval
            .evaluateWithAncestors(
              item: item1,
              allDocuments: allDocs,
              allStats: allStats,
              now: _tuesday,
            )
            .status,
        ConstraintStatus.blocked,
        reason: 'item1 reached the limit',
      );

      // item2 (never played) must also be blocked because the folder pool is full.
      expect(
        _eval
            .evaluateWithAncestors(
              item: item2,
              allDocuments: allDocs,
              allStats: allStats,
              now: _tuesday,
            )
            .status,
        ConstraintStatus.blocked,
        reason: 'sibling item2 must be blocked when folder pool is exhausted',
      );
    });

    test(
        'folder with own constraint evaluated as the item aggregates its '
        'children (regression: indicator while browsing inside the folder)', () {
      // When the kid is browsing inside a folder F that holds its own
      // constraint, the app-bar indicator passes F itself as the "item".
      // Without aggregation, F's own (null) stats would make the constraint
      // silently report allowed regardless of how much was played.
      const constraint = PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final folder = _folder('folder', c: constraint);
      final item1 = _item('item1', parent: 'folder');
      final item2 = _item('item2', parent: 'folder');
      final allDocs = <String, MediaBase>{
        'folder': folder,
        'item1': item1,
        'item2': item2,
      };
      // Children have between them played for the full 30 min today.
      final allStats = <String, HearingStats?>{
        'folder': null,
        'item1': _stats('item1', [
          _event('2026-03-03T09:00:00', durationMs: 20 * 60 * 1000),
        ]),
        'item2': _stats('item2', [
          _event('2026-03-03T09:30:00', durationMs: 10 * 60 * 1000),
        ]),
      };

      final result = _eval.evaluateWithAncestors(
        item: folder,
        allDocuments: allDocs,
        allStats: allStats,
        now: _tuesday,
      );
      expect(
        result.status,
        ConstraintStatus.blocked,
        reason:
            'folder constraint must aggregate children when folder is the item',
      );

      // And the used-ratio path (driven by the indicator) must report 1.0.
      final ratio = _eval.usedRatioWithAncestors(
        item: folder,
        allDocuments: allDocs,
        allStats: allStats,
        now: _tuesday,
      );
      expect(ratio, 1.0);
    });
  });

  // ── remainingAllowance ──────────────────────────────────────────────────────

  group('remainingAllowance', () {
    test('PlayDurationConstraint: full allowance when no stats', () {
      const c = PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 30 * 60 * 1000); // 30 min in ms
    });

    test('PlayDurationConstraint: partial allowance with used time', () {
      const c = PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 600000), // 10 min used
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: s,
        now: _monday,
      );
      expect(result, 20 * 60 * 1000); // 20 min remaining
    });

    test('PlayDurationConstraint: zero when at limit', () {
      const c = PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final s = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 1800000), // 30 min
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: s,
        now: _monday,
      );
      expect(result, 0);
    });

    test('PlayDurationConstraint: events outside window not counted', () {
      const c = PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final s = _stats('item-1', [
        _event('2026-03-01T09:00:00', durationMs: 1800000), // yesterday
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: s,
        now: _monday,
      );
      expect(result, 30 * 60 * 1000); // full allowance
    });

    test('TimeOfDayConstraint: ms until window closes', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 18, 0); // 18:00 → 2h until 20:00
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: now,
      );
      expect(result, 2 * 60 * 60 * 1000); // 2 hours in ms
    });

    test('TimeOfDayConstraint: zero when outside window', () {
      const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
      final now = DateTime(2026, 3, 2, 21, 0); // 21:00 → outside
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: now,
      );
      expect(result, 0);
    });

    test('TimeOfDayConstraint: overnight range', () {
      const c = TimeOfDayConstraint(fromTime: '22:00', toTime: '06:00');
      final now = DateTime(2026, 3, 2, 23, 0); // 23:00 → 7h until 06:00
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: now,
      );
      expect(result, 7 * 60 * 60 * 1000);
    });

    test('PlayCountConstraint: returns null (not time-limiting)', () {
      const c = PlayCountConstraint(
        maxCount: 3,
        window: TimeWindow(type: TimeWindowType.perDay),
      );
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, isNull);
    });

    test('DayOfWeekConstraint: returns null (not time-limiting)', () {
      const c = DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, isNull);
    });

    test('AND: returns minimum of children', () {
      const c = LogicalAndConstraint(nodes: [
        PlayDurationConstraint(
          maxMinutes: 30,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
        TimeOfDayConstraint(fromTime: '08:00', toTime: '11:00'),
      ]);
      // At 10:00: duration allowance = 30min (1800000ms),
      // time-of-day allowance = 1h (3600000ms). AND → min = 1800000.
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday, // 10:00
      );
      expect(result, 30 * 60 * 1000);
    });

    test('OR: returns maximum of children', () {
      const c = LogicalOrConstraint(nodes: [
        PlayDurationConstraint(
          maxMinutes: 10,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
        PlayDurationConstraint(
          maxMinutes: 30,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]);
      // OR → max of the two = 30 min.
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 30 * 60 * 1000);
    });

    test('AND with non-time constraint: ignores null, returns time-based', () {
      const c = LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
        PlayDurationConstraint(
          maxMinutes: 15,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 15 * 60 * 1000);
    });

    test('AND: returns 0 when non-time child is blocked (DayOfWeek)', () {
      // AND(Sat-Sun, 3 min/day) on a Monday — DayOfWeek blocks the branch.
      // Even though PlayDuration has 3 min remaining, AND must return 0.
      const c = LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [6, 7]),
        PlayDurationConstraint(
          maxMinutes: 3,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 0);
    });

    test('OR: uses only passing branches — OR(AND(Mon-Fri,1min), AND(Sat-Sun,3min)) on Monday', () {
      // Regression test: previously OR returned max(60000, 180000)=180000 because
      // _allowanceAnd ignored the blocked DayOfWeek child and returned 180000 for
      // the weekend branch. The correct result is 60000ms (weekday branch only).
      const c = LogicalOrConstraint(nodes: [
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          PlayDurationConstraint(
            maxMinutes: 1,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [6, 7]),
          PlayDurationConstraint(
            maxMinutes: 3,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 1 * 60 * 1000); // 1 min, not 3 min
    });

    test('OR: returns 0 when all branches blocked', () {
      // Monday, 1 min already used → weekday branch blocked.
      // Weekend branch also blocked (wrong day). OR → 0.
      const c = LogicalOrConstraint(nodes: [
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          PlayDurationConstraint(
            maxMinutes: 1,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [6, 7]),
          PlayDurationConstraint(
            maxMinutes: 3,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
      ]);
      final stats = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 60000), // 1 min used
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: stats,
        now: _monday,
      );
      expect(result, 0);
    });

    test('OR: on Saturday uses weekend branch (3 min)', () {
      const c = LogicalOrConstraint(nodes: [
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          PlayDurationConstraint(
            maxMinutes: 1,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [6, 7]),
          PlayDurationConstraint(
            maxMinutes: 3,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
      ]);
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _saturday,
      );
      expect(result, 3 * 60 * 1000); // 3 min on Saturday
    });
  });

  // ── remainingAllowanceWithAncestors (nearest-wins) ──────────────────────────

  group('remainingAllowanceWithAncestors', () {
    MediaFolder _folder(String id, {String? parent, HearingConstraint? c}) =>
        MediaFolder(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          showItemNumbering: false,
          hearingConstraint: c,
        );

    MediaItem _item(String id, {String? parent, HearingConstraint? c}) =>
        MediaItem(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          media: const [],
          repeat: false,
          shuffle: false,
          showTrackCoverRatherThanItemCover: false,
          isAudioBook: false,
          isNew: false,
          hearingConstraint: c,
        );

    test('nearest-wins: item own constraint used, folder ignored', () {
      // Folder: 60 min/day. Item: 15 min/day.
      // Nearest is item → 15 min (folder's 60 min is not checked).
      final folder = _folder('f',
          c: const PlayDurationConstraint(
            maxMinutes: 60,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final item = _item('i',
          parent: 'f',
          c: const PlayDurationConstraint(
            maxMinutes: 15,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final result = _eval.remainingAllowanceWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _monday,
      );
      expect(result, 15 * 60 * 1000);
    });

    test('nearest-wins: item constraint wins even when larger than folder', () {
      // Folder: 15 min/day. Item: 60 min/day.
      // Old semantics would return min(15, 60) = 15.
      // Nearest-wins: item is nearest → 60 min.
      final folder = _folder('f',
          c: const PlayDurationConstraint(
            maxMinutes: 15,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final item = _item('i',
          parent: 'f',
          c: const PlayDurationConstraint(
            maxMinutes: 60,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final result = _eval.remainingAllowanceWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _monday,
      );
      expect(result, 60 * 60 * 1000);
    });

    test('returns null when nearest constraint is not time-limiting', () {
      final folder = _folder('f',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final item = _item('i', parent: 'f');
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final result = _eval.remainingAllowanceWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _monday,
      );
      expect(result, isNull);
    });

    test('folder duration constraint inherited by child item aggregates children',
        () {
      // Play events are stored per item ID. When a child inherits a
      // PlayDurationConstraint from its folder, all direct-child events are
      // aggregated so the limit applies at the folder level.
      final folder = _folder('f',
          c: const PlayDurationConstraint(
            maxMinutes: 30,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final item = _item('i', parent: 'f');
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final allStats = <String, HearingStats?>{
        'f': null,
        'i': _stats('i', [
          _event('2026-03-02T09:00:00', durationMs: 600000),
        ]),
      };
      final result = _eval.remainingAllowanceWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: allStats,
        now: _monday,
      );
      expect(result, 20 * 60 * 1000); // 20 min remaining
    });

    test('no constraint in chain → null', () {
      final folder = _folder('f');
      final item = _item('i', parent: 'f');
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final result = _eval.remainingAllowanceWithAncestors(
        item: item,
        allDocuments: allDocs,
        allStats: {},
        now: _monday,
      );
      expect(result, isNull);
    });
  });

  // ── Complex real-world constraint patterns ─────────────────────────────────

  group('Complex constraints', () {
    test('OR(AND(weekdays, 2x/day), AND(weekends, 3x/day))', () {
      // Mon-Fri: max 2 plays/day. Sat-Sun: max 3 plays/day.
      const c = LogicalOrConstraint(nodes: [
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          PlayCountConstraint(
            maxCount: 2,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [6, 7]),
          PlayCountConstraint(
            maxCount: 3,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
      ]);

      // Monday with 1 play → allowed (weekday branch: 1 of 2, warning)
      // Weekend branch blocked (wrong day). OR takes best → warning.
      final monS1 = _stats('item-1', [_event('2026-03-02T09:00:00')]);
      expect(_run(c, stats: monS1, now: _monday).status,
          ConstraintStatus.warning);

      // Monday with 2 plays → blocked on weekday branch.
      // Weekend branch also blocked (wrong day). OR → blocked.
      final monS2 = _stats('item-1', [
        _event('2026-03-02T09:00:00'),
        _event('2026-03-02T10:00:00'),
      ]);
      expect(_run(c, stats: monS2, now: _monday).status,
          ConstraintStatus.blocked);

      // Saturday with 2 plays → weekday branch blocked (wrong day).
      // Weekend branch: 2 of 3 → warning. OR takes best → warning.
      final satS2 = _stats('item-1', [
        _event('2026-03-07T09:00:00'),
        _event('2026-03-07T10:00:00'),
      ]);
      expect(_run(c, stats: satS2, now: _saturday).status,
          ConstraintStatus.warning);

      // Saturday with 3 plays → both branches blocked → blocked.
      final satS3 = _stats('item-1', [
        _event('2026-03-07T09:00:00'),
        _event('2026-03-07T10:00:00'),
        _event('2026-03-07T11:00:00'),
      ]);
      expect(_run(c, stats: satS3, now: _saturday).status,
          ConstraintStatus.blocked);

      // Saturday with 0 plays → weekday blocked. Weekend: 0 of 3 → allowed.
      // (maxCount==3, 0 < 2 → allowed, not even warning)
      expect(_run(c, stats: null, now: _saturday).status,
          ConstraintStatus.allowed);
    });

    test('AND(TimeOfDay, PlayDuration) — both must pass', () {
      // Allowed 08:00-20:00 AND max 30 min/day.
      const c = LogicalAndConstraint(nodes: [
        TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
        PlayDurationConstraint(
          maxMinutes: 30,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]);

      // 10:00 with 20 min used → both pass → allowed.
      final s1 = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 1200000),
      ]);
      expect(_run(c, stats: s1, now: _monday).status, ConstraintStatus.allowed);

      // 10:00 with 30 min used → TimeOfDay OK, duration blocked → blocked.
      final s2 = _stats('item-1', [
        _event('2026-03-02T09:00:00', durationMs: 1800000),
      ]);
      expect(_run(c, stats: s2, now: _monday).status, ConstraintStatus.blocked);

      // 21:00 with 0 min → TimeOfDay blocked → blocked.
      final night = DateTime(2026, 3, 2, 21, 0);
      expect(_run(c, now: night).status, ConstraintStatus.blocked);
    });

    test('remaining allowance for AND(TimeOfDay, PlayDuration) = minimum', () {
      const c = LogicalAndConstraint(nodes: [
        TimeOfDayConstraint(fromTime: '08:00', toTime: '10:30'),
        PlayDurationConstraint(
          maxMinutes: 60,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]);
      // At 10:00: TOD = 30 min remaining (1800000ms),
      // Duration = 60 min (3600000ms). AND → min = 1800000ms.
      final result = _eval.remainingAllowance(
        constraint: c,
        stats: null,
        now: _monday,
      );
      expect(result, 30 * 60 * 1000);
    });
  });

  // ── findNearestConstraintHolder ────────────────────────────────────────────

  group('findNearestConstraintHolder', () {
    MediaFolder _folder(String id, {String? parent, HearingConstraint? c}) =>
        MediaFolder(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          showItemNumbering: false,
          hearingConstraint: c,
        );

    MediaItem _item(String id, {String? parent, HearingConstraint? c}) =>
        MediaItem(
          id: id,
          parent: parent,
          sortHint: 0,
          name: id,
          media: const [],
          repeat: false,
          shuffle: false,
          showTrackCoverRatherThanItemCover: false,
          isAudioBook: false,
          isNew: false,
          hearingConstraint: c,
        );

    test('returns item itself when it has a constraint', () {
      final item = _item('i',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final allDocs = <String, MediaBase>{'i': item};
      final holder = ConstraintEvaluator.findNearestConstraintHolder(
        item: item,
        allDocuments: allDocs,
      );
      expect(holder, same(item));
    });

    test('returns nearest ancestor with constraint', () {
      final folder = _folder('f',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final item = _item('i', parent: 'f');
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final holder = ConstraintEvaluator.findNearestConstraintHolder(
        item: item,
        allDocuments: allDocs,
      );
      expect(holder, same(folder));
    });

    test('skips parent without constraint, finds grandparent', () {
      final gp = _folder('gp',
          c: const DayOfWeekConstraint(allowedDays: [6, 7]));
      final parent = _folder('p', parent: 'gp');
      final item = _item('i', parent: 'p');
      final allDocs = <String, MediaBase>{'gp': gp, 'p': parent, 'i': item};
      final holder = ConstraintEvaluator.findNearestConstraintHolder(
        item: item,
        allDocuments: allDocs,
      );
      expect(holder, same(gp));
    });

    test('returns null when no constraint in chain', () {
      final folder = _folder('f');
      final item = _item('i', parent: 'f');
      final allDocs = <String, MediaBase>{'f': folder, 'i': item};
      final holder = ConstraintEvaluator.findNearestConstraintHolder(
        item: item,
        allDocuments: allDocs,
      );
      expect(holder, isNull);
    });

    test('returns parent, not grandparent, when parent has constraint', () {
      final gp = _folder('gp',
          c: const PlayCountConstraint(
            maxCount: 1,
            window: TimeWindow(type: TimeWindowType.perDay),
          ));
      final parent = _folder('p',
          parent: 'gp',
          c: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]));
      final item = _item('i', parent: 'p');
      final allDocs = <String, MediaBase>{'gp': gp, 'p': parent, 'i': item};
      final holder = ConstraintEvaluator.findNearestConstraintHolder(
        item: item,
        allDocuments: allDocs,
      );
      expect(holder, same(parent));
    });
  });
}
