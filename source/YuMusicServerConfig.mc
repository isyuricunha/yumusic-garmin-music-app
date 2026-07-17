import Toybox.Application.Storage;
import Toybox.Lang;

// Module to manage server configuration storage
class YuMusicServerConfig {
    private const SERVER_URL_KEY = "serverUrl";
    private const USERNAME_KEY = "username";
    private const PASSWORD_KEY = "password";
    private const MAX_BITRATE_KEY = "maxBitRate";
    private const LEGACY_AUTH_KEY = "legacyAuth";
    private const CONFIGURED_KEY = "configured";
    private const SERVER_TYPE_KEY = "serverType"; // "subsonic" | "jellyfin"
    private const API_KEY_KEY = "apiKey";

    function initialize() {
    }

    // Save server configuration
    function saveConfig(serverUrl as String, username as String, password as String, maxBitRate as String, legacyAuth as Boolean, serverType as String, apiKey as String) as Void {
        Storage.setValue(SERVER_URL_KEY, serverUrl);
        Storage.setValue(USERNAME_KEY, username);
        Storage.setValue(PASSWORD_KEY, password);
        Storage.setValue(MAX_BITRATE_KEY, maxBitRate);
        Storage.setValue(LEGACY_AUTH_KEY, legacyAuth);
        Storage.setValue(SERVER_TYPE_KEY, serverType);
        Storage.setValue(API_KEY_KEY, apiKey);
        Storage.setValue(CONFIGURED_KEY, true);
    }

    // Get server URL
    function getServerUrl() as String? {
        return Storage.getValue(SERVER_URL_KEY) as String?;
    }

    // Get username
    function getUsername() as String? {
        return Storage.getValue(USERNAME_KEY) as String?;
    }

    // Get password
    function getPassword() as String? {
        return Storage.getValue(PASSWORD_KEY) as String?;
    }

    // Get max bit rate
    function getMaxBitRate() as String? {
        var bitrate = Storage.getValue(MAX_BITRATE_KEY) as String?;
        return bitrate != null ? bitrate : "320"; // Default High Quality
    }

    // Get legacy auth boolean
    function getLegacyAuth() as Boolean {
        var legacyAuth = Storage.getValue(LEGACY_AUTH_KEY) as Boolean?;
        return legacyAuth != null && legacyAuth;
    }

    // Get server type ("subsonic" default, or "jellyfin")
    function getServerType() as String {
        var t = Storage.getValue(SERVER_TYPE_KEY) as String?;
        return (t != null && t.equals("jellyfin")) ? "jellyfin" : "subsonic";
    }

    // Get Jellyfin API key
    function getApiKey() as String? {
        return Storage.getValue(API_KEY_KEY) as String?;
    }

    // Check if server is configured
    function isConfigured() as Boolean {
        var configured = Storage.getValue(CONFIGURED_KEY) as Boolean?;
        return configured != null && configured;
    }

    // Clear all configuration
    function clearConfig() as Void {
        Storage.deleteValue(SERVER_URL_KEY);
        Storage.deleteValue(USERNAME_KEY);
        Storage.deleteValue(PASSWORD_KEY);
        Storage.deleteValue(MAX_BITRATE_KEY);
        Storage.deleteValue(LEGACY_AUTH_KEY);
        Storage.deleteValue(SERVER_TYPE_KEY);
        Storage.deleteValue(API_KEY_KEY);
        Storage.deleteValue(CONFIGURED_KEY);
    }

    // Get full configuration as dictionary
    function getConfig() as Dictionary {
        return {
            "serverUrl" => getServerUrl(),
            "username" => getUsername(),
            "password" => getPassword(),
            "maxBitRate" => getMaxBitRate(),
            "legacyAuth" => getLegacyAuth(),
            "serverType" => getServerType(),
            "apiKey" => getApiKey(),
            "configured" => isConfigured()
        };
    }
}
