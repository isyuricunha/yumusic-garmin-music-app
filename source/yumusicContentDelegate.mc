import Toybox.Lang;
import Toybox.Media;
import Toybox.PersistedContent;
import Toybox.WatchUi;

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
        var maxBitRate = config["maxBitRate"] as String?;
        var legacyAuth = config["legacyAuth"] as Boolean?;
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password, maxBitRate, legacyAuth);
        }
    }

    // Returns an iterator that is used by the system to play songs.
    // A custom iterator can be created that extends Media.ContentIterator
    // to return only songs chosen in the sync configuration mode.
    function getContentIterator() as ContentIterator? {
        return new YuMusicContentIterator();
    }

    // Reset the iterator to the beginning of the current playlist.
    function resetContentIterator() as ContentIterator? {
        return new YuMusicContentIterator();
    }

    // Respond to a user ad click
    function onAdAction(adContext as Object) as Void {
    }

    // Respond to a thumbs-up action
    function onThumbsUp(contentRefId as Object) as Void {
        // Star the song on the server
        if (contentRefId != null) {
            var song = _library.getSongByContentRefId(contentRefId);
            var songId = song != null ? song["id"] as String? : null;
            if (songId != null) {
                _api.star(songId, method(:onStarResponse));
            } else {
                var contentRefString = contentRefId as String?;
                if (contentRefString != null) {
                    _api.star(contentRefString, method(:onStarResponse));
                }
            }
        }
    }

    // Respond to a thumbs-down action
    function onThumbsDown(contentRefId as Object) as Void {
        // Unstar the song on the server
        if (contentRefId != null) {
            var song = _library.getSongByContentRefId(contentRefId);
            var songId = song != null ? song["id"] as String? : null;
            if (songId != null) {
                _api.unstar(songId, method(:onUnstarResponse));
            } else {
                var contentRefString = contentRefId as String?;
                if (contentRefString != null) {
                    _api.unstar(contentRefString, method(:onUnstarResponse));
                }
            }
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
        if (contentRefId != null) {
            _library.setLastPlayedContentRefId(contentRefId);
            var song = _library.getSongByContentRefId(contentRefId);
            var songId = song != null ? song["id"] as String? : null;
            var targetId = songId != null ? songId : (contentRefId as String?);

            if (targetId != null) {
                // Queue scrobble locally to support offline playback
                if (songEvent == Media.SONG_EVENT_COMPLETE) {
                    _library.queueScrobble(targetId, Toybox.Time.now().value());
                    flushNextScrobble();
                }
            }
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

    function flushNextScrobble() as Void {
        var queue = _library.getScrobbleQueue();
        if (queue.size() > 0) {
            var item = queue[0] as Dictionary;
            var id = item["id"] as String?;
            var time = item["time"] as Number?;
            if (id != null) {
                _api.scrobble(id, time, method(:onScrobbleFlushed));
            } else {
                _library.removeFirstScrobble();
                flushNextScrobble();
            }
        }
    }

    function onScrobbleFlushed(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (responseCode == 200) {
            _library.removeFirstScrobble();
            flushNextScrobble();
        }
        // If it fails (like offline -104), queue is left alone for later.
    }
}
