import Toybox.Test;
import Toybox.Lang;
import Toybox.Media;

// Regression tests for the YuMusicContentDelegate media callbacks.
//
// The system media framework delivers a NUMERIC contentRefId (see
// YuMusicLibrary.computeContentRefId -> Number). Casting that Number to String
// (the old `contentRefId as String?` fallback) throws an Unexpected Type Error
// at runtime and crashes the app whenever a media event fires for a song that
// is not present in the local library (e.g. right after launch when the media
// player reports the last-played content and the library is empty).
//
// Each test drives the callback with a numeric contentRefId against an empty
// library and passes only if the callback returns without an uncaught throw.

(:test)
function onSong_numericContentRefId_unknownSong_doesNotThrow(logger as Logger) as Boolean {
    new YuMusicLibrary().clearSongs();
    var delegate = new YuMusicContentDelegate();
    delegate.onSong(123456, Media.SONG_EVENT_COMPLETE, 0);
    return true;
}

(:test)
function onThumbsUp_numericContentRefId_unknownSong_doesNotThrow(logger as Logger) as Boolean {
    new YuMusicLibrary().clearSongs();
    var delegate = new YuMusicContentDelegate();
    delegate.onThumbsUp(123456);
    return true;
}

(:test)
function onThumbsDown_numericContentRefId_unknownSong_doesNotThrow(logger as Logger) as Boolean {
    new YuMusicLibrary().clearSongs();
    var delegate = new YuMusicContentDelegate();
    delegate.onThumbsDown(123456);
    return true;
}
