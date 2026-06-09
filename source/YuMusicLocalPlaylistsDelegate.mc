import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Media;

class YuMusicLocalPlaylistsDelegate extends WatchUi.Menu2InputDelegate {
    private var _library as YuMusicLibrary;

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
        Media.startPlayback(null);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
