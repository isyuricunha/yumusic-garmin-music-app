# YuMusic - Garmin Music App for Navidrome/Subsonic

YuMusic is an audio content provider app for Garmin smartwatches. It allows you to select playlists from a Subsonic-compatible server (including Navidrome, Gonic, Airsonic and Subsonic), sync tracks over Wi-Fi, and play them offline using the native Garmin music player.

## Features

- Compatible with Navidrome, Gonic, Airsonic and Subsonic
- Subsonic API version 1.16.1
- Playlist selection on the watch
- Wi-Fi sync (downloads audio to the device)
- Offline playback via the native Garmin player
- Shuffle mode
- Automatic scrobbling (marks tracks as played)
- Thumbs up/down (star/unstar)
- Tested with Garmin Venu 2

## Requirements

- A Garmin smartwatch with music support (e.g. Venu 2)
- Connect IQ SDK (min API level 5.0.0)
- A Subsonic-compatible server accessible by the watch
- Wi-Fi configured on the watch
- Garmin Connect app on the phone (for app settings)

## Installation

### Build

This is a Connect IQ project. Build it with `monkeyc`:

```bash
monkeyc -d venu2 -f monkey.jungle -o bin/YuMusic.prg -y developer_key
```

### Run on simulator

```bash
monkeydo bin/YuMusic.prg venu2
```

### Install on a device

You can install through the Connect IQ workflow (recommended). If you manually copy the `.prg`, place it under `GARMIN/APPS` on the device.

## Configuration

### 1) Server settings (phone)

Server settings are delivered through the Garmin Connect app:

- Server URL (example: `https://music.example.com`)
- Username
- Password

These values are stored on the device using `Application.Storage`.

### 2) Select a playlist (watch)

On the watch, open YuMusic playback settings and choose:

- Select Playlist

Then pick one of the playlists returned by the server.

### 3) Sync (download audio to the device)

After selecting a playlist, start sync:

- Sync Now

The system will download tracks using Wi-Fi and store them in the Garmin media cache. After sync, tracks are available for offline playback.

## Playback

Use the native Garmin music player and select YuMusic as the music provider.

When shuffle is off, YuMusic can resume from the last played track.

## Project structure

```
yumusic-garmin-music-app/
├── source/
│   ├── yumusicApp.mc                      # App entry point (AudioContentProviderApp)
│   ├── YuMusicSubsonicAPI.mc              # Subsonic API client
│   ├── YuMusicServerConfig.mc             # Server configuration storage
│   ├── YuMusicLibrary.mc                  # Library persistence and helpers
│   ├── yumusicContentDelegate.mc          # Media content delegate
│   ├── yumusicContentIterator.mc          # Media content iterator
│   ├── yumusicSyncDelegate.mc             # Sync delegate (downloads audio)
│   ├── yumusicConfigurePlaybackView.mc    # Playback configuration view
│   ├── yumusicConfigurePlaybackDelegate.mc # Playback configuration delegate
│   ├── yumusicConfigureSyncView.mc        # Sync configuration view
│   ├── yumusicConfigureSyncDelegate.mc    # Sync configuration delegate
│   ├── YuMusicPlaylistMenuDelegate.mc     # Playlist selection menu delegate
│   ├── YuMusicPlaybackMenuDelegate.mc     # Playback menu delegate
│   ├── YuMusicServerConfigView.mc         # Server configuration view
│   ├── YuMusicServerConfigDelegate.mc     # Server configuration delegate
│   ├── YuMusicLoadingView.mc              # Loading view
│   ├── YuMusicConfirmView.mc              # Confirmation view
│   └── YuMusicConfirmDelegate.mc          # Confirmation delegate
├── resources/
│   ├── drawables/
│   ├── layouts/
│   │   ├── configurePlaybackLayout.xml
│   │   └── configureSyncLayout.xml
│   └── strings/
│       └── strings.xml
└── manifest.xml
```

## Development

### Tooling

- Connect IQ SDK
- Visual Studio Code with the Monkey C extension (optional)

## Security notes

- Credentials are stored on-device using `Application.Storage`
- Authentication uses the Subsonic token + salt (MD5 of password + salt)

## Troubleshooting

### Server does not connect

- Verify the server URL and credentials
- Ensure the watch can reach the server (Wi-Fi and DNS)

### Tracks do not sync

- Ensure Wi-Fi is connected
- Keep the watch on the charger during long syncs
- Check free space on the device

### Tracks do not show up in the player

- Sync must complete successfully
- If you selected a new playlist, only the selected tracks will be available for playback

## Supported Subsonic endpoints

- `ping`
- `getPlaylists`
- `getPlaylist`
- `getRandomSongs`
- `getArtists`
- `getArtist`
- `getAlbum`
- `search3`
- `download`
- `stream`
- `getCoverArt`
- `scrobble`
- `star`
- `unstar`

## License

AGPL-3.0 license. See `LICENSE.txt`.

## Disclaimer

This is an independent project and is not affiliated with Garmin, Navidrome, Gonic, Airsonic, or Subsonic.
