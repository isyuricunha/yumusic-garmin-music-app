import Toybox.Application.Storage;
import Toybox.Lang;

// Manager for storing and retrieving app settings
class SettingsManager {
    private const KEY_SERVER_URL = "serverUrl";
    private const KEY_USERNAME = "username";
    private const KEY_PASSWORD = "password";
    private const KEY_CONFIGURED = "configured";
    private const KEY_CURRENT_PLAYLIST = "currentPlaylist";
    private const KEY_SHUFFLE_MODE = "shuffleMode";

    function initialize() {
    }

    // Save server configuration
    function saveServerConfig(serverUrl as String, username as String, password as String) as Void {
        Storage.setValue(KEY_SERVER_URL, serverUrl);
        Storage.setValue(KEY_USERNAME, username);
        Storage.setValue(KEY_PASSWORD, password);
        Storage.setValue(KEY_CONFIGURED, true);
    }

    // Get server URL
    function getServerUrl() as String? {
        return Storage.getValue(KEY_SERVER_URL);
    }

    // Get username
    function getUsername() as String? {
        return Storage.getValue(KEY_USERNAME);
    }

    // Get password
    function getPassword() as String? {
        return Storage.getValue(KEY_PASSWORD);
    }

    // Check if app is configured
    function isConfigured() as Boolean {
        var configured = Storage.getValue(KEY_CONFIGURED);
        return configured != null && configured;
    }

    // Clear all settings
    function clearSettings() as Void {
        Storage.deleteValue(KEY_SERVER_URL);
        Storage.deleteValue(KEY_USERNAME);
        Storage.deleteValue(KEY_PASSWORD);
        Storage.deleteValue(KEY_CONFIGURED);
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
