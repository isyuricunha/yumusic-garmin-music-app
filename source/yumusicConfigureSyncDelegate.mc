import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;

class yumusicConfigureSyncDelegate extends WatchUi.BehaviorDelegate {
    private var _view as yumusicConfigureSyncView?;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;

    function initialize() {
        BehaviorDelegate.initialize();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
    }

    // Set the view reference
    function setView(view as yumusicConfigureSyncView) as Void {
        _view = view;
    }

    // Handle up button - move selection up
    function onPreviousPage() as Boolean {
        _view.moveUp();
        return true;
    }

    // Handle down button - move selection down
    function onNextPage() as Boolean {
        _view.moveDown();
        return true;
    }

    // Handle select button press - execute selected option
    function onSelect() as Boolean {
        if (!_settings.isConfigured()) {
            return false;
        }
        
        var selectedIndex = _view.getSelectedIndex();
        
        switch (selectedIndex) {
            case 0: // Browse Playlists
                browsePlaylists();
                break;
            case 1: // Test Connection
                testConnection();
                break;
            case 2: // Settings Info
                showSettingsInfo();
                break;
        }
        
        return true;
    }

    // Browse playlists
    private function browsePlaylists() as Void {
        try {
            var playlistView = new yumusicPlaylistSelectionView();
            var playlistDelegate = new yumusicPlaylistSelectionDelegate(playlistView);
            WatchUi.switchToView(playlistView, playlistDelegate, WatchUi.SLIDE_LEFT);
        } catch (ex) {
            _view.setStatusText("Error loading");
        }
    }
    
    // Show settings info
    private function showSettingsInfo() as Void {
        var serverUrl = _settings.getServerUrl();
        var username = _settings.getUsername();
        
        var info = "Server: ";
        if (serverUrl != null) {
            info += serverUrl;
        } else {
            info += "Not set";
        }
        
        info += "\nUser: ";
        if (username != null) {
            info += username;
        } else {
            info += "Not set";
        }
        
        _view.setStatusText(info);
    }
    
    // Test connection to server
    private function testConnection() as Void {
        var serverUrl = _settings.getServerUrl();
        var username = _settings.getUsername();
        var password = _settings.getPassword();

        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password);
            _view.setStatusText("testing");
            _api.ping(method(:onPingResponse));
        }
    }

    // Handle ping response
    function onPingResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        System.println("ConfigureSyncDelegate: Received ping response - HTTP " + responseCode);
        
        if (responseCode == 200 && data != null) {
            System.println("ConfigureSyncDelegate: Ping successful, data received");
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("status") && subsonicResponse["status"].equals("ok")) {
                    System.println("ConfigureSyncDelegate: Server responded OK");
                    _view.setStatusText("success");
                    return;
                }
            }
        }
        System.println("ConfigureSyncDelegate: Ping failed - HTTP " + responseCode);
        _view.setStatusText("failed");
    }

    // Handle back button - exit configuration
    function onBack() as Boolean {
        return false; // Allow default back behavior
    }
}
