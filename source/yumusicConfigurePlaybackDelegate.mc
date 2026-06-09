import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Media;
import Toybox.Communications;
import Toybox.PersistedContent;

class YuMusicConfigurePlaybackDelegate extends WatchUi.Menu2InputDelegate {
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _api as YuMusicSubsonicAPI;

    function initialize() {
        Menu2InputDelegate.initialize();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        _api = new YuMusicSubsonicAPI();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == null) {
            return;
        }
        
        if (id.equals("selectPlaylist")) {
            var view = new YuMusicLocalPlaylistsView();
            var delegate = new YuMusicLocalPlaylistsDelegate();
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (id.equals("addMusic")) {
            if (!_serverConfig.isConfigured()) {
                var errorView = new YuMusicConfirmView("Error", "Server not configured");
                WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            var view = new YuMusicConfigureSyncView();
            var delegate = new YuMusicConfigureSyncDelegate();
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (id.equals("syncNow")) {
            if (!_serverConfig.isConfigured()) {
                var errorView = new YuMusicConfirmView("Error", "Server not configured");
                WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            Communications.startSync();
        } else if (id.equals("syncScrobbles")) {
            if (!_serverConfig.isConfigured()) {
                var errorView = new YuMusicConfirmView("Error", "Server not configured");
                WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            var queue = _library.getScrobbleQueue();
            if (queue.size() == 0) {
                var confirmView = new YuMusicConfirmView("Synced", "No pending scrobbles");
                WatchUi.pushView(confirmView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            var config = _serverConfig.getConfig();
            if (_api.configure(config)) {
                var loadingView = new YuMusicLoadingView("Syncing scrobbles...");
                WatchUi.pushView(loadingView, null, WatchUi.SLIDE_LEFT);
                flushNextScrobble();
            }
        } else if (id.equals("shuffle")) {
            _library.setShuffle(!_library.getShuffle());
            var shuffleText = _library.getShuffle() ? "Disable Shuffle" : "Enable Shuffle";
            item.setLabel(shuffleText);
        } else if (id.equals("manage")) {
            WatchUi.pushView(
                new YuMusicManagePlaylistsView(),
                new YuMusicManagePlaylistsDelegate(),
                WatchUi.SLIDE_LEFT
            );
        } else if (id.equals("clear")) {
            WatchUi.pushView(
                new WatchUi.Confirmation("Clear all downloaded music?"),
                new YuMusicClearLibraryDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id.equals("server")) {
            var serverView = new YuMusicServerConfigView();
            var serverDelegate = new YuMusicServerConfigDelegate();
            serverDelegate.setView(serverView);
            WatchUi.pushView(serverView, serverDelegate, WatchUi.SLIDE_LEFT);
        } else if (id.equals("testConnection")) {
            var view = new YuMusicConnectionTestView();
            var delegate = new YuMusicConnectionTestDelegate();
            delegate.setView(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function flushNextScrobble() as Void {
        var queue = _library.getScrobbleQueue();
        if (queue.size() > 0) {
            var item = queue[0] as Dictionary;
            var id = item["id"] as String?;
            var time = item["time"] as Number?;
            if (id != null) {
                _api.scrobble(id, time, method(:onScrobbleFlushed));
            } else {
                _library.removeFirstScrobble();
                flushNextScrobble();
            }
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // Remove loading view
            var successView = new YuMusicConfirmView("Success", "Scrobbles uploaded");
            WatchUi.pushView(successView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
        }
    }

    function onScrobbleFlushed(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (_api.isResponseSuccessful(responseCode, data)) {
            _library.removeFirstScrobble();
            flushNextScrobble();
        } else {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // Remove loading view
            var error = _api.getResponseError(responseCode, data);
            var msg = "Sync failed (" + (error != null ? error : responseCode.toString()) + ")";
            if (responseCode == -104) {
                msg = "BLE Disconnected";
            }
            var errorView = new YuMusicConfirmView("Error", msg);
            WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
        }
    }
}
