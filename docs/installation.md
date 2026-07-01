# Installation & Setup

## 1. Install from Connect IQ
Download and install **YuMusic** from the [Garmin Connect IQ Store](https://apps.garmin.com/apps/cdb7dbb1-66d9-4bd3-8894-f44e507cdd01).

## 2. Configure Settings
Open the **Garmin Connect** app on your phone:
1. Navigate to your Device -> **Music** -> **Music Providers**.
2. Select **YuMusic**.
3. Tap **Settings**.

You must fill in the following:
* **Server URL**: Your public server address. **Must start with `https://`** (e.g., `https://music.mydomain.com`). See [Network Requirements](network-requirements.md) for why HTTP fails.
* **Username**: Your server username.
* **Password**: Your server password (or API password for Nextcloud Music).
* **Legacy Authentication (optional)**: Only check this if your server requires older API password transmission methods (like Nextcloud Music). Navidrome works perfectly with this disabled.

## 3. Syncing Music
1. On your watch, open the Music controls.
2. Select YuMusic as the provider.
3. Use the app menu to **Browse** and select playlists to download.
4. Press **Sync** to download the tracks via Wi-Fi to your watch for offline playback.
