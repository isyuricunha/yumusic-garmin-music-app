import Toybox.Application.Storage;
import Toybox.Lang;

// Module to manage server configuration storage
class YuMusicServerConfig {
    private const SERVER_URL_KEY = "serverUrl";
    private const USERNAME_KEY = "username";
    private const PASSWORD_KEY = "password";
    private const CONFIGURED_KEY = "configured";

    function initialize() {
    }

    // Save server configuration
    function saveConfig(serverUrl as String, username as String, password as String) as Void {
        Storage.setValue(SERVER_URL_KEY, serverUrl);
        Storage.setValue(USERNAME_KEY, username);
        Storage.setValue(PASSWORD_KEY, password);
        Storage.setValue(CONFIGURED_KEY, true);
    }

    // Get server URL
    function getServerUrl() as String? {
        return Storage.getValue(SERVER_URL_KEY);
    }

    // Get username
    function getUsername() as String? {
        return Storage.getValue(USERNAME_KEY);
    }

    // Get password
    function getPassword() as String? {
        return Storage.getValue(PASSWORD_KEY);
    }

    // Check if server is configured
    function isConfigured() as Boolean {
        var configured = Storage.getValue(CONFIGURED_KEY);
        return configured != null && configured == true;
    }

    // Clear all configuration
    function clearConfig() as Void {
        Storage.deleteValue(SERVER_URL_KEY);
        Storage.deleteValue(USERNAME_KEY);
        Storage.deleteValue(PASSWORD_KEY);
        Storage.deleteValue(CONFIGURED_KEY);
    }

    // Get full configuration as dictionary
    function getConfig() as Dictionary {
        return {
            "serverUrl" => getServerUrl(),
            "username" => getUsername(),
            "password" => getPassword(),
            "configured" => isConfigured()
        };
    }
}
