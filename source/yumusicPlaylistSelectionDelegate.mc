import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;

// Delegate for playlist/album selection
class yumusicPlaylistSelectionDelegate extends WatchUi.BehaviorDelegate {
    private var _view as yumusicPlaylistSelectionView;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;
    private var _library as MusicLibrary;

    function initialize(view as yumusicPlaylistSelectionView) {
        BehaviorDelegate.initialize();
        _view = view;
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        _library = new MusicLibrary();
        
        // Configure API
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
        
        // Load playlists automatically
        loadPlaylists();
    }

    // Load playlists from server
    private function loadPlaylists() as Void {
        if (!_settings.isConfigured()) {
            _view.setError("Not configured");
            return;
        }
        
        _view.setLoading(true);
        _api.getPlaylists(method(:onPlaylistsResponse));
    }

    // Handle playlists response
    function onPlaylistsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                
                // Check for API errors
                if (subsonicResponse.hasKey("status")) {
                    var status = subsonicResponse["status"];
                    if (!status.equals("ok")) {
                        // API returned an error
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
                
                if (subsonicResponse.hasKey("playlists")) {
                    var playlists = subsonicResponse["playlists"];
                    if (playlists.hasKey("playlist")) {
                        var playlistArray = playlists["playlist"] as Array;
                        _view.setItems(playlistArray, "Select Playlist");
                        return;
                    }
                }
            }
        }
        
        // Error handling
        var errorMsg = "Failed to load";
        if (responseCode == 401) {
            errorMsg = "Auth failed\nCheck credentials";
        } else if (responseCode == 404) {
            errorMsg = "Server not found\nCheck URL";
        } else if (responseCode == 0) {
            errorMsg = "No connection\nCheck network";
        } else if (responseCode != 200) {
            errorMsg = "HTTP " + responseCode;
        }
        
        _view.setError(errorMsg);
    }

    // Handle up button - move selection up
    function onPreviousPage() as Boolean {
        _view.moveUp();
        return true;
    }

    // Handle down button - move selection down
    function onNextPage() as Boolean {
        _view.moveDown();
        return true;
    }

    // Handle select button - start downloading selected playlist
    function onSelect() as Boolean {
        var selectedItem = _view.getSelectedItem();
        if (selectedItem != null) {
            // Get playlist ID
            var playlistId = selectedItem.hasKey("id") ? selectedItem["id"] : null;
            var playlistName = selectedItem.hasKey("name") ? selectedItem["name"] : "Unknown";
            
            if (playlistId != null) {
                // Save selected playlist
                _settings.saveCurrentPlaylist(playlistId as String);
                
                // Show download view
                var downloadView = new yumusicDownloadView();
                var downloadDelegate = new yumusicDownloadDelegate(downloadView, playlistId as String, playlistName as String);
                WatchUi.switchToView(downloadView, downloadDelegate, WatchUi.SLIDE_LEFT);
            }
        }
        return true;
    }

    // Handle back button
    function onBack() as Boolean {
        return false; // Allow default back behavior
    }
}
