import Toybox.Lang;
import Toybox.WatchUi;

class YuMusicManagePlaylistsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var playlistId = item.getId() as String?;
        if (playlistId == null || playlistId.equals("empty")) {
            return;
        }

        WatchUi.pushView(
            new WatchUi.Confirmation("Remove this playlist?"),
            new YuMusicRemovePlaylistDelegate(playlistId),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
