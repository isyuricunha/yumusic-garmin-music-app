import Toybox.Communications;
import Toybox.Media;
import Toybox.Lang;
import Toybox.Application.Storage;

class yumusicSyncDelegate extends Media.SyncDelegate {
    private var _syncList as Array<Dictionary>;
    private var _currentIndex as Number;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;

    function initialize() {
        SyncDelegate.initialize();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        _syncList = [] as Array<Dictionary>;
        _currentIndex = 0;
        
        // Configure API
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
    }

    // Called when the system starts a sync of the app.
    // The app should begin to download songs chosen in the configure
    // sync view.
    function onStartSync() as Void {
        System.println("SyncDelegate: onStartSync called");
        
        if (!_settings.isConfigured()) {
            System.println("SyncDelegate: Not configured");
            Media.notifySyncComplete("Not configured. Please set server URL, username, and password in Garmin Connect Mobile.");
            return;
        }
        
        System.println("SyncDelegate: Configured, fetching songs...");
        
        // Get the selected playlist or songs to download
        var playlistId = _settings.getCurrentPlaylist();
        
        if (playlistId != null) {
            System.println("SyncDelegate: Downloading playlist " + playlistId);
            // Download specific playlist
            _api.getPlaylist(playlistId, method(:onPlaylistResponse));
        } else {
            System.println("SyncDelegate: Downloading random songs");
            // Download random songs as default
            _api.getRandomSongs(20, method(:onRandomSongsResponse));
        }
    }

    // Handle playlist response
    function onPlaylistResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("SyncDelegate: Playlist response - HTTP " + responseCode);
        
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("playlist")) {
                    var playlist = subsonicResponse["playlist"];
                    if (playlist.hasKey("entry")) {
                        var songs = playlist["entry"] as Array;
                        System.println("SyncDelegate: Got " + songs.size() + " songs");
                        _syncList = songs;
                        _currentIndex = 0;
                        syncNextSong();
                        return;
                    }
                }
            }
        }
        System.println("SyncDelegate: Failed to load playlist");
        Media.notifySyncComplete("Failed to load playlist");
    }

    // Handle random songs response
    function onRandomSongsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("SyncDelegate: Random songs response - HTTP " + responseCode);
        
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("randomSongs")) {
                    var randomSongs = subsonicResponse["randomSongs"];
                    if (randomSongs.hasKey("song")) {
                        var songs = randomSongs["song"] as Array;
                        System.println("SyncDelegate: Got " + songs.size() + " random songs");
                        _syncList = songs;
                        _currentIndex = 0;
                        syncNextSong();
                        return;
                    }
                }
            }
        }
        System.println("SyncDelegate: Failed to load songs");
        Media.notifySyncComplete("Failed to load songs");
    }

    // Download next song in the sync list
    private function syncNextSong() as Void {
        if (_currentIndex >= _syncList.size()) {
            System.println("SyncDelegate: All songs synced!");
            Media.notifySyncComplete(null);
            return;
        }
        
        var song = _syncList[_currentIndex];
        var songId = song.hasKey("id") ? song["id"] : null;
        var title = song.hasKey("title") ? song["title"] : "Unknown";
        
        if (songId == null) {
            System.println("SyncDelegate: Song has no ID, skipping");
            _currentIndex++;
            syncNextSong();
            return;
        }
        
        System.println("SyncDelegate: Downloading song " + (_currentIndex + 1) + "/" + _syncList.size() + ": " + title);
        
        // Update progress
        var progress = ((_currentIndex * 100) / _syncList.size());
        Media.notifySyncProgress(progress);
        
        // Get stream URL
        var streamUrl = _api.getStreamUrl(songId as String);
        
        // Download the audio file
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => Media.ENCODING_MP3
        };
        
        System.println("SyncDelegate: Requesting " + streamUrl);
        Communications.makeWebRequest(streamUrl, {}, options, method(:onSongDownloaded));
    }
    
    // Callback when song is downloaded
    function onSongDownloaded(responseCode as Number, data as Media.ContentRef or Null) as Void {
        var song = _syncList[_currentIndex];
        var title = song.hasKey("title") ? song["title"] : "Unknown";
        
        System.println("SyncDelegate: Song download response - HTTP " + responseCode + " for " + title);
        
        if (responseCode == 200 && data != null) {
            System.println("SyncDelegate: Successfully downloaded: " + title);
            // Song is now cached by the system
        } else {
            System.println("SyncDelegate: Failed to download: " + title);
        }
        
        // Move to next song
        _currentIndex++;
        syncNextSong();
    }

    // Called by the system to determine if the app needs to be synced.
    function isSyncNeeded() as Boolean {
        // Return true if configured and user wants to download music
        return _settings.isConfigured();
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        System.println("SyncDelegate: Sync cancelled by user");
        Communications.cancelAllRequests();
        Media.notifySyncComplete("Sync cancelled");
    }
}
