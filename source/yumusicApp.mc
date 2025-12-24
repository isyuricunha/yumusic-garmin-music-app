import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;
import Toybox.WatchUi;

class YuMusicApp extends Application.AudioContentProviderApp {

    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        AudioContentProviderApp.initialize();
        _serverConfig = new YuMusicServerConfig();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        apply_settings();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    function onSettingsChanged() as Void {
        apply_settings();
        WatchUi.requestUpdate();
    }

    private function apply_settings() as Void {
        var serverUrlRaw = safe_get_property_string("serverUrl");
        var usernameRaw = safe_get_property_string("username");
        var passwordRaw = safe_get_property_string("password");

        // If the app settings haven't been delivered yet, don't overwrite/clear
        // previously stored configuration.
        if (serverUrlRaw == null && usernameRaw == null && passwordRaw == null) {
            return;
        }

        var serverUrl = normalize_setting_string(serverUrlRaw);
        if (serverUrl != null) {
            if (serverUrl.length() > 0 && serverUrl.substring(serverUrl.length() - 1, serverUrl.length()) == "/") {
                serverUrl = serverUrl.substring(0, serverUrl.length() - 1);
            }
        }
        var username = normalize_setting_string(usernameRaw);
        var password = normalize_setting_string(passwordRaw);

        if (serverUrl != null && username != null && password != null) {
            _serverConfig.saveConfig(serverUrl, username, password);
        } else {
            _serverConfig.clearConfig();
        }
    }

    private function normalize_setting_string(value as String?) as String? {
        if (value == null) {
            return null;
        }

        if (value.length() == 0) {
            return null;
        }

        var startIndex = 0;
        var endIndex = value.length();

        while (startIndex < endIndex) {
            var ch = value.substring(startIndex, startIndex + 1);
            if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") {
                startIndex++;
            } else {
                break;
            }
        }

        while (endIndex > startIndex) {
            var ch = value.substring(endIndex - 1, endIndex);
            if (ch == " " || ch == "\t" || ch == "\n" || ch == "\r") {
                endIndex--;
            } else {
                break;
            }
        }

        var trimmedValue = value.substring(startIndex, endIndex) as String?;

        if (trimmedValue == null || trimmedValue.length() == 0) {
            return null;
        }

        return trimmedValue;
    }

    private function safe_get_property_string(key as String) as String? {
        try {
            return Properties.getValue(key) as String?;
        } catch (ex) {
            return null;
        }
    }

    // Get a Media.ContentDelegate for use by the system to get and iterate through media on the device
    function getContentDelegate(arg as Application.PersistableType) as Media.ContentDelegate {
        return new YuMusicContentDelegate();
    }

    // Get a delegate that communicates sync status to the system for syncing media content to the device
    function getSyncDelegate() as Communications.SyncDelegate? {
        return new YuMusicSyncDelegate();
    }

    // Get the initial view for configuring playback
    function getPlaybackConfigurationView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [ new YuMusicConfigurePlaybackView(), new YuMusicConfigurePlaybackDelegate() ];
    }

    // Get the initial view for configuring sync
    function getSyncConfigurationView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new YuMusicConfigureSyncView();
        var delegate = new YuMusicConfigureSyncDelegate();
        delegate.setView(view);
        return [ view, delegate ];
    }

}

function getApp() as YuMusicApp {
    return Application.getApp() as YuMusicApp;
}