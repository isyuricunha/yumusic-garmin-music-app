import Toybox.Lang;
import Toybox.Media;

class yumusicContentIterator extends Media.ContentIterator {
    private var _library as MusicLibrary;
    private var _api as SubsonicAPI;
    private var _settings as SettingsManager;

    function initialize() {
        ContentIterator.initialize();
        _library = new MusicLibrary();
        _api = new SubsonicAPI();
        _settings = new SettingsManager();
        
        // Configure API
        if (_settings.isConfigured()) {
            var serverUrl = _settings.getServerUrl();
            var username = _settings.getUsername();
            var password = _settings.getPassword();
            if (serverUrl != null && username != null && password != null) {
                _api.configure(serverUrl, username, password);
            }
        }
    }

    // Set the music library
    function setLibrary(library as MusicLibrary) as Void {
        _library = library;
    }

    // Determine if the the current track can be skipped.
    function canSkip() as Boolean {
        return true;
    }

    // Get the current media content object.
    function get() as Content? {
        var song = _library.getCurrentSong();
        if (song == null) {
            return null;
        }
        return createContentFromSong(song);
    }

    // Get the current media content playback profile
    function getPlaybackProfile() as PlaybackProfile? {
        var profile = new Media.PlaybackProfile();
        profile.attemptSkipAfterThumbsDown = false;
        profile.playbackControls = [
            PLAYBACK_CONTROL_SKIP_BACKWARD,
            PLAYBACK_CONTROL_PLAYBACK,
            PLAYBACK_CONTROL_SKIP_FORWARD
        ];
        profile.playbackNotificationThreshold = 1;
        profile.requirePlaybackNotification = false;
        profile.skipPreviousThreshold = null;
        return profile;
    }

    // Get the next media content object.
    function next() as Content? {
        var song = _library.nextSong();
        if (song == null) {
            return null;
        }
        return createContentFromSong(song);
    }

    // Get the next media content object without incrementing the iterator.
    function peekNext() as Content? {
        var song = _library.peekNext();
        if (song == null) {
            return null;
        }
        return createContentFromSong(song);
    }

    // Get the previous media content object without decrementing the iterator.
    function peekPrevious() as Content? {
        var song = _library.peekPrevious();
        if (song == null) {
            return null;
        }
        return createContentFromSong(song);
    }

    // Get the previous media content object.
    function previous() as Content? {
        var song = _library.previousSong();
        if (song == null) {
            return null;
        }
        return createContentFromSong(song);
    }

    // Determine if playback is currently set to shuffle.
    function shuffling() as Boolean {
        return _library.isShuffleEnabled();
    }

    // Create a Media.Content object from a song dictionary
    private function createContentFromSong(song as Dictionary) as Content? {
        var songId = song.hasKey("id") ? song["id"] : null;
        if (songId == null) {
            return null;
        }

        var streamUrl = _api.getStreamUrl(songId as String);
        
        var content = new Media.Content(streamUrl);
        
        // Set metadata
        if (song.hasKey("title")) {
            content.setMetadata(new Media.ContentMetadata());
            content.getMetadata().title = song["title"];
        }
        
        if (song.hasKey("artist")) {
            if (content.getMetadata() == null) {
                content.setMetadata(new Media.ContentMetadata());
            }
            content.getMetadata().artist = song["artist"];
        }
        
        if (song.hasKey("album")) {
            if (content.getMetadata() == null) {
                content.setMetadata(new Media.ContentMetadata());
            }
            content.getMetadata().album = song["album"];
        }
        
        // Set cover art if available
        if (song.hasKey("coverArt")) {
            var coverArtUrl = _api.getCoverArtUrl(song["coverArt"] as String);
            // Note: Cover art would need to be downloaded separately
            // and set using content.getMetadata().albumArt
        }
        
        return content;
    }
}
