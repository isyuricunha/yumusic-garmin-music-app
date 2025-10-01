import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;

class yumusicConfigurePlaybackDelegate extends WatchUi.BehaviorDelegate {
    private var _view as yumusicConfigurePlaybackView;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;
    private var _library as MusicLibrary;

    function initialize() {
        BehaviorDelegate.initialize();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        _library = new MusicLibrary();
        
        // Configure API with saved settings
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
    }

    // Set the view reference
    function setView(view as yumusicConfigurePlaybackView) as Void {
        _view = view;
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

    // Handle select button - load selected music source
    function onSelect() as Boolean {
        var selectedIndex = _view.getSelectedIndex();
        
        switch (selectedIndex) {
            case 0: // Random Songs
                loadRandomSongs();
                break;
            case 1: // Playlists
                loadPlaylists();
                break;
            case 2: // Artists
                loadArtists();
                break;
            case 3: // Albums
                loadAlbums();
                break;
            case 4: // Search
                // TODO: Implement search functionality
                break;
        }
        
        return true;
    }

    // Load random songs from server
    private function loadRandomSongs() as Void {
        _api.getRandomSongs(50, method(:onRandomSongsResponse));
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
                        _library.setQueue(songs);
                        // Start playback
                        Media.startPlayback(null);
                    }
                }
            }
        }
    }

    // Load playlists from server
    private function loadPlaylists() as Void {
        _api.getPlaylists(method(:onPlaylistsResponse));
    }

    // Handle playlists response
    function onPlaylistsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("playlists")) {
                    var playlists = subsonicResponse["playlists"];
                    if (playlists.hasKey("playlist")) {
                        var playlistArray = playlists["playlist"] as Array;
                        _library.addPlaylists(playlistArray);
                        // TODO: Show playlist selection menu
                    }
                }
            }
        }
    }

    // Load artists from server
    private function loadArtists() as Void {
        _api.getArtists(method(:onArtistsResponse));
    }

    // Handle artists response
    function onArtistsResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("artists")) {
                    var artists = subsonicResponse["artists"];
                    if (artists.hasKey("index")) {
                        var indexes = artists["index"] as Array;
                        // TODO: Process and display artists
                    }
                }
            }
        }
    }

    // Load albums from server
    private function loadAlbums() as Void {
        // Get recent albums
        // TODO: Implement album list retrieval
    }

    // Get the music library
    function getLibrary() as MusicLibrary {
        return _library;
    }
}
