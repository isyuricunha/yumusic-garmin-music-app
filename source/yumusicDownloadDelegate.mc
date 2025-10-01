import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;

// Delegate for handling playlist download
class yumusicDownloadDelegate extends WatchUi.BehaviorDelegate {
    private var _view as yumusicDownloadView;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;
    private var _library as MusicLibrary;
    private var _playlistId as String;
    private var _playlistName as String;
    private var _songs as Array<Dictionary>;

    function initialize(view as yumusicDownloadView, playlistId as String, playlistName as String) {
        BehaviorDelegate.initialize();
        _view = view;
        _playlistId = playlistId;
        _playlistName = playlistName;
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        _library = new MusicLibrary();
        _songs = [] as Array<Dictionary>;
        
        // Configure API
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
        
        // Set playlist name in view
        _view.setPlaylistName(_playlistName);
        
        // Start loading playlist
        startDownload();
    }

    // Start downloading playlist
    private function startDownload() as Void {
        if (!_settings.isConfigured()) {
            _view.setError("Not configured\nCheck settings");
            return;
        }
        
        // Get playlist details
        _api.getPlaylist(_playlistId, method(:onPlaylistResponse));
    }

    // Handle playlist response
    function onPlaylistResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("DownloadDelegate: Received playlist response - HTTP " + responseCode);
        
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                
                // Check for API errors
                if (subsonicResponse.hasKey("status")) {
                    var status = subsonicResponse["status"];
                    if (!status.equals("ok")) {
                        var errorMsg = "Server error";
                        if (subsonicResponse.hasKey("error")) {
                            var error = subsonicResponse["error"];
                            if (error.hasKey("message")) {
                                errorMsg = error["message"] as String;
                            }
                        }
                        _view.setError(errorMsg);
                        return;
                    }
                }
                
                if (subsonicResponse.hasKey("playlist")) {
                    var playlist = subsonicResponse["playlist"];
                    if (playlist.hasKey("entry")) {
                        _songs = playlist["entry"] as Array<Dictionary>;
                        
                        System.println("DownloadDelegate: Found " + _songs.size() + " songs in playlist");
                        
                        if (_songs.size() == 0) {
                            _view.setError("Playlist is empty");
                            return;
                        }
                        
                        // Add songs to library for playback
                        _library.addSongs(_songs);
                        _library.setQueue(_songs);
                        
                        // Start "downloading" songs (queuing them for streaming)
                        processSongs();
                        return;
                    }
                }
            }
        }
        
        // Error handling
        var errorMsg = "Failed to load\nplaylist";
        if (responseCode == 401) {
            errorMsg = "Auth failed\nCheck credentials";
        } else if (responseCode == 404) {
            errorMsg = "Playlist not found";
        } else if (responseCode == 0) {
            errorMsg = "No connection\nCheck network";
        } else if (responseCode != 200) {
            errorMsg = "HTTP " + responseCode;
        }
        
        _view.setError(errorMsg);
    }

    // Process songs - actually download them via HTTP
    private function processSongs() as Void {
        System.println("DownloadDelegate: Starting to process " + _songs.size() + " songs");
        
        var totalSongs = _songs.size();
        _view.updateProgress(0, totalSongs, "Starting...");
        
        // Create download manager and queue songs
        var downloadManager = new DownloadManager(_api);
        
        for (var i = 0; i < _songs.size(); i++) {
            var song = _songs[i];
            if (song != null) {
                downloadManager.queueSong(song);
            }
        }
        
        // Start downloading songs
        downloadManager.startDownload(method(:onDownloadProgress));
    }
    
    // Handle download progress updates
    function onDownloadProgress(complete as Boolean, message as String) as Void {
        System.println("DownloadDelegate: Download progress - Complete: " + complete + ", Message: " + message);
        
        if (complete) {
            _view.setComplete();
        } else {
            // Parse message to update progress
            // Message format: "Downloading: SongTitle (X remaining)"
            var totalSongs = _songs.size();
            var currentSong = totalSongs; // Default to last
            
            // Try to extract remaining count from message
            if (message.find("remaining") != null) {
                var startIdx = message.find("(");
                var endIdx = message.find(" remaining");
                if (startIdx != null && endIdx != null) {
                    var remainingStr = message.substring(startIdx + 1, endIdx);
                    var remaining = remainingStr.toNumber();
                    if (remaining != null) {
                        currentSong = totalSongs - remaining;
                    }
                }
            }
            
            _view.updateProgress(currentSong, totalSongs, message);
        }
    }

    // Handle back button
    function onBack() as Boolean {
        return false; // Allow default back behavior
    }

    // Handle select button
    function onSelect() as Boolean {
        // If download is complete, go back to allow user to play music
        return false;
    }
}
