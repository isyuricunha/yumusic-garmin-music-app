import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// View for server configuration
class YuMusicServerConfigView extends WatchUi.View {
    private var _serverConfig as YuMusicServerConfig;
    private var _serverUrl as String = "";
    private var _username as String = "";
    private var _password as String = "";
    private var _currentField as Number = 0; // 0=url, 1=username, 2=password
    private var _message as String?;

    function initialize() {
        View.initialize();
        _serverConfig = new YuMusicServerConfig();
        
        // Load existing config if available
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        if (serverUrl != null) {
            _serverUrl = serverUrl;
        }
        var username = config["username"] as String?;
        if (username != null) {
            _username = username;
        }
        var password = config["password"] as String?;
        if (password != null) {
            _password = password;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var width = dc.getWidth();
        var centerX = width / 2;
        var y = 30;

        // Draw title
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, "Server Config", Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        // Draw instructions
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_TINY, "Configure via Garmin Connect", Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        // Draw current configuration status
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        if (_serverConfig.isConfigured()) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, "Configured", Graphics.TEXT_JUSTIFY_CENTER);
            y += 30;
            
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_TINY, "Server: " + _serverUrl, Graphics.TEXT_JUSTIFY_CENTER);
            y += 25;
            dc.drawText(centerX, y, Graphics.FONT_TINY, "User: " + _username, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, "Not Configured", Graphics.TEXT_JUSTIFY_CENTER);
            y += 40;
            
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_TINY, "Open Garmin Connect", Graphics.TEXT_JUSTIFY_CENTER);
            y += 25;
            dc.drawText(centerX, y, Graphics.FONT_TINY, "to set up server", Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Draw message if any
        if (_message != null) {
            y += 40;
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_TINY, _message, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function setMessage(message as String) as Void {
        _message = message;
        WatchUi.requestUpdate();
    }

    function getServerUrl() as String {
        return _serverUrl;
    }

    function getUsername() as String {
        return _username;
    }

    function getPassword() as String {
        return _password;
    }
}
