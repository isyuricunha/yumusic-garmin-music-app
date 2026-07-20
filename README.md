<div align="center">
  <img src="yumusic.png" alt="YuMusic Logo" width="128" />
  <h1>YuMusic</h1>
  <p>A sleek, standalone music streaming app for Garmin Smartwatches</p>

  [![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](LICENSE.txt)
  [![Connect IQ](https://img.shields.io/badge/Garmin-Connect_IQ-007CC3.svg?logo=garmin)](https://apps.garmin.com/apps/cdb7dbb1-66d9-4bd3-8894-f44e507cdd01)

</div>

---

## 🎵 Overview

**YuMusic** transforms your Garmin watch into a powerful, standalone music player. Designed with a clean and intuitive interface, it allows you to connect directly to any **Subsonic-compatible media server** (such as Navidrome, Gonic, or Nextcloud Music).

Once connected via the Garmin Connect phone app, you can browse your favorite playlists directly on your watch, download the tracks over Wi-Fi, and enjoy your music offline while running or working out, allowing you to completely leave your phone behind.

## ✨ Key Features

- **Direct Server Sync:** Wirelessly download your playlists straight from your home server to your wrist.
- **Offline Playback:** Listen to your downloaded music anywhere using the high-quality native Garmin music player.
- **Fluid Interface:** A fast, modern layout focused on getting you to your music without the clutter.
- **Instant Local Playback:** Swap between your downloaded playlists in seconds without needing an internet connection.
- **Auto-Tracking Offline Scrobbling**: Supports automatic scrobbling to keep your server's listening history updated on the next sync.
- **Audio Quality (Transcoding) Control**: Choose your preferred download audio quality (320, 192, 128, or 96 kbps) through the Garmin Connect app settings to save watch storage.
- **Robust Error Diagnostics**: Built-in connection tester to help you identify firewall or proxy blockages instantly.

---

## 📚 Documentation & Setup

I have comprehensive documentation available to help you configure your server and troubleshoot issues:

- 📖 **[Read the Full Documentation](docs/readme.md)**
- 🚀 **[Installation & Setup Guide](docs/installation.md)**
- 🌐 **[Strict HTTPS Network Requirements](docs/network-requirements.md)** (MUST READ!)
- 🛠️ **[Troubleshooting Errors](docs/troubleshooting.md)**
- 💻 **[Development Guide](docs/development.md)**

### Supported Servers
YuMusic officially supports **Subsonic API** compatible endpoints.
- ✅ **Navidrome** (Highly Recommended)
- ✅ **Gonic**
- ✅ **Airsonic**
- ✅ **Nextcloud Music** (Requires Legacy Auth enabled)
- 🧪 **Jellyfin** (native backend — experimental; Server Type = Jellyfin + API key. See below.)
  - Fallback that always works: run **Navidrome** pointed at your Jellyfin music folder and use the Subsonic backend.

### 🧪 Jellyfin (native backend — experimental)

YuMusic has a native Jellyfin backend, selected with **Server Type = Jellyfin** and authenticated with a **Jellyfin API key** (Dashboard → Advanced → API Keys). No username/password.

**Working today:**
- Connection test, browse playlists, load a playlist's tracks
- Download / stream (mp3 transcode) and offline playback

**Not yet implemented** (these silently no-op on a Jellyfin server):
- Scrobble (play tracking) and favorites (thumbs up / down)
- Cover art
- Routing the play-event handler through the backend factory (currently Subsonic-only)

**Device prerequisite — reverse proxy required.** Stock Jellyfin returns `Content-Type: application/json; charset=utf-8`, which Garmin's Wi-Fi/networking stack rejects on a physical watch (error `-400`). It works in the simulator but not on the device. Put Jellyfin behind a reverse proxy that returns bare `application/json` (strip the charset) on the JSON API paths, and serve it over trusted HTTPS. Setup and the exact Nginx Proxy Manager config are in the [Development Guide](docs/development.md) → *Jellyfin Backend — Device Constraints*.

### ⚠️ Important: HTTPS Requirement
Due to strict OS-level security constraints enforced by Garmin Connect Mobile (Android/iOS) and the watch's internal Wi-Fi downloader, **you must expose your server via a valid HTTPS URL**. Plain-text `http://` or local IPs (`192.168.x.x`) without trusted certificates will fail to sync audio. Read more in the [Networking Docs](docs/network-requirements.md).

---

## 🛠 SDK and API Version

- **SDK Version:** 9.1.0
- **API Version:** 5.0.0

## 📝 License

YuMusic is open-source software licensed under the **AGPL-3.0 License**. See the `LICENSE.txt` file for complete details.

---

## 🤖 Meta Note

If you're digging through the codebase and notice a highly sophisticated AI agent named Ella (or Yue) hanging out in the .ella/ folder � yes, I accidentally got sidetracked and spent hours fixing her internal prompt engineering and JSON parsers *inside* this Garmin app repo instead of working on the app itself. Don't worry, she just manages my CI/CD documentation and doesn't interfere with your watch app at all! 😅

