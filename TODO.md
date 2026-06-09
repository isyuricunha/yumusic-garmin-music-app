# YuMusic Issue Remediation

This file tracks the user-reported issues being addressed. Every milestone must
compile for the affected device families before it is considered complete.

## Milestone 1: Connection, Authentication, and Diagnostics

- [ ] Preserve valid HTTP and HTTPS server URLs, including reverse-proxy paths.
- [ ] URL-encode all Subsonic request parameters.
- [ ] Keep token authentication as the backward-compatible default.
- [ ] Add legacy password authentication for compatible Subsonic servers.
- [ ] Add API-key authentication for Nextcloud Music.
- [ ] Validate Subsonic response status and error payloads, not only HTTP status.
- [ ] Replace the unrelated public HTTPS probe with server-specific diagnostics.
- [ ] Show actionable messages for Garmin network and memory error codes.
- [ ] Document Nextcloud Music's generated API-key requirement.

Related reports: #5, #7, #9.

## Milestone 2: Playlist Loading, Sync, and Storage

- [ ] Remove unsupported `offset` and `count` parameters from `getPlaylist`.
- [ ] Handle Garmin `-402` and `-403` playlist response limits explicitly.
- [ ] Use Navidrome's supported transcoding parameters.
- [ ] Request an estimated content length for transcoded Navidrome downloads.
- [ ] Download only tracks that are not already cached.
- [ ] Do not expose incomplete playlists as ready for playback.
- [ ] Replace oversized aggregate storage values with per-record storage.
- [ ] Migrate existing stored playlists and songs without losing cached content.
- [ ] Add tests for URL construction, response validation, migration, and sync state.

Related reports: #5, #6, #9.

## Milestone 3: Library Management

- [ ] Add a playlist-management screen.
- [ ] Remove a selected downloaded playlist.
- [ ] Delete cached tracks only when no remaining playlist references them.
- [ ] Make Clear Library remove playlists, tracks, state, and cached media.
- [ ] Add confirmation before destructive library operations.
- [ ] Add tests for shared-track and last-playlist removal.

Related report: #8.

## Milestone 4: Playback Navigation

- [ ] Start Garmin playback directly after a local playlist is selected.
- [ ] Remove delayed double-pop navigation that can return to the watch face.
- [ ] Keep the selected playlist stable when Garmin recreates the provider.
- [ ] Verify selection from a cold provider launch and after synchronization.

Related reports: #6, #8.

## Milestone 5: Jellyfin

- [ ] Define a backend abstraction instead of mixing protocols.
- [ ] Implement Jellyfin server validation and access-token authentication.
- [ ] Discover audio libraries and playlists using Jellyfin APIs.
- [ ] Map Jellyfin tracks to the existing Garmin content model.
- [ ] Request Garmin-compatible MP3 audio with bounded bitrate.
- [ ] Add backend-specific tests and setup documentation.
- [ ] Keep all existing Subsonic-compatible servers working unchanged.

Related report: #10.

## Milestone 6: Documentation and Release Validation

- [ ] Update the README and Garmin Store description content.
- [ ] List tested and expected-compatible server types.
- [ ] Explain HTTP, HTTPS, certificates, local-network, and Garmin limitations.
- [ ] Explain playlist-size limits as device/response dependent.
- [ ] Add an error-code troubleshooting table.
- [ ] Build with the current SDK for Forerunner 955, Forerunner 265, and Enduro 3.
- [ ] Build with the previous supported SDK to catch compatibility regressions.
- [ ] Run all automated tests and complete a final code review.
