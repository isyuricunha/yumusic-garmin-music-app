# YuMusic Issue Remediation

This file tracks the user-reported issues being addressed. Every milestone must
compile for the affected device families before it is considered complete.

## Milestone 1: Connection, Authentication, and Diagnostics

- [x] Preserve valid HTTP and HTTPS server URLs, including reverse-proxy paths.
- [x] URL-encode all Subsonic request parameters.
- [x] Keep token authentication as the backward-compatible default.
- [x] Add legacy password authentication for compatible Subsonic servers.
- [x] Add API-key authentication for Nextcloud Music.
- [x] Validate Subsonic response status and error payloads, not only HTTP status.
- [x] Replace the unrelated public HTTPS probe with server-specific diagnostics.
- [x] Show actionable messages for Garmin network and memory error codes.
- [x] Document Nextcloud Music's generated API-key requirement.

Related reports: #5, #7, #9.

## Milestone 2: Playlist Loading, Sync, and Storage

- [x] Remove unsupported `offset` and `count` parameters from `getPlaylist`.
- [x] Handle Garmin `-402` and `-403` playlist response limits explicitly.
- [x] Use Navidrome's supported transcoding parameters.
- [x] Request an estimated content length for transcoded Navidrome downloads.
- [x] Download only tracks that are not already cached.
- [x] Do not expose incomplete playlists as ready for playback.
- [x] Replace oversized aggregate storage values with per-record storage.
- [x] Migrate existing stored playlists and songs without losing cached content.
- [x] Add tests for URL construction, response validation, migration, and sync state.

Related reports: #5, #6, #9.

## Milestone 3: Library Management

- [x] Add a playlist-management screen.
- [x] Remove a selected downloaded playlist.
- [x] Delete cached tracks only when no remaining playlist references them.
- [x] Make Clear Library remove playlists, tracks, state, and cached media.
- [x] Add confirmation before destructive library operations.
- [x] Add tests for shared-track and last-playlist removal.

Related report: #8.

## Milestone 4: Playback Navigation

- [x] Start Garmin playback directly after a local playlist is selected.
- [x] Remove delayed double-pop navigation that can return to the watch face.
- [x] Keep the selected playlist stable when Garmin recreates the provider.
- [x] Verify selection state across provider recreation in automated tests.

Related reports: #6, #8.

## Milestone 5: Jellyfin

- [x] Define a backend abstraction instead of mixing protocols.
- [x] Implement Jellyfin server validation and access-token authentication.
- [x] Discover playlists across Jellyfin audio libraries with paginated requests.
- [x] Map Jellyfin tracks to the existing Garmin content model.
- [x] Request Garmin-compatible MP3 audio with bounded bitrate.
- [x] Add backend-specific automated and live integration tests.
- [x] Add Jellyfin setup documentation.
- [x] Keep all existing Subsonic-compatible servers working unchanged.

Related report: #10.

## Milestone 6: Documentation and Release Validation

- [x] Update the README and Garmin Store description content.
- [x] List tested and expected-compatible server types.
- [x] Explain HTTP, HTTPS, certificates, local-network, and Garmin limitations.
- [x] Explain playlist-size limits as device/response dependent.
- [x] Add an error-code troubleshooting table.
- [x] Build with the current SDK for Forerunner 955, Forerunner 265, and Enduro 3.
- [x] Build with the previous supported SDK to catch compatibility regressions.
- [x] Run all automated tests and complete a final code review.

## Milestone 7: Playback and Cache Hardening

- [x] Verify cached Garmin audio exists before exposing a track to playback.
- [x] Mark stale cached tracks as pending instead of crashing playback.
- [x] Avoid sending Garmin local content IDs to Subsonic or Jellyfin actions.
- [x] Serialize Jellyfin playback actions so callbacks cannot overwrite each other.
- [x] Keep library metadata cleanup independent from content-cache reset failures.
- [x] Add regression coverage for unmapped Garmin content IDs.
- [x] Build with the current SDK for Forerunner 955, Venu 2, Enduro 3, and Forerunner 265.
- [x] Run all automated tests after the cache and playback fixes.

## Milestone 8: Media Download Progress

- [x] Use Garmin's media file download progress callback during audio sync.
- [x] Calculate overall sync progress from the current track and file progress.
- [x] Request audio responses with an explicit MP3/audio `Accept` header.
- [x] Add regression coverage for sync progress calculation.
- [x] Build with the current SDK for Forerunner 955, Venu 2, Enduro 3, and Forerunner 265.
- [x] Build with the previous supported SDK to catch compatibility regressions.
- [x] Run all automated tests after the download-progress fix.

Related reports: #5, #10.
