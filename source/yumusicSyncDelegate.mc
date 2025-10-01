import Toybox.Communications;
import Toybox.Lang;
import Toybox.Application.Storage;

class yumusicSyncDelegate extends Communications.SyncDelegate {
    private var _downloadManager as DownloadManager?;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;

    function initialize() {
        SyncDelegate.initialize();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        
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
        if (!_settings.isConfigured()) {
            Communications.notifySyncComplete("Not configured. Please set server URL, username, and password in Garmin Connect Mobile.");
            return;
        }
        
        // Get the selected playlist or songs to download
        var playlistId = _settings.getCurrentPlaylist();
        
        if (playlistId != null) {
            // Download specific playlist
            _api.getPlaylist(playlistId, method(:onPlaylistResponse));
        } else {
            // Download random songs as default
            _api.getRandomSongs(20, method(:onRandomSongsResponse));
        }
    }

    // Handle playlist response
    function onPlaylistResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("playlist")) {
                    var playlist = subsonicResponse["playlist"];
                    if (playlist.hasKey("entry")) {
                        var songs = playlist["entry"] as Array;
                        startDownload(songs);
                        return;
                    }
                }
            }
        }
        Communications.notifySyncComplete("Failed to load playlist");
    }

    // Handle random songs response
    function onRandomSongsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("randomSongs")) {
                    var randomSongs = subsonicResponse["randomSongs"];
                    if (randomSongs.hasKey("song")) {
                        var songs = randomSongs["song"] as Array;
                        startDownload(songs);
                        return;
                    }
                }
            }
        }
        Communications.notifySyncComplete("Failed to load songs");
    }

    // Start downloading songs
    private function startDownload(songs as Array) as Void {
        _downloadManager = new DownloadManager(_api);
        
        // Queue all songs for download
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i];
            if (song != null) {
                _downloadManager.queueSong(song as Dictionary);
            }
        }
        
        // Start download process
        _downloadManager.startDownload(method(:onDownloadProgress));
    }

    // Handle download progress
    function onDownloadProgress(complete as Boolean, message as String) as Void {
        if (complete) {
            Communications.notifySyncComplete(null);
        }
        // Progress messages can be logged or displayed
    }

    // Called by the system to determine if the app needs to be synced.
    function isSyncNeeded() as Boolean {
        // Return true if configured and user wants to download music
        return _settings.isConfigured();
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        if (_downloadManager != null) {
            _downloadManager.stopDownload();
        }
        Communications.cancelAllRequests();
        Communications.notifySyncComplete("Sync cancelled");
    }
}
