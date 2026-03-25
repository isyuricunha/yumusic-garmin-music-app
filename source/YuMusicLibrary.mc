import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Media;

// Module to manage music library and downloaded songs
class YuMusicLibrary {
    private const SONGS_KEY = "songs";
    private const PLAYLISTS_KEY = "playlists";
    private const CURRENT_PLAYLIST_KEY = "currentPlaylist";
    private const SHUFFLE_KEY = "shuffle";
    private const LAST_PLAYED_CONTENT_REF_ID_KEY = "lastPlayedContentRefId";
    private const SCROBBLES_KEY = "scrobbles";

    function initialize() {
    }

    private function hashStringToNumber(value as String) as Number {
        var bytes = value.toUtf8Array();
        var hash = 0;

        for (var i = 0; i < bytes.size(); i++) {
            var b = bytes[i] as Number?;
            if (b == null) {
                b = bytes[i].toString().toNumber();
            }

            if (b != null) {
                hash = ((hash * 31) + b) & 0x7FFFFFFF;
            }
        }

        if (hash == 0) {
            hash = 1;
        }

        return hash;
    }

    function computeContentRefId(songId as String) as Number {
        return hashStringToNumber(songId);
    }

    private function safe_number(value as Object) as Number? {
        try {
            return value as Number?;
        } catch (ex) {
            return null;
        }
    }

    // Save songs to library
    function saveSongs(songs as Array) as Void {
        Storage.setValue(SONGS_KEY, songs as Array<Application.PropertyValueType>);
    }

    function saveSelectedSongsPreservingDownloads(selectedSongs as Array, playlistId as String) as Void {
        var existingSongs = Storage.getValue(SONGS_KEY) as Array?;
        if (existingSongs == null) {
            for (var i = 0; i < selectedSongs.size(); i++) {
                var s = selectedSongs[i] as Dictionary?;
                if (s != null) {
                    s["playlistId"] = playlistId;
                }
            }
            saveSongs(selectedSongs);
            return;
        }

        var existingById = {};
        for (var i = 0; i < existingSongs.size(); i++) {
            var existingSong = existingSongs[i] as Dictionary?;
            if (existingSong == null) {
                continue;
            }
            var existingId = existingSong["id"] as String?;
            if (existingId == null) {
                continue;
            }
            existingById[existingId] = existingSong;
        }

        var mergedSongs = [];
        for (var j = 0; j < selectedSongs.size(); j++) {
            var song = selectedSongs[j] as Dictionary?;
            if (song == null) {
                continue;
            }
            var songId = song["id"] as String?;
            if (songId == null) {
                continue;
            }

            song["playlistId"] = playlistId;

            var existing = existingById.hasKey(songId) ? existingById[songId] as Dictionary? : null;
            if (existing != null) {
                if (existing.hasKey("downloaded")) {
                    song["downloaded"] = existing["downloaded"];
                }

                if (existing.hasKey("contentRefId")) {
                    var rawExistingContentRefId = existing["contentRefId"];
                    if (rawExistingContentRefId != null) {
                        var existingContentRefIdNumber = safe_number(rawExistingContentRefId);
                        if (existingContentRefIdNumber != null) {
                            song["contentRefId"] = rawExistingContentRefId;
                        }
                    }
                }
            }

            mergedSongs.add(song);
            existingById.remove(songId);
        }

        var keys = existingById.keys();
        for (var k = 0; k < keys.size(); k++) {
            var key = keys[k];
            var oldSong = existingById[key] as Dictionary?;
            if (oldSong != null) {
                var pId = oldSong["playlistId"] as String?;
                if (pId != null && !pId.equals(playlistId)) {
                    mergedSongs.add(oldSong);
                }
            }
        }

        saveSongs(mergedSongs);
    }

    // Get all songs from library
    function getSongs() as Array {
        var songs = Storage.getValue(SONGS_KEY) as Array?;
        if (songs == null) {
            return [];
        }

        var changed = false;
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }

            if (song.hasKey("contentRefId")) {
                var rawContentRefId = song["contentRefId"];
                if (rawContentRefId != null) {
                    // Persisted media ids must be numeric. If a String is stored here, it's legacy/invalid.
                    if (rawContentRefId instanceof String) {
                        song.remove("contentRefId");
                        song["downloaded"] = false;
                        changed = true;
                    }

                    var contentRefIdNumber = safe_number(rawContentRefId);
                    if (contentRefIdNumber != null) {
                        // Valid numeric persisted id, keep as-is
                    } else {
                        song.remove("contentRefId");
                        song["downloaded"] = false;
                        changed = true;
                    }
                } else {
                    song.remove("contentRefId");
                    song["downloaded"] = false;
                    changed = true;
                }
            }

            if (song.hasKey("duration")) {
                var rawDuration = song["duration"];
                if (rawDuration != null) {
                    var durationNumber = rawDuration as Number?;
                    if (durationNumber == null) {
                        var durationString = rawDuration as String?;
                        if (durationString != null) {
                            durationNumber = durationString.toNumber();
                            song["duration"] = durationNumber;
                            changed = true;
                        }
                    }
                }
            }
        }

        if (changed) {
            saveSongs(songs);
        }
        return songs;
    }

    // Add a single song to library
    function addSong(song as Dictionary) as Void {
        var songs = getSongs();
        songs.add(song);
        saveSongs(songs);
    }

    // Remove a song from library
    function removeSong(songId as String) as Void {
        var songs = getSongs();
        var newSongs = [];
        
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            var id = song["id"] as String?;
            if (id == null || !id.equals(songId)) {
                newSongs.add(song);
            }
        }
        
        saveSongs(newSongs);
    }

    // Clear all songs
    function clearSongs() as Void {
        Storage.deleteValue(SONGS_KEY);
    }

    // Get song by ID
    function getSongById(songId as String) as Dictionary? {
        var songs = getSongs();
        
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            var id = song["id"] as String?;
            if (id != null && id.equals(songId)) {
                return song;
            }
        }
        
        return null;
    }

    // Save playlists
    function savePlaylists(playlists as Array) as Void {
        Storage.setValue(PLAYLISTS_KEY, playlists as Array<Application.PropertyValueType>);
    }

    // Save a newly downloaded playlist metadata, keeping old ones
    function saveDownloadedPlaylist(playlist as Dictionary) as Void {
        var playlists = getPlaylists();
        var newPlaylists = [];
        var playlistId = playlist["id"] as String?;
        
        for (var i = 0; i < playlists.size(); i++) {
            var p = playlists[i] as Dictionary?;
            if (p != null) {
                var pId = p["id"] as String?;
                if (pId != null && !pId.equals(playlistId)) {
                    newPlaylists.add(p);
                }
            }
        }
        newPlaylists.add(playlist);
        savePlaylists(newPlaylists);
    }

    // Get all playlists
    function getPlaylists() as Array {
        var playlists = Storage.getValue(PLAYLISTS_KEY) as Array?;
        if (playlists == null) {
            return [];
        }
        return playlists;
    }

    // Set current playlist
    function setCurrentPlaylist(playlistId as String) as Void {
        Storage.setValue(CURRENT_PLAYLIST_KEY, playlistId);
    }

    // Get current playlist
    function getCurrentPlaylist() as String? {
        return Storage.getValue(CURRENT_PLAYLIST_KEY) as String?;
    }

    // Set shuffle mode
    function setShuffle(enabled as Boolean) as Void {
        Storage.setValue(SHUFFLE_KEY, enabled);
    }

    // Get shuffle mode
    function getShuffle() as Boolean {
        var shuffle = Storage.getValue(SHUFFLE_KEY) as Boolean?;
        return shuffle != null && shuffle;
    }

    function setLastPlayedContentRefId(contentRefId as Object) as Void {
        var number = safe_number(contentRefId);
        if (number == null) {
            return;
        }
        Storage.setValue(LAST_PLAYED_CONTENT_REF_ID_KEY, number);
    }

    function getLastPlayedContentRefId() as Number? {
        var raw = Storage.getValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
        if (raw == null) {
            return null;
        }
        return safe_number(raw);
    }

    // Create Media.Content object from song data
    function createMediaContent(song as Dictionary) as Media.Content? {
        var contentRefId = null;
        if (song.hasKey("contentRefId")) {
            var rawContentRefId = song["contentRefId"];
            if (rawContentRefId != null) {
                contentRefId = safe_number(rawContentRefId);
            }
        }
        if (contentRefId == null) {
            return null;
        }
        var contentRef = new Media.ContentRef(contentRefId, Media.CONTENT_TYPE_AUDIO);
        var content = Media.getCachedContentObj(contentRef);

        var metadata = content.getMetadata();
        if (metadata != null) {
            var title = song.hasKey("title") ? song["title"] as String? : null;
            if (title != null) {
                metadata.title = title;
            }

            var artist = song.hasKey("artist") ? song["artist"] as String? : null;
            if (artist != null) {
                metadata.artist = artist;
            }

            var album = song.hasKey("album") ? song["album"] as String? : null;
            if (album != null) {
                metadata.album = album;
            }
        }

        return content;
    }

    // Find a song by the ContentRef ID used by playback (typically the stream/download URL)
    function getSongByContentRefId(contentRefId as Object) as Dictionary? {
        var contentRefNumber = safe_number(contentRefId);
        var contentRefString = null;
        try {
            contentRefString = contentRefId as String?;
        } catch (ex) {
            contentRefString = null;
        }
        var songs = getSongs();
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }

            if (contentRefNumber != null) {
                var storedNumber = null;
                if (song.hasKey("contentRefId")) {
                    var rawStoredNumber = song["contentRefId"];
                    if (rawStoredNumber != null) {
                        storedNumber = safe_number(rawStoredNumber);
                    }
                }
                if (storedNumber != null && storedNumber == contentRefNumber) {
                    return song;
                }
            }

            if (contentRefString != null) {
                var storedString = null;
                if (song.hasKey("contentRefId")) {
                    try {
                        storedString = song["contentRefId"] as String?;
                    } catch (ex) {
                        storedString = null;
                    }
                }
                if (storedString != null && storedString.equals(contentRefString)) {
                    return song;
                }
                var url = song.hasKey("url") ? song["url"] as String? : null;
                if (url != null && url.equals(contentRefString)) {
                    return song;
                }
            }
        }
        return null;
    }

    // Get total library size
    function getLibrarySize() as Number {
        return getSongs().size();
    }

    // Check if library is empty
    function isEmpty() as Boolean {
        return getLibrarySize() == 0;
    }

    // Get library statistics
    function getStats() as Dictionary {
        var songs = getSongs();
        var totalDuration = 0;
        
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            var duration = song.hasKey("duration") ? song["duration"] as Number? : null;
            if (duration != null) {
                totalDuration += duration;
            }
        }

        return {
            "songCount" => songs.size(),
            "totalDuration" => totalDuration,
            "playlistCount" => getPlaylists().size()
        };
    }

    // --- Offline Scrobble Queue ---

    // Get all pending scrobbles
    function getScrobbleQueue() as Array {
        var scrobbles = Storage.getValue(SCROBBLES_KEY) as Array?;
        if (scrobbles == null) {
            return [];
        }
        return scrobbles;
    }

    // Add a scrobble to the offline queue
    function queueScrobble(songId as String, timestamp as Number) as Void {
        var queue = getScrobbleQueue();
        queue.add({
            "id" => songId,
            "time" => timestamp
        });
        Storage.setValue(SCROBBLES_KEY, queue as Array<Application.PropertyValueType>);
    }

    // Clear the offline scrobble queue (usually called after completely successful upload)
    function clearScrobbleQueue() as Void {
        Storage.deleteValue(SCROBBLES_KEY);
    }

    // Remove only the first item from the queue (for sequential processing)
    function removeFirstScrobble() as Void {
        var queue = getScrobbleQueue();
        if (queue.size() > 0) {
            queue = queue.slice(1, null);
            Storage.setValue(SCROBBLES_KEY, queue as Array<Application.PropertyValueType>);
        }
    }
}
