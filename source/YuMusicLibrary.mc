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
                    // Persisted media ids must be numeric. Any String stored here is legacy/invalid.
                    var contentRefIdString = null;
                    try {
                        contentRefIdString = rawContentRefId as String?;
                    } catch (ex) {
                        contentRefIdString = null;
                    }
                    if (contentRefIdString != null) {
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
        
        // Set metadata
        var metadata = new Media.ContentMetadata();
        
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
        
        // Note: duration is not a property of ContentMetadata in this API version
        
        // Create Content with ContentRef and metadata
        var content = new Media.Content(contentRef, metadata);

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
}
