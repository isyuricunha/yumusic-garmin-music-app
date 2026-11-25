# Changelog

## Unreleased

- Fixed playback broken since 1.10.1: persisted media ids were stored as strings, so `Media.ContentRef` lookups missed every downloaded track. Ids are now kept in their native (numeric) form.
- Existing libraries with stringified numeric ids are repaired automatically on first load, so already-downloaded tracks play again without a re-sync.
- Fixed incremental sync re-downloading every track and cached-media cleanup silently failing for the same reason.
- Sync callback now checks the response type at runtime instead of relying on compile-time casts.

## 1.11.0 - 2026-08-30

- Added a Shuffle All playback option for the full downloaded local library.
- Added Shuffle All to the local playlist picker so users with split playlists can play everything without switching playlists mid-activity.
- Kept the implementation backed by the existing content iterator instead of duplicating songs into a synthetic playlist.
- Added tests for whole-library playback selection and downloaded-track counting.

## 1.10.1 - 2026-08-30

- Fixed a Garmin "Media Error" crash when selecting additional playlists after other playlists had already been marked for sync.
- Migrated the local library from one large `songs` storage value to compact per-track records to stay within Garmin `Application.Storage` value limits.
- Stopped storing authenticated stream URLs in the local song library; YuMusic now generates download URLs only during sync.
- Fixed playlist removal so shared tracks remain available in other synced playlists.
- Kept cached media cleanup intact for tracks removed from a playlist, individual tracks removed from storage, and full library clears.
- Added migration support for older libraries that only stored `playlistId` instead of a playlist membership list.
- Improved sync validation so a track is only marked as downloaded after Garmin returns a valid persisted media id.
- Treat Garmin persisted media ids as opaque content references instead of assuming they are numeric, matching the current Connect IQ media APIs.
- Added support for Garmin persisted-content iterator responses during audio download callbacks.
- URL-encoded Subsonic request parameters and removed authenticated URLs from debug logs.
- Added unit tests for multi-playlist storage, legacy migration, playlist removal, and persisted download state.
