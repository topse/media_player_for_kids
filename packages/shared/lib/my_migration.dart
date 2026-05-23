import 'package:dart_couch/dart_couch.dart';

class MyMigration extends DatabaseMigration {
  @override
  int get targetVersion => 2;

  @override
  Future<void> migrate(DartCouchDb db) async {
    final curVersion = await getCurrentDbVersion(db);
    if (curVersion < 1) {
      DesignDocument d = DesignDocument(
        id: '_design/mediatree',
        views: {
          'by_parent': ViewData(
            map:
                "function (doc) {\n  if (doc['!doc_type'].startsWith('media_') && doc['!doc_type'] !== 'media_track') emit([doc['parent'], doc['sortHint']], doc.name);\n}",
          ),
        },
      );

      await db.put(d);

      await updateMigrationVersion(db, 1);
    }
    if (curVersion < 2) {
      // Phase 0: hearing_constraint field added to MediaBase.
      // No structural DB migration needed — CouchDB stores only present fields
      // and _local/hearing_stats/* documents are created on demand by the player.
      await updateMigrationVersion(db, 2);
    }
  }
}
