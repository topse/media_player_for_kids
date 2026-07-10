# Media Player for Kids

## Scope of this document

This file (and the per-package `CLAUDE.md`s under `packages/*/`) captures **requirements and decisions** with high priority:

- *What* the system must do — behavior contracts.
- *Why* a particular choice was made — especially decisions that prevent regressions, fix past bugs, or document trade-offs.
- Cross-cutting facts a future contributor cannot reasonably re-derive from reading the code.

It does **not** describe *how* behaviors are implemented. Implementation details — current data structures, method signatures, internal timers, magic numbers, file layout under `lib/` — belong in the code and in code comments next to the relevant lines. If you find yourself documenting a function's internal mechanics here, move it into a docstring on that function instead.

Scope split between files:

- **This file (root)**: cross-package contracts — the constraint DSL, evaluation semantics, the data model that lives in `packages/shared/`, and anything both apps must agree on.
- **`packages/player/CLAUDE.md`**: requirements that apply to the child-facing Android player only.
- **`packages/companion/CLAUDE.md`**: requirements that apply to the parent's desktop companion only.

## Project Overview

A two-app system for curated children's media playback with parental controls:

- **Player app** (`packages/player/`): Android app for children to browse and play audio content
- **Companion app** (`packages/companion/`): Desktop app for parents to manage content and settings
- **Shared package** (`packages/shared/`): Common models, constraints DSL, and utilities

### Tech Stack

- Flutter / Dart
- CouchDB with offline-first replication (`dart_couch_widgets`)
- `just_audio` + `audio_service` for playback
- `dart_mappable` for JSON serialization
- `watch_it` for dependency injection

## Feature: Hearing Constraints (Hörregeln)

Parental controls that limit when, how often, and how long children can listen to specific media items or folders.

### Constraint DSL

Constraints are a composable tree of nodes stored as JSON on `MediaBase.hearingConstraint`. The discriminator key is `!constraint_type`.

**Node types:**

| Type | Purpose |
|---|---|
| `PlayCountConstraint` | Max N plays per time window |
| `PlayDurationConstraint` | Max N minutes per time window |
| `FolderItemCountConstraint` | Max N distinct children started per window |
| `TimeOfDayConstraint` | Allowed only during HH:mm–HH:mm (supports overnight) |
| `DayOfWeekConstraint` | Allowed only on specified ISO weekdays |
| `DateRangeConstraint` | Allowed only within a date range |
| `LogicalAndConstraint` | All children must pass (worst-case) |
| `LogicalOrConstraint` | At least one child must pass (best-case) |
| `LogicalNotConstraint` | Inverts inner result (allowed↔blocked, warning stays) |

**Time windows** (`TimeWindowType`): `perDay`, `perWeek`, `perMonth`, `sinceDate`, `rollingHours`

**Play counting is fractional:** `PlayCountConstraint` sums `playCountFraction` over the window — a 10 % listen consumes 0.1 plays, and a session split into several segments by seeks consumes the fraction actually heard, never one count per segment. (There is no per-event count mode; an earlier `CountMode` design was never implemented.)

### Evaluation Semantics — Nearest Wins

- `ConstraintEvaluator` is purely synchronous — all data injected by caller
- `evaluateWithAncestors()` uses **nearest-wins** semantics: walks from item upward, evaluates the **first** (nearest) node with a `hearingConstraint`, and returns that result
  - If the item has its own constraint → only that is evaluated
  - Otherwise the nearest ancestor folder with a constraint is used
  - If no constraint exists in the entire chain → allowed
- **Folder-level pool.** When the nearest-wins holder is a folder, evaluation aggregates play events across **all direct children** of that folder. Folder constraints are a shared budget across siblings, not a per-item limit — this also applies when the folder itself is passed as the "item" (e.g. for indicators while the kid is browsing inside it).
- `findNearestConstraintHolder()` static helper returns which node owns the effective constraint (used by companion UI for "inherited from" indicators)
- Fail-open: null stats → `allowed`, unknown constraint type → `allowed`

**Remaining allowance semantics for logical operators** (critical — past bug source):
- `_allowanceAnd`: if **any** child evaluates to `blocked` (including non-time-based nodes like `DayOfWeekConstraint`), return `0` — the AND branch is gated off and contributes no time
- `_allowanceOr`: only count **passing** (non-blocked) branches; a blocked branch is skipped entirely; if ALL branches are blocked return `0`
- Without this, a blocked `DayOfWeekConstraint` returns `null` from `_allowance` (not time-based) and is silently ignored, causing its sibling `PlayDurationConstraint` to bleed through as if the branch were active — e.g. OR(AND(Mon-Fri, 1min), AND(Sat-Sun, 3min)) on Monday would incorrectly give 3 min allowance instead of 1 min

### Play Event Tracking

Each contiguous play segment that survives the minimum-play threshold records a `PlayEvent` with:
- `startedAt`: ISO 8601 local datetime
- `durationMs`: Actual playback milliseconds (position-based, not wall-clock)
- `playCountFraction`: Fraction of total item heard (0.0 to 1.0)

The item `title` (MediaItem name at recording time, survives deletion/rename) is stored once per item on the play-log entry, not per event. There is no per-event "completed" flag — natural playlist completion matters only at recording time: a completing segment is never discarded, regardless of duration.

**Minimum play threshold (cross-cutting contract):** The play log only stores `PlayEvent` records for **contiguous play segments** that meet the admin-configured minimum threshold; shorter segments are discarded. Per-item, per-folder, and global constraints all read from the same filtered event stream, so they share the same threshold semantics. Natural completions are never discarded regardless of duration. The per-segment rule, skip-resets-segment behavior, and worked examples are described in [packages/player/CLAUDE.md](packages/player/CLAUDE.md) (the player is the only writer).

**Storage layout (data-model decision):** play stats are stored as a single replicated `playlog-<deviceUuid>` document per device, structured by `itemId`. Events older than 31 days are aggregated into `playlog_archive-<deviceUuid>` (per-item monthly buckets) so the live playlog never grows unbounded. Both documents are consumed by the companion for statistics.

**Audiobook resume positions** use the same per-device pattern: a replicated `playposition-<deviceUuid>` document keyed by `itemId`, with each entry carrying the item `title` plus either a resume `position` (track + seconds) or a `done` marker. Replicated (not `_local/...`) so the companion can purge entries when items are deleted (see Catalog deletion below) and so positions survive a reinstall via replication. The player is the only writer.

**Catalog deletion (companion-only contract):** when the companion deletes media items, it must remove any matching entries from every `playposition-<deviceUuid>` document immediately. Additionally, the companion's startup `repairDatabase` sweep drops orphaned entries from `playlog-<uuid>` and `playposition-<uuid>` (catches out-of-band deletions, e.g. via Fauxton, and races where the immediate purge didn't reach a device). `playlog_archive-<uuid>` is intentionally *not* swept: archive items carry their own preserved `title` and represent the long-term listening record, which should remain meaningful after the original item is gone. The live PlayLog/PlayLogItem `title` field primarily survives renames in flight.

### Constraint Enforcement (contracts)

Enforcement happens at three levels — all are required behavior the player implements:

- **Hard gate at play start.** A blocked item must not load audio, must not record stats, and must close the player.
- **Mid-playback enforcement with grace period.** Once allowance is exhausted mid-playback, the kid may finish the current item *only* if the remaining item duration is within the admin-configured grace period ("Kulanzzeit"); otherwise playback stops and the player closes. Grace period applies equally to per-item and global constraints. Player-specific details (how remaining duration is measured, repeat-mode carve-out) are in [packages/player/CLAUDE.md](packages/player/CLAUDE.md).
- **Soft visual hint in the grid.** Items must show a child-friendly indicator when they are blocked (dark + lock icon) or when the kid's remaining allowance — including the grace period — is no longer enough to hear the item to its natural end (small red timer icon in the bottom-left). Otherwise no marker is shown. No text — the indicator must be readable to non-reading children. The "cannot finish" check uses the same most-restrictive-wins combine of per-item and global allowance as everywhere else.

The unified remaining-ratio measure (duration → `remainingMs / itemDurationMs`, count → fractional plays remaining, folder-item-count → remaining slots; see `remainingPlayRatioWithAncestors()` in `constraint_evaluator.dart`) is no longer used to drive the grid hint, but still feeds the app-bar allowance indicator.

**Combining per-item and global constraints.** A per-item nearest-wins constraint and the global constraint (when configured) are combined using most-restrictive-wins semantics: blocked beats warning beats allowed; remaining-allowance and used-ratio take the smaller and larger respectively. This combine rule must live in a single shared helper in `ConstraintEvaluator` — every consumer (gates, indicators, timers) delegates there rather than re-implementing it. Constraints that are not quantifiable as a "% used" (`TimeOfDay`, `DayOfWeek`, `DateRange`, `NOT`) contribute to gating but not to indicators.

### Admin Overrides and Settings

Admin can bypass constraint enforcement for emergency / troubleshooting:

- `ignoreConstraints`: bypasses all constraint checks (per-item, per-folder, and global).
- `ignoreDateSettings`: bypasses `fromDateTime`/`toDateTime` visibility.

While either override is active, the player must show a visible warning so the override is not forgotten.

Admin-configurable thresholds shared with the constraint subsystem:

- Minimum-play seconds (default 15): the per-segment threshold (see Play Event Tracking).
- Grace period in minutes (default 5): how much of an item the kid may finish past an exhausted allowance.

### Device Identity and Kid Name

Each device has a UUID (generated on first login). A `DeviceIdentity` document (`device-id-<uuid>`) stores the UUID and `kidName`. The kid name must be collected at first startup after login if missing (blocking) and is used by the companion to label per-device statistics.

### Test Coverage

The behaviour contracts in this document are guarded by tests in `packages/shared/test/constraints/` — `constraint_evaluator_test.dart` covers node types, time windows, nearest-wins, remaining allowance, and complex OR/AND interaction; `constraint_description_test.dart` covers the German text summaries. Treat these tests as a regression net for any change to the constraint DSL or evaluation semantics.
