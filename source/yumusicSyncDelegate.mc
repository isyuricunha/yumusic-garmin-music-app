import Toybox.Communications;
import Toybox.Lang;
import Toybox.Media;

class YuMusicSyncDelegate extends Communications.SyncDelegate {
    private var _library as YuMusicLibrary;
    private var _api as YuMusicSubsonicAPI;
    private var _serverConfig as YuMusicServerConfig;
    private var _songsToDownload as Array = [];
    private var _currentDownloadIndex as Number = 0;
    private var _syncInProgress as Boolean = false;

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
        _syncInProgress = true;
        _songsToDownload = _library.getSongs();
        _currentDownloadIndex = 0;

        if (_songsToDownload.size() == 0) {
            // No songs to download
            Communications.notifySyncComplete(null);
            _syncInProgress = false;
            return;
        }

        // Configure API
        var config = _serverConfig.getConfig();
        if (config["serverUrl"] != null) {
            _api.configure(config["serverUrl"], config["username"], config["password"]);
        } else {
            // Server not configured
            Communications.notifySyncComplete("Server not configured");
            _syncInProgress = false;
            return;
        }

        // Start downloading songs
        downloadNextSong();
    }

    // Download the next song in the queue
    private function downloadNextSong() as Void {
        if (_currentDownloadIndex >= _songsToDownload.size()) {
            // All songs downloaded
            Communications.notifySyncComplete(null);
            _syncInProgress = false;
            return;
        }

        var song = _songsToDownload[_currentDownloadIndex];
        var url = song["url"];

        // Download options
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_URL_ENCODED
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
    function onSongDownloaded(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null) {
            // Song downloaded successfully
            var song = _songsToDownload[_currentDownloadIndex];
            
            // Store the downloaded audio data
            // In a real implementation, this would save to device storage
            // For now, we'll just mark it as downloaded
            song["downloaded"] = true;
            
            // Move to next song
            _currentDownloadIndex++;
            downloadNextSong();
        } else {
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
            if (!songs[i].hasKey("downloaded") || songs[i]["downloaded"] == false) {
                return true;
            }
        }

        return false;
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        _syncInProgress = false;
        Communications.cancelAllRequests();
        Communications.notifySyncComplete("Sync cancelled");
    }
}
