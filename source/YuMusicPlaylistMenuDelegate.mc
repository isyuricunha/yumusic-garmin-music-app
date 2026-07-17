import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// Delegate for playlist selection menu
class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicBackend?;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _loadingPushed as Boolean = false;

    // Fetch state
    private var _pendingPlaylistId as String?;

    function initialize() {
        Menu2InputDelegate.initialize();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        _api = YuMusicApiFactory.create(_serverConfig.getConfig());
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

        // Initialise fetch state
        _pendingPlaylistId = playlistId.toString();

        fetchNextPage();
    }

    // Request the playlist from the server.
    private function fetchNextPage() as Void {
        if (_pendingPlaylistId == null) {
            return;
        }
        System.println("fetchPlaylist id=" + _pendingPlaylistId);
        _api.getPlaylistNeutral(_pendingPlaylistId, method(:onPageReceived));
    }

    // Callback for playlist received.
    function onPageReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("onPlaylistReceived responseCode=" + responseCode.toString());

        if (responseCode != 200) {
            popLoadingView();
            if (responseCode == -402 || responseCode == -403) {
                // Only reachable when the server ignored pagination params and returned
                // everything at once, still hitting the device memory limit.
                showError("Too many songs.\nKeep under \n30 or 50.");
            } else {
                showError("Failed (" + responseCode.toString() + ")");
            }
            return;
        }

        var result = data as Dictionary?;
        if (result == null) {
            popLoadingView();
            showError("Empty response");
            return;
        }

        var songs = result["songs"] as Array?;
        if (songs == null || songs.size() == 0) {
            popLoadingView();
            showError("Playlist is empty");
            return;
        }

        finaliseFetch(result, songs);
    }

    // Called once playlist has been parsed.
    private function finaliseFetch(playlistMeta as Dictionary, songs as Array) as Void {
        popLoadingView();
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
