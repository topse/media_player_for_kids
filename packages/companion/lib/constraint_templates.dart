import 'package:shared/shared.dart';

class ConstraintTemplate {
  final String label;
  final String emoji;
  final HearingConstraint constraint;
  final bool folderOnly;

  const ConstraintTemplate({
    required this.label,
    required this.emoji,
    required this.constraint,
    this.folderOnly = false,
  });

  /// Localized human-readable summary of [constraint] for the current [loc].
  String description(SharedL10n loc) =>
      ConstraintDescriptionGenerator(loc).describe(constraint);
}

/// Returns the preset templates with localized labels for [loc].
///
/// Templates can't be const because their labels come from the .arb files —
/// the cost of allocating a fresh list per editor open is trivial.
List<ConstraintTemplate> constraintTemplates(SharedL10n loc) => [
      ConstraintTemplate(
        label: loc.presetThreeTimesPerDay,
        emoji: '3️⃣',
        constraint: const PlayCountConstraint(
          maxCount: 3,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ),
      ConstraintTemplate(
        label: loc.presetOnceAWeek,
        emoji: '📅',
        constraint: const PlayCountConstraint(
          maxCount: 1,
          window: TimeWindow(type: TimeWindowType.perWeek),
        ),
      ),
      ConstraintTemplate(
        label: loc.presetDaytimeOnly,
        emoji: '☀️',
        constraint:
            const TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
      ),
      ConstraintTemplate(
        label: loc.presetWeekdaysOnly,
        emoji: '📆',
        constraint:
            const DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
      ),
      ConstraintTemplate(
        label: loc.presetWeekdaysAndDaytime,
        emoji: '🗓️',
        constraint: const LogicalAndConstraint(nodes: [
          DayOfWeekConstraint(allowedDays: [1, 2, 3, 4, 5]),
          TimeOfDayConstraint(fromTime: '08:00', toTime: '20:00'),
        ]),
      ),
      ConstraintTemplate(
        label: loc.presetWeekendOnly,
        emoji: '🎉',
        constraint: const DayOfWeekConstraint(allowedDays: [6, 7]),
      ),
      ConstraintTemplate(
        label: loc.presetMax30MinPerWeek,
        emoji: '⏱️',
        constraint: const PlayDurationConstraint(
          maxMinutes: 30,
          window: TimeWindow(type: TimeWindowType.perWeek),
        ),
      ),
      ConstraintTemplate(
        label: loc.preset2xMonFri3xSatSun,
        emoji: '🔀',
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
        label: loc.preset2hMonFri3hSatSun,
        emoji: '⏰',
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
        label: loc.presetMax2DifferentItems,
        emoji: '📂',
        folderOnly: true,
        constraint: const FolderItemCountConstraint(
          maxItems: 2,
          window: TimeWindow(type: TimeWindowType.perDay),
        ),
      ),
    ];
