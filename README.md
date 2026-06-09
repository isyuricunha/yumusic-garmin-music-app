# YuMusic

YuMusic downloads playlists from a self-hosted music server to compatible
Garmin music watches for offline playback. It supports Subsonic-compatible
servers and Jellyfin, uses the native Garmin music player, and does not require
a phone after the selected music has been synchronized.

## Store Description

Connect your Garmin watch to your own Navidrome, Subsonic-compatible, Nextcloud
Music, or Jellyfin server. Browse server playlists from the watch, download
tracks over the Garmin music synchronization flow, and listen offline during
activities without carrying a phone.

Features:

- Native offline playback through the Garmin music player.
- Subsonic-compatible and native Jellyfin server support.
- Selectable MP3 download quality: 96, 128, 192, or 320 kbps.
- Direct playback after selecting a downloaded playlist.
- Playlist removal and full library cleanup from the watch.
- Shared tracks are stored once when they appear in multiple playlists.
- Offline play history is sent to the server on the next synchronization.

YuMusic requires a compatible Garmin music watch, a reachable self-hosted
server, and a configured Wi-Fi connection for music downloads.

## Supported Servers

| Server | Status | Authentication |
| --- | --- | --- |
| Navidrome | Supported | Subsonic token or legacy password |
| OpenSubsonic-compatible servers | Supported when the required playlist and MP3 streaming endpoints are implemented | Subsonic token or legacy password |
| Gonic and Airsonic derivatives | Expected compatible | Subsonic token or legacy password |
| Nextcloud Music | Supported through its Subsonic API | Generated API password |
| Jellyfin | Native integration | Jellyfin username and password |

Jellyfin integration was validated against the official Jellyfin 10.11.11 demo
server on June 9, 2026. Other Subsonic derivatives can differ in authentication,
playlist responses, or transcoding behavior even when they advertise Subsonic
compatibility.

## Configuration

Configure YuMusic in Garmin Connect or Connect IQ:

1. Select the **Server Type**.
2. Enter the server's base URL, including any reverse-proxy path.
3. Enter the username and credential required by that server.
4. For Subsonic servers, select the matching authentication method.
5. Select the preferred MP3 download bitrate.
6. Open YuMusic on the watch and run **Test Connection**.

Do not add `/rest` to a normal Subsonic server URL. YuMusic adds the Subsonic
REST path to each request. Preserve a reverse-proxy path when one is required,
for example `https://music.example.com/navidrome`.

### Navidrome and Subsonic

Use **Subsonic Compatible** as the server type.

- **Subsonic Token (Recommended):** sends an MD5 token and a unique random salt
  for each request. Use this when the server supports standard Subsonic token
  authentication.
- **Legacy Password:** sends the URL-encoded server password. Use this only when
  the server does not support token authentication.

YuMusic requests an MP3 stream at the configured bitrate. Navidrome requests
also ask the server to estimate the transcoded content length for Garmin's
download progress reporting.

### Nextcloud Music

Nextcloud Music uses its own generated API password instead of the Nextcloud
account password:

1. Open the Nextcloud **Music** app.
2. Open the Music app settings.
3. Find **Ampache and Subsonic**.
4. Copy the displayed Subsonic URL.
5. Select **Generate API password**, then copy the generated password.
6. In YuMusic, choose **Subsonic Compatible** and **Nextcloud Music API Key**.
7. Enter the copied Subsonic URL and generated API password. The username can
   remain empty in this authentication mode.

The generated password can be revoked independently in Nextcloud Music. Token
authentication is not supported by Nextcloud Music's Subsonic implementation.

### Jellyfin

Use **Jellyfin** as the server type and enter the Jellyfin server base URL,
username, and password. The Subsonic Authentication setting is ignored for this
backend. Passwordless Jellyfin accounts are supported.

YuMusic authenticates with Jellyfin, discovers playlists using paginated
requests, and requests an MP3 audio stream at the configured bitrate.

## Synchronization and Playback

Use **Add Music** on the watch to browse server playlists and select one to
download. Garmin performs music downloads in its synchronization mode and may
show its own transfer screen.

Only complete playlists appear in the local playback list. Tracks already
stored by another playlist are reused instead of downloaded again. Selecting a
local playlist starts the Garmin player directly.

Use **Playback Settings > Manage Downloads** to remove a playlist. A track is
deleted only when no remaining playlist references it. Use **Clear Library** to
remove all YuMusic playlists, metadata, pending state, and downloaded media.

## Network Requirements

YuMusic accepts both `http://` and `https://` server URLs. HTTPS is strongly
recommended, particularly outside a trusted local network, because HTTP exposes
credentials and media traffic.

Garmin uses two distinct communication paths:

- Connection tests and playlist metadata requests use the Garmin
  Communications API and can be proxied through the paired phone.
- Music files are downloaded by Garmin's bulk content synchronization flow,
  normally over a configured Wi-Fi network.

Consequently, a successful browser or phone request does not prove that the
watch can reach the server during synchronization. For a local HTTP server:

- The phone and watch must be able to reach the server address.
- Do not use `localhost`; use a LAN hostname or IP address.
- Wi-Fi client isolation, guest networks, VPN routing, and firewall rules can
  block one path while allowing the other.
- Some Garmin devices, firmware versions, or request contexts can return
  `-1001` when a secure connection is required. This is a Garmin platform
  restriction; use HTTPS for that environment.

For HTTPS, use a certificate chain trusted by the Garmin communication path.
The server URL must match the certificate hostname.

## Playlist and Storage Limits

YuMusic does not enforce a fixed 30-track or 50-track playlist limit.

Subsonic's `getPlaylist` endpoint returns the complete playlist in one response
and does not define pagination. The practical maximum therefore varies with the
watch model, available memory, number of tracks, and metadata size. A large
playlist can exceed Garmin's response memory before audio downloading begins.
Jellyfin playlist discovery and loading are paginated to reduce response-memory
spikes, but device memory and free music storage still apply.

YuMusic stores playlist and track metadata as separate records instead of one
large aggregate value. This avoids Garmin's 8 KB limit per application-storage
key or value. Garmin still limits the application's total persistent metadata
storage, and downloaded audio is limited by the watch's available music
storage. Lower bitrates reduce download time and storage use.

## Troubleshooting

**Test Connection** checks the configured server, authentication, and playlist
endpoint. It does not use an unrelated public HTTPS probe. Any HTTP `2xx`
response can be valid for an endpoint; YuMusic also validates the expected
Subsonic or Jellyfin response body.

| Code or symptom | Meaning | Action |
| --- | --- | --- |
| HTTP `401` | Server rejected authentication | Verify username and credential. For Nextcloud Music, generate an API password. |
| HTTP `403` | Server or reverse proxy refused the request | Check server permissions, proxy rules, and server logs. |
| Subsonic error `40` | Wrong username or password | Verify credentials and selected authentication mode. |
| Subsonic error `41` | Token authentication is not supported | Select Legacy Password, or Nextcloud Music API Key for Nextcloud. |
| Garmin `-300` | Request timed out | Verify routing, firewall, DNS, reverse proxy, and whether the phone/watch can reach the URL. |
| Garmin `-400` | Invalid network response or response body | Check proxy/server logs and confirm the endpoint returns the expected JSON payload. |
| Garmin `-402` | Network response exceeded the platform limit | Reduce response size or split an unusually large playlist. |
| Garmin `-403` | The watch ran out of memory while processing the response | This is not HTTP 403. Reduce playlist metadata/size and retry after restarting the watch. |
| Garmin `-1001` | The Garmin request context requires a secure connection | Configure HTTPS with a trusted certificate. |
| Garmin `-1002` | Unsupported content or response type | Confirm the server can provide MP3 and that a proxy is not replacing the audio response. |
| `Sync failed (0)` | Synchronization ended without a usable Garmin error code | Re-run Test Connection, confirm the playlist contains downloadable audio, and inspect server/proxy logs for the stream requests. |
| Sync completes with zero playlists | The server returned no visible playlists | Create or expose a playlist for the user. For Nextcloud Music, verify its displayed Subsonic URL and generated API password. |

If a failure affects only one playlist, compare its size and track metadata with
a working playlist and inspect server logs for the playlist and MP3 stream
requests. A playlist working in a browser does not rule out a Garmin response
memory limit.

## Privacy and Security

YuMusic stores its configuration in Garmin application storage and sends
credentials only to the configured music server. It does not use a YuMusic
relay service. Use HTTPS whenever credentials or media leave a trusted local
network.

## Development

- Connect IQ SDK: 9.1.0
- Minimum Connect IQ API level: 5.0.0
- Language: Monkey C

The release validation matrix includes Forerunner 955, Forerunner 265, and
Enduro 3 builds, a previous supported SDK build, and automated tests for
authentication, URL construction, storage migration, playlist removal,
playback state, synchronization, and Jellyfin mapping.

## References

- [YuMusic on the Connect IQ Store](https://apps.garmin.com/apps/cdb7dbb1-66d9-4bd3-8894-f44e507cdd01)
- [Garmin Communications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html)
- [Garmin Downloading Content](https://developer.garmin.com/connect-iq/core-topics/downloading-content/)
- [Garmin Persisting Data](https://developer.garmin.com/connect-iq/core-topics/persisting-data/)
- [OpenSubsonic API documentation](https://opensubsonic.netlify.app/docs/)
- [Nextcloud Music Subsonic documentation](https://github.com/owncloud/music/wiki/Subsonic)
- [Jellyfin API documentation](https://api.jellyfin.org/)

## License

YuMusic is licensed under the [AGPL-3.0 License](LICENSE.txt).
