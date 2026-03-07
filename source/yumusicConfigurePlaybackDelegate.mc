import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Media;
import Toybox.Communications;

class YuMusicConfigurePlaybackDelegate extends WatchUi.Menu2InputDelegate {
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        Menu2InputDelegate.initialize();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
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
        } else if (id.equals("shuffle")) {
            _library.setShuffle(!_library.getShuffle());
            var shuffleText = _library.getShuffle() ? "Disable Shuffle" : "Enable Shuffle";
            item.setLabel(shuffleText);
        } else if (id.equals("clear")) {
            _library.clearSongs();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
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
}
