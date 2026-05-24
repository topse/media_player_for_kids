# Media Player for Kids — Player Package

## Scope of this document

This file captures **requirements and decisions** for the child-facing Android player. It is requirements-first: when changing code, preserve the behaviors listed here over local implementation convenience.

It does **not** describe *how* behaviors are implemented. Method signatures, internal timers, magic numbers, exact widget sizes, and other mechanics belong in code and in docstrings next to the relevant lines — not here. If a fact is only useful to read the code, it belongs in the code.

Cross-package contracts (the constraint DSL, evaluator semantics, play log data model) live in the root [CLAUDE.md](../../CLAUDE.md). Companion-specific requirements live in [packages/companion/CLAUDE.md](../companion/CLAUDE.md).

## Purpose

This package contains the Android player app for `media_player_for_kids`.

The app is designed for children to browse and play curated media from a CouchDB-backed catalog while keeping sensitive settings under parental control. The child-facing experience should stay simple, visual, and safe. Administrative capabilities must be intentionally separated and password protected.

## Platform and Stack

- Platform: Android
- UI: Flutter / Material
- Local/service architecture: `watch_it` DI and singleton services
- Data source: CouchDB via `dart_couch_widgets`
- Audio playback: `just_audio` + `audio_service` + `audio_session`
- Audio device detection: custom platform channel to Android `AudioManager`
- Local persistence:
  - `SharedPreferencesWithCache` for admin password, audio-device volume configs, grid column settings, and hearing constraint admin values
  - Replicated CouchDB document (`playposition-<deviceUuid>`) for audiobook play positions and "done" markers — see root [CLAUDE.md](../../CLAUDE.md) for the cross-package storage decision

## Main User Flows

### Child flow

1. Open the app and browse visible root-level media items.
2. Navigate into folders.
3. Open a media item and play its tracks.
4. For audiobooks, resume from the previously saved position.

### Parent/admin flow

1. Enter the admin area through password verification.
2. Change the admin password.
3. Configure audio output device volume limits:
   - set a per-device volume limit from `-18.0 dB` to `0.0 dB`
4. Configure grid layout:
   - set number of grid columns for portrait orientation (1–12, default 2)
   - set number of grid columns for landscape orientation (1–12, default 4)
5. Configure hearing constraint behaviour (Hörregeln section):
   - set minimum play duration (0–120 s, default 15 s) — below this, sessions are not counted and audiobook positions are not saved
   - set grace period / Kulanzzeit (1–30 min, default 5 min) — if remaining item time is within this window when the allowance expires, playback may finish

## Functional Requirements

## 1. Child-facing browsing

- The home screen must display only media entries that are currently visible.
- Visibility depends on the media model and time windows such as `fromDateTime` / `toDateTime`.
- Root items are shown in a grid whose column count is configurable per orientation (portrait / landscape) via admin settings.
- Folder navigation must preserve a simple breadcrumb-based mental model.
- Child-facing UI should avoid exposing technical settings directly.

## 2. Media playback

- The app must load track audio and play it through a singleton audio service.
- Audio tracks should support:
  - play / pause
  - seek
  - previous / next track
  - repeat
  - optional shuffle for non-audiobook items
- Playlist completion without repeat should stop playback and close the player page.
- The current media item should be exposed to the background audio service for notification/system controls.

## 3. Audiobook resume behavior

- Audiobooks must save their current position.
- Saved position must include track index and elapsed seconds.
- If playback reaches the end of the final track, the item should be marked as done.
- On reopening an audiobook, playback should resume from the saved position when available.
- Progress should be visible in the browsing grid for audiobooks.
- **Minimum threshold for position saving:** a position is only saved when the **current** contiguous play segment has met the minimum play threshold (`kMinPlaySeconds`). The threshold is checked on the segment being played right now — not on the whole session — so the saved position always reflects a spot the kid actually listened to past the threshold, never a spot they briefly skimmed. See [Per-segment threshold](#per-segment-minimum-play-threshold) for what counts as a segment.
  - This applies equally to items that already had a saved in-progress position (no resume-mode bypass) and to items being heard for the first time.
  - **Save before seek/skip.** Every slider seek and skip-next / skip-previous calls the position-save path BEFORE finalising the segment, so a valid segment ending in a seek-away still saves the pre-seek position. After `recordSeek`, the new (post-seek) segment starts at 0 ms and won't pass the gate until it reaches the threshold itself.
  - "Done" markers are never overwritten by a session in which the current segment hasn't met the threshold.
  - Near-end detection (last track, within 30 s of end) always saves as done, regardless of the current segment.

### Per-segment minimum-play threshold

The minimum-play threshold (`HearingStatsService.kMinPlaySeconds`, admin-configurable, default 15 s) applies to a **single contiguous play segment**, not to the cumulative session.

- A *segment* runs from the last play start (or last user-initiated seek / track skip) until the next seek or until the session ends.
- A *session* runs from opening the player page until closing it (or natural playlist completion).
- A user-initiated seek on the slider or a press of skip-next / skip-previous calls `HearingStatsService.recordSeek`, which finalises the current segment and starts a new one.
- Pauses do NOT end a segment. Pause/resume keeps accumulating into the same segment.
- A segment that finishes below threshold (i.e. its `PlayEvent` would be too short) is discarded entirely — it never appears in the play log and contributes nothing to per-item, per-folder, or global hearing-constraint counters.
- Natural playlist completion always counts as a valid segment, regardless of accumulated duration.

Two related helpers expose this:
- `HearingStatsService.meetsMinimumPlayThreshold()` — true if **any** segment in the session passed the threshold. Drives **session-level** side effects like `isNew` clearing.
- `HearingStatsService.currentSegmentMeetsThreshold()` — true only if the segment in progress right now has passed the threshold. Drives **position saving** (see above), because the saved position must always correspond to a spot the kid is actively listening to past the threshold — not a spot they briefly skimmed after seeking away from a valid segment.

#### Worked example

Threshold = 15 s. Kid opens an item, plays 10 s, seeks to a new position, plays another 10 s, exits.

- Two segments, both 10 s, both below threshold.
- Both segments are discarded; the play log records nothing.
- Per-item, per-folder, and global hearing-constraint counters do not advance.
- The "new" flag is **not** cleared.
- The audiobook position is **not** saved (and any pre-existing done/in-progress marker is preserved).

If instead the kid had played 20 s, then seeked and played 5 s before exiting: the 20 s segment is recorded, the new flag is cleared, and the audiobook position is saved at the **pre-seek** point (captured by the save-before-seek hook while the 20 s segment was still current). The 5 s post-seek segment is discarded and, because it didn't cross the threshold, does not overwrite that saved position on exit.

### "New" flag clearing

The `isNew` flag on a media item is cleared by the player only after the kid has actually listened to the item — specifically, only when `HearingStatsService.meetsMinimumPlayThreshold()` is true (i.e. at least one segment of this session passed the threshold). Opening the player page and immediately exiting, or scanning through with short seeks, must not clear the flag. The clearing happens at session exit points (natural completion, dispose, lifecycle pause / inactive), not at session start.

## 4. Admin protection requirements

- Admin-only features must be protected by an admin password.
- First launch requires the parent/admin to set a password.
- Password changes must require the existing password.
- Child-facing navigation must not expose admin actions without verification.

## 5. Audio output device volume attenuation

- The app detects which audio output device Android is currently routing media to.
- Android controls media audio routing automatically (Bluetooth A2DP > wired > speaker). The app cannot programmatically switch the output device.
- The app applies a per-device volume attenuation factor based on admin-configured dB limits.
- The admin can set a volume limit per device type or per bonded Bluetooth device address.
- Volume attenuation is applied in real time whenever the active device changes.

## 6. Parental control over output device volume

- Audio output device volume configuration belongs in the admin area.
- Each device type/address can be configured with a volume limit in dB.
- The admin page shows all currently available devices plus bonded Bluetooth devices (even when off).

## 7. Fallback behavior for disconnected devices

- If the active playback device disappears (e.g. Bluetooth disconnected), Android automatically routes to the next available device.
- The app detects the new active device and applies its configured volume limit.
- Volume recalculation happens without requiring user interaction.

## 8. Loudness and volume requirements

- Track loudness normalization is based on LUFS metadata.
- Per-device volume limits must be applied on top of track normalization.
- Volume changes caused by device switches or admin device-limit changes must apply in real time while playback is active.
- Volume must remain clamped to safe internal bounds used by the audio player service.

## 9. Persistence requirements

- The following must persist across app restarts:
  - admin password
  - audio device volume configurations (keyed by device type or Bluetooth address)
  - grid column counts for portrait and landscape
  - audiobook play positions / done state
  - minimum play threshold in seconds (`HearingStatsService.kMinPlaySeconds`)
  - grace period in minutes (`AdminOverrideService.kGracePeriodMinutes`)
- Audio device persistence is keyed by device type or bonded Bluetooth device address.
- All SharedPreferences keys must be listed in the `allowList` in `main.dart`.

## 10. Sync and data model requirements

- Media content and metadata come from CouchDB.
- The app should continue using the existing offline-first replication setup.
- The UI must react to database updates.
- New flags and metadata coming from the shared media model should remain respected.

## 11. Global hearing constraint

- A global hearing constraint limits total listening time across ALL items.
- The constraint definition is stored in a CouchDB document (`global-constraints`, type `GlobalConstraints`) managed exclusively by the companion app — the player only reads and subscribes.
- The constraint uses the existing `HearingConstraint` DSL (e.g. `PlayDurationConstraint` combined with `DayOfWeekConstraint` via logical operators).
- Evaluation uses aggregated play stats from all items (not per-item stats).
- The global constraint is combined with per-item/folder constraints using most-restrictive-wins semantics: if either is blocked, playback is blocked.
- The grace period applies equally to the global constraint — if remaining item time ≤ grace threshold when global allowance expires, the child can finish the current item.
- The `ignoreConstraints` admin override disables the global constraint along with all per-item constraints.
- The directory-view grid marker (red timer icon, shown when an item can no longer be finished even with the grace period applied) reflects the most restrictive of per-item and global remaining allowance.
- The allowance timer during playback fires based on `min(perItemAllowance, globalAllowance)`.
- The most-restrictive combine rule is a cross-package contract (see root [CLAUDE.md](../../CLAUDE.md)); the player must always go through the shared helper rather than re-implementing it for each call site.

## 12. Grace period contract

- "Remaining item time" for the grace-period check is measured from the current playhead to the natural end of the playlist, **not** from session-accumulated play time. This matters for audiobooks resumed mid-item and for items the kid seeked through — those would otherwise compute the wrong remainder.
- Grace applies whenever the effective allowance reaches zero mid-play, regardless of whether the cause is a time limit, a count limit surfaced as zero allowance, or a constraint that flipped from allowed to blocked via a sync.
- **Repeat mode does not bypass enforcement.** A repeating item is subject to the same per-item and global limits as any other item. Because a repeating playlist has no natural end, grace cannot apply in that case — playback stops cleanly when allowance expires. This closes an earlier loophole where a short item on repeat could be used to listen indefinitely.

## 13. App-bar allowance indicator

A circular indicator in the app bar shows how much of the effective hearing-constraint budget is consumed (0 % = nothing used, 100 % = limit reached). The visual is tiered: progressively warmer colours as the ratio approaches and exceeds the limit. Exact thresholds and colours live in the widget code.

**What counts as an "active" constraint for the indicator:**

- **Global constraint:** always included when configured.
- **Per-item / per-folder constraint:** included via the navigation context the kid is currently in:
  - Directory view **at root** → global only.
  - Directory view **inside folder F** → F's nearest-wins constraint contributes (F's own or whichever ancestor's is nearest, with the folder-level pool semantics from the root contract).
  - Player page **playing item Y** → Y's nearest-wins constraint contributes.

The indicator combines per-item-in-context with global using the cross-package most-restrictive rule.

**Hides itself** when no quantifiable constraint is active — that includes the "only `TimeOfDay` / `DayOfWeek` / `DateRange` / `NOT`" case (binary, no "% used" meaning) and when `ignoreConstraints` is on.

**Live updates during playback.** The indicator must visibly tick down while the kid listens — i.e. its source of truth must reflect the in-flight session, not just the last persisted state. The player keeps stats fresh independently of the (slower) CouchDB persist cadence to satisfy this.

## Code navigation

Entry points to look at when working on the major concerns above. Each file's responsibilities are documented in its own file-level docstring — keep details there, not here.

- `lib/main.dart` — app bootstrap, DI, admin password gate, admin settings entry point.
- `lib/directory_view.dart` — child-facing media browsing.
- `lib/media_player_page.dart` — player screen, constraint gate, mid-playback allowance enforcement.
- `lib/hearing_stats_service.dart` — play event recording, persistence, archiving, global constraint subscription.
- `lib/audio_player_service.dart` — playback queue, background audio, LUFS normalization, per-device volume.
- `lib/play_position_service.dart` — audiobook position persistence.
- `lib/audio_device_service.dart` — output device detection, per-device volume config.
- `lib/admin/` — admin-gated UI (password, settings, audio device limits).
- `lib/widgets/media_app_bar.dart` — breadcrumbs, admin menu entry.

## Current Audio Device Model

The current implementation stores audio output volume settings by device type or by bonded Bluetooth device address.

Implications:

- Non-Bluetooth devices: config applies per logical type (e.g. all wired headsets share one volume limit).
- Bluetooth devices: config is keyed per bonded device MAC address when known, allowing separate volume limits for different headphones.
- The app does not and cannot switch the active audio output device. Android handles media routing automatically.
- The app detects the current output device and applies the matching volume attenuation.

## Known Limitations / Follow-up Candidates

- Android does not expose a public API to programmatically route media audio to a specific device (`setPreferredDeviceForStrategy` is `@SystemApi`).
- The admin page shows only devices that are currently available to Android plus bonded Bluetooth devices.
- If new hardware appears later, the UI relies on refresh and stream updates rather than a full hardware-management workflow.
- Existing analyzer warnings unrelated to these features still exist in the project.

## Change Guidance

When extending this package:

- Keep child interactions minimal and visual.
- Keep admin controls gated.
- Treat the requirements above as behavior contracts.
- Preserve audiobook resume semantics.
- Recalculate effective playback volume whenever the active output device changes.

## Open TODO from README

- When a media item has ended its playlist, the play button should show a play icon and allow restart.