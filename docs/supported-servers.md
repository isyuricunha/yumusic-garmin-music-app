# Supported Servers

YuMusic is designed to communicate with **Subsonic API** compatible media servers. 

## Fully Supported Servers
* **Navidrome** (Highly recommended, extremely fast and lightweight)
* **Gonic**
* **Airsonic / Airsonic-Advanced**
* **Nextcloud Music** (Requires enabling "Legacy Authentication" in YuMusic settings, and generating an App/API password in Nextcloud).

## A Note on Jellyfin
**Jellyfin is not natively supported by YuMusic.**

Jellyfin uses a proprietary API and does not natively support the Subsonic API standard. Creating and maintaining a completely separate Jellyfin API client within YuMusic is outside the scope of this project.

**Workaround for Jellyfin Users:**
Because Navidrome is incredibly lightweight, many users who use Jellyfin for their primary media library simply install Navidrome alongside it. You can point Navidrome to the exact same music directory that Jellyfin uses. Navidrome will scan the music, and you can connect YuMusic to Navidrome to sync your tracks to your watch!
