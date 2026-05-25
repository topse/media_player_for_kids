import 'models/datatypes.dart';
import 'constraints/global_constraints.dart';
import 'constraints/hearing_constraint.dart';
import 'constraints/hearing_stats.dart';
import 'constraints/play_log.dart';

/// Initializes all dart_mappable mappers in the shared package.
///
/// Call this once in main() before using any model serialization.
void initializeMappers() {
  MediaBaseMapper.ensureInitialized();
  MediaItemMapper.ensureInitialized();
  MediaFolderMapper.ensureInitialized();
  MediaTrackMapper.ensureInitialized();
  HearingConstraintMapper.ensureInitialized();
  HearingStatsMapper.ensureInitialized();
  PlayLogEventMapper.ensureInitialized();
  PlayLogItemMapper.ensureInitialized();
  PlayLogMapper.ensureInitialized();
  PlayLogArchiveMapper.ensureInitialized();
  PlayPositionPointMapper.ensureInitialized();
  PlayPositionItemMapper.ensureInitialized();
  PlayPositionMapper.ensureInitialized();
  DeviceIdentityMapper.ensureInitialized();
  GlobalConstraintsMapper.ensureInitialized();
}
