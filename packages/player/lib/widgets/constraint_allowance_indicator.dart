import 'package:flutter/material.dart';
import 'package:player/admin/admin_override_service.dart';
import 'package:player/hearing_stats_service.dart';
import 'package:shared/shared.dart';
import 'package:watch_it/watch_it.dart';

/// App-bar indicator showing how much of the effective hearing constraint
/// has been consumed (0 % = nothing used, 100 % = limit reached).
///
/// - When [item] is non-null (player page), shows the most-restrictive of
///   the item's nearest-wins constraint and the global constraint.
/// - When [item] is null (directory grid), shows only the global constraint.
///
/// Hides itself when the effective ratio is not quantifiable (e.g. only
/// `DayOfWeek` / `DateRange` / `TimeOfDay` constraints are active) or when
/// the `ignoreConstraints` admin override is on.
///
/// Subscribes to [HearingStatsService] so the percentage updates live as
/// playback accumulates (see refresh ticker on the service).
class ConstraintAllowanceIndicator extends StatefulWidget {
  final MediaBase? item;
  final Map<String, MediaBase>? allDocuments;

  const ConstraintAllowanceIndicator({
    super.key,
    this.item,
    this.allDocuments,
  });

  @override
  State<ConstraintAllowanceIndicator> createState() =>
      _ConstraintAllowanceIndicatorState();
}

class _ConstraintAllowanceIndicatorState
    extends State<ConstraintAllowanceIndicator> {
  @override
  void initState() {
    super.initState();
    // Main channel: external sync, record-play events, constraint changes.
    di<HearingStatsService>().addListener(_onChanged);
    // Live ticker: in-flight 5 s pulse during active playback so the % ticks
    // down even between record events. This indicator is the only consumer
    // that needs the live tick — keeping it off the main channel avoids
    // dragging the player page and directory grid into a full re-eval every
    // 5 s during playback.
    di<HearingStatsService>().liveTicker.addListener(_onChanged);
    di<AdminOverrideService>().addListener(_onChanged);
  }

  @override
  void dispose() {
    di<HearingStatsService>().liveTicker.removeListener(_onChanged);
    di<HearingStatsService>().removeListener(_onChanged);
    di<AdminOverrideService>().removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  double? _computeUsedRatio() {
    if (di<AdminOverrideService>().ignoreConstraints) return null;
    final statsService = di<HearingStatsService>();
    final globalConstraint = statsService.globalConstraint;

    const evaluator = ConstraintEvaluator();
    final item = widget.item;
    final allDocuments = widget.allDocuments;
    if (item != null && allDocuments != null) {
      return evaluator.effectiveUsedRatio(
        item: item,
        allDocuments: allDocuments,
        statsLookup: statsService.statsFor,
        globalConstraint: globalConstraint,
        globalStats: statsService.globalStats(),
      );
    }

    if (globalConstraint == null) return null;
    return evaluator.usedRatio(
      constraint: globalConstraint,
      stats: statsService.globalStats(),
    );
  }

  Color _colorFor(double ratio) {
    if (ratio >= 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.deepOrange;
    if (ratio >= 0.5) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _computeUsedRatio();
    if (ratio == null) return const SizedBox.shrink();

    final clamped = ratio.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    final color = _colorFor(ratio);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: clamped,
                strokeWidth: 4,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
