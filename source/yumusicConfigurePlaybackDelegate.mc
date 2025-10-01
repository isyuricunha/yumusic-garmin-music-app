import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConfigurePlaybackDelegate extends WatchUi.BehaviorDelegate {
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        BehaviorDelegate.initialize();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
    }

    // Handle select button - toggle shuffle or show menu
    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Playback"});
        
        // Add shuffle toggle
        var shuffleText = _library.getShuffle() ? "Disable Shuffle" : "Enable Shuffle";
        menu.addItem(new WatchUi.MenuItem(shuffleText, null, :shuffle, {}));
        
        // Add clear library option
        if (_library.getLibrarySize() > 0) {
            menu.addItem(new WatchUi.MenuItem("Clear Library", null, :clear, {}));
        }
        
        // Add server configuration option
        menu.addItem(new WatchUi.MenuItem("Configure Server", null, :server, {}));
        
        WatchUi.pushView(menu, new YuMusicPlaybackMenuDelegate(), WatchUi.SLIDE_LEFT);
        return true;
    }

    // Handle back button
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
