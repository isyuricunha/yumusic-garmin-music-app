import Toybox.Lang;
import Toybox.Media;

class YuMusicContentIterator extends Media.ContentIterator {

    function initialize() {
        ContentIterator.initialize();
    }

    // Determine if the the current track can be skipped.
    function canSkip() as Boolean {
        return false;
    }

    // Get the current media content object.
    function get() as Content? {
        return null;
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
        return null;
    }

    // Get the next media content object without incrementing the iterator.
    function peekNext() as Content? {
        return null;
    }

    // Get the previous media content object without decrementing the iterator.
    function peekPrevious() as Content? {
        return null;
    }

    // Get the previous media content object.
    function previous() as Content? {
        return null;
    }

    // Determine if playback is currently set to shuffle.
    function shuffling() as Boolean {
        return false;
    }

}
