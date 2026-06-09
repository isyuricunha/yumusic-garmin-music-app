using Toybox.Test;
import Toybox.Lang;
import Toybox.System;

class FakePersistedContent {
    private var _id as Number;

    function initialize(id as Number) {
        _id = id;
    }

    function getName() as String {
        return "Fake Content";
    }

    function toIntent() as System.Intent {
        return new System.Intent("fake://content", null);
    }

    function getId() as Number {
        return _id;
    }

    function remove() as Void {
    }
}

(:test)
function syncAcceptsDirectPersistedContentCallback(logger) {
    var delegate = new YuMusicSyncDelegate();
    var id = delegate.readPersistedContentId(new FakePersistedContent(42));

    logger.debug("content id: " + (id != null ? id.toString() : "null"));
    return id == 42;
}

(:test)
function syncProgressIncludesCurrentFileFraction(logger) {
    var delegate = new YuMusicSyncDelegate();
    var halfFirstSong = delegate.calculateSyncProgress(0, 4, 0.5);
    var secondSongStart = delegate.calculateSyncProgress(1, 4, 0.0);
    var finalSongDone = delegate.calculateSyncProgress(3, 4, 1.0);

    logger.debug("half first song: " + halfFirstSong.toString());
    logger.debug("second song start: " + secondSongStart.toString());
    logger.debug("final song done: " + finalSongDone.toString());

    return halfFirstSong >= 12
        && halfFirstSong <= 13
        && secondSongStart == 25
        && finalSongDone == 100;
}

(:test)
function syncProgressClampsInvalidInputs(logger) {
    var delegate = new YuMusicSyncDelegate();

    return delegate.calculateSyncProgress(-1, 4, -0.5) == 0
        && delegate.calculateSyncProgress(4, 4, 1.0) == 100
        && delegate.calculateSyncProgress(0, 0, 0.0) == 100
        && delegate.calculateSyncProgress(1, 4, 2.0) == 50;
}
