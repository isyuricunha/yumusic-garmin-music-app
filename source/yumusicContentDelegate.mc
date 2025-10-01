import Toybox.Lang;
import Toybox.Media;

// This class handles events from the system's media
// player. getContentIterator() returns an iterator
// that iterates over the songs configured to play.
class yumusicContentDelegate extends Media.ContentDelegate {
    private var _library as MusicLibrary;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;

    function initialize() {
        ContentDelegate.initialize();
        _library = new MusicLibrary();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
    }

    // Set the music library
    function setLibrary(library as MusicLibrary) as Void {
        _library = library;
    }

    // Returns an iterator that is used by the system to play songs.
    // A custom iterator can be created that extends Media.ContentIterator
    // to return only songs chosen in the sync configuration mode.
    function getContentIterator() as ContentIterator? {
        var iterator = new yumusicContentIterator();
        iterator.setLibrary(_library);
        return iterator;
    }

    // Respond to a user ad click
    function onAdAction(adContext as Object) as Void {
    }

    // Respond to a thumbs-up action (star/favorite)
    function onThumbsUp(contentRefId as Object) as Void {
        if (contentRefId != null && _settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
                _api.star(contentRefId.toString(), method(:onStarResponse));
            }
        }
    }

    // Respond to a thumbs-down action (unstar/unfavorite)
    function onThumbsDown(contentRefId as Object) as Void {
        if (contentRefId != null && _settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
                _api.unstar(contentRefId.toString(), method(:onUnstarResponse));
            }
        }
    }

    // Respond to a command to turn shuffle on or off
    function onShuffle() as Void {
        var currentShuffle = _library.isShuffleEnabled();
        _library.setShuffleMode(!currentShuffle);
        _settings.setShuffleMode(!currentShuffle);
    }

    // Handles a notification from the system that an event has
    // been triggered for the given song
    function onSong(contentRefId as Object, songEvent as SongEvent, playbackPosition as Number or PlaybackPosition) as Void {
        // Scrobble when song completes
        if (songEvent == SONG_EVENT_COMPLETE && contentRefId != null && _settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
                _api.scrobble(contentRefId.toString(), method(:onScrobbleResponse));
            }
        }
    }

    // Handle star response
    function onStarResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        // Silent success/failure
    }

    // Handle unstar response
    function onUnstarResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        // Silent success/failure
    }

    // Handle scrobble response
    function onScrobbleResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        // Silent success/failure
    }
}
