import 'package:flutter_test/flutter_test.dart';
import 'package:shared/constraints/constraint_description.dart';
import 'package:shared/constraints/hearing_constraint.dart';

const _gen = ConstraintDescriptionGenerator();

void main() {
  group('ConstraintDescriptionGenerator', () {
    group('PlayCountConstraint', () {
      test('maxCount == 1 perDay → "Einmal pro Tag"', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        expect(_gen.describe(c), 'Einmal pro Tag');
      });

      test('maxCount == 3 perDay → "Maximal 3× pro Tag"', () {
        const c = PlayCountConstraint(
          maxCount: 3,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        expect(_gen.describe(c), 'Maximal 3× pro Tag');
      });

      test('maxCount == 1 rollingHours 24 → "Einmal je 24 Stunden"', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.rollingHours, rollingHours: 24),
        );
        expect(_gen.describe(c), 'Einmal je 24 Stunden');
      });

      test('perWeek → "pro Woche"', () {
        const c = PlayCountConstraint(
          maxCount: 2,
          window: TimeWindow(type: TimeWindowType.perWeek),
        );
        expect(_gen.describe(c), 'Maximal 2× pro Woche');
      });

      test('perMonth → "pro Monat"', () {
        const c = PlayCountConstraint(
          maxCount: 5,
          window: TimeWindow(type: TimeWindowType.perMonth),
        );
        expect(_gen.describe(c), 'Maximal 5× pro Monat');
      });

      test('sinceDate → formatted date in label', () {
        const c = PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.sinceDate, sinceDate: '2026-12-01'),
        );
        expect(_gen.describe(c), 'Einmal seit 01.12.2026');
      });
    });

    group('PlayDurationConstraint', () {
      test('30 min perWeek → "Max. 30 Min. pro Woche"', () {
        const c = PlayDurationConstraint(
          maxMinutes: 30,
          window: TimeWindow(type: TimeWindowType.perWeek),
        );
        expect(_gen.describe(c), 'Max. 30 Min. pro Woche');
      });
    });

    group('FolderItemCountConstraint', () {
      test('2 items perDay → "Max. 2 Einträge pro Tag"', () {
        const c = FolderItemCountConstraint(
          maxItems: 2,
          window: TimeWindow(type: TimeWindowType.perDay),
        );
        expect(_gen.describe(c), 'Max. 2 verschiedene Einträge pro Tag');
      });
    });

    group('TimeOfDayConstraint', () {
      test('"Nur 08:00–20:00 Uhr"', () {
        const c = TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00');
        expect(_gen.describe(c), 'Nur 08:00–20:00 Uhr');
      });
    });

    group('DayOfWeekConstraint', () {
      test('[1,2,3,4,5] → "Nur Mo–Fr"', () {
        const c = DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]);
        expect(_gen.describe(c), 'Nur Mo–Fr');
      });

      test('[6,7] → "Nur am Wochenende"', () {
        const c = DayOfWeekConstraint(allowedDays: [6, 7]);
        expect(_gen.describe(c), 'Nur am Wochenende');
      });

      test('single day → lists abbreviation', () {
        const c = DayOfWeekConstraint(allowedDays: [3]); // Wednesday
        expect(_gen.describe(c), 'Nur Mi');
      });

      test('non-contiguous days → comma separated', () {
        const c = DayOfWeekConstraint(allowedDays: [1, 3, 5]);
        expect(_gen.describe(c), 'Nur Mo, Mi, Fr');
      });
    });

    group('DateRangeConstraint', () {
      test('fromDate only → "Ab dd.MM.yyyy"', () {
        const c = DateRangeConstraint(fromDate: '2026-12-01');
        expect(_gen.describe(c), 'Ab 01.12.2026');
      });

      test('toDate only → "Bis dd.MM.yyyy"', () {
        const c = DateRangeConstraint(toDate: '2026-12-31');
        expect(_gen.describe(c), 'Bis 31.12.2026');
      });

      test('both → "from – to"', () {
        const c = DateRangeConstraint(fromDate: '2026-12-01', toDate: '2026-12-24');
        expect(_gen.describe(c), '01.12.2026 – 24.12.2026');
      });

      test('neither → empty string', () {
        const c = DateRangeConstraint();
        expect(_gen.describe(c), '');
      });
    });

    group('Logical operators', () {
      test('AND joins with " und "', () {
        const c = LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
        ]);
        expect(_gen.describe(c), 'Nur Mo–Fr und Nur 08:00–20:00 Uhr');
      });

      test('OR joins with " oder "', () {
        const c = LogicalOrConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          DayOfWeekConstraint(allowedDays: [6, 7]),
        ]);
        expect(_gen.describe(c), 'Nur Mo–Fr oder Nur am Wochenende');
      });

      test('NOT prefixes with "Nicht: "', () {
        const c = LogicalNotConstraint(
          node: TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
        );
        expect(_gen.describe(c), 'Nicht: Nur 08:00–20:00 Uhr');
      });

      test('nested AND inside NOT', () {
        const c = LogicalNotConstraint(
          node: LogicalAndConstraint(nodes: [
            DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          ]),
        );
        expect(_gen.describe(c), 'Nicht: Nur Mo–Fr');
      });
    });
  });
}
