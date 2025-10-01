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

    // Handle select button press - test connection
    function onSelect() as Boolean {
        if (_settings.isConfigured()) {
            testConnection();
            return true;
        }
        return false;
    }

    // Test connection to server
    private function testConnection() as Void {
        var serverUrl = _settings.getServerUrl();
        var username = _settings.getUsername();
        var password = _settings.getPassword();

        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password);
            _view.setStatusText("Testing connection...");
            _api.ping(method(:onPingResponse));
        }
    }

    // Handle ping response
    function onPingResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            var response = data as Dictionary;
            if (response.hasKey("subsonic-response")) {
                var subsonicResponse = response["subsonic-response"];
                if (subsonicResponse.hasKey("status") && subsonicResponse["status"].equals("ok")) {
                    _view.setStatusText("Connected!\nReady to sync");
                    return;
                }
            }
        }
        _view.setStatusText("Connection failed\nCheck settings");
    }

    // Handle back button - exit configuration
    function onBack() as Boolean {
        return false; // Allow default back behavior
    }
}
