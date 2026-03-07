import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConfigureSyncDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as YuMusicConfigureSyncView?;

    function initialize() {
        Menu2InputDelegate.initialize();
        _view = null;
    }

    function setView(view as YuMusicConfigureSyncView) as Void {
        _view = view;
    }

    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId();
        if (playlistId == null || playlistId.equals("loading") || playlistId.equals("error") || playlistId.equals("empty")) {
            return;
        }

        // When a playlist is selected, load the songs via the existing playlist menu logic.
        // We will just create a mock menu item to trigger YuMusicPlaylistMenuDelegate correctly.
        var playlistDelegate = new YuMusicPlaylistMenuDelegate();
        playlistDelegate.onSelect(item);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
