# Media Player for Kids

## Purpose

This package contains the Android player app for `media_player_for_kids`.

The app is designed for children to browse and play curated media from a CouchDB-backed catalog while keeping sensitive settings under parental control. The child-facing experience should stay simple, visual, and safe. Administrative capabilities must be intentionally separated and password protected.

This document is requirements-first. When changing code, prefer preserving the behaviors listed here over local implementation convenience.

## Platform and Stack

- Platform: Android
- UI: Flutter / Material
- Local/service architecture: `watch_it` DI and singleton services
- Data source: CouchDB via `dart_couch_widgets`
- Audio playback: `just_audio` + `audio_service` + `audio_session`
- Audio device detection: custom platform channel to Android `AudioManager`
- Local persistence:
  - `SharedPreferencesWithCache` for admin password, audio-device volume configs, and grid column settings
  - CouchDB local document for audiobook play positions

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
- Audio device persistence is keyed by device type or bonded Bluetooth device address.

## 10. Sync and data model requirements

- Media content and metadata come from CouchDB.
- The app should continue using the existing offline-first replication setup.
- The UI must react to database updates.
- New flags and metadata coming from the shared media model should remain respected.

## Important Files

- `lib/main.dart`
  - app bootstrap
  - DI registration
  - admin password gate
  - admin settings entry point
- `lib/directory_view.dart`
  - child-facing media browsing
  - visibility filtering
  - audiobook progress display
- `lib/media_player_page.dart`
  - player screen
  - resume behavior
  - completion handling
- `lib/audio_player_service.dart`
  - playback queue management
  - background audio integration
  - LUFS normalization
  - real-time volume recalculation
- `lib/play_position_service.dart`
  - audiobook position persistence
- `lib/audio_device_service.dart`
  - device discovery via platform channel
  - per-device volume config (keyed by type or Bluetooth address)
  - current device detection (follows Android auto-routing priority)
- `lib/admin/audio_device_admin_page.dart`
  - admin UI for per-device volume limits
- `lib/widgets/media_app_bar.dart`
  - breadcrumbs
  - admin menu entry

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