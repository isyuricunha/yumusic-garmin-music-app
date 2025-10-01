import Toybox.WatchUi;
import Toybox.Lang;

// Delegate for server configuration view
class YuMusicServerConfigDelegate extends WatchUi.BehaviorDelegate {
    private var _view as YuMusicServerConfigView?;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        BehaviorDelegate.initialize();
        _serverConfig = new YuMusicServerConfig();
    }

    function setView(view as YuMusicServerConfigView) as Void {
        _view = view;
    }

    // Handle select button
    function onSelect() as Boolean {
        // In a real implementation, this would open text input
        // For now, show a message about using Garmin Connect
        if (_view != null) {
            _view.setMessage("Use Garmin Connect app");
        }
        return true;
    }

    // Handle back button
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
