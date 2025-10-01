import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;

// Manager for storing and retrieving app settings
class SettingsManager {
    private const KEY_CURRENT_PLAYLIST = "currentPlaylist";
    private const KEY_SHUFFLE_MODE = "shuffleMode";

    function initialize() {
    }

    // Get server URL from Properties
    function getServerUrl() as String? {
        var url = Properties.getValue("serverUrl");
        if (url != null && url instanceof String && (url as String).length() > 0) {
            return url as String;
        }
        return null;
    }

    // Get username from Properties
    function getUsername() as String? {
        var username = Properties.getValue("username");
        if (username != null && username instanceof String && (username as String).length() > 0) {
            return username as String;
        }
        return null;
    }

    // Get password from Properties
    function getPassword() as String? {
        var password = Properties.getValue("password");
        if (password != null && password instanceof String && (password as String).length() > 0) {
            return password as String;
        }
        return null;
    }

    // Check if app is configured
    function isConfigured() as Boolean {
        var url = getServerUrl();
        var username = getUsername();
        var password = getPassword();
        return url != null && username != null && password != null;
    }

    // Clear all settings
    function clearSettings() as Void {
        Storage.deleteValue(KEY_CURRENT_PLAYLIST);
        Storage.deleteValue(KEY_SHUFFLE_MODE);
    }

    // Save current playlist ID
    function saveCurrentPlaylist(playlistId as String) as Void {
        Storage.setValue(KEY_CURRENT_PLAYLIST, playlistId);
    }

    // Get current playlist ID
    function getCurrentPlaylist() as String? {
        return Storage.getValue(KEY_CURRENT_PLAYLIST);
    }

    // Save shuffle mode
    function setShuffleMode(enabled as Boolean) as Void {
        Storage.setValue(KEY_SHUFFLE_MODE, enabled);
    }

    // Get shuffle mode
    function getShuffleMode() as Boolean {
        var shuffle = Storage.getValue(KEY_SHUFFLE_MODE);
        return shuffle != null && shuffle;
    }
}
