import Toybox.Lang;
import Toybox.Media;
import Toybox.System;

class YuMusicContentIterator extends Media.ContentIterator {
    private var _library as YuMusicLibrary;
    private var _songs as Array;
    private var _currentIndex as Number = 0;
    private var _shuffle as Boolean = false;

    function initialize() {
        ContentIterator.initialize();
        _library = new YuMusicLibrary();
        var allSongs = _library.getSongs();
        _songs = [];
        for (var i = 0; i < allSongs.size(); i++) {
            var song = allSongs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            var contentRefId = song.hasKey("contentRefId") ? song["contentRefId"] as Number? : null;
            if (contentRefId != null) {
                _songs.add(song);
            }
        }
        _shuffle = _library.getShuffle();

        System.println("contentIterator songs: " + _songs.size().toString());
        if (_songs.size() > 0) {
            var firstSong = _songs[0] as Dictionary?;
            if (firstSong != null) {
                var firstContentRefId = firstSong.hasKey("contentRefId") ? firstSong["contentRefId"] : null;
                if (firstContentRefId != null) {
                    System.println("contentIterator first contentRefId: " + firstContentRefId.toString());
                }
                var firstUrl = firstSong.hasKey("url") ? firstSong["url"] as String? : null;
                if (firstUrl != null) {
                    System.println("contentIterator first url: " + firstUrl);
                }
            }
        }
        
        // If shuffle is enabled, randomize the song order
        if (_shuffle && _songs.size() > 0) {
            shuffleSongs();
        }
    }

    // Shuffle the songs array
    private function shuffleSongs() as Void {
        // Simple Fisher-Yates shuffle
        for (var i = _songs.size() - 1; i > 0; i--) {
            var j = (System.getTimer() % (i + 1)).toNumber();
            var temp = _songs[i];
            _songs[i] = _songs[j];
            _songs[j] = temp;
        }
    }

    // Determine if the the current track can be skipped.
    function canSkip() as Boolean {
        return true;
    }

    // Get the current media content object.
    function get() as Content? {
        if (_songs.size() == 0 || _currentIndex >= _songs.size()) {
            return null;
        }
        
        var song = _songs[_currentIndex] as Dictionary?;
        if (song == null) {
            return null;
        }
        
        return _library.createMediaContent(song);
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
        if (_songs.size() == 0) {
            return null;
        }
        
        _currentIndex++;
        
        // Loop back to beginning if at end
        if (_currentIndex >= _songs.size()) {
            _currentIndex = 0;
        }
        
        return get();
    }

    // Get the next media content object without incrementing the iterator.
    function peekNext() as Content? {
        if (_songs.size() == 0) {
            return null;
        }
        
        var nextIndex = _currentIndex + 1;
        
        // Loop back to beginning if at end
        if (nextIndex >= _songs.size()) {
            nextIndex = 0;
        }
        
        var song = _songs[nextIndex] as Dictionary?;
        if (song == null) {
            return null;
        }
        
        return _library.createMediaContent(song);
    }

    // Get the previous media content object without decrementing the iterator.
    function peekPrevious() as Content? {
        if (_songs.size() == 0) {
            return null;
        }
        
        var prevIndex = _currentIndex - 1;
        
        // Loop to end if at beginning
        if (prevIndex < 0) {
            prevIndex = _songs.size() - 1;
        }
        
        var song = _songs[prevIndex] as Dictionary?;
        if (song == null) {
            return null;
        }
        
        return _library.createMediaContent(song);
    }

    // Get the previous media content object.
    function previous() as Content? {
        if (_songs.size() == 0) {
            return null;
        }
        
        _currentIndex--;
        
        // Loop to end if at beginning
        if (_currentIndex < 0) {
            _currentIndex = _songs.size() - 1;
        }
        
        return get();
    }

    // Determine if playback is currently set to shuffle.
    function shuffling() as Boolean {
        return _shuffle;
    }

}
