import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Media;

// Delegate for playback settings menu
class YuMusicPlaybackMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        Menu2InputDelegate.initialize();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
    }

    // Handle menu item selection
    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        
        if (id == :selectPlaylist) {
            if (!_serverConfig.isConfigured()) {
                var errorView = new YuMusicConfirmView("Error", "Server not configured");
                WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            var view = new YuMusicConfigureSyncView();
            var delegate = new YuMusicConfigureSyncDelegate();
            delegate.setView(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        } else if (id == :syncNow) {
            if (!_serverConfig.isConfigured()) {
                var errorView = new YuMusicConfirmView("Error", "Server not configured");
                WatchUi.pushView(errorView, new YuMusicConfirmDelegate(false), WatchUi.SLIDE_LEFT);
                return;
            }

            Media.startSync();
        } else if (id == :shuffle) {
            // Toggle shuffle
            _library.setShuffle(!_library.getShuffle());
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :clear) {
            // Clear library
            _library.clearSongs();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :server) {
            // Show server configuration
            var serverView = new YuMusicServerConfigView();
            var serverDelegate = new YuMusicServerConfigDelegate();
            serverDelegate.setView(serverView);
            WatchUi.pushView(serverView, serverDelegate, WatchUi.SLIDE_LEFT);
        } else if (id == :testConnection) {
            var view = new YuMusicConnectionTestView();
            var delegate = new YuMusicConnectionTestDelegate();
            delegate.setView(view);
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        }
    }

    // Handle back button
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
