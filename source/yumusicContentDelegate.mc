import Toybox.Lang;
import Toybox.Media;
import Toybox.PersistedContent;

// This class handles events from the system's media
// player. getContentIterator() returns an iterator
// that iterates over the songs configured to play.
class YuMusicContentDelegate extends Media.ContentDelegate {
    private var _library as YuMusicLibrary;
    private var _api as YuMusicSubsonicAPI;
    private var _serverConfig as YuMusicServerConfig;

    function initialize() {
        ContentDelegate.initialize();
        _library = new YuMusicLibrary();
        _api = new YuMusicSubsonicAPI();
        _serverConfig = new YuMusicServerConfig();
        
        // Configure API if server is set up
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password);
        }
    }

    // Returns an iterator that is used by the system to play songs.
    // A custom iterator can be created that extends Media.ContentIterator
    // to return only songs chosen in the sync configuration mode.
    function getContentIterator() as ContentIterator? {
        return new YuMusicContentIterator();
    }

    // Respond to a user ad click
    function onAdAction(adContext as Object) as Void {
    }

    // Respond to a thumbs-up action
    function onThumbsUp(contentRefId as Object) as Void {
        // Star the song on the server
        if (contentRefId != null) {
            _api.star(contentRefId.toString(), method(:onStarResponse));
        }
    }

    // Respond to a thumbs-down action
    function onThumbsDown(contentRefId as Object) as Void {
        // Unstar the song on the server
        if (contentRefId != null) {
            _api.unstar(contentRefId.toString(), method(:onUnstarResponse));
        }
    }

    // Respond to a command to turn shuffle on or off
    function onShuffle() as Void {
        // Toggle shuffle mode
        _library.setShuffle(!_library.getShuffle());
    }

    // Handles a notification from the system that an event has
    // been triggered for the given song
    function onSong(contentRefId as Object, songEvent as SongEvent, playbackPosition as Number or PlaybackPosition) as Void {
        // Scrobble the song when it's played
        // Note: We scrobble on any song event to ensure tracking
        if (contentRefId != null) {
            _api.scrobble(contentRefId.toString(), method(:onScrobbleResponse));
        }
    }

    // Callback for star response
    function onStarResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        // Silent success/failure
    }

    // Callback for unstar response
    function onUnstarResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        // Silent success/failure
    }

    // Callback for scrobble response
    function onScrobbleResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        // Silent success/failure
    }
}
