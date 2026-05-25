import 'package:intl/intl.dart';

import '../l10n/shared_l10n.dart';
import '../models/datatypes.dart';
import 'hearing_constraint.dart';
import 'hearing_stats.dart';

// ── Result types ──────────────────────────────────────────────────────────────

enum ConstraintStatus { allowed, warning, blocked }

class EvaluationResult {
  final ConstraintStatus status;

  /// Short localized reason shown to the child or in the AppBar tooltip.
  /// Null when status == allowed, or when the caller did not provide a
  /// [SharedL10n] to the evaluator.
  final String? humanReadableReason;

  /// How long until the blocking constraint resets (for the countdown icon).
  /// Null when not computable (e.g. DayOfWeek, DateRange with no obvious reset).
  final Duration? resetsIn;

  const EvaluationResult({
    required this.status,
    this.humanReadableReason,
    this.resetsIn,
  });

  static const EvaluationResult allowed =
      EvaluationResult(status: ConstraintStatus.allowed);
}

/// Lazy stats accessor — returns the [HearingStats] for [itemId] or `null`.
///
/// Hot-path callers (the directory grid, the player page, the allowance
/// indicator) build one of these once per UI build and pass it into the
/// evaluator wrappers instead of pre-materialising a full
/// `Map<String, HearingStats?>` per evaluation. The evaluator only touches
/// the item itself and (for folder constraints) the holder's direct
/// children, so materialising the full map per call was pure waste.
typedef StatsLookup = HearingStats? Function(String itemId);

// ── Evaluator ─────────────────────────────────────────────────────────────────

/// Purely synchronous constraint evaluator. All data is provided by the caller;
/// no I/O is performed.
class ConstraintEvaluator {
  const ConstraintEvaluator();

  /// Evaluate a single [constraint] node for [itemId].
  ///
  /// [stats] is the stats document for the item (`null` = no history yet →
  /// all count/duration constraints evaluate to `allowed`, per EC-08).
  /// [allStats] is used by [FolderItemCountConstraint] to inspect child stats.
  /// [folderChildIds] is the list of direct child IDs when evaluating a folder.
  /// [now] is injected for testability; defaults to [DateTime.now()].
  EvaluationResult evaluate({
    required HearingConstraint constraint,
    required String itemId,
    required HearingStats? stats,
    Map<String, HearingStats> allStats = const {},
    List<String> folderChildIds = const [],
    DateTime? now,
    SharedL10n? loc,
  }) {
    return _eval(
      constraint,
      stats,
      allStats,
      folderChildIds,
      now ?? DateTime.now(),
      loc,
    );
  }

  /// Canonical tree-up check using **nearest-wins** semantics: walks from
  /// [item] upward through its ancestors and evaluates the constraint on the
  /// **first** (nearest) node that has one.
  ///
  /// * If the item itself has a `hearingConstraint`, only that is evaluated.
  /// * Otherwise the nearest ancestor with a constraint is used.
  /// * If no constraint exists in the entire chain → allowed.
  ///
  /// This is the ONLY method that must be used at every playback gate and in
  /// the grid view. Never call [evaluate] in isolation for playback gating
  /// (P-08).
  EvaluationResult evaluateWithAncestors({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    DateTime? now,
    SharedL10n? loc,
  }) {
    final t = now ?? DateTime.now();
    final lookup = statsLookup ?? (id) => allStats[id];

    // Walk up to the nearest node with a constraint.
    MediaBase? current = item;
    while (current != null) {
      if (current.hearingConstraint != null) {
        return _evalAtHolder(
          item: item,
          holder: current,
          allDocuments: allDocuments,
          lookup: lookup,
          now: t,
          loc: loc,
        );
      }
      current = current.parent != null ? allDocuments[current.parent] : null;
    }
    return EvaluationResult.allowed;
  }

  /// Variant that takes a pre-resolved [holder] so callers iterating many
  /// items in the same folder can compute the holder once and reuse the
  /// result across siblings. Behaves identically to
  /// [evaluateWithAncestors] when [holder] is the same node the walk would
  /// have found.
  EvaluationResult evaluateAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    DateTime? now,
    SharedL10n? loc,
  }) {
    return _evalAtHolder(
      item: item,
      holder: holder,
      allDocuments: allDocuments,
      lookup: lookup,
      now: now ?? DateTime.now(),
      loc: loc,
    );
  }

  EvaluationResult _evalAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    required DateTime now,
    SharedL10n? loc,
  }) {
    final children = allDocuments.values
        .where((d) => d.parent == holder.id)
        .map((d) => d.id!)
        .toList();
    final childStats = <String, HearingStats>{};
    for (final id in children) {
      final s = lookup(id);
      if (s != null) childStats[id] = s;
    }
    return _eval(
      holder.hearingConstraint!,
      _effectiveStatsLookup(item, holder, children, lookup),
      childStats,
      children,
      now,
      loc,
    );
  }

  /// Finds the nearest ancestor (or the item itself) that carries a
  /// [hearingConstraint]. Returns `null` when no constraint exists in the
  /// chain.
  ///
  /// Useful for companion UI to show "inherited from <folder>" indicators.
  static MediaBase? findNearestConstraintHolder({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
  }) {
    MediaBase? current = item;
    while (current != null) {
      if (current.hearingConstraint != null) return current;
      current = current.parent != null ? allDocuments[current.parent] : null;
    }
    return null;
  }

  // ── Stats resolution ────────────────────────────────────────────────────────

  /// Returns the [HearingStats] to use when evaluating [constraintHolder]'s
  /// constraint against [item].
  ///
  /// * **Leaf holder** (no children — typically a media item that holds its
  ///   own constraint): return the item's own stats. This is the per-item
  ///   case where the limit applies to playbacks of that single item.
  /// * **Folder holder** (has direct children): aggregate play events across
  ///   all direct children so the constraint applies as a shared pool. This
  ///   covers two cases that look the same to the evaluator:
  ///   - constraint inherited from an ancestor folder while evaluating a
  ///     child item (nearest-wins walk landed on the folder);
  ///   - constraint held directly by a folder being evaluated as the "item"
  ///     itself (e.g. the app-bar indicator while the kid is browsing
  ///     inside that folder). Without aggregating here the folder's own
  ///     stats would be `null` and the constraint would silently report
  ///     "allowed" no matter how much was played.
  HearingStats? _effectiveStatsLookup(
    MediaBase item,
    MediaBase constraintHolder,
    List<String> holderChildren,
    StatsLookup lookup,
  ) {
    if (holderChildren.isEmpty) {
      return lookup(item.id!);
    }
    final allChildEvents = <PlayEvent>[];
    for (final id in holderChildren) {
      final s = lookup(id);
      if (s != null) allChildEvents.addAll(s.playEvents);
    }
    return allChildEvents.isEmpty
        ? null
        : HearingStats(
            itemId: constraintHolder.id!, playEvents: allChildEvents);
  }

  // ── Dispatch ────────────────────────────────────────────────────────────────

  EvaluationResult _eval(
    HearingConstraint constraint,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    SharedL10n? loc,
  ) {
    if (constraint is LogicalAndConstraint) {
      return _evalAnd(constraint, stats, allStats, folderChildIds, now, loc);
    }
    if (constraint is LogicalOrConstraint) {
      return _evalOr(constraint, stats, allStats, folderChildIds, now, loc);
    }
    if (constraint is LogicalNotConstraint) {
      return _evalNot(constraint, stats, allStats, folderChildIds, now, loc);
    }
    if (constraint is PlayCountConstraint) {
      return _evalPlayCount(constraint, stats, now, loc);
    }
    if (constraint is PlayDurationConstraint) {
      return _evalPlayDuration(constraint, stats, now, loc);
    }
    if (constraint is FolderItemCountConstraint) {
      return _evalFolderItemCount(constraint, allStats, folderChildIds, now, loc);
    }
    if (constraint is TimeOfDayConstraint) {
      return _evalTimeOfDay(constraint, now, loc);
    }
    if (constraint is DayOfWeekConstraint) {
      return _evalDayOfWeek(constraint, now, loc);
    }
    if (constraint is DateRangeConstraint) {
      return _evalDateRange(constraint, now, loc);
    }
    // NFR-04: Unknown constraint type → fail-open (permissive unknown).
    return EvaluationResult.allowed;
  }

  // ── Logical operators ────────────────────────────────────────────────────────

  EvaluationResult _evalAnd(
    LogicalAndConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    SharedL10n? loc,
  ) {
    EvaluationResult worst = EvaluationResult.allowed;
    for (final node in c.nodes) {
      final r = _eval(node, stats, allStats, folderChildIds, now, loc);
      if (r.status.index > worst.status.index) {
        worst = r;
        if (worst.status == ConstraintStatus.blocked) return worst;
      }
    }
    return worst;
  }

  EvaluationResult _evalOr(
    LogicalOrConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    SharedL10n? loc,
  ) {
    if (c.nodes.isEmpty) return EvaluationResult.allowed;
    EvaluationResult best = EvaluationResult(
      status: ConstraintStatus.blocked,
      humanReadableReason: loc?.reasonNoAccess,
    );
    for (final node in c.nodes) {
      final r = _eval(node, stats, allStats, folderChildIds, now, loc);
      if (r.status.index < best.status.index) {
        best = r;
        if (best.status == ConstraintStatus.allowed) return best;
      }
    }
    return best;
  }

  EvaluationResult _evalNot(
    LogicalNotConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    SharedL10n? loc,
  ) {
    final inner = _eval(c.node, stats, allStats, folderChildIds, now, loc);
    switch (inner.status) {
      case ConstraintStatus.allowed:
        return EvaluationResult(
          status: ConstraintStatus.blocked,
          humanReadableReason: loc?.reasonLocked,
        );
      case ConstraintStatus.blocked:
        return EvaluationResult.allowed;
      case ConstraintStatus.warning:
        // Near inversion: warning stays warning (still passing but close).
        return inner;
    }
  }

  // ── PlayCountConstraint ──────────────────────────────────────────────────────

  EvaluationResult _evalPlayCount(
    PlayCountConstraint c,
    HearingStats? stats,
    DateTime now,
    SharedL10n? loc,
  ) {
    // EC-08: null stats → no history yet → allowed.
    if (stats == null) return EvaluationResult.allowed;

    final events = _eventsInWindow(stats.playEvents, c.window, now);
    // Sum fractional play counts: each event contributes its playCountFraction
    // so that a 10% listen counts as 0.1 rather than 1.
    final count =
        events.fold<double>(0.0, (sum, e) => sum + e.playCountFraction);

    if (count >= c.maxCount) {
      return EvaluationResult(
        status: ConstraintStatus.blocked,
        humanReadableReason:
            loc?.reasonMaxPlaysReached(c.maxCount, _windowLabel(c.window, loc)),
        resetsIn: _resetsIn(c.window, events, now),
      );
    }
    // Warning threshold: less than one full listen remaining.
    if (c.maxCount > 0 && count >= c.maxCount - 1) {
      return EvaluationResult(
        status: ConstraintStatus.warning,
        humanReadableReason: loc?.reasonOnePlayLeft,
        resetsIn: _resetsIn(c.window, events, now),
      );
    }
    return EvaluationResult.allowed;
  }

  // ── PlayDurationConstraint ───────────────────────────────────────────────────

  EvaluationResult _evalPlayDuration(
    PlayDurationConstraint c,
    HearingStats? stats,
    DateTime now,
    SharedL10n? loc,
  ) {
    if (stats == null) return EvaluationResult.allowed;

    final events = _eventsInWindow(stats.playEvents, c.window, now);
    final usedMs = events.fold<int>(0, (sum, e) => sum + e.durationMs);
    final usedMinutes = usedMs / 60000.0;

    if (usedMinutes >= c.maxMinutes) {
      return EvaluationResult(
        status: ConstraintStatus.blocked,
        humanReadableReason: loc?.reasonTimeLimitReached(
          c.maxMinutes,
          _windowLabel(c.window, loc),
        ),
        resetsIn: _resetsIn(c.window, events, now),
      );
    }
    // Warning threshold: within 10 % of limit.
    if (usedMinutes >= c.maxMinutes * 0.9) {
      return EvaluationResult(
        status: ConstraintStatus.warning,
        humanReadableReason: loc?.reasonAlmostAtTimeLimit,
        resetsIn: _resetsIn(c.window, events, now),
      );
    }
    return EvaluationResult.allowed;
  }

  // ── FolderItemCountConstraint ────────────────────────────────────────────────

  EvaluationResult _evalFolderItemCount(
    FolderItemCountConstraint c,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    SharedL10n? loc,
  ) {
    int startedCount = 0;
    for (final childId in folderChildIds) {
      final childStats = allStats[childId];
      if (childStats == null) continue;
      if (_eventsInWindow(childStats.playEvents, c.window, now).isNotEmpty) {
        startedCount++;
      }
    }

    if (startedCount >= c.maxItems) {
      return EvaluationResult(
        status: ConstraintStatus.blocked,
        humanReadableReason:
            loc?.reasonMaxItemsStarted(c.maxItems, _windowLabel(c.window, loc)),
      );
    }
    if (c.maxItems > 0 && startedCount >= c.maxItems - 1) {
      return EvaluationResult(
        status: ConstraintStatus.warning,
        humanReadableReason: loc?.reasonOneItemLeft,
      );
    }
    return EvaluationResult.allowed;
  }

  // ── TimeOfDayConstraint ──────────────────────────────────────────────────────

  EvaluationResult _evalTimeOfDay(
    TimeOfDayConstraint c,
    DateTime now,
    SharedL10n? loc,
  ) {
    final from = _parseHHmm(c.fromTime);
    final to = _parseHHmm(c.toTime);
    final current = now.hour * 60 + now.minute;

    final inRange = from <= to
        ? current >= from && current < to // normal range
        : current >= from || current < to; // overnight range

    if (!inRange) {
      return EvaluationResult(
        status: ConstraintStatus.blocked,
        humanReadableReason: loc?.reasonOnlyAvailableHours(c.fromTime, c.toTime),
        resetsIn: _resetsInTimeOfDay(from, current),
      );
    }
    return EvaluationResult.allowed;
  }

  // ── DayOfWeekConstraint ──────────────────────────────────────────────────────

  EvaluationResult _evalDayOfWeek(
    DayOfWeekConstraint c,
    DateTime now,
    SharedL10n? loc,
  ) {
    if (c.allowedDays.contains(now.weekday)) {
      return EvaluationResult.allowed;
    }
    return EvaluationResult(
      status: ConstraintStatus.blocked,
      humanReadableReason: loc?.reasonNotAvailableToday,
    );
  }

  // ── DateRangeConstraint ──────────────────────────────────────────────────────

  EvaluationResult _evalDateRange(
    DateRangeConstraint c,
    DateTime now,
    SharedL10n? loc,
  ) {
    final today = DateTime(now.year, now.month, now.day);

    if (c.fromDate != null) {
      final from = DateTime.parse(c.fromDate!);
      if (today.isBefore(from)) {
        return EvaluationResult(
          status: ConstraintStatus.blocked,
          humanReadableReason: loc?.reasonAvailableFrom(_formatDate(from, loc)),
          resetsIn: from.difference(today),
        );
      }
    }

    if (c.toDate != null) {
      final to = DateTime.parse(c.toDate!);
      if (today.isAfter(to)) {
        return EvaluationResult(
          status: ConstraintStatus.blocked,
          humanReadableReason: loc?.reasonNoLongerAvailable,
        );
      }
    }

    return EvaluationResult.allowed;
  }

  // ── Remaining allowance ──────────────────────────────────────────────────────

  /// Returns the remaining playback allowance in milliseconds for a single
  /// [constraint] node, or `null` if the constraint is not time-limiting
  /// (e.g. count-based, day-of-week).
  ///
  /// Only [PlayDurationConstraint] and [TimeOfDayConstraint] produce a
  /// non-null result. Logical operators aggregate their children.
  int? remainingAllowance({
    required HearingConstraint constraint,
    required HearingStats? stats,
    Map<String, HearingStats> allStats = const {},
    List<String> folderChildIds = const [],
    DateTime? now,
  }) {
    return _allowance(
      constraint,
      stats,
      allStats,
      folderChildIds,
      now ?? DateTime.now(),
    );
  }

  /// Returns the remaining allowance as a multiple of one full item listen for
  /// a single [constraint] node (no tree-up walk).
  ///
  /// See [remainingPlayRatioWithAncestors] for the tree-up version and full
  /// documentation of return values per constraint type.
  double? remainingPlayRatio({
    required HearingConstraint constraint,
    required HearingStats? stats,
    Map<String, HearingStats> allStats = const {},
    List<String> folderChildIds = const [],
    int itemDurationMs = 0,
    DateTime? now,
  }) {
    return _allowanceRatio(
      constraint,
      stats,
      allStats,
      folderChildIds,
      now ?? DateTime.now(),
      itemDurationMs,
    );
  }

  /// Tree-up version using **nearest-wins** semantics: finds the nearest
  /// node with a constraint and returns its remaining allowance.
  /// Returns `null` if no time-limiting constraint exists in the chain.
  int? remainingAllowanceWithAncestors({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final lookup = statsLookup ?? (id) => allStats[id];

    MediaBase? current = item;
    while (current != null) {
      if (current.hearingConstraint != null) {
        return _allowanceAtHolder(
          item: item,
          holder: current,
          allDocuments: allDocuments,
          lookup: lookup,
          now: t,
        );
      }
      current = current.parent != null ? allDocuments[current.parent] : null;
    }
    return null;
  }

  /// Variant of [remainingAllowanceWithAncestors] that takes a pre-resolved
  /// constraint [holder]. See [evaluateAtHolder] for motivation.
  int? remainingAllowanceAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    DateTime? now,
  }) =>
      _allowanceAtHolder(
        item: item,
        holder: holder,
        allDocuments: allDocuments,
        lookup: lookup,
        now: now ?? DateTime.now(),
      );

  int? _allowanceAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    required DateTime now,
  }) {
    final children = allDocuments.values
        .where((d) => d.parent == holder.id)
        .map((d) => d.id!)
        .toList();
    final childStats = <String, HearingStats>{};
    for (final id in children) {
      final s = lookup(id);
      if (s != null) childStats[id] = s;
    }
    return _allowance(
      holder.hearingConstraint!,
      _effectiveStatsLookup(item, holder, children, lookup),
      childStats,
      children,
      now,
    );
  }

  /// Returns the remaining allowance as a multiple of one full item listen.
  ///
  /// Uses **nearest-wins** semantics (same as [remainingAllowanceWithAncestors]).
  ///
  /// - [PlayDurationConstraint]: `remainingMs / itemDurationMs`
  /// - [PlayCountConstraint]: `maxCount − usedCount` (fractional plays)
  /// - [FolderItemCountConstraint]: `maxItems − startedCount`
  /// - [TimeOfDayConstraint]: `remainingWindowMs / itemDurationMs`
  /// - `DayOfWeek`, `DateRange`, `NOT`: `null` (not meaningfully quantifiable)
  /// - Logical `AND`: minimum of non-null children
  /// - Logical `OR`: maximum of non-null children
  ///
  /// Returns `null` if no constraint exists in the chain or quantification is
  /// impossible. Always ≥ 0 when non-null.
  ///
  /// [itemDurationMs] is required for duration- and time-of-day-based ratios;
  /// pass 0 (or omit) for folder items — those constraints will return `null`.
  double? remainingPlayRatioWithAncestors({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    int itemDurationMs = 0,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final lookup = statsLookup ?? (id) => allStats[id];

    MediaBase? current = item;
    while (current != null) {
      if (current.hearingConstraint != null) {
        final children = allDocuments.values
            .where((d) => d.parent == current!.id)
            .map((d) => d.id!)
            .toList();
        final childStats = <String, HearingStats>{};
        for (final id in children) {
          final s = lookup(id);
          if (s != null) childStats[id] = s;
        }
        return _allowanceRatio(
          current.hearingConstraint!,
          _effectiveStatsLookup(item, current, children, lookup),
          childStats,
          children,
          t,
          itemDurationMs,
        );
      }
      current = current.parent != null ? allDocuments[current.parent] : null;
    }
    return null;
  }

  // ── Effective (per-item + global) helpers ───────────────────────────────────
  //
  // The player combines a per-item (nearest-wins) constraint with an
  // independent global hearing constraint using "most-restrictive wins"
  // semantics. These helpers exist so the combine rule lives in exactly
  // one place — every grid tile, every playback gate, the allowance timer
  // and the app-bar indicator delegate here.
  //
  // The `combine*` helpers below are exposed so callers that compute the
  // per-item side separately (e.g. a per-folder cache that bypasses the
  // ancestor walk for known holders) can still go through the canonical
  // combine rule rather than re-implementing it.

  /// Combine rule for status: most-restrictive wins (blocked > warning >
  /// allowed). `globalResult == null` returns [perItem] unchanged.
  EvaluationResult combineStatus(
    EvaluationResult perItem,
    EvaluationResult? globalResult,
  ) {
    if (globalResult == null) return perItem;
    return globalResult.status.index > perItem.status.index
        ? globalResult
        : perItem;
  }

  /// Combine rule for remaining allowance in ms: smaller wins. Either side
  /// may be `null` (no time-limiting constraint on that side); returns
  /// whichever is non-null, or `null` if both are.
  int? combineRemainingMs(int? perItemMs, int? globalMs) {
    if (perItemMs != null && globalMs != null) {
      return perItemMs < globalMs ? perItemMs : globalMs;
    }
    return perItemMs ?? globalMs;
  }

  /// Combine rule for remaining play ratio: smaller wins. Same null
  /// handling as [combineRemainingMs].
  double? combineRemainingRatio(double? perItem, double? global) {
    if (perItem != null && global != null) {
      return perItem < global ? perItem : global;
    }
    return perItem ?? global;
  }

  /// Combine rule for used ratio: larger (most-restrictive) wins. Same
  /// null handling as [combineRemainingMs].
  double? combineUsedRatio(double? perItem, double? global) {
    if (perItem != null && global != null) {
      return perItem > global ? perItem : global;
    }
    return perItem ?? global;
  }

  /// Combined evaluation: returns the worst (most-restrictive) status of the
  /// nearest-wins per-item constraint and the global constraint.
  EvaluationResult effectiveEvaluation({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    HearingConstraint? globalConstraint,
    HearingStats? globalStats,
    DateTime? now,
    SharedL10n? loc,
  }) {
    final t = now ?? DateTime.now();
    final perItem = evaluateWithAncestors(
      item: item,
      allDocuments: allDocuments,
      allStats: allStats,
      statsLookup: statsLookup,
      now: t,
      loc: loc,
    );
    if (globalConstraint == null) return perItem;
    final global = evaluate(
      constraint: globalConstraint,
      itemId: '_global',
      stats: globalStats,
      now: t,
      loc: loc,
    );
    return combineStatus(perItem, global);
  }

  /// Combined remaining allowance in ms. Returns the smaller of the per-item
  /// nearest-wins remaining allowance and the global remaining allowance.
  /// Either side may be `null` (no time-limiting constraint on that side).
  int? effectiveRemainingAllowance({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    HearingConstraint? globalConstraint,
    HearingStats? globalStats,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final perItemMs = remainingAllowanceWithAncestors(
      item: item,
      allDocuments: allDocuments,
      allStats: allStats,
      statsLookup: statsLookup,
      now: t,
    );
    final globalMs = globalConstraint == null
        ? null
        : remainingAllowance(
            constraint: globalConstraint,
            stats: globalStats,
            now: t,
          );
    return combineRemainingMs(perItemMs, globalMs);
  }

  /// Combined remaining play ratio (multiples of one item-listen). Returns
  /// the smaller of per-item and global ratios.
  double? effectiveRemainingPlayRatio({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    HearingConstraint? globalConstraint,
    HearingStats? globalStats,
    int itemDurationMs = 0,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final perItem = remainingPlayRatioWithAncestors(
      item: item,
      allDocuments: allDocuments,
      allStats: allStats,
      statsLookup: statsLookup,
      itemDurationMs: itemDurationMs,
      now: t,
    );
    final global = globalConstraint == null
        ? null
        : remainingPlayRatio(
            constraint: globalConstraint,
            stats: globalStats,
            itemDurationMs: itemDurationMs,
            now: t,
          );
    return combineRemainingRatio(perItem, global);
  }

  /// Combined used ratio (0.0 = nothing used, 1.0 = limit reached). Returns
  /// the larger (most-restrictive) of per-item and global. Returns `null`
  /// when neither side has a quantifiable constraint.
  double? effectiveUsedRatio({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    HearingConstraint? globalConstraint,
    HearingStats? globalStats,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final perItem = usedRatioWithAncestors(
      item: item,
      allDocuments: allDocuments,
      allStats: allStats,
      statsLookup: statsLookup,
      now: t,
    );
    final global = globalConstraint == null
        ? null
        : usedRatio(
            constraint: globalConstraint,
            stats: globalStats,
            now: t,
          );
    return combineUsedRatio(perItem, global);
  }

  // ── Allowance dispatch ──────────────────────────────────────────────────────

  int? _allowance(
    HearingConstraint constraint,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
  ) {
    if (constraint is LogicalAndConstraint) {
      return _allowanceAnd(constraint, stats, allStats, folderChildIds, now);
    }
    if (constraint is LogicalOrConstraint) {
      return _allowanceOr(constraint, stats, allStats, folderChildIds, now);
    }
    if (constraint is LogicalNotConstraint) {
      // NOT inverts pass/block semantics — remaining allowance is not
      // meaningful after inversion, so return null.
      return null;
    }
    if (constraint is PlayDurationConstraint) {
      return _allowanceDuration(constraint, stats, now);
    }
    if (constraint is TimeOfDayConstraint) {
      return _allowanceTimeOfDay(constraint, now);
    }
    // Count, DayOfWeek, DateRange, FolderItemCount — no time-based allowance.
    return null;
  }

  int? _allowanceAnd(
    LogicalAndConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
  ) {
    // If any child is blocked (e.g. DayOfWeek, DateRange), the whole AND is
    // blocked → return 0. Without this, non-time-based blocked constraints
    // would return null and be ignored, making the AND look like it has
    // unlimited time even when it is gated off.
    int? min;
    for (final node in c.nodes) {
      final evalResult = _eval(node, stats, allStats, folderChildIds, now, null);
      if (evalResult.status == ConstraintStatus.blocked) return 0;
      final a = _allowance(node, stats, allStats, folderChildIds, now);
      if (a != null) {
        min = min == null ? a : (a < min ? a : min);
      }
    }
    return min;
  }

  int? _allowanceOr(
    LogicalOrConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
  ) {
    // Only passing branches contribute — a blocked branch does not extend the
    // allowance. E.g. OR(AND(Mon-Fri, 1min), AND(Sat-Sun, 3min)) on Monday
    // must give 1 min, not 3 min from the already-blocked weekend branch.
    int? max;
    bool anyPassing = false;
    for (final node in c.nodes) {
      final evalResult = _eval(node, stats, allStats, folderChildIds, now, null);
      if (evalResult.status == ConstraintStatus.blocked) continue;
      anyPassing = true;
      final a = _allowance(node, stats, allStats, folderChildIds, now);
      if (a != null) {
        max = max == null ? a : (a > max ? a : max);
      }
    }
    // All branches blocked → OR itself is blocked.
    if (!anyPassing) return 0;
    return max;
  }

  int? _allowanceDuration(
    PlayDurationConstraint c,
    HearingStats? stats,
    DateTime now,
  ) {
    final usedMs = stats == null
        ? 0
        : _eventsInWindow(stats.playEvents, c.window, now)
            .fold<int>(0, (sum, e) => sum + e.durationMs);
    final limitMs = c.maxMinutes * 60000;
    final remaining = limitMs - usedMs;
    return remaining > 0 ? remaining : 0;
  }

  int? _allowanceTimeOfDay(TimeOfDayConstraint c, DateTime now) {
    final from = _parseHHmm(c.fromTime);
    final to = _parseHHmm(c.toTime);
    final current = now.hour * 60 + now.minute;

    final inRange = from <= to
        ? current >= from && current < to
        : current >= from || current < to;

    if (!inRange) return 0;

    // Minutes until the window closes.
    final minutesUntilEnd = from <= to
        ? to - current
        : current >= from
            ? (24 * 60 - current) + to
            : to - current;

    return minutesUntilEnd * 60 * 1000; // convert to ms
  }

  // ── Allowance ratio dispatch ────────────────────────────────────────────────

  double? _allowanceRatio(
    HearingConstraint constraint,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    int itemDurationMs,
  ) {
    if (constraint is LogicalAndConstraint) {
      return _allowanceRatioAnd(
          constraint, stats, allStats, folderChildIds, now, itemDurationMs);
    }
    if (constraint is LogicalOrConstraint) {
      return _allowanceRatioOr(
          constraint, stats, allStats, folderChildIds, now, itemDurationMs);
    }
    if (constraint is LogicalNotConstraint) {
      // Inversion makes "remaining ratio" semantically undefined.
      return null;
    }
    if (constraint is PlayDurationConstraint) {
      return _allowanceRatioDuration(constraint, stats, now, itemDurationMs);
    }
    if (constraint is PlayCountConstraint) {
      return _allowanceRatioCount(constraint, stats, now);
    }
    if (constraint is FolderItemCountConstraint) {
      return _allowanceRatioFolderCount(
          constraint, allStats, folderChildIds, now);
    }
    if (constraint is TimeOfDayConstraint) {
      return _allowanceRatioTimeOfDay(constraint, now, itemDurationMs);
    }
    // DayOfWeek, DateRange — not quantifiable as a ratio.
    return null;
  }

  double? _allowanceRatioDuration(
    PlayDurationConstraint c,
    HearingStats? stats,
    DateTime now,
    int itemDurationMs,
  ) {
    if (itemDurationMs <= 0) return null;
    final remainingMs = _allowanceDuration(c, stats, now) ?? 0;
    return remainingMs / itemDurationMs;
  }

  double _allowanceRatioCount(
    PlayCountConstraint c,
    HearingStats? stats,
    DateTime now,
  ) {
    final events =
        _eventsInWindow(stats?.playEvents ?? [], c.window, now);
    final used =
        events.fold<double>(0.0, (sum, e) => sum + e.playCountFraction);
    return (c.maxCount - used).clamp(0.0, double.infinity);
  }

  double _allowanceRatioFolderCount(
    FolderItemCountConstraint c,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
  ) {
    int started = 0;
    for (final childId in folderChildIds) {
      final childStats = allStats[childId];
      if (childStats == null) continue;
      if (_eventsInWindow(childStats.playEvents, c.window, now).isNotEmpty) {
        started++;
      }
    }
    final remaining = c.maxItems - started;
    return remaining < 0 ? 0.0 : remaining.toDouble();
  }

  double? _allowanceRatioTimeOfDay(
    TimeOfDayConstraint c,
    DateTime now,
    int itemDurationMs,
  ) {
    if (itemDurationMs <= 0) return null;
    final remainingMs = _allowanceTimeOfDay(c, now);
    if (remainingMs == null) return null;
    return remainingMs / itemDurationMs;
  }

  double? _allowanceRatioAnd(
    LogicalAndConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    int itemDurationMs,
  ) {
    // Mirror _allowanceAnd: if any child is blocked, the AND is blocked → 0.
    double? min;
    for (final node in c.nodes) {
      final evalResult = _eval(node, stats, allStats, folderChildIds, now, null);
      if (evalResult.status == ConstraintStatus.blocked) return 0.0;
      final r =
          _allowanceRatio(node, stats, allStats, folderChildIds, now, itemDurationMs);
      if (r != null) {
        min = min == null ? r : (r < min ? r : min);
      }
    }
    return min;
  }

  double? _allowanceRatioOr(
    LogicalOrConstraint c,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
    int itemDurationMs,
  ) {
    // Mirror _allowanceOr: only passing branches contribute.
    double? max;
    bool anyPassing = false;
    for (final node in c.nodes) {
      final evalResult = _eval(node, stats, allStats, folderChildIds, now, null);
      if (evalResult.status == ConstraintStatus.blocked) continue;
      anyPassing = true;
      final r =
          _allowanceRatio(node, stats, allStats, folderChildIds, now, itemDurationMs);
      if (r != null) {
        max = max == null ? r : (r > max ? r : max);
      }
    }
    if (!anyPassing) return 0.0;
    return max;
  }

  // ── Used ratio (for app-bar "% consumed" indicator) ──────────────────────────

  /// Returns the **used fraction** of [constraint]'s budget (0.0 = nothing
  /// used, 1.0 = limit reached, > 1.0 possible if over-used).
  ///
  /// Quantifiable constraints:
  /// - [PlayDurationConstraint]: usedMs / maxMs
  /// - [PlayCountConstraint]: fractional plays / maxCount
  /// - [FolderItemCountConstraint]: started / maxItems
  ///
  /// Non-quantifiable constraints return `null`:
  /// - [TimeOfDayConstraint], [DayOfWeekConstraint], [DateRangeConstraint]
  ///   (binary in-window/out-of-window — no meaningful "% used")
  /// - [LogicalNotConstraint] (inversion makes the metric undefined)
  ///
  /// Logical operators aggregate quantifiable children:
  /// - `AND`: maximum across children (most-restrictive drives the indicator)
  /// - `OR`: minimum across children (least-restrictive — at least one branch
  ///   has headroom)
  ///
  /// Returns `null` when no quantifiable child exists.
  double? usedRatio({
    required HearingConstraint constraint,
    required HearingStats? stats,
    Map<String, HearingStats> allStats = const {},
    List<String> folderChildIds = const [],
    DateTime? now,
  }) {
    return _usedRatio(
      constraint,
      stats,
      allStats,
      folderChildIds,
      now ?? DateTime.now(),
    );
  }

  /// Tree-up version using **nearest-wins** semantics: returns the used ratio
  /// of the nearest ancestor (or [item] itself) that has a constraint.
  /// Returns `null` when no quantifiable constraint exists in the chain.
  double? usedRatioWithAncestors({
    required MediaBase item,
    required Map<String, MediaBase> allDocuments,
    Map<String, HearingStats?> allStats = const {},
    StatsLookup? statsLookup,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final lookup = statsLookup ?? (id) => allStats[id];

    MediaBase? current = item;
    while (current != null) {
      if (current.hearingConstraint != null) {
        return _usedRatioAtHolder(
          item: item,
          holder: current,
          allDocuments: allDocuments,
          lookup: lookup,
          now: t,
        );
      }
      current = current.parent != null ? allDocuments[current.parent] : null;
    }
    return null;
  }

  /// Variant of [usedRatioWithAncestors] that takes a pre-resolved
  /// constraint [holder]. See [evaluateAtHolder] for motivation.
  double? usedRatioAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    DateTime? now,
  }) =>
      _usedRatioAtHolder(
        item: item,
        holder: holder,
        allDocuments: allDocuments,
        lookup: lookup,
        now: now ?? DateTime.now(),
      );

  double? _usedRatioAtHolder({
    required MediaBase item,
    required MediaBase holder,
    required Map<String, MediaBase> allDocuments,
    required StatsLookup lookup,
    required DateTime now,
  }) {
    final children = allDocuments.values
        .where((d) => d.parent == holder.id)
        .map((d) => d.id!)
        .toList();
    final childStats = <String, HearingStats>{};
    for (final id in children) {
      final s = lookup(id);
      if (s != null) childStats[id] = s;
    }
    return _usedRatio(
      holder.hearingConstraint!,
      _effectiveStatsLookup(item, holder, children, lookup),
      childStats,
      children,
      now,
    );
  }

  double? _usedRatio(
    HearingConstraint constraint,
    HearingStats? stats,
    Map<String, HearingStats> allStats,
    List<String> folderChildIds,
    DateTime now,
  ) {
    if (constraint is LogicalAndConstraint) {
      double? max;
      for (final node in constraint.nodes) {
        final r = _usedRatio(node, stats, allStats, folderChildIds, now);
        if (r != null) {
          max = max == null ? r : (r > max ? r : max);
        }
      }
      return max;
    }
    if (constraint is LogicalOrConstraint) {
      double? min;
      for (final node in constraint.nodes) {
        final r = _usedRatio(node, stats, allStats, folderChildIds, now);
        if (r != null) {
          min = min == null ? r : (r < min ? r : min);
        }
      }
      return min;
    }
    if (constraint is LogicalNotConstraint) return null;
    if (constraint is PlayDurationConstraint) {
      final limitMs = constraint.maxMinutes * 60000;
      if (limitMs <= 0) return null;
      final usedMs = stats == null
          ? 0
          : _eventsInWindow(stats.playEvents, constraint.window, now)
              .fold<int>(0, (sum, e) => sum + e.durationMs);
      return usedMs / limitMs;
    }
    if (constraint is PlayCountConstraint) {
      if (constraint.maxCount <= 0) return null;
      final events = stats == null
          ? const <PlayEvent>[]
          : _eventsInWindow(stats.playEvents, constraint.window, now);
      final count =
          events.fold<double>(0.0, (sum, e) => sum + e.playCountFraction);
      return count / constraint.maxCount;
    }
    if (constraint is FolderItemCountConstraint) {
      if (constraint.maxItems <= 0) return null;
      int started = 0;
      for (final childId in folderChildIds) {
        final childStats = allStats[childId];
        if (childStats == null) continue;
        if (_eventsInWindow(childStats.playEvents, constraint.window, now)
            .isNotEmpty) {
          started++;
        }
      }
      return started / constraint.maxItems;
    }
    // TimeOfDay / DayOfWeek / DateRange — not "consumed", return null.
    return null;
  }

  // ── Time-window helpers ──────────────────────────────────────────────────────

  List<PlayEvent> _eventsInWindow(
    List<PlayEvent> events,
    TimeWindow window,
    DateTime now,
  ) {
    return events.where((e) => _inWindow(e.startedAt, window, now)).toList();
  }

  bool _inWindow(String startedAt, TimeWindow window, DateTime now) {
    final t = DateTime.parse(startedAt);
    switch (window.type) {
      case TimeWindowType.perDay:
        return !t.isBefore(DateTime(now.year, now.month, now.day));
      case TimeWindowType.perWeek:
        return !t.isBefore(_isoWeekStart(now));
      case TimeWindowType.perMonth:
        return !t.isBefore(DateTime(now.year, now.month, 1));
      case TimeWindowType.sinceDate:
        return !t.isBefore(DateTime.parse(window.sinceDate!));
      case TimeWindowType.rollingHours:
        return t.isAfter(now.subtract(Duration(hours: window.rollingHours!)));
    }
  }

  DateTime _isoWeekStart(DateTime now) {
    // ISO week starts on Monday (weekday == 1).
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  // ── resetsIn helpers ─────────────────────────────────────────────────────────

  Duration? _resetsIn(
    TimeWindow window,
    List<PlayEvent> eventsInWindow,
    DateTime now,
  ) {
    switch (window.type) {
      case TimeWindowType.perDay:
        final midnight = DateTime(now.year, now.month, now.day + 1);
        return midnight.difference(now);
      case TimeWindowType.perWeek:
        final daysUntilNextMonday = 8 - now.weekday;
        final nextMonday =
            DateTime(now.year, now.month, now.day + daysUntilNextMonday);
        return nextMonday.difference(now);
      case TimeWindowType.perMonth:
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        return nextMonth.difference(now);
      case TimeWindowType.rollingHours:
        if (eventsInWindow.isEmpty) return null;
        final oldest = eventsInWindow
            .map((e) => DateTime.parse(e.startedAt))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final expiry = oldest.add(Duration(hours: window.rollingHours!));
        final remaining = expiry.difference(now);
        return remaining.isNegative ? null : remaining;
      case TimeWindowType.sinceDate:
        // Cumulative from a fixed date: never resets.
        return null;
    }
  }

  Duration _resetsInTimeOfDay(int fromMinutes, int currentMinutes) {
    // How long until fromMinutes is reached again.
    final minutesUntilFrom = currentMinutes < fromMinutes
        ? fromMinutes - currentMinutes
        : (24 * 60 - currentMinutes) + fromMinutes;
    return Duration(minutes: minutesUntilFrom);
  }

  // ── Misc helpers ─────────────────────────────────────────────────────────────

  int _parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _windowLabel(TimeWindow w, SharedL10n? loc) {
    if (loc == null) return '';
    switch (w.type) {
      case TimeWindowType.perDay:
        return loc.windowPerDay;
      case TimeWindowType.perWeek:
        return loc.windowPerWeek;
      case TimeWindowType.perMonth:
        return loc.windowPerMonth;
      case TimeWindowType.sinceDate:
        return loc.windowSinceDate(
            _formatDate(DateTime.parse(w.sinceDate!), loc));
      case TimeWindowType.rollingHours:
        return loc.windowRollingHours(w.rollingHours!);
    }
  }

  String _formatDate(DateTime dt, SharedL10n? loc) {
    return DateFormat.yMd(loc?.localeName).format(dt);
  }
}
