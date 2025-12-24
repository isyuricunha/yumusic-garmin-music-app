import Toybox.WatchUi;
import Toybox.Lang;

// Delegate for server configuration view
class YuMusicServerConfigDelegate extends WatchUi.BehaviorDelegate {
    private var _view as YuMusicServerConfigView;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = new YuMusicServerConfigView();
        _serverConfig = new YuMusicServerConfig();
    }

    function setView(view as YuMusicServerConfigView) as Void {
        _view = view;
    }

    // Handle select button
    function onSelect() as Boolean {
        if (_serverConfig.isConfigured()) {
            _view.cycleField();
        } else {
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
