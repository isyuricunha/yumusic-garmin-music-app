import Toybox.WatchUi;
import Toybox.Lang;

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
        
        if (id == :shuffle) {
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
        }
    }

    // Handle back button
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
