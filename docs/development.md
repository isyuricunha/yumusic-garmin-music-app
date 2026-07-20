# Development Guide

This guide is for developers looking to contribute, build, or test YuMusic locally.

## Prerequisites
1. Download and install the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).
2. Install the **Monkey C** extension for Visual Studio Code.
3. Generate a Developer Key (`developer_key.der`) via the Monkey C extension.

## Building the App
YuMusic is compiled using the `monkeyc` compiler. The project configuration is managed by the `monkey.jungle` file, which tells the compiler where to find source code and resources.

To compile the app via command line for a specific device (e.g., Fenix 7):
```bash
monkeyc -d fenix7 -f monkey.jungle -y /path/to/your/developer_key.der -o app.prg
```

## Running in the Simulator
1. Start the Connect IQ Simulator from VS Code (`Ctrl+Shift+P` -> `Monkey C: Start Simulator`).
2. Run the app (`F5` in VS Code).
3. **Important**: In the simulator Settings, ensure you test with **Use Device HTTPS Requirements** enabled to simulate real-world networking constraints.

## Building via Makefile
A `Makefile` wraps the common `monkeyc`/`monkeydo` commands. It auto-detects the latest installed Connect IQ SDK and defaults to `DEVICE=fr165m`. Run `make help` for the full target list.

```bash
make check              # Print the resolved SDK / device / key
make build              # Compile a signed .prg to /tmp/yumusic.prg
make sim                # Launch the Connect IQ simulator (background)
make run                # Build, then load the app into the running simulator
make test               # Build unit tests, relaunch the sim, run them
make package            # Build an exportable .iq store package
```
Override any variable on the command line, e.g. `make build DEVICE=fr965`.

## Deploying to a Physical Watch (macOS)
Modern Garmin watches (including the Forerunner 165) expose storage over **MTP**, not USB mass storage. macOS does not mount MTP devices in Finder, which has two consequences:
* The watch never appears under `/Volumes/GARMIN`.
* The `make install` target copies to `/Volumes/GARMIN/GARMIN/APPS` and therefore does **not** work on macOS for these devices. Use the MTP workflow below instead.

### Prerequisites
* A **data** USB cable — many cables are charge-only. When a data connection is active, the watch displays a computer icon.
* [OpenMTP](https://openmtp.ganeshrvel.com/) (or Android File Transfer) to browse the device over MTP.
* **Garmin Express must be closed.** It reverts sideloaded `.prg` files while running in the background.

### Steps
1. Build the `.prg`: `make build` (output: `/tmp/yumusic.prg`, built for `DEVICE=fr165m`).
2. Connect the watch with the data cable and open OpenMTP. The watch appears in the right-hand pane.
3. On the device, navigate to `GARMIN/APPS`.
4. Copy `/tmp/yumusic.prg` into `GARMIN/APPS`, alongside the `DATA`, `LOGS`, `SETTINGS`, `TEMP` folders.
5. Eject the watch in OpenMTP, then unplug it.
6. **Restart the watch** to force a rescan of the `APPS` directory: hold the **LIGHT** button (top-left) → **Power Off**, then press **LIGHT** to power back on.

### Locating the app on the watch
An `audio-content-provider-app` does **not** appear in the general apps/activities list. Access it through the music menu:

> Hold **DOWN** (music controls) → hold **UP** → **Music Providers** → **YuMusic**

If YuMusic is missing after a restart, reconnect the watch and confirm `YUMUSIC.PRG` is still present in `GARMIN/APPS`. If it has disappeared, Garmin Express removed it — close it and repeat the copy.

## Testing in the Simulator

### Configuring the server in the simulator
The simulator persists app Properties and Storage between launches. A `properties.xml` default is applied **only when the property does not already exist**, so once any value (even empty) has been persisted from a previous run, changing the default has no effect. Two ways to configure:

* **App Settings editor** — set Server Type, Server URL, and API Key (Jellyfin) or Username/Password (Subsonic) directly in the simulator's settings editor. This writes the Properties immediately.
* **Defaults + reset** — set the values in `resources/settings/properties.xml`, then clear persisted data with the simulator **File → Reset App Data** (or **Reset Simulator**) and relaunch, so the new defaults load.
* **`make build-test`** (recommended) — bake a server config into a build without committing credentials. Copy `server-config.example.sh` to a git-ignored profile (`test-config.sh`, or `prod-config.sh` for the LAN server) and fill it in; `tools/build-configured.sh` backs up `properties.xml`, injects the values, builds, and always restores the file afterwards. Profile variables are prefixed `YUMUSIC_`; set `YUMUSIC_JELLYFIN_DEMO=1` to auto-fetch a fresh `demo.jellyfin.org` token at build time. Pick a profile with `CONFIG=` (e.g. `make build-test CONFIG=prod-config.sh`). `make run-test` builds the same way and loads it into the simulator; the resulting `.prg` is also what you sideload to a watch (a sideloaded app is not configurable via Garmin Connect, so baking is the only way to configure it there).

### Reaching the app's menus in the simulator
YuMusic is an `audio-content-provider-app`. Launched directly, the simulator shows the native media player — **"No Media"** when the local library is empty — not the app's own menus. The provider flows are reached from the **simulator menu bar**:

* **Settings → Media Mode → Sync Configuration** — opens the Add Music / Browse-playlists view (`getSyncConfigurationView`).
* **Settings → Media Mode → Sync** — runs a media sync (Wi-Fi download).
* **Playback** — playback controls.

On a physical watch these are reached instead via **Music → Music Providers → YuMusic**; the simulator does not wrap the provider in the Garmin Music menu.

### Connection Test
The Configure Playback view exposes a **Test Connection** action. It is backend-aware: it resolves the backend from `serverType` via `YuMusicApiFactory` and runs Public-HTTPS → ping → getPlaylists using the neutral API surface, so it validates Subsonic and Jellyfin alike. Each row shows the backend + host and the raw response code.

## Jellyfin Backend — Device Constraints

The Jellyfin read path (auth, playlists, playlist items, stream) works in the simulator but has device-only constraints that the simulator does not enforce. The simulator's networking stack is lenient; the Garmin Connect Mobile proxy on a physical device is strict.

### Response Content-Type must be bare `application/json`
Jellyfin returns `Content-Type: application/json; charset=utf-8`. On a physical device (and over Wi-Fi on music watches) Connect IQ validates the response Content-Type against the request `:responseType` and **rejects the `; charset=utf-8` suffix with error `-400`**. The simulator accepts it, so a request that returns `200` in the simulator can fail with `-400` on the watch.

There is no client-side fix. The server must return bare `application/json`. Place a reverse proxy in front of Jellyfin (Caddy / nginx / Traefik) that rewrites the JSON response Content-Type to strip the charset parameter. The public demo server (`demo.jellyfin.org`) cannot be used for on-device testing for this reason (its Content-Type carries the charset); it works only in the simulator.

#### Working setup: LAN Jellyfin via Nginx Proxy Manager
A LAN Jellyfin can serve a physical watch through a public domain fronted by Nginx Proxy Manager (NPM), which provides both the required valid TLS certificate and the Content-Type rewrite:

1. In NPM, create a Proxy Host for your domain (e.g. `jellyfin.example.com`) forwarding to the LAN Jellyfin, with **SSL → Let's Encrypt** enabled (Garmin requires HTTPS).
2. In the proxy host, **Advanced → Custom Nginx Configuration**, add a location that strips the charset on the JSON API paths only (leaving `/Audio` streams as `audio/mpeg`):
   ```nginx
   location ~* ^/(System|Items|Playlists) {
       proxy_pass        $forward_scheme://$server:$port;
       proxy_set_header  Host              $host;
       proxy_set_header  X-Forwarded-Proto $scheme;
       proxy_set_header  X-Forwarded-For   $remote_addr;
       proxy_set_header  X-Real-IP         $remote_addr;
       proxy_hide_header Content-Type;
       add_header        Content-Type application/json always;
   }
   ```
3. Verify from any machine (the JSON path must return bare `application/json`; the audio path must stay `audio/mpeg`):
   ```bash
   curl -sD - -o /dev/null "https://<domain>/Items?IncludeItemTypes=Playlist&Recursive=true&api_key=<key>" | grep -i content-type
   curl -sD - -o /dev/null "https://<domain>/Audio/<id>/stream.mp3?api_key=<key>&AudioCodec=mp3&AudioBitRate=320000" | grep -i content-type
   ```
4. Point the app at `https://<domain>` with `serverType=jellyfin` and the API key. For a sideloaded build, keep the profile in `prod-config.sh` and run `make build-test CONFIG=prod-config.sh`.

### Query parameters go in the params dict
`Communications.makeWebRequest` expects query parameters in the params dictionary, not embedded in the URL string. Params in the URL work in the simulator and on Android but are stripped/mangled by the Garmin Connect Mobile proxy on physical devices. The Jellyfin backend passes `IncludeItemTypes`, `Recursive`, `api_key`, and `Fields` via the params dict. The stream/download URL is the exception — it embeds `api_key` in the URL by design, because the media download step fetches the URL directly.

### Authentication
The Jellyfin backend authenticates with an API key (the `apiKey` setting), sent as the `api_key` query parameter. Username and password are not used for Jellyfin. Configure the API key via Garmin Connect (device) or the App Settings editor (simulator).

## Architecture Notes
* **Audio Content Provider**: YuMusic operates as a Garmin Audio Content Provider. 
* **State Management**: The app uses `Toybox.Application.Storage` and `Toybox.Application.Properties` to manage playlists and auth tokens.
* **Sync Flow**: Syncing is initiated by the Garmin OS over Wi-Fi, calling `yumusicSyncDelegate.mc`. Downloads must provide a valid `Content-Length` and `audio/*` content type.
