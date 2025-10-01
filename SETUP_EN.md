# yumusic Setup Guide

Complete setup guide for yumusic - Garmin Music App for Subsonic/Navidrome/Gonic/AirSonic servers.

## Requirements

- Garmin watch with Music support (API Level 5.0+)
  - Tested on Venu 2 (416x416 AMOLED)
- Subsonic-compatible server:
  - Navidrome
  - Gonic
  - AirSonic
  - Subsonic
- Garmin Connect Mobile App (iOS or Android)

## Installation

1. Download the app from Garmin Connect IQ Store (when published)
2. Or sideload using Connect IQ SDK

## Configuration

### Step 1: Configure Server Settings

**Important**: Settings must be configured through Garmin Connect Mobile App, not on the watch.

1. Open **Garmin Connect Mobile** app on your phone
2. Select your device (e.g., Venu 2)
3. Go to **Activities & Apps** → **Activities, Apps & More**
4. Find **yumusic** in the list
5. Tap on **yumusic** → **Settings**
6. Configure the following:

   **Server URL**
   - Full URL including protocol and port
   - Examples:
     - `http://192.168.1.100:4533` (local network)
     - `https://music.yourdomain.com` (internet)
   - Do NOT add `/rest` or any path - just the base URL

   **Username**
   - Your server username

   **Password**
   - Your server password

7. Tap **Save** or **Done**

### Step 2: Test Connection

1. On your watch, open **yumusic** app
2. Navigate to **Sync Settings**
3. Press **SELECT** button to test connection
4. You should see:
   - ✓ Success! (orange) if connection works
   - ✗ Failed (red) if there's an issue

### Step 3: Download Music

1. From the main menu, select **Sync**
2. The app will download songs from your server
3. By default, it downloads 20 random songs
4. Wait for sync to complete

### Step 4: Play Music

1. From the main menu, select **Playback**
2. Choose music source:
   - **Random Songs**: Play downloaded random tracks
   - **Playlists**: Select from your server playlists
   - **Artists**: Browse by artist
   - **Albums**: Browse by album
   - **Search**: Search for music
3. Press **SELECT** to start playback
4. Use watch controls to play/pause, skip, etc.

## Features

### Dark Theme
- Pure black background (AMOLED optimized)
- Orange accent colors (#FF6600)
- High contrast for outdoor visibility

### Download Management
- Music downloads to watch storage
- No streaming - all playback is offline
- Scrobbling support (marks songs as played)
- Star/favorite support (thumbs up/down)

### Round Display Optimization
- Optimized for circular displays
- Proper text centering
- No text cutoff issues
- Works on 416x416 screens (Venu 2)

## Troubleshooting

### Connection Issues

**"Connection Failed"**
- Verify server URL is correct
- Ensure port number is included
- Check server is running and accessible
- Try accessing server URL in a web browser first
- Ensure watch has WiFi or phone connection

**"Not Configured"**
- Settings must be entered in Garmin Connect Mobile
- Restart Garmin Connect app after entering settings
- Sync watch with phone

### Download Issues

**"Download Failed"**
- Check watch storage space
- Ensure stable WiFi connection
- Verify server has music files
- Try downloading fewer songs

### Playback Issues

**"No Music Found"**
- Complete a sync first
- Check that downloads completed successfully
- Try syncing again

## Network Configuration

### Local Network (Home WiFi)
```
Server URL: http://192.168.1.100:4533
```
- Watch must be on same WiFi network
- Or connected to phone via Bluetooth

### Internet Access (Remote)
```
Server URL: https://music.yourdomain.com
```
- Requires HTTPS for security
- Server must be publicly accessible
- Consider VPN for better security

## Storage Management

- Downloaded music uses watch storage
- Monitor available space
- Delete old downloads before syncing new music
- Typical song size: 3-10 MB

## API Compatibility

- Supports Subsonic API version 1.16.1
- Compatible with:
  - Navidrome (all versions)
  - Gonic (all versions)
  - AirSonic (all versions)
  - Subsonic (6.0+)

## Support

For issues, please check:
1. This setup guide
2. DOWNLOAD_INFO.md for download details
3. GitHub issues page
4. Garmin Developer Forums

## Privacy

- Credentials stored securely on watch
- No data sent to third parties
- All communication direct to your server
- Open source - review code on GitHub
