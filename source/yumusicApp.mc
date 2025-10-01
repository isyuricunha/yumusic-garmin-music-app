import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;
import Toybox.WatchUi;

class yumusicApp extends Application.AudioContentProviderApp {
    private var _library as MusicLibrary;
    private var _settings as SettingsManager;
    private var _api as SubsonicAPI;

    function initialize() {
        AudioContentProviderApp.initialize();
        _library = new MusicLibrary();
        _settings = new SettingsManager();
        _api = new SubsonicAPI();
        
        // Configure API if settings exist
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Get a Media.ContentDelegate for use by the system to get and iterate through media on the device
    function getContentDelegate(arg as PersistableType) as ContentDelegate? {
        var delegate = new yumusicContentDelegate();
        delegate.setLibrary(_library);
        return delegate;
    }

    // Get a delegate that communicates sync status to the system for syncing media content to the device
    function getSyncDelegate() as Communications.SyncDelegate? {
        return new yumusicSyncDelegate();
    }

    // Get the initial view for configuring playback
    function getPlaybackConfigurationView() as [Views] or [Views, InputDelegates] {
        var view = new yumusicConfigurePlaybackView();
        var delegate = new yumusicConfigurePlaybackDelegate();
        delegate.setView(view);
        return [ view, delegate ];
    }

    // Get the initial view for configuring sync
    function getSyncConfigurationView() as [Views] or [Views, InputDelegates] {
        var view = new yumusicConfigureSyncView();
        var delegate = new yumusicConfigureSyncDelegate();
        delegate.setView(view);
        return [ view, delegate ];
    }

    // Get the music library
    function getLibrary() as MusicLibrary {
        return _library;
    }

    // Get the settings manager
    function getSettings() as SettingsManager {
        return _settings;
    }

    // Get the API client
    function getAPI() as SubsonicAPI {
        return _api;
    }
}

function getApp() as yumusicApp {
    return Application.getApp() as yumusicApp;
}