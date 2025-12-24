import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConfigurePlaybackDelegate extends WatchUi.BehaviorDelegate {
    private var _library as YuMusicLibrary;

    function initialize() {
        BehaviorDelegate.initialize();
        _library = new YuMusicLibrary();
    }

    // Handle select button - toggle shuffle or show menu
    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({:title => "Playback"});

        menu.addItem(new WatchUi.MenuItem("Select Playlist", null, :selectPlaylist, {}));
        menu.addItem(new WatchUi.MenuItem("Sync Now", null, :syncNow, {}));
        menu.addItem(new WatchUi.MenuItem("Test Connection", null, :testConnection, {}));
        
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

    // Handle touch tap (Venu 2 is primarily touch)
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        return onSelect();
    }

    // Handle back button
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
