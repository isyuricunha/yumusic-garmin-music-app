import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConfigureSyncDelegate extends WatchUi.BehaviorDelegate {
    private var _view as YuMusicConfigureSyncView?;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = null;
    }

    // Set the view reference
    function setView(view as YuMusicConfigureSyncView) as Void {
        _view = view;
    }

    // Handle select button press
    function onSelect() as Boolean {
        if (_view != null) {
            var playlists = _view.getPlaylists();
            if (playlists != null && playlists.size() > 0) {
                // Push playlist selection menu
                var menu = new WatchUi.Menu2({:title => "Playlists"});
                
                for (var i = 0; i < playlists.size(); i++) {
                    var playlist = playlists[i];
                    menu.addItem(
                        new WatchUi.MenuItem(
                            playlist["name"],
                            playlist["songCount"] + " songs",
                            playlist["id"],
                            {}
                        )
                    );
                }
                
                WatchUi.pushView(menu, new YuMusicPlaylistMenuDelegate(), WatchUi.SLIDE_LEFT);
                return true;
            }
        }
        return false;
    }

    // Handle back button
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
