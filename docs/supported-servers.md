# Supported Servers

YuMusic communicates with **Subsonic API** compatible media servers, and has a **native Jellyfin** backend.

Select the backend with the `serverType` setting (`subsonic` or `jellyfin`) in Garmin Connect (device) or the App Settings editor (simulator).

## Subsonic-Compatible Servers

* **Navidrome** (Highly recommended, extremely fast and lightweight)
* **Gonic**
* **Airsonic / Airsonic-Advanced**
* **Nextcloud Music** (Requires enabling "Legacy Authentication" in YuMusic settings, and generating an App/API password in Nextcloud).

Subsonic servers authenticate with a username and password.

## Jellyfin (Native)

YuMusic has a native Jellyfin backend. Core playback works: browse playlists, sync tracks to the watch, and play them offline.

**Authentication**: API key only. Set `serverType=jellyfin` and the `apiKey` setting. Username and password are not used for Jellyfin.

**Not yet implemented on Jellyfin** (available on Subsonic): scrobble (mark played), favorites (thumbs up/down), cover art.

### Server prerequisites

A physical watch enforces constraints the simulator does not. Two are mandatory for on-device use:

1. **HTTPS with a certificate from a trusted public CA.** Garmin rejects self-signed certificates and plain HTTP, and the watch has no UI to trust a custom root CA. A publicly resolvable domain name is required even when the server stays fully on the LAN (e.g. a free DuckDNS / deSEC name + Let's Encrypt).
2. **JSON responses must be bare `application/json`.** Stock Jellyfin returns `application/json; charset=utf-8`; the watch rejects the `; charset=utf-8` suffix with error `-400`. This has no client-side fix — a reverse proxy in front of Jellyfin (Caddy / nginx / Nginx Proxy Manager / Traefik) must strip the charset from the JSON API responses.

A reverse proxy (NPM, Caddy, …) satisfies both at once: it terminates trusted TLS and rewrites the Content-Type. See `docs/development.md` → **Jellyfin Backend — Device Constraints** for a working Nginx Proxy Manager configuration.

> The public demo server (`demo.jellyfin.org`) works only in the simulator — its Content-Type carries the charset, so it cannot be used for on-device testing.

### Alternative: Navidrome bridge

If you do not want to run a reverse proxy, you can keep the Subsonic path instead of the native Jellyfin backend. Navidrome is lightweight; point it at the same music directory Jellyfin uses, let it scan, and connect YuMusic to Navidrome over Subsonic.
