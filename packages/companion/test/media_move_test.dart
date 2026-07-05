// Integration tests for the move / reparent helpers in media_move_dialog.dart.
//
// They run against a real (SQLite-backed) LocalDartCouchDb — no server or Docker
// needed — so the actual db.put/db.post round-trips are exercised, and we assert
// both the new parent AND the resulting sortHint order numbers of every affected
// sibling set after each move.

import 'dart:io';

import 'package:dart_couch_widgets/dart_couch.dart' hide Directory;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

import 'package:media_player_for_kids_companion/media_move_dialog.dart';

void main() {
  setUpAll(initializeMappers);

  late Directory tmp;
  late LocalDartCouchServer server;
  late DartCouchDb db;

  // Standard tree built fresh for each test:
  //   root ─┬─ A(1) ─┬─ a1(1)
  //         │        ├─ a2(2)
  //         │        └─ a3(3)
  //         └─ B(2) ─── b1(1)
  const allIds = ['A', 'B', 'a1', 'a2', 'a3', 'b1'];

  Future<void> putFolder(String id, String? parent, int sortHint) =>
      db.put(MediaFolder(
        id: id,
        parent: parent,
        sortHint: sortHint,
        name: id,
        showItemNumbering: false,
      ));

  Future<void> putItem(String id, String? parent, int sortHint) =>
      db.put(MediaItem(
        id: id,
        parent: parent,
        sortHint: sortHint,
        name: id,
        media: const [],
        repeat: false,
        shuffle: false,
        showTrackCoverRatherThanItemCover: false,
        isAudioBook: false,
        isNew: false,
      ));

  /// Fresh id -> doc map (with current revs) to feed the move helpers.
  Future<Map<String, MediaBase>> loadDocs(Iterable<String> ids) async {
    final map = <String, MediaBase>{};
    for (final id in ids) {
      final d = await db.get(id);
      if (d is MediaBase) map[id] = d;
    }
    return map;
  }

  Future<MediaBase> get(String id) async => await db.get(id) as MediaBase;

  /// (parent, sortHint) pair for compact assertions.
  Future<({String? parent, int sort})> where(String id) async {
    final d = await get(id);
    return (parent: d.parent, sort: d.sortHint);
  }

  setUp(() async {
    tmp = Directory.systemTemp.createTempSync('companion_move_test_');
    server = LocalDartCouchServer(tmp);
    db = await server.db('move_test') ??
        await server.createDatabase('move_test');

    await putFolder('A', null, 1);
    await putFolder('B', null, 2);
    await putItem('a1', 'A', 1);
    await putItem('a2', 'A', 2);
    await putItem('a3', 'A', 3);
    await putItem('b1', 'B', 1);
  });

  tearDown(() async {
    await server.dispose();
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('move one item into another folder appends it and compacts the source',
      () async {
    await moveMediaBases(
      db: db,
      items: [await get('a2')],
      newParentId: 'B',
      allDocuments: await loadDocs(allIds),
    );

    // a2 is now the last child of B (after b1 at 1).
    expect(await where('a2'), (parent: 'B', sort: 2));
    expect(await where('b1'), (parent: 'B', sort: 1));
    // A's remaining children are compacted 1..N (a1 keeps 1, a3 3->2).
    expect(await where('a1'), (parent: 'A', sort: 1));
    expect(await where('a3'), (parent: 'A', sort: 2));
  });

  test('move an item to the root (top level)', () async {
    await moveMediaBases(
      db: db,
      items: [await get('a1')],
      newParentId: null,
      allDocuments: await loadDocs(allIds),
    );

    // Appended after the existing root folders A(1), B(2).
    expect(await where('a1'), (parent: null, sort: 3));
    // A's remaining children compacted: a2 2->1, a3 3->2.
    expect(await where('a2'), (parent: 'A', sort: 1));
    expect(await where('a3'), (parent: 'A', sort: 2));
  });

  test('move multiple items keeps their relative order and compacts source',
      () async {
    await moveMediaBases(
      db: db,
      items: [await get('a3'), await get('a1')], // deliberately out of order
      newParentId: 'B',
      allDocuments: await loadDocs(allIds),
    );

    // Appended after b1(1) preserving prior relative order a1 before a3.
    expect(await where('b1'), (parent: 'B', sort: 1));
    expect(await where('a1'), (parent: 'B', sort: 2));
    expect(await where('a3'), (parent: 'B', sort: 3));
    // Only a2 remains in A, compacted to 1.
    expect(await where('a2'), (parent: 'A', sort: 1));
  });

  test('move into a new subfolder creates it in the parent and moves inside',
      () async {
    final newId = await moveIntoNewSubfolder(
      db: db,
      items: [await get('a1'), await get('a2')],
      parentId: 'A',
      name: 'Sub',
      allDocuments: await loadDocs(allIds),
    );

    // New subfolder sits in A, appended at the end (after a3 at 3 -> sort 4).
    final sub = await get(newId);
    expect(sub, isA<MediaFolder>());
    expect(sub.parent, 'A');
    expect(sub.sortHint, 4);

    // The two items now live in the subfolder, numbered 1..2.
    expect(await where('a1'), (parent: newId, sort: 1));
    expect(await where('a2'), (parent: newId, sort: 2));
    // A's remaining direct child a3 compacts to 1; subfolder stays last.
    expect(await where('a3'), (parent: 'A', sort: 1));
  });
}
