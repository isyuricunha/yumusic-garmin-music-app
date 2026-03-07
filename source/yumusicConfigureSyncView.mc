import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// Native Menu2 for configuring songs to sync.
class YuMusicConfigureSyncView extends WatchUi.Menu2 {
    private var _serverConfig as YuMusicServerConfig;
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _playlists as Array?;
    private var _fetching as Boolean = false;

    private var _itemCount as Number = 0;

    function initialize() {
        Menu2.initialize({:title => "Add Music"});
        _serverConfig = new YuMusicServerConfig();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
    }

    function onShow() as Void {
        if (_fetching || _playlists != null) {
            return;
        }

        if (!_serverConfig.isConfigured()) {
            addSingleItem("Error", "Server not configured", "error");
            return;
        }

        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        if (serverUrl == null || username == null || password == null) {
            addSingleItem("Error", "Server not configured", "error");
            return;
        }

        _api.configure(serverUrl, username, password);
        
        _fetching = true;
        addSingleItem("Loading...", "Please wait", "loading");

        Communications.checkWifiConnection(method(:onWifiChecked));
    }

    private function addSingleItem(label as String, subLabel as String, id as String) as Void {
        clearItems();
        addItem(new WatchUi.MenuItem(label, subLabel, id, {}));
        _itemCount = 1;
    }

    private function clearItems() as Void {
        while(_itemCount > 0) {
            deleteItem(0);
            _itemCount--;
        }
    }

    function onWifiChecked(result as { :wifiAvailable as Boolean, :errorCode as Communications.WifiConnectionStatus }) as Void {
        try {
            var wifiAvailable = result[:wifiAvailable];
            if (!wifiAvailable) {
                _fetching = false;
                var errorCode = result[:errorCode] as Number;
                addSingleItem("Error", "Wi-Fi not available (" + errorCode.toString() + ")", "error");
                WatchUi.requestUpdate();
                return;
            }

            _api.getPlaylists(method(:onPlaylistsReceived));
        } catch (ex) {
            _fetching = false;
            addSingleItem("Error", "Wi-Fi check failed", "error");
            WatchUi.requestUpdate();
        }
    }

    function onPlaylistsReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        _fetching = false;

        var dict = data as Dictionary?;
        if (responseCode == 200 && dict != null) {
            var subsonic = dict["subsonic-response"] as Dictionary?;
            if (subsonic != null) {
                var playlistsContainer = subsonic["playlists"] as Dictionary?;
                var playlists = playlistsContainer != null ? _api.ensureArray(playlistsContainer["playlist"]) : null;
                if (playlists != null && playlists.size() > 0) {
                    _playlists = playlists;
                    _library.savePlaylists(playlists);
                    
                    // Populate menu items
                    clearItems();
                    for (var i = 0; i < playlists.size(); i++) {
                        var playlist = playlists[i] as Dictionary?;
                        if (playlist == null) {
                            continue;
                        }
                        var name = playlist["name"] as String?;
                        var id = playlist["id"] as String?;
                        var songCount = playlist["songCount"] as Number?;
                        if (name != null && id != null) {
                            var subtitle = (songCount != null ? songCount.toString() : "0") + " songs";
                            addItem(new WatchUi.MenuItem(name, subtitle, id, {}));
                            _itemCount++;
                        }
                    }
                } else {
                    addSingleItem("No playlists", "No playlists found on server", "empty");
                }
            } else {
                addSingleItem("Error", "Invalid response", "error");
            }
        } else {
            addSingleItem("Error", "Failed to load (" + responseCode.toString() + ")", "error");
        }
        
        WatchUi.requestUpdate();
    }

    function getPlaylists() as Array? {
        return _playlists;
    }
}
