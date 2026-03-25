import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class YuMusicConfigurePlaybackView extends WatchUi.Menu2 {
    private var _serverConfig as YuMusicServerConfig;
    private var _library as YuMusicLibrary;

    private var _playlistItem as WatchUi.MenuItem;
    private var _shuffleItem as WatchUi.MenuItem;
    private var _serverItem as WatchUi.MenuItem;

    function initialize() {
        Menu2.initialize({:title => "Playback"});
        _serverConfig = new YuMusicServerConfig();
        _library = new YuMusicLibrary();

        _playlistItem = new WatchUi.MenuItem("Select Playlist", "", "selectPlaylist", {});
        addItem(_playlistItem);
        addItem(new WatchUi.MenuItem("Add Music", "Browse server", "addMusic", {}));
        addItem(new WatchUi.MenuItem("Sync Now", null, "syncNow", {}));
        addItem(new WatchUi.MenuItem("Sync Scrobbles", "Upload offline plays", "syncScrobbles", {}));
        addItem(new WatchUi.MenuItem("Test Connection", null, "testConnection", {}));
        
        _shuffleItem = new WatchUi.MenuItem("Enable Shuffle", null, "shuffle", {});
        addItem(_shuffleItem);
        
        addItem(new WatchUi.MenuItem("Clear Library", null, "clear", {}));
        
        _serverItem = new WatchUi.MenuItem("Configure Server", "", "server", {});
        addItem(_serverItem);
    }

    function onShow() as Void {
        var stats = _library.getStats();
        var songCount = stats["songCount"] as Number?;
        if (songCount == null) { songCount = 0; }
        
        var totalDuration = stats["totalDuration"] as Number?;
        if (totalDuration == null) { totalDuration = 0; }
        var minutes = (totalDuration / 60).toNumber();

        var statsText = songCount.toString() + " songs, " + minutes.toString() + " mins";
        _playlistItem.setSubLabel(statsText);
        
        var shuffleText = _library.getShuffle() ? "Disable Shuffle" : "Enable Shuffle";
        _shuffleItem.setLabel(shuffleText);
        
        var serverStatus = _serverConfig.isConfigured() ? "Configured" : "Not configured";
        _serverItem.setSubLabel(serverStatus);
    }
}
