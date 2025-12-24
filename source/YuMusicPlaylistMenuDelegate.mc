import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;

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
        
        // Load playlist songs
        _api.getPlaylist(playlistId.toString(), method(:onPlaylistReceived));
        
        // Show loading view
        var loadingView = new YuMusicLoadingView("Loading playlist...");
        WatchUi.pushView(loadingView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Callback when playlist details are received
    function onPlaylistReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        // Pop loading view
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        
        var dict = data as Dictionary?;
        if (responseCode == 200 && dict != null) {
            var response = dict["subsonic-response"] as Dictionary?;
            var playlist = response != null ? response["playlist"] as Dictionary? : null;
            if (playlist != null) {
                var songs = playlist["entry"] as Array?;
                if (songs != null) {
                    
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

                        var coverArtId = song.hasKey("coverArt") ? song["coverArt"] as String? : null;
                        var streamUrl = _api.getStreamUrl(songId);
                        var processedSong = {
                            "id" => songId,
                            "title" => title,
                            "artist" => artist,
                            "album" => album,
                            "duration" => duration != null ? duration : 0,
                            "url" => streamUrl,
                            "streamUrl" => streamUrl
                        };

                        if (coverArtId != null) {
                            processedSong["coverArtUrl"] = _api.getCoverArtUrl(coverArtId, 200);
                        }
                        processedSongs.add(processedSong);
                    }
                    
                    // Save songs to library
                    _library.saveSelectedSongsPreservingDownloads(processedSongs);
                    var playlistId = playlist["id"] as String?;
                    if (playlistId != null) {
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
