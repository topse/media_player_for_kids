import 'package:shared/shared.dart';

class ConstraintTemplate {
  final String label;
  final String description;
  final String emoji;
  final HearingConstraint constraint;
  final bool folderOnly;

  const ConstraintTemplate({
    required this.label,
    required this.description,
    required this.emoji,
    required this.constraint,
    this.folderOnly = false,
  });
}

final List<ConstraintTemplate> kConstraintTemplates = [
  ConstraintTemplate(
    label: 'Dreimal am Tag',
    emoji: '3\uFE0F\u20E3',
    description: const ConstraintDescriptionGenerator().describe(
      const PlayCountConstraint(
        maxCount: 3,
        window: TimeWindow(type: TimeWindowType.perDay),
      ),
    ),
    constraint: const PlayCountConstraint(
      maxCount: 3,
      window: TimeWindow(type: TimeWindowType.perDay),
    ),
  ),
  ConstraintTemplate(
    label: 'Einmal die Woche',
    emoji: '\uD83D\uDCC5',
    description: const ConstraintDescriptionGenerator().describe(
      const PlayCountConstraint(
        maxCount: 1,
        window: TimeWindow(type: TimeWindowType.perWeek),
      ),
    ),
    constraint: const PlayCountConstraint(
      maxCount: 1,
      window: TimeWindow(type: TimeWindowType.perWeek),
    ),
  ),
  ConstraintTemplate(
    label: 'Nur tagsüber (8–20 Uhr)',
    emoji: '\u2600\uFE0F',
    description: const ConstraintDescriptionGenerator().describe(
      const TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
    ),
    constraint: const TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
  ),
  ConstraintTemplate(
    label: 'Nur Wochentage',
    emoji: '\uD83D\uDCC6',
    description: const ConstraintDescriptionGenerator().describe(
      const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
    ),
    constraint: const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
  ),
  ConstraintTemplate(
    label: 'Wochentage & tagsüber',
    emoji: '\uD83D\uDDD3\uFE0F',
    description: const ConstraintDescriptionGenerator().describe(
      const LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
        TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
      ]),
    ),
    constraint: const LogicalAndConstraint(nodes: [
      DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
      TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
    ]),
  ),
  ConstraintTemplate(
    label: 'Nur am Wochenende',
    emoji: '\uD83C\uDF89',
    description: const ConstraintDescriptionGenerator().describe(
      const DayOfWeekConstraint(allowedDays: [6, 7]),
    ),
    constraint: const DayOfWeekConstraint(allowedDays: [6, 7]),
  ),
  ConstraintTemplate(
    label: 'Max. 30 Min. pro Woche',
    emoji: '\u23F1\uFE0F',
    description: const ConstraintDescriptionGenerator().describe(
      const PlayDurationConstraint(
        maxMinutes: 30,
        window: TimeWindow(type: TimeWindowType.perWeek),
      ),
    ),
    constraint: const PlayDurationConstraint(
      maxMinutes: 30,
      window: TimeWindow(type: TimeWindowType.perWeek),
    ),
  ),
  ConstraintTemplate(
    label: '2x Mo–Fr, 3x Sa+So',
    emoji: '\uD83D\uDD00',
    description: const ConstraintDescriptionGenerator().describe(
      const LogicalOrConstraint(nodes: [
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
      ]),
    ),
    constraint: const LogicalOrConstraint(nodes: [
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
    ]),
  ),
  ConstraintTemplate(
    label: '2h Mo–Fr, 3h Sa+So',
    emoji: '\u23F0',
    description: const ConstraintDescriptionGenerator().describe(
      const LogicalOrConstraint(nodes: [
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          PlayDurationConstraint(
            maxMinutes: 120,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
        LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [6, 7]),
          PlayDurationConstraint(
            maxMinutes: 180,
            window: TimeWindow(type: TimeWindowType.perDay),
          ),
        ]),
      ]),
    ),
    constraint: const LogicalOrConstraint(nodes: [
      LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
        PlayDurationConstraint(
          maxMinutes: 120,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]),
      LogicalAndConstraint(nodes: [
        DayOfWeekConstraint(allowedDays: [6, 7]),
        PlayDurationConstraint(
          maxMinutes: 180,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ]),
    ]),
  ),
  ConstraintTemplate(
    label: 'Max. 2 verschiedene Einträge',
    emoji: '\uD83D\uDCC2',
    description: const ConstraintDescriptionGenerator().describe(
      const FolderItemCountConstraint(
        maxItems: 2,
        window: TimeWindow(type: TimeWindowType.perDay),
      ),
    ),
    folderOnly: true,
    constraint: const FolderItemCountConstraint(
      maxItems: 2,
      window: TimeWindow(type: TimeWindowType.perDay),
    ),
  ),
];
