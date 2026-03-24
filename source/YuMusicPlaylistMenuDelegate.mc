import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;

// Delegate for playlist selection menu
class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _loadingPushed as Boolean = false;

    function initialize() {
        Menu2InputDelegate.initialize();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        
        // Configure API
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password);
        }
    }

    // Handle menu item selection
    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId();
        
        if (playlistId == null) {
            return;
        }

        // Show loading view first. On some devices/network failures the web request can
        // invoke the callback very quickly; pushing first avoids popping the wrong view.
        _loadingPushed = true;
        var loadingView = new YuMusicLoadingView("Loading playlist...");
        WatchUi.pushView(loadingView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);

        // Load playlist songs
        _api.getPlaylist(playlistId.toString(), method(:onPlaylistReceived));
    }

    // Callback when playlist details are received
    function onPlaylistReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("getPlaylist responseCode: " + responseCode.toString());

        // Pop loading view (if it was pushed). Guard against popping the menu view
        // in case the callback fires before the view stack updates.
        if (_loadingPushed) {
            _loadingPushed = false;
            try {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            } catch (ex) {
                System.println("pop loading view failed: " + ex.toString());
            }
        }
        
        var dict = data as Dictionary?;
        if (responseCode == 200 && dict != null) {
            var response = dict["subsonic-response"] as Dictionary?;
            var playlist = response != null ? response["playlist"] as Dictionary? : null;
            if (playlist != null) {
                    var songs = _api.ensureArray(playlist["entry"]);
                if (songs != null && songs.size() > 0) {
                    
                    // Process songs and prepare for download
                    var processedSongs = [];
                    for (var i = 0; i < songs.size(); i++) {
                        var song = songs[i] as Dictionary?;
                        if (song == null) {
                            continue;
                        }

                        var songId = song["id"] as String?;
                        var title = song["title"] as String?;
                        if (songId == null || title == null) {
                            continue;
                        }

                        var duration = null;
                        if (song.hasKey("duration")) {
                            var rawDuration = song["duration"];
                            if (rawDuration != null) {
                                duration = rawDuration as Number?;
                                if (duration == null) {
                                    var durationString = rawDuration as String?;
                                    if (durationString != null) {
                                        duration = durationString.toNumber();
                                    }
                                }
                            }
                        }
                        var artist = song.hasKey("artist") ? song["artist"] as String? : null;
                        if (artist == null) {
                            artist = "Unknown";
                        }

                        var album = song.hasKey("album") ? song["album"] as String? : null;
                        if (album == null) {
                            album = "Unknown";
                        }

                        var streamUrl = _api.getStreamUrl(songId);
                        // Keep only the essential fields to minimise the in-memory
                        // footprint. Garmin limits JSON response body sizes and large
                        // playlists can overflow that limit (-402) if extra fields like
                        // coverArtUrl are retained per song.
                        var processedSong = {
                            "id" => songId,
                            "title" => title,
                            "artist" => artist,
                            "album" => album,
                            "duration" => duration != null ? duration : 0,
                            "url" => streamUrl,
                            "streamUrl" => streamUrl
                        };
                        processedSongs.add(processedSong);
                    }
                    
                    var playlistId = playlist["id"] as String?;
                    if (playlistId != null) {
                        // Clean up the playlist object to keep only essential metadata for the list
                        var savedPlaylist = {
                            "id" => playlistId,
                            "name" => playlist.hasKey("name") ? playlist["name"] : "Unnamed",
                            "songCount" => processedSongs.size()
                        };
                        _library.saveDownloadedPlaylist(savedPlaylist);

                        // Save songs to library with the tagged playlistId
                        _library.saveSelectedSongsPreservingDownloads(processedSongs, playlistId);
                        
                        _library.setCurrentPlaylist(playlistId);
                    }
                    
                    // Show confirmation
                    var confirmView = new YuMusicConfirmView(
                        "Ready to Sync",
                        processedSongs.size().toString() + " songs selected"
                    );
                    WatchUi.pushView(confirmView, new YuMusicConfirmDelegate(true), WatchUi.SLIDE_LEFT);
                } else {
                    showError("Playlist is empty");
                }
            } else {
                showError("Invalid playlist data");
            }
        } else if (responseCode == -402) {
            // Garmin response-too-large error: the playlist JSON exceeded the device
            // memory limit. Instruct the user to use fewer songs.
            showError("Playlist too large. Try syncing fewer than 30 songs at a time.");
        } else {
            showError("Failed to load playlist (" + responseCode.toString() + ")");
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
