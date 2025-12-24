import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// This is the View that is used to configure the songs
// to sync. New pages may be pushed as needed to complete
// the configuration.
class YuMusicConfigureSyncView extends WatchUi.View {
    private var _serverConfig as YuMusicServerConfig;
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _playlists as Array?;
    private var _loading as Boolean = false;
    private var _error as String?;

    function initialize() {
        View.initialize();
        _serverConfig = new YuMusicServerConfig();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConfigureSyncLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        // Check if server is configured
        if (!_serverConfig.isConfigured()) {
            _error = "Server not configured";
            WatchUi.requestUpdate();
            return;
        }

        // Configure API and load playlists
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        if (serverUrl == null || username == null || password == null) {
            _error = "Server not configured";
            WatchUi.requestUpdate();
            return;
        }

        System.println("serverUrl: " + serverUrl);
        System.println("username: " + username);
        _api.configure(serverUrl, username, password);
        
        _loading = true;
        WatchUi.requestUpdate();

        Communications.checkWifiConnection(method(:onWifiChecked));
    }

    function onWifiChecked(result as { :wifiAvailable as Boolean, :errorCode as Communications.WifiConnectionStatus }) as Void {
        try {
            var wifiAvailable = result[:wifiAvailable];
            var errorCode = result[:errorCode];

            System.println("wifiAvailable: " + wifiAvailable.toString());
            var errorCodeNumber = errorCode as Number;
            System.println("wifiErrorCode: " + errorCodeNumber.toString());

            if (!wifiAvailable) {
                _loading = false;
                _error = "Wi-Fi not available (" + errorCodeNumber.toString() + ")";
                WatchUi.requestUpdate();
                return;
            }

            // Load playlists from server
            _api.getPlaylists(method(:onPlaylistsReceived));
        } catch (ex) {
            System.println("wifi check exception: " + ex.toString());
            _loading = false;
            _error = "Wi-Fi check failed";
            WatchUi.requestUpdate();
        }
    }

    // Callback when playlists are received
    function onPlaylistsReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        _loading = false;

        System.println("getPlaylists responseCode: " + responseCode.toString());
        var dataString = data as String?;
        if (dataString != null) {
            System.println("getPlaylists data (string): " + dataString);
        }
 
        var dict = data as Dictionary?;
        if (responseCode == 200 && dict != null) {
            var subsonic = dict["subsonic-response"] as Dictionary?;
            if (subsonic != null) {
                var playlistsContainer = subsonic["playlists"] as Dictionary?;
                var playlists = playlistsContainer != null ? playlistsContainer["playlist"] as Array? : null;
                if (playlists != null) {
                    _playlists = playlists;
                    _library.savePlaylists(playlists);
                    _error = null;
                } else {
                    _error = "No playlists found";
                }
            } else {
                _error = "Invalid response";
            }
        } else {
            _error = "Failed to load playlists (" + responseCode.toString() + ")";
        }
        
        WatchUi.requestUpdate();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = 40;

        // Draw title
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, "Select Music", Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        if (_loading) {
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_error != null) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL, _error, Graphics.TEXT_JUSTIFY_CENTER);
        } else if (_playlists != null && _playlists.size() > 0) {
            dc.drawText(centerX, y, Graphics.FONT_SMALL, _playlists.size().toString() + " playlists", Graphics.TEXT_JUSTIFY_CENTER);
            y += 30;
            dc.drawText(centerX, y, Graphics.FONT_TINY, "Tap to select", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(centerX, height / 2, Graphics.FONT_SMALL, "No playlists", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Get playlists for delegate
    function getPlaylists() as Array? {
        return _playlists;
    }
}
