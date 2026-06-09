import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicSyncDelegate extends Communications.SyncDelegate {
    private var _library as YuMusicLibrary;
    private var _api as YuMusicBackend;
    private var _serverConfig as YuMusicServerConfig;
    private var _songsToDownload as Array = [];
    private var _currentDownloadIndex as Number = 0;
    private var _downloadedCount as Number = 0;
    private var _failedCount as Number = 0;
    private var _firstFailureCode as Number? = null;
    private var _lastProgress as Number = -1;
    private var _downloadFallbackAttempted as Boolean = false;

    function initialize() {
        SyncDelegate.initialize();
        _library = new YuMusicLibrary();
        _api = new YuMusicBackend();
        _serverConfig = new YuMusicServerConfig();
    }

    // Called when the system starts a sync of the app.
    // The app should begin to download songs chosen in the configure
    // sync view.
    function onStartSync() as Void {
        _songsToDownload = _library.getPendingSongs();
        _currentDownloadIndex = 0;
        _downloadedCount = 0;
        _failedCount = 0;
        _firstFailureCode = null;
        _lastProgress = -1;
        _downloadFallbackAttempted = false;

        System.println("sync onStartSync songs: " + _songsToDownload.size().toString());

        if (_songsToDownload.size() == 0 && _library.getScrobbleQueue().size() == 0) {
            Communications.notifySyncComplete("No songs selected");
            return;
        }

        // Configure API
        var config = _serverConfig.getConfig();
        if (!_api.configure(config)) {
            // Server not configured
            Communications.notifySyncComplete("Server not configured");
            return;
        }

        _api.prepare(method(:onBackendPrepared));
    }

    function onBackendPrepared(success as Boolean, error as String?) as Void {
        if (!success) {
            Communications.notifySyncComplete(error != null ? error : "Server authentication failed");
            return;
        }

        flushNextScrobble();
    }

    // Sequentially flush the next offline scrobble
    private function flushNextScrobble() as Void {
        var scrobbles = _library.getScrobbleQueue();
        if (scrobbles.size() > 0) {
            System.println("sync flushing offline scrobble, " + scrobbles.size().toString() + " remaining");
            var item = scrobbles[0] as Dictionary;
            var id = item["id"] as String?;
            var time = item["time"] as Number?;
            if (id != null) {
                _api.scrobble(id, time, method(:onScrobbleFlushed));
            } else {
                // Invalid data, just remove it and continue
                _library.removeFirstScrobble();
                flushNextScrobble();
            }
        } else {
            // Queue empty, proceed to download songs
            downloadNextSong();
        }
    }

    // Callback when a single offline scrobble flush completes
    function onScrobbleFlushed(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (_api.isResponseSuccessful(responseCode, data)) {
            System.println("sync scrobble flush successful");
            // Remove the successfully uploaded scrobble
            _library.removeFirstScrobble();
            // Process the next one
            flushNextScrobble();
        } else {
            System.println("sync scrobble flush failed: " + responseCode.toString());
            // Give up for now, proceed to download songs to not block sync
            downloadNextSong();
        }
    }

    // Download the next song in the queue
    private function downloadNextSong() as Void {
        if (_currentDownloadIndex >= _songsToDownload.size()) {
            _library.refreshPlaylistReadiness();
            if (_downloadedCount == 0 && _failedCount > 0) {
                var message = "Sync failed";
                if (_firstFailureCode != null) {
                    message += ": " + _api.formatTransportError(_firstFailureCode);
                }
                Communications.notifySyncComplete(message);
            } else if (_failedCount > 0) {
                Communications.notifySyncComplete("Sync finished with errors (" + _failedCount.toString() + " failed)");
            } else {
                Communications.notifySyncComplete(null);
            }
            return;
        }

        var song = _songsToDownload[_currentDownloadIndex] as Dictionary?;
        if (song == null) {
            notifyCurrentSongProgress(1.0);
            _currentDownloadIndex++;
            downloadNextSong();
            return;
        }

        var songId = song["id"] as String?;
        if (songId == null) {
            recordFailure(0);
            notifyCurrentSongProgress(1.0);
            _currentDownloadIndex++;
            downloadNextSong();
            return;
        }

        var url = _api.getDownloadUrl(song);
        if (url.length() == 0) {
            recordFailure(0);
            notifyCurrentSongProgress(1.0);
            _currentDownloadIndex++;
            downloadNextSong();
            return;
        }

        System.println("sync download song index " + _currentDownloadIndex.toString());
        _downloadFallbackAttempted = false;
        notifyCurrentSongProgress(0.0);
        startDownloadRequest(url);
    }

    private function startDownloadRequest(url as String) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => Media.ENCODING_MP3
        };

        Communications.makeWebRequest(
            url,
            {},
            options,
            method(:onSongDownloaded)
        );
    }

    // Callback when a song is downloaded
    function onSongDownloaded(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (responseCode == 200) {
            var song = _songsToDownload[_currentDownloadIndex] as Dictionary?;
            var persistedContent = extractPersistedContent(data);
            var persistedIdNumber = persistedContent != null
                ? persistedContent.getId() as Number?
                : null;
            if (song == null || persistedIdNumber == null) {
                System.println("sync download response had no persisted content id");
                if (persistedContent != null) {
                    persistedContent.remove();
                }
                if (tryFallbackDownload(song, "no persisted content")) {
                    return;
                }
                failCurrentSong(-1005);
                return;
            }

            song["downloaded"] = true;
            song["contentRefId"] = persistedIdNumber;
            _library.saveSong(song);
            System.println("sync downloaded persisted id: " + persistedIdNumber.toString());
            _downloadedCount++;
            notifyCurrentSongProgress(1.0);

            // Move to next song
            _currentDownloadIndex++;
            downloadNextSong();
        } else {
            System.println("sync download failed responseCode: " + responseCode.toString());
            var song = _songsToDownload[_currentDownloadIndex] as Dictionary?;
            if (isRetriableDownloadFailure(responseCode) && tryFallbackDownload(song, "response " + responseCode.toString())) {
                return;
            }
            failCurrentSong(responseCode);
        }
    }

    private function extractPersistedContent(data as Dictionary or String or PersistedContent.Iterator or PersistedContent.Content or Null) as PersistedContent.Content? {
        var content = data as PersistedContent.Content?;
        if (content != null) {
            return content;
        }

        var iterator = data as PersistedContent.Iterator?;
        return iterator != null ? iterator.next() : null;
    }

    function readPersistedContentId(data as Dictionary or String or PersistedContent.Iterator or PersistedContent.Content or Null) as Number? {
        var content = extractPersistedContent(data);
        return content != null ? content.getId() as Number? : null;
    }

    function calculateSyncProgress(currentIndex as Number, totalCount as Number, fileProgress as Float) as Number {
        if (totalCount <= 0) {
            return 100;
        }

        var boundedIndex = currentIndex;
        if (boundedIndex < 0) {
            boundedIndex = 0;
        } else if (boundedIndex > totalCount) {
            boundedIndex = totalCount;
        }

        var boundedFileProgress = fileProgress;
        if (boundedFileProgress < 0.0) {
            boundedFileProgress = 0.0;
        } else if (boundedFileProgress > 1.0) {
            boundedFileProgress = 1.0;
        }

        var progress = ((boundedIndex.toFloat() + boundedFileProgress) / totalCount.toFloat()) * 100;
        var progressNumber = progress.toNumber();
        if (progressNumber < 0) {
            return 0;
        }
        if (progressNumber > 100) {
            return 100;
        }
        return progressNumber;
    }

    private function notifyCurrentSongProgress(fileProgress as Float) as Void {
        notifySyncProgress(calculateSyncProgress(
            _currentDownloadIndex,
            _songsToDownload.size(),
            fileProgress
        ));
    }

    private function notifySyncProgress(progress as Number) as Void {
        if (progress != _lastProgress) {
            _lastProgress = progress;
            Communications.notifySyncProgress(progress);
        }
    }

    private function recordFailure(responseCode as Number) as Void {
        if (_firstFailureCode == null) {
            _firstFailureCode = responseCode;
        }
        _failedCount++;
    }

    private function failCurrentSong(responseCode as Number) as Void {
        recordFailure(responseCode);
        notifyCurrentSongProgress(1.0);
        _currentDownloadIndex++;
        downloadNextSong();
    }

    private function isRetriableDownloadFailure(responseCode as Number) as Boolean {
        return responseCode == 0
            || responseCode == -1002
            || responseCode == -1005;
    }

    private function tryFallbackDownload(song as Dictionary?, reason as String) as Boolean {
        if (_downloadFallbackAttempted || song == null) {
            return false;
        }

        var fallbackUrl = _api.getFallbackDownloadUrl(song);
        if (fallbackUrl.length() == 0) {
            return false;
        }

        _downloadFallbackAttempted = true;
        System.println("sync retrying download with fallback URL: " + reason);
        startDownloadRequest(fallbackUrl);
        return true;
    }

    // Called by the system to determine if the app needs to be synced.
    function isSyncNeeded() as Boolean {
        return _library.getPendingSongs().size() > 0
            || _library.getScrobbleQueue().size() > 0;
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        Communications.cancelAllRequests();
        Communications.notifySyncComplete("Sync cancelled");
    }
}
