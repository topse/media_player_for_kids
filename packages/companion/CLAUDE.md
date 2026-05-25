# Media Player for Kids — Companion Package

## Scope of this document

This file captures **requirements and decisions** for the parent-facing desktop companion app. It is requirements-first: when changing code, preserve the behaviors listed here over local implementation convenience.

It does **not** describe *how* behaviors are implemented. Architecture diagrams, technical-stack laundry lists, file layout under `lib/`, and other mechanics belong in code and in docstrings next to the relevant lines — not here. If a fact is only useful to read the code, it belongs in the code.

Cross-package contracts (the constraint DSL, evaluator semantics, play log data model) live in the root [CLAUDE.md](../../CLAUDE.md). Player-specific requirements live in [packages/player/CLAUDE.md](../player/CLAUDE.md).

## Purpose

The companion is the parent's desktop app for managing the media catalog and parental controls that the child's player consumes. It is the **only** writer of the content tree, the per-item / per-folder constraints, and the global hearing constraint. The player reads these via CouchDB replication.

## Main user flows

### Content management

1. Log in.
2. Browse the tree of folders and items.
3. Import audio files (drag-and-drop or picker), with automatic loudness scanning during import.
4. Edit metadata, cover images, visibility windows, audiobook flag, shuffle, repeat.
5. Set per-item / per-folder hearing constraints (Hörregeln).
6. Manage the global hearing constraint.
7. Review listening statistics from the player (per device, by kid name).

### Audio preview

The companion must be able to play audio locally for preview (independent of the player app's runtime).

## Functional requirements

### 1. Content tree

- Folders and items form a tree. Items contain tracks; folders contain folders or items.
- The companion is the source of truth for the tree. Edits replicate to the player via CouchDB.
- Tree edits (rename, move, delete, add) must take effect on the player on next replication without requiring player restart.

### 2. Audio import

- Drag-and-drop import of audio files into a folder or item.
- Loudness is measured (LUFS) at import time and stored on the track so the player can normalize without re-scanning.
- Cover images must be importable and attached to either items or individual tracks.

### 3. Visibility scheduling

- Each item / folder may carry `fromDateTime` and `toDateTime` to restrict when it is visible to the child. The companion edits these; the player honors them (unless `ignoreDateSettings` is set on the player side).

### 4. Hearing constraint editor (Hörregeln)

The companion provides the **only** UI for authoring `HearingConstraint` trees. The DSL itself is documented in the root CLAUDE.md.

- **Two-mode editor:**
  1. **Template mode.** A card picker with pre-built templates (e.g. "max 30 min on weekdays", "weekend only") with German labels. New parents should reach a sensible policy without learning the DSL.
  2. **Advanced mode.** Recursive tree editor with drag-and-drop, exposing every node type for arbitrary composition.
- **Inherited-constraint indicator.** When an item has no own constraint but inherits one from an ancestor folder (per nearest-wins evaluation), the constraint tile must show a "geerbt von [folder]" chip. The editor must offer to deep-copy the inherited constraint as a starting point rather than forcing the parent to retype it.
- A constraint set on an item / folder shadows any ancestor constraint (nearest-wins — see root CLAUDE.md). The editor must make this clear in the UI so parents don't double-restrict by accident.

### 5. Global hearing constraint

- The companion is the **sole writer** of the `global-constraints` document (type `GlobalConstraints`); the player only reads and subscribes.
- The global constraint uses the same `HearingConstraint` DSL.
- The UI must communicate that the global constraint stacks **most-restrictively** with per-item / per-folder constraints — i.e. blocking on either side blocks playback.

### 6. Listening statistics

- The companion reads the player's `playlog-<deviceUuid>` and `playlog_archive-<deviceUuid>` documents (one set per device) to display statistics.
- Statistics must be labeled by `kidName` from the `device-id-<uuid>` document so the parent can distinguish multiple kids.

### 7. Cross-platform support

- The companion must run on Windows, macOS, and Linux desktop. Web is supported where the dependencies allow but is not a primary target.

## Key decisions

- **Companion is the only writer of catalog & constraints.** The player only reads (and writes its own play log + device identity). This keeps the child-facing app simple and constrains the surface for accidental corruption.
- **Offline-first via CouchDB.** Both apps work fully offline and reconcile via replication. Any new write should respect this and never assume a live network.
- **Constraint editing has a templates-first surface.** Most parents will never open advanced mode; the template set is the supported authoring path. New templates should be additive — don't remove existing ones, even if redundant, because they may be referenced by parents' memory of the UI.

## Change guidance

- **New `@MappableClass` document types must be registered in [`packages/shared/lib/init.dart`](../shared/lib/init.dart) under `initializeMappers()` — including all nested mappable types.** Without `XxxMapper.ensureInitialized()` the discriminator (`!doc_type`) never dispatches; `db.get()` silently returns a generic `CouchDocumentBase` with the real fields stuffed into `unmappedProps`. Callers' `loaded is XxxType` checks then fail, the service falls through to a fresh in-memory doc with `rev = null`, and every subsequent `db.put` is treated as "create" → 409 conflict forever (already-exists). Symptom: in-memory state diverges from DB, UI shows transient state during a session that vanishes on restart, persist logs show repeated 409s. This bit us on `PlayPositionMapper`.

## Code navigation

Entry points for the major concerns above. Each file's responsibilities are documented in its own file-level docstring — keep details there, not here.

- `lib/main.dart` — app bootstrap, DI.
- `lib/login_screen.dart`, `lib/login_profile*.dart` — login and saved profiles.
- `lib/my_home_page.dart`, `lib/split_view.dart` — top-level shell and tree/detail split.
- `lib/media_folder_detail.dart`, `lib/media_item_detail.dart`, `lib/media_*_dialog.dart` — per-folder / per-item editing UI.
- `lib/audio_import_util.dart`, `lib/loudness_scanner.dart`, `lib/loudness_batch_scanner.dart` — drag-and-drop import and LUFS scanning.
- `lib/constraint_editor.dart` — visual constraint editor (template + advanced mode + inherited import).
- `lib/constraint_templates.dart` — the pre-built constraint templates.
- `lib/media_base_header.dart` — item / folder header, including the inherited-constraint indicator.
- `lib/global_constraint_page.dart` — global constraint authoring UI.
- `lib/audio_player_service.dart`, `lib/audio_playback_controls.dart` — local audio preview.
- `lib/db_repair.dart` — admin / maintenance database utilities.
