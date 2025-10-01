import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;

// Delegate for playlist selection menu
class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        Menu2InputDelegate.initialize();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        
        // Configure API
        var config = _serverConfig.getConfig();
        if (config["serverUrl"] != null) {
            _api.configure(config["serverUrl"], config["username"], config["password"]);
        }
    }

    // Handle menu item selection
    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId();
        
        if (playlistId == null) {
            return;
        }
        
        // Load playlist songs
        _api.getPlaylist(playlistId.toString(), method(:onPlaylistReceived));
        
        // Show loading view
        var loadingView = new YuMusicLoadingView("Loading playlist...");
        WatchUi.pushView(loadingView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Callback when playlist details are received
    function onPlaylistReceived(responseCode as Number, data as Dictionary?) as Void {
        // Pop loading view
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        
        if (responseCode == 200 && data != null) {
            if (data.hasKey("subsonic-response")) {
                var response = data["subsonic-response"];
                if (response.hasKey("playlist")) {
                    var playlist = response["playlist"];
                    
                    if (playlist.hasKey("entry")) {
                        var songs = playlist["entry"];
                        
                        // Process songs and prepare for download
                        var processedSongs = [];
                        for (var i = 0; i < songs.size(); i++) {
                            var song = songs[i];
                            var processedSong = {
                                "id" => song["id"],
                                "title" => song["title"],
                                "artist" => song.hasKey("artist") ? song["artist"] : "Unknown",
                                "album" => song.hasKey("album") ? song["album"] : "Unknown",
                                "duration" => song.hasKey("duration") ? song["duration"] : 0,
                                "url" => _api.getDownloadUrl(song["id"]),
                                "streamUrl" => _api.getStreamUrl(song["id"]),
                                "coverArtUrl" => song.hasKey("coverArt") ? _api.getCoverArtUrl(song["coverArt"], 200) : null
                            };
                            processedSongs.add(processedSong);
                        }
                        
                        // Save songs to library
                        _library.saveSongs(processedSongs);
                        _library.setCurrentPlaylist(playlist["id"]);
                        
                        // Show confirmation
                        var confirmView = new YuMusicConfirmView(
                            "Ready to Sync",
                            processedSongs.size() + " songs selected"
                        );
                        WatchUi.pushView(confirmView, new YuMusicConfirmDelegate(), WatchUi.SLIDE_LEFT);
                    } else {
                        showError("Playlist is empty");
                    }
                } else {
                    showError("Invalid playlist data");
                }
            } else {
                showError("Invalid response");
            }
        } else {
            showError("Failed to load playlist");
        }
    }

    // Show error message
    private function showError(message as String) as Void {
        var errorView = new YuMusicConfirmView("Error", message);
        WatchUi.pushView(errorView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Handle back button
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
