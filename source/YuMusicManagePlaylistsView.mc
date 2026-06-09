import Toybox.Lang;
import Toybox.WatchUi;

class YuMusicManagePlaylistsView extends WatchUi.Menu2 {
    private var _library as YuMusicLibrary;
    private var _itemCount as Number = 0;

    function initialize() {
        Menu2.initialize({:title => "Manage Downloads"});
        _library = new YuMusicLibrary();
    }

    function onShow() as Void {
        clearItems();
        var playlists = _library.getPlaylists();
        if (playlists.size() == 0) {
            addItem(new WatchUi.MenuItem("No Playlists", "Nothing to remove", "empty", {}));
            _itemCount = 1;
            return;
        }

        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist == null) {
                continue;
            }

            var playlistId = playlist["id"] as String?;
            var name = playlist["name"] as String?;
            var songCount = playlist["songCount"] as Number?;
            var ready = playlist["ready"] == true;
            if (playlistId == null || name == null) {
                continue;
            }

            var status = ready ? "downloaded" : "pending";
            var count = songCount != null ? songCount : 0;
            addItem(new WatchUi.MenuItem(
                name,
                count.toString() + " songs - " + status,
                playlistId,
                {}
            ));
            _itemCount++;
        }
    }

    private function clearItems() as Void {
        while (_itemCount > 0) {
            deleteItem(0);
            _itemCount--;
        }
    }
}
