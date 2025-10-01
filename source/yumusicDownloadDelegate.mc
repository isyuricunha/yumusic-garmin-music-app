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
    private var _downloadedCount as Number;

    function initialize(view as yumusicDownloadView, playlistId as String, playlistName as String) {
        BehaviorDelegate.initialize();
        _view = view;
        _playlistId = playlistId;
        _playlistName = playlistName;
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        _library = new MusicLibrary();
        _songs = [] as Array<Dictionary>;
        _downloadedCount = 0;
        
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

    // Process songs (in Garmin system, this prepares them for streaming)
    private function processSongs() as Void {
        var totalSongs = _songs.size();
        
        // Simulate download progress by showing each song
        for (var i = 0; i < _songs.size(); i++) {
            var song = _songs[i];
            var title = song.hasKey("title") ? song["title"] : "Unknown";
            
            // Update progress
            _view.updateProgress(i + 1, totalSongs, title as String);
            
            // In a real download scenario, we would call Communications.makeWebRequest here
            // But Garmin's Audio Content Provider streams on demand, so we just queue them
        }
        
        // Mark as complete
        _view.setComplete();
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
