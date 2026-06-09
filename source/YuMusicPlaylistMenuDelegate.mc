import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicBackend;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _loadingPushed as Boolean = false;
    private var _pendingPlaylistId as String?;

    function initialize() {
        Menu2InputDelegate.initialize();
        _api = new YuMusicBackend();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        _api.configure(_serverConfig.getConfig());
    }

    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId();
        if (playlistId == null) {
            return;
        }

        _loadingPushed = true;
        _pendingPlaylistId = playlistId.toString();
        WatchUi.pushView(
            new YuMusicLoadingView("Loading playlist..."),
            new WatchUi.BehaviorDelegate(),
            WatchUi.SLIDE_LEFT
        );
        _api.getPlaylist(_pendingPlaylistId, method(:onPlaylistReceived));
    }

    function onPlaylistReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var responseError = _api.getResponseError(responseCode, data);
        if (responseError != null) {
            popLoadingView();
            if (responseCode == -402 || responseCode == -403) {
                showError("Playlist too large\nfor this watch\n(" + responseCode.toString() + ")");
            } else {
                showError(responseError);
            }
            return;
        }

        var details = _api.extractPlaylist(data);
        var playlist = details != null ? details["playlist"] as Dictionary? : null;
        var songs = details != null ? details["songs"] as Array? : null;
        if (playlist == null || songs == null) {
            popLoadingView();
            showError("Invalid playlist data");
            return;
        }

        popLoadingView();
        if (songs.size() == 0) {
            showError("Playlist is empty");
            return;
        }

        saveSelection(playlist, songs);
    }

    private function saveSelection(playlist as Dictionary, songs as Array) as Void {
        var playlistId = _pendingPlaylistId;
        if (playlistId == null) {
            showError("Invalid playlist");
            return;
        }

        _library.saveDownloadedPlaylist({
            "id" => playlistId,
            "name" => playlist.hasKey("name") ? playlist["name"] : "Unnamed",
            "songCount" => songs.size(),
            "ready" => false
        });
        _library.saveSelectedSongsPreservingDownloads(songs, playlistId);
        _library.setCurrentPlaylist(playlistId);

        WatchUi.pushView(
            new YuMusicConfirmView("Ready to Sync", songs.size().toString() + " songs selected"),
            new YuMusicConfirmDelegate(true),
            WatchUi.SLIDE_LEFT
        );
    }

    private function popLoadingView() as Void {
        if (!_loadingPushed) {
            return;
        }

        _loadingPushed = false;
        try {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } catch (ex) {
            System.println("pop loading view failed: " + ex.toString());
        }
    }

    private function showError(message as String) as Void {
        WatchUi.pushView(
            new YuMusicConfirmView("Error", message),
            new WatchUi.BehaviorDelegate(),
            WatchUi.SLIDE_LEFT
        );
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
