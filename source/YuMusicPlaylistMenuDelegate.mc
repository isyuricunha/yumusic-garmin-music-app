import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// Songs fetched per paginated API request. Kept small so each HTTP response body
// fits within the Garmin JSON response memory limit on all devices.
const PLAYLIST_PAGE_SIZE = 15;

// Delegate for playlist selection menu
class YuMusicPlaylistMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _api as YuMusicSubsonicAPI;
    private var _library as YuMusicLibrary;
    private var _serverConfig as YuMusicServerConfig;
    private var _loadingPushed as Boolean = false;

    // Paginated-fetch state
    private var _pendingPlaylistId as String?;
    private var _fetchOffset as Number = 0;
    private var _accumulatedSongs as Array = [];
    private var _isPodcast as Boolean = false;

    function initialize() {
        Menu2InputDelegate.initialize();
        _api = new YuMusicSubsonicAPI();
        _library = new YuMusicLibrary();
        _serverConfig = new YuMusicServerConfig();
        
        // Configure API
        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        var maxBitRate = config["maxBitRate"] as String?;
        if (serverUrl != null && username != null && password != null) {
            _api.configure(serverUrl, username, password, maxBitRate);
        }
    }

    // Handle menu item selection
    function onSelect(item as MenuItem) as Void {
        var rawId = item.getId() as String?;
        if (rawId == null) {
            return;
        }

        _pendingPlaylistId = rawId;
        _isPodcast = false;
        
        if (rawId.find("podcast_") == 0) {
            _isPodcast = true;
            _pendingPlaylistId = rawId.substring(8, rawId.length());
        }

        // Show loading view first
        _loadingPushed = true;
        var loadingText = _isPodcast ? "Loading episodes..." : "Loading playlist...";
        var loadingView = new YuMusicLoadingView(loadingText);
        WatchUi.pushView(loadingView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);

        // Initialise paginated fetch state
        _fetchOffset = 0;
        _accumulatedSongs = [];

        fetchNextPage();
    }

    // Request the next page of songs from the server.
    private function fetchNextPage() as Void {
        if (_pendingPlaylistId == null) {
            return;
        }
        
        if (_isPodcast) {
            System.println("fetchNextPage (podcast) channelId=" + _pendingPlaylistId);
            // Use getNewestPodcasts (lightweight flat list) instead of getPodcasts?includeEpisodes=true
            // to avoid the -402 memory overflow caused by the heavy channel+episodes wrapper payload.
            // We request more than we need (50) and filter by channelId client side.
            _api.getNewestPodcasts(50, method(:onNewestPodcastsReceived));
        } else {
            System.println("fetchNextPage offset=" + _fetchOffset.toString());
            _api.getPlaylist(_pendingPlaylistId, _fetchOffset, PLAYLIST_PAGE_SIZE, method(:onPageReceived));
        }
    }

    // Callback for each page received.
    function onPageReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("onPageReceived responseCode=" + responseCode.toString() + " offset=" + _fetchOffset.toString());

        if (responseCode != 200) {
            popLoadingView();
            if (responseCode == -402) {
                // Only reachable when the server ignored pagination params and returned
                // everything at once, still hitting the device memory limit.
                showError("Too many songs.\nKeep under \n30 or 50.");
            } else {
                showError("Failed (" + responseCode.toString() + ")");
            }
            return;
        }

        var dict = data as Dictionary?;
        if (dict == null) {
            popLoadingView();
            showError("Empty response");
            return;
        }

        var response = dict["subsonic-response"] as Dictionary?;
        var playlist = response != null ? response["playlist"] as Dictionary? : null;
        if (playlist == null) {
            popLoadingView();
            showError("Invalid playlist data");
            return;
        }

        var pageSongs = _api.ensureArray(playlist["entry"]);

        // Extract and accumulate only the essential fields per song.
        for (var i = 0; i < pageSongs.size(); i++) {
            var song = pageSongs[i] as Dictionary?;
            if (song == null) { continue; }

            var songId = song["id"] as String?;
            var title = song["title"] as String?;
            if (songId == null || title == null) { continue; }

            var duration = null;
            if (song.hasKey("duration")) {
                var raw = song["duration"];
                if (raw != null) {
                    duration = raw as Number?;
                    if (duration == null) {
                        var s = raw as String?;
                        if (s != null) { duration = s.toNumber(); }
                    }
                }
            }

            var artist = song.hasKey("artist") ? song["artist"] as String? : null;
            if (artist == null) { artist = "Unknown"; }

            var album = song.hasKey("album") ? song["album"] as String? : null;
            if (album == null) { album = "Unknown"; }

            var streamUrl = _api.getStreamUrl(songId);
            _accumulatedSongs.add({
                "id"        => songId,
                "title"     => title,
                "artist"    => artist,
                "album"     => album,
                "duration"  => duration != null ? duration : 0,
                "url"       => streamUrl,
                "streamUrl" => streamUrl
            });
        }

        var pageCount = pageSongs.size();
        System.println("page had " + pageCount.toString() + " songs, total=" + _accumulatedSongs.size().toString());

        // If the server honoured the page size and returned a full page, there may be more.
        // If it returned fewer songs (or zero), we have reached the end.
        // If it returned MORE than PLAYLIST_PAGE_SIZE the server ignored pagination and
        // returned everything in one shot — treat this page as the final page.
        if (pageCount == PLAYLIST_PAGE_SIZE) {
            _fetchOffset += PLAYLIST_PAGE_SIZE;
            fetchNextPage();
            return;
        }

        // All pages received — finalise.
        finaliseFetch(playlist);
    }

    // Callback for getNewestPodcasts — filters by the selected channelId client-side.
    // This avoids -402 memory overflows caused by the heavy getPodcasts?includeEpisodes=true payload.
    function onNewestPodcastsReceived(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("onNewestPodcastsReceived responseCode=" + responseCode.toString());

        if (responseCode != 200) {
            popLoadingView();
            if (responseCode == -402) {
                showError("Too many episodes.\nReduce retention\nin Gonic.");
            } else {
                showError("Failed (" + responseCode.toString() + ")");
            }
            return;
        }

        var dict = data as Dictionary?;
        if (dict == null) {
            popLoadingView();
            showError("Empty response");
            return;
        }

        var response = dict["subsonic-response"] as Dictionary?;
        var newestPodcasts = response != null ? response["newestPodcasts"] as Dictionary? : null;
        if (newestPodcasts == null) {
            popLoadingView();
            showError("No podcast data");
            return;
        }

        var episodes = _api.ensureArray(newestPodcasts["episode"]);
        if (episodes.size() == 0) {
            popLoadingView();
            showError("No episodes found");
            return;
        }

        var targetChannelId = _pendingPlaylistId; // e.g. "pd-4"
        var channelTitle = "Podcast";
        
        for (var i = 0; i < episodes.size(); i++) {
            var episode = episodes[i] as Dictionary?;
            if (episode == null) { continue; }

            // Filter only episodes that belong to the selected channel.
            // Fall back to keeping all episodes if channelId is missing from the payload.
            if (targetChannelId != null && episode.hasKey("channelId")) {
                var epChannelId = episode["channelId"] as String?;
                if (epChannelId != null && !epChannelId.equals(targetChannelId)) {
                    continue; // Skip episodes from other channels
                }
            }

            // Episode uses 'streamId' as the playable media ID (may differ from the episode ID)
            var streamId = episode.hasKey("streamId") ? episode["streamId"] as String? : episode["id"] as String?;
            var title = episode["title"] as String?;
            if (streamId == null || title == null) { continue; }

            var duration = null;
            if (episode.hasKey("duration")) {
                var raw = episode["duration"];
                if (raw != null) {
                    duration = raw as Number?;
                    if (duration == null) {
                        var s = raw as String?;
                        if (s != null) { duration = s.toNumber(); }
                    }
                }
            }

            // Use 'artist' field from the episode (it holds the channel name in most servers)
            var artist = episode.hasKey("artist") ? episode["artist"] as String? : "Podcast";
            if (artist == null) { artist = "Podcast"; }
            channelTitle = artist; // Capture for finaliseFetch metadata

            var streamUrl = _api.getStreamUrl(streamId);
            _accumulatedSongs.add({
                "id"        => streamId,
                "title"     => title,
                "artist"    => artist,
                "album"     => "Podcast",
                "duration"  => duration != null ? duration : 0,
                "url"       => streamUrl,
                "streamUrl" => streamUrl
            });
        }

        finaliseFetch({ "name" => channelTitle });
    }

    // Called once all pages have been collected.
    private function finaliseFetch(playlistMeta as Dictionary) as Void {
        popLoadingView();

        var songs = _accumulatedSongs;
        if (songs.size() == 0) {
            showError("Playlist is empty");
            return;
        }

        var playlistId = _pendingPlaylistId;
        if (playlistId != null) {
            // Re-apply prefix when saving to prevent namespace collisions internally
            var saveId = _isPodcast ? ("podcast_" + playlistId) : playlistId;
            var savedPlaylist = {
                "id"        => saveId,
                "name"      => playlistMeta.hasKey("name") ? playlistMeta["name"] : "Unnamed",
                "songCount" => songs.size()
            };
            _library.saveDownloadedPlaylist(savedPlaylist);
            _library.saveSelectedSongsPreservingDownloads(songs, saveId);
            _library.setCurrentPlaylist(saveId);
        }

        var confirmView = new YuMusicConfirmView(
            "Ready to Sync",
            songs.size().toString() + " songs selected"
        );
        WatchUi.pushView(confirmView, new YuMusicConfirmDelegate(true), WatchUi.SLIDE_LEFT);
    }

    private function popLoadingView() as Void {
        if (_loadingPushed) {
            _loadingPushed = false;
            try {
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
            } catch (ex) {
                System.println("pop loading view failed: " + ex.toString());
            }
        }
    }

    // Show error message
    private function showError(message as String) as Void {
        var errorView = new YuMusicConfirmView("Error", message);
        WatchUi.pushView(errorView, new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Handle back button
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
