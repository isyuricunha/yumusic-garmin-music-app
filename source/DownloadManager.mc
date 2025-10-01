import Toybox.Lang;
import Toybox.Communications;
import Toybox.Media;
import Toybox.System;

// Manager for downloading music files from Subsonic/Navidrome server
class DownloadManager {
    private var _api as SubsonicAPI;
    private var _downloadQueue as Array<Dictionary>;
    private var _currentDownload as Dictionary?;
    private var _downloadCallback as Method?;
    private var _isDownloading as Boolean;

    function initialize(api as SubsonicAPI) {
        _api = api;
        _downloadQueue = [] as Array<Dictionary>;
        _currentDownload = null;
        _downloadCallback = null;
        _isDownloading = false;
    }

    // Add song to download queue
    function queueSong(song as Dictionary) as Void {
        _downloadQueue.add(song);
    }

    // Add multiple songs to download queue
    function queueSongs(songs as Array<Dictionary>) as Void {
        for (var i = 0; i < songs.size(); i++) {
            _downloadQueue.add(songs[i]);
        }
    }

    // Get download queue size
    function getQueueSize() as Number {
        return _downloadQueue.size();
    }

    // Clear download queue
    function clearQueue() as Void {
        _downloadQueue = [] as Array<Dictionary>;
    }

    // Start downloading queued songs
    function startDownload(callback as Method) as Void {
        _downloadCallback = callback;
        
        if (_downloadQueue.size() > 0 && !_isDownloading) {
            downloadNext();
        }
    }

    // Download next song in queue
    private function downloadNext() as Void {
        if (_downloadQueue.size() == 0) {
            _isDownloading = false;
            if (_downloadCallback != null) {
                _downloadCallback.invoke(true, "All songs queued");
            }
            return;
        }

        _isDownloading = true;
        _currentDownload = _downloadQueue[0];
        _downloadQueue.remove(_currentDownload);

        var songId = _currentDownload.hasKey("id") ? _currentDownload["id"] : null;
        if (songId == null) {
            downloadNext();
            return;
        }

        // In Garmin's Audio Content Provider system, we don't manually download files.
        // Instead, we create ContentRef objects with valid stream URLs.
        // The system automatically caches audio when it's played.
        // So we just validate the song info and move to the next.
        
        var title = _currentDownload.hasKey("title") ? _currentDownload["title"] : "Unknown";
        
        // Notify progress
        if (_downloadCallback != null) {
            var remaining = _downloadQueue.size();
            _downloadCallback.invoke(false, "Queued: " + title + " (" + remaining + " remaining)");
        }
        
        // Continue with next song
        downloadNext();
    }


    // Stop current download
    function stopDownload() as Void {
        _isDownloading = false;
        Communications.cancelAllRequests();
        if (_downloadCallback != null) {
            _downloadCallback.invoke(false, "Download cancelled");
        }
    }

    // Check if currently downloading
    function isDownloading() as Boolean {
        return _isDownloading;
    }

    // Get current download info
    function getCurrentDownload() as Dictionary? {
        return _currentDownload;
    }
}
