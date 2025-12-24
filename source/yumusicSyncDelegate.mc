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
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password);
        } else {
            // Server not configured
            Communications.notifySyncComplete("Server not configured");
            return;
        }

        // Start downloading songs
        downloadNextSong();
    }

    // Download the next song in the queue
    private function downloadNextSong() as Void {
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
            _currentDownloadIndex++;
            downloadNextSong();
            return;
        }

        var url = song["url"] as String?;
        if (url == null) {
            _currentDownloadIndex++;
            downloadNextSong();
            return;
        }

        var streamUrl = song.hasKey("streamUrl") ? song["streamUrl"] as String? : null;
        if (streamUrl != null) {
            url = streamUrl;
        }

        System.println("sync download song index " + _currentDownloadIndex.toString() + ": " + url);

        // Download options (audio content provider expects audio responses)
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_AUDIO,
            :mediaEncoding => Media.ENCODING_MP3
        };

        // Make the download request
        Communications.makeWebRequest(
            url,
            null,
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
                song["downloaded"] = true;

                // For HTTP_RESPONSE_CONTENT_TYPE_AUDIO, the response object can provide
                // the persisted media id used by the system media cache.
                var persistedContent = data as PersistedContent.Content?;
                if (persistedContent != null) {
                    var persistedIdNumber = persistedContent.getId() as Number?;
                    if (persistedIdNumber != null) {
                        song["contentRefId"] = persistedIdNumber;
                        System.println("sync downloaded persisted id: " + persistedIdNumber.toString());
                    }
                } else {
                    System.println("sync download response had no persisted content object");
                }
            }

            _library.saveSongs(_songsToDownload);

            _downloadedCount++;

            // Move to next song
            _currentDownloadIndex++;
            downloadNextSong();
        } else {
            System.println("sync download failed responseCode: " + responseCode.toString());
            if (_firstFailureCode == null) {
                _firstFailureCode = responseCode;
            }
            _failedCount++;
            // Download failed, try next song
            _currentDownloadIndex++;
            downloadNextSong();
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
