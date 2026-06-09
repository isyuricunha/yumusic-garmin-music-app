import Toybox.Application.Storage;
import Toybox.Lang;

const YUMUSIC_AUTH_TOKEN = 0;
const YUMUSIC_AUTH_PASSWORD = 1;
const YUMUSIC_AUTH_API_KEY = 2;
const YUMUSIC_BACKEND_SUBSONIC = 0;
const YUMUSIC_BACKEND_JELLYFIN = 1;

// Module to manage server configuration storage
class YuMusicServerConfig {
    private const SERVER_URL_KEY = "serverUrl";
    private const USERNAME_KEY = "username";
    private const PASSWORD_KEY = "password";
    private const MAX_BITRATE_KEY = "maxBitRate";
    private const AUTH_MODE_KEY = "authMode";
    private const BACKEND_TYPE_KEY = "backendType";
    private const CONFIGURED_KEY = "configured";

    function initialize() {
    }

    // Save server configuration
    function saveConfig(serverUrl as String, username as String?, password as String, maxBitRate as String, authMode as Number, backendType as Number) as Void {
        Storage.setValue(SERVER_URL_KEY, serverUrl);
        if (username != null) {
            Storage.setValue(USERNAME_KEY, username);
        } else {
            Storage.deleteValue(USERNAME_KEY);
        }
        Storage.setValue(PASSWORD_KEY, password);
        Storage.setValue(MAX_BITRATE_KEY, maxBitRate);
        Storage.setValue(AUTH_MODE_KEY, authMode);
        Storage.setValue(BACKEND_TYPE_KEY, backendType);
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

    function getAuthMode() as Number {
        var authMode = Storage.getValue(AUTH_MODE_KEY) as Number?;
        return authMode != null ? authMode : YUMUSIC_AUTH_TOKEN;
    }

    function getBackendType() as Number {
        var backendType = Storage.getValue(BACKEND_TYPE_KEY) as Number?;
        return backendType != null ? backendType : YUMUSIC_BACKEND_SUBSONIC;
    }

    // Check if server is configured
    function isConfigured() as Boolean {
        var serverUrl = getServerUrl();
        var password = getPassword();
        var authMode = getAuthMode();
        var backendType = getBackendType();

        if (serverUrl == null || password == null) {
            return false;
        }

        if (backendType == YUMUSIC_BACKEND_JELLYFIN) {
            return getUsername() != null;
        }

        return authMode == YUMUSIC_AUTH_API_KEY || getUsername() != null;
    }

    // Clear all configuration
    function clearConfig() as Void {
        Storage.deleteValue(SERVER_URL_KEY);
        Storage.deleteValue(USERNAME_KEY);
        Storage.deleteValue(PASSWORD_KEY);
        Storage.deleteValue(MAX_BITRATE_KEY);
        Storage.deleteValue(AUTH_MODE_KEY);
        Storage.deleteValue(BACKEND_TYPE_KEY);
        Storage.deleteValue(CONFIGURED_KEY);
    }

    // Get full configuration as dictionary
    function getConfig() as Dictionary {
        return {
            "serverUrl" => getServerUrl(),
            "username" => getUsername(),
            "password" => getPassword(),
            "maxBitRate" => getMaxBitRate(),
            "authMode" => getAuthMode(),
            "backendType" => getBackendType(),
            "configured" => isConfigured()
        };
    }
}
