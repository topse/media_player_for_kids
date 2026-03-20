import 'models/datatypes.dart';

typedef MediaTraversalFilter = bool Function(MediaBase media);

/// Builds a per-document map that indicates whether a media node should show
/// the "new" marker.
///
/// - For [MediaItem], this is [MediaItem.isNew].
/// - For [MediaFolder], this is true if any descendant resolves to true.
///
/// Use [includeInTraversal] to control which nodes are considered during
/// recursion. This allows app-specific behavior:
/// - Companion can ignore date visibility by using the default (include all).
/// - Player can respect date visibility by passing
///   `(media) => media.isVisibleAt(now)`.
Map<String, bool> buildEffectiveIsNewMap(
  Map<String, MediaBase> allDocuments, {
  MediaTraversalFilter? includeInTraversal,
}) {
  final include = includeInTraversal ?? (_) => true;

  final childrenByParent = <String?, List<MediaBase>>{};
  for (final doc in allDocuments.values) {
    childrenByParent.putIfAbsent(doc.parent, () => <MediaBase>[]).add(doc);
  }

  final memo = <String, bool>{};
  final inProgress = <String>{};

  bool resolve(MediaBase media) {
    final id = media.id;
    if (id != null && memo.containsKey(id)) return memo[id]!;

    // Guard against unexpected parent loops in malformed data.
    if (id != null && inProgress.contains(id)) return false;

    if (!include(media)) {
      if (id != null) memo[id] = false;
      return false;
    }

    if (id != null) inProgress.add(id);

    bool result;
    if (media is MediaItem) {
      result = media.isNew;
    } else if (media is MediaFolder) {
      final children = childrenByParent[media.id] ?? const <MediaBase>[];
      result = children.any(resolve);
    } else {
      result = false;
    }

    if (id != null) {
      inProgress.remove(id);
      memo[id] = result;
    }
    return result;
  }

  for (final doc in allDocuments.values) {
    resolve(doc);
  }

  return memo;
}
