import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicSyncDelegate extends Communications.SyncDelegate {
    private var _library as YuMusicLibrary;
    private var _api as YuMusicSubsonicAPI;
    private var _serverConfig as YuMusicServerConfig;
    private var _songsToDownload as Array = [];
    private var _currentDownloadIndex as Number = 0;
    private var _downloadedCount as Number = 0;
    private var _failedCount as Number = 0;
    private var _firstFailureCode as Number? = null;

    function initialize() {
        SyncDelegate.initialize();
        _library = new YuMusicLibrary();
        _api = new YuMusicSubsonicAPI();
        _serverConfig = new YuMusicServerConfig();
    }

    // Called when the system starts a sync of the app.
    // The app should begin to download songs chosen in the configure
    // sync view.
    function onStartSync() as Void {
        _songsToDownload = _library.getSongs();
        _currentDownloadIndex = 0;
        _downloadedCount = 0;
        _failedCount = 0;
        _firstFailureCode = null;

        System.println("sync onStartSync songs: " + _songsToDownload.size().toString());

        if (_songsToDownload.size() == 0) {
            // No songs to download
            Communications.notifySyncComplete("No songs selected");
            return;
        }

        // Configure API
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        var maxBitRate = config["maxBitRate"] as String?;
        var legacyAuth = config["legacyAuth"] as Boolean?;
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password, maxBitRate, legacyAuth);
        } else {
            // Server not configured
            Communications.notifySyncComplete("Server not configured");
            return;
        }

        // Flush offline scrobbles before downloading songs
        // Flush offline scrobbles sequentially before downloading songs
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
        if (responseCode == 200) {
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

    private function getDownloadUrlForSong(song as Dictionary?) as String? {
        if (song == null) {
            return null;
        }

        var streamUrl = song.hasKey("streamUrl") ? song["streamUrl"] as String? : null;
        if (streamUrl != null && streamUrl.length() > 0) {
            return streamUrl;
        }

        var url = song.hasKey("url") ? song["url"] as String? : null;
        if (url != null && url.length() > 0) {
            return url;
        }

        var songId = song.hasKey("id") ? song["id"] as String? : null;
        if (songId == null || songId.length() == 0) {
            return null;
        }

        var generatedUrl = _api.getStreamUrl(songId);
        if (generatedUrl.length() == 0) {
            return null;
        }
        return generatedUrl;
    }

    private function recordDownloadFailure(responseCode as Number) as Void {
        if (_firstFailureCode == null) {
            _firstFailureCode = responseCode;
        }
        _failedCount++;
        _currentDownloadIndex++;
        downloadNextSong();
    }

    // Returns the persisted media id in its native form (a Number on real
    // devices). It must not be stringified: Media.ContentRef lookups only
    // match the id type the system handed out.
    private function extractPersistedContentId(data as Object?) as Object? {
        if (data == null) {
            return null;
        }

        if (data instanceof Media.ContentRef) {
            return _library.nativeContentRefId((data as Media.ContentRef).getId());
        }

        if (data instanceof Media.Content) {
            var contentRef = (data as Media.Content).getContentRef();
            if (contentRef != null) {
                return _library.nativeContentRefId(contentRef.getId());
            }
            return null;
        }

        if (data instanceof PersistedContent.Iterator) {
            try {
                var content = (data as PersistedContent.Iterator).next();
                if (content != null) {
                    return _library.nativeContentRefId(content.getId());
                }
            } catch (ex) {
                System.println("sync persisted iterator read failed: " + ex.toString());
            }
            return null;
        }

        if (data has :getId) {
            return _library.nativeContentRefId((data as PersistedContent.Content).getId());
        }

        return null;
    }

    // Download the next song in the queue
    private function downloadNextSong() as Void {
        // Incremental sync: advance past songs that are already persisted
        // in the media cache, so only new tracks get downloaded.
        while (_currentDownloadIndex < _songsToDownload.size()) {
            var candidate = _songsToDownload[_currentDownloadIndex] as Dictionary?;
            if (candidate != null && _library.isSongPersisted(candidate)) {
                System.println("sync skip persisted song index " + _currentDownloadIndex.toString());
                _currentDownloadIndex++;
            } else {
                break;
            }
        }

        if (_currentDownloadIndex >= _songsToDownload.size()) {
            // All songs processed
            if (_downloadedCount == 0 && _failedCount > 0) {
                var message = "Sync failed";
                if (_firstFailureCode != null) {
                    message += " (" + _firstFailureCode.toString() + ")";
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
            recordDownloadFailure(0);
            return;
        }

        var url = getDownloadUrlForSong(song);
        if (url == null) {
            System.println("sync download skipped invalid song at index " + _currentDownloadIndex.toString());
            recordDownloadFailure(0);
            return;
        }

        var songId = song.hasKey("id") ? song["id"] as String? : null;
        System.println("sync download song index " + _currentDownloadIndex.toString() + " id=" + (songId != null ? songId : "unknown"));

        // Download options (audio content provider expects audio responses)
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => Media.ENCODING_MP3
        };

        // Make the download request
        Communications.makeWebRequest(
            url,
            {},
            options,
            method(:onSongDownloaded)
        );

        // Update sync progress
        var progress = (_currentDownloadIndex.toFloat() / _songsToDownload.size().toFloat()) * 100;
        Communications.notifySyncProgress(progress.toNumber());
    }

    // Callback when a song is downloaded
    function onSongDownloaded(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (responseCode == 200) {
            // Song downloaded successfully
            var song = _songsToDownload[_currentDownloadIndex] as Dictionary?;
            if (song != null) {
                // For HTTP_RESPONSE_CONTENT_TYPE_AUDIO, the response object can provide
                // the persisted media id used by the system media cache.
                var persistedId = extractPersistedContentId(data);
                if (persistedId == null) {
                    System.println("sync download response had no persisted content id");
                    recordDownloadFailure(0);
                    return;
                }

                song["downloaded"] = true;
                song["contentRefId"] = persistedId;
                System.println("sync downloaded persisted id: " + persistedId.toString());

                try {
                    _library.saveSong(song);
                } catch (ex) {
                    System.println("sync save song failed: " + ex.toString());
                    Communications.notifySyncComplete("Library save failed");
                    return;
                }
            } else {
                recordDownloadFailure(0);
                return;
            }

            _downloadedCount++;

            // Move to next song
            _currentDownloadIndex++;
            downloadNextSong();
        } else {
            System.println("sync download failed responseCode: " + responseCode.toString());
            recordDownloadFailure(responseCode);
        }
    }

    // Called by the system to determine if the app needs to be synced.
    function isSyncNeeded() as Boolean {
        // Check if there are songs in the library that need to be downloaded
        var songs = _library.getSongs();
        
        if (songs.size() == 0) {
            return false;
        }

        // Check if any songs are not downloaded
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            if (!song.hasKey("downloaded") || song["downloaded"] == false) {
                return true;
            }
        }

        return false;
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        Communications.cancelAllRequests();
        Communications.notifySyncComplete("Sync cancelled");
    }
}
