import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// Songs fetched per paginated API request. Kept small so each HTTP response body
// fits within the Garmin JSON response memory limit on all devices.
const PLAYLIST_PAGE_SIZE = 15;

// Delegate for playlist selection menu
class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _loadingPushed as Boolean = false;

    // Paginated-fetch state
    private var _pendingPlaylistId as String?;
    private var _fetchOffset as Number = 0;
    private var _accumulatedSongs as Array = [];

    function initialize() {
        Menu2InputDelegate.initialize();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        
        // Configure API
        var config = _serverConfig.getConfig();
        _api.configure(config);
    }

    // Handle menu item selection
    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId();
        
        if (playlistId == null) {
            return;
        }

        // Show loading view first
        _loadingPushed = true;
        var loadingView = new YuMusicLoadingView("Loading playlist...");
        WatchUi.pushView(loadingView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);

        // Initialise paginated fetch state
        _pendingPlaylistId = playlistId.toString();
        _fetchOffset = 0;
        _accumulatedSongs = [];

        fetchNextPage();
    }

    // Request the next page of songs from the server.
    private function fetchNextPage() as Void {
        if (_pendingPlaylistId == null) {
            return;
        }
        System.println("fetchNextPage offset=" + _fetchOffset.toString());
        _api.getPlaylist(_pendingPlaylistId, _fetchOffset, PLAYLIST_PAGE_SIZE, method(:onPageReceived));
    }

    // Callback for each page received.
    function onPageReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("onPageReceived responseCode=" + responseCode.toString() + " offset=" + _fetchOffset.toString());

        if (responseCode != 200) {
            popLoadingView();
            if (responseCode == -402) {
                // Only reachable when the server ignored pagination params and returned
                // everything at once, still hitting the device memory limit.
                showError("Too many songs.\nKeep under \n30 or 50.");
            } else {
                showError("Failed (" + responseCode.toString() + ")");
            }
            return;
        }

        var dict = data as Dictionary?;
        if (dict == null) {
            popLoadingView();
            showError("Empty response");
            return;
        }

        var response = dict["subsonic-response"] as Dictionary?;
        var playlist = response != null ? response["playlist"] as Dictionary? : null;
        if (playlist == null) {
            popLoadingView();
            showError("Invalid playlist data");
            return;
        }

        var pageSongs = _api.ensureArray(playlist["entry"]);

        // Extract and accumulate only the essential fields per song.
        for (var i = 0; i < pageSongs.size(); i++) {
            var song = pageSongs[i] as Dictionary?;
            if (song == null) { continue; }

            var songId = song["id"] as String?;
            var title = song["title"] as String?;
            if (songId == null || title == null) { continue; }

            var duration = null;
            if (song.hasKey("duration")) {
                var raw = song["duration"];
                if (raw != null) {
                    duration = raw as Number?;
                    if (duration == null) {
                        var s = raw as String?;
                        if (s != null) { duration = s.toNumber(); }
                    }
                }
            }

            var artist = song.hasKey("artist") ? song["artist"] as String? : null;
            if (artist == null) { artist = "Unknown"; }

            var album = song.hasKey("album") ? song["album"] as String? : null;
            if (album == null) { album = "Unknown"; }

            var streamUrl = _api.getStreamUrl(songId);
            _accumulatedSongs.add({
                "id"        => songId,
                "title"     => title,
                "artist"    => artist,
                "album"     => album,
                "duration"  => duration != null ? duration : 0,
                "url"       => streamUrl,
                "streamUrl" => streamUrl
            });
        }

        var pageCount = pageSongs.size();
        System.println("page had " + pageCount.toString() + " songs, total=" + _accumulatedSongs.size().toString());

        // If the server honoured the page size and returned a full page, there may be more.
        // If it returned fewer songs (or zero), we have reached the end.
        // If it returned MORE than PLAYLIST_PAGE_SIZE the server ignored pagination and
        // returned everything in one shot — treat this page as the final page.
        if (pageCount == PLAYLIST_PAGE_SIZE) {
            _fetchOffset += PLAYLIST_PAGE_SIZE;
            fetchNextPage();
            return;
        }

        // All pages received — finalise.
        finaliseFetch(playlist);
    }

    // Called once all pages have been collected.
    private function finaliseFetch(playlistMeta as Dictionary) as Void {
        popLoadingView();

        var songs = _accumulatedSongs;
        if (songs.size() == 0) {
            showError("Playlist is empty");
            return;
        }

        var playlistId = _pendingPlaylistId;
        if (playlistId != null) {
            var savedPlaylist = {
                "id"        => playlistId,
                "name"      => playlistMeta.hasKey("name") ? playlistMeta["name"] : "Unnamed",
                "songCount" => songs.size()
            };
            _library.saveDownloadedPlaylist(savedPlaylist);
            _library.saveSelectedSongsPreservingDownloads(songs, playlistId);
            _library.setCurrentPlaylist(playlistId);
        }

        var confirmView = new YuMusicConfirmView(
            "Ready to Sync",
            songs.size().toString() + " songs selected"
        );
        WatchUi.pushView(confirmView, new YuMusicConfirmDelegate(true), WatchUi.SLIDE_LEFT);
    }

    private function popLoadingView() as Void {
        if (_loadingPushed) {
            _loadingPushed = false;
            try {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            } catch (ex) {
                System.println("pop loading view failed: " + ex.toString());
            }
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
