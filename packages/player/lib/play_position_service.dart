import 'package:dart_couch_widgets/dart_couch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:logging/logging.dart';
import 'package:watch_it/watch_it.dart';

final _log = Logger('PlayPositionService');

class PlayPositionService extends ChangeNotifier {
  static const _docId = '_local/playposition';

  Map<String, dynamic> _doc = {'_id': _docId};

  PlayPositionService();

  /// Load positions from the database. Call once after DB is available.
  Future<void> load() async {
    final raw = await di<DartCouchDb>().getRaw(_docId);
    if (raw != null) {
      _doc = raw;
    }
    notifyListeners();
  }

  /// Returns the saved entry for [itemId], or null.
  Map<String, dynamic>? getEntry(String itemId) {
    final entry = _doc[itemId];
    return entry is Map<String, dynamic> ? entry : null;
  }

  /// Update position in memory and persist to DB.
  void savePosition(String itemId, {required int track, required int seconds}) {
    _doc[itemId] = <String, dynamic>{
      'position': <String, dynamic>{'track': track, 'seconds': seconds},
    };
    _notifyDeferred();
    _persist();
  }

  /// Mark an audiobook as done in memory and persist to DB.
  void saveDone(String itemId) {
    _doc[itemId] = <String, dynamic>{'done': true};
    _notifyDeferred();
    _persist();
  }

  /// Notify listeners after the current frame to avoid calling setState()
  /// while the widget tree is locked (e.g. during dispose/unmount).
  void _notifyDeferred() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _persist() async {
    try {
      final result = await di<DartCouchDb>().putRaw(_doc);
      // Update _rev from the result so subsequent writes don't conflict.
      _doc['_rev'] = result['_rev'];
    } catch (e) {
      _log.warning('Failed to persist play positions: $e');
    }
  }
}
