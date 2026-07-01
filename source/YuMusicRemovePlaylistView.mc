import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Graphics;

// View for selecting a locally downloaded playlist to remove
class YuMusicRemovePlaylistView extends WatchUi.Menu2 {
    private var _library as YuMusicLibrary;
    private var _itemCount as Number = 0;

    function initialize() {
        Menu2.initialize({:title => "Remove Playlist"});
        _library = new YuMusicLibrary();
    }

    function onShow() as Void {
        clearItems();
        var playlists = _library.getPlaylists();
        
        if (playlists == null || playlists.size() == 0) {
            addItem(new WatchUi.MenuItem("No Playlists", "Nothing to remove", "empty", {}));
            _itemCount = 1;
            return;
        }

        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist == null) {
                continue;
            }
            var name = playlist["name"] as String?;
            var id = playlist["id"] as String?;
            
            if (name != null && id != null) {
                var subtitle = "Tap to remove";
                addItem(new WatchUi.MenuItem(name, subtitle, id, {}));
                _itemCount++;
            }
        }
    }

    private function clearItems() as Void {
        while(_itemCount > 0) {
            deleteItem(0);
            _itemCount--;
        }
    }
}
