# Troubleshooting

If you are experiencing issues, open YuMusic on your watch, scroll to the bottom of the menu, and select **Test Connection**. This will give you a specific error code.

## Network & Connectivity Errors

### `-1001 (HTTPS Required)`
Garmin's mobile app proxy blocked the connection because you are trying to use an insecure `http://` URL. **Solution**: You must expose your server via HTTPS with a valid certificate. See [Network Requirements](network-requirements.md).

### `-300 (Timeout / Local IP?)`
The watch could not reach the server within the time limit. 
* **If you are using a Local IP (`192.168.x.x`)**: This happens if your phone is currently using mobile data (4G/5G) instead of being connected to your home Wi-Fi. The phone cannot route to your local network.
* **If you are using a public URL**: Your firewall might be blocking the connection, or your server is down.

### `Sync failed: 0` (Invalid Download Response)
The watch successfully connected to your server via Bluetooth to browse playlists, but when it tried to download the audio over Wi-Fi, it failed. 
* **Cause**: Usually caused by attempting to download over HTTP (which the Wi-Fi chip blocks abruptly) or server configurations blocking the file transfer. Ensure you are on YuMusic v1.7.0+ and using a valid HTTPS URL.

### `-404` or `-401`
Incorrect credentials, or incorrect Subsonic API endpoint. Ensure you don't have trailing spaces in your URL or username.

## Watch & Memory Errors

### `-403` (Memory Exhaustion / Out of Memory)
Garmin watches have extremely limited RAM for parsing JSON. If you select a playlist that has hundreds or thousands of songs, the server attempts to send the entire tracklist at once, crashing the Garmin memory limit.
* **Solution**: Keep your playlists synced to the watch under a reasonable size (e.g., ~50-100 tracks depending on the watch model).

### `-400 (Bad Request)`
Usually means the JSON response from the server was malformed or too large for the proxy to pass down to the watch.
