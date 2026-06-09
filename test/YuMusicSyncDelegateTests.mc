using Toybox.Test;

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
