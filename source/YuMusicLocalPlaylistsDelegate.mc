import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.Media;

class YuMusicLocalPlaylistsDelegate extends WatchUi.Menu2InputDelegate {
    private var _library as YuMusicLibrary;
    private var _timer as Timer.Timer?;

    function initialize() {
        Menu2InputDelegate.initialize();
        _library = new YuMusicLibrary();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == null || id.equals("empty")) {
            return;
        }

        // Set the current playlist
        var playlistId = id as String;
        _library.setCurrentPlaylist(playlistId);
        
        try {
            // Tell the OS to cleanly exit configuration and transition to the music player
            Media.startPlayback(null);
        } catch (ex) {
            // Fallback for older devices/firmwares if startPlayback fails
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            _timer = new Timer.Timer();
            _timer.start(method(:triggerSecondPop), 200, false);
        }
    }

    function triggerSecondPop() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
