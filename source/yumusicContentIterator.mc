import Toybox.Lang;
import Toybox.Graphics;
import Toybox.Media;
import Toybox.System;
import Toybox.WatchUi;

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
            var contentRefId = null;
            if (song.hasKey("contentRefId")) {
                try {
                    contentRefId = song["contentRefId"] as Number?;
                } catch (ex) {
                    contentRefId = null;
                }
            }
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
        } else {
            var lastPlayed = _library.getLastPlayedContentRefId();
            if (lastPlayed != null && _songs.size() > 0) {
                for (var j = 0; j < _songs.size(); j++) {
                    var s = _songs[j] as Dictionary?;
                    if (s == null) {
                        continue;
                    }
                    var id = null;
                    if (s.hasKey("contentRefId")) {
                        try {
                            id = s["contentRefId"] as Number?;
                        } catch (ex) {
                            id = null;
                        }
                    }
                    if (id != null && id == lastPlayed) {
                        _currentIndex = j;
                        break;
                    }
                }
            }
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

        // Use Toybox.Media playback control constants. Using unqualified constants
        // can lead to duplicated/incorrect controls in the native player UI.
        profile.playbackControls = [
            Media.PLAYBACK_CONTROL_NEXT,
            Media.PLAYBACK_CONTROL_SKIP_FORWARD,
            Media.PLAYBACK_CONTROL_PREVIOUS,
            Media.PLAYBACK_CONTROL_SKIP_BACKWARD,
            Media.PLAYBACK_CONTROL_VOLUME,
            new YuMusicMenuButton()
        ];

        profile.playbackNotificationThreshold = 30;
        profile.requirePlaybackNotification = false;
        profile.skipPreviousThreshold = 4;
        return profile;
    }

    // Get the next media content object.
    function next() as Content? {
        if (_songs.size() == 0) {
            return null;
        }

        if (_currentIndex < (_songs.size() - 1)) {
            _currentIndex++;
            return get();
        }

        return null;
    }

    // Get the next media content object without incrementing the iterator.
    function peekNext() as Content? {
        if (_songs.size() == 0) {
            return null;
        }
        
        var nextIndex = _currentIndex + 1;
        if (nextIndex >= _songs.size()) {
            return null;
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
        if (prevIndex < 0) {
            return null;
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

        if (_currentIndex > 0) {
            _currentIndex--;
            return get();
        }

        return null;
    }

    // Determine if playback is currently set to shuffle.
    function shuffling() as Boolean {
        return _shuffle;
    }

}

class YuMusicMenuButton extends Media.CustomButton {
    function initialize() {
        CustomButton.initialize();
    }

    function getState() as Media.ButtonState {
        return Media.BUTTON_STATE_DEFAULT;
    }

    function getText(state as Media.ButtonState) as String? {
        return "menu";
    }

    function getImage(image as Media.ButtonImage, highlighted as Boolean) as WatchUi.BitmapResource or Graphics.BitmapReference or Null {
        return null;
    }
}
