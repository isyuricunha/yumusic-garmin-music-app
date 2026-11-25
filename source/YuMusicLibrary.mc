import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Media;
import Toybox.System;

// Module to manage music library and downloaded songs
class YuMusicLibrary {
    private const SONGS_KEY = "songs";
    private const SONG_IDS_KEY = "songIds";
    private const SONG_STORAGE_VERSION_KEY = "songStorageVersion";
    private const SONG_STORAGE_VERSION = 2;
    private const SONG_KEY_PREFIX = "song:";
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

    private function safe_number(value as Object?) as Number? {
        if (value instanceof Number) {
            return value as Number;
        }
        return null;
    }

    private function safe_string(value as Object?) as String? {
        if (value instanceof String) {
            return value as String;
        }

        var numberValue = safe_number(value);
        if (numberValue != null) {
            return numberValue.toString();
        }

        return null;
    }

    function contentRefIdToString(value as Object?) as String? {
        if (value == null) {
            return null;
        }

        if (value instanceof String) {
            var stringValue = value as String;
            if (stringValue.length() == 0) {
                return null;
            }
            return stringValue;
        }

        var numberValue = safe_number(value);
        if (numberValue != null) {
            return numberValue.toString();
        }

        return null;
    }

    // Garmin hands out persisted media ids as Numbers on real devices, and
    // Media.ContentRef lookups only match when the id is passed back in that
    // same native form. 1.10.1 stored ids as strings ("12345"), which made
    // every Media.getCachedContentObj lookup miss and broke playback. Numeric
    // strings are converted back to Numbers here; any other id is kept as-is.
    function nativeContentRefId(value as Object?) as Object? {
        if (value == null) {
            return null;
        }

        var numberValue = safe_number(value);
        if (numberValue != null) {
            return numberValue;
        }

        if (value instanceof String) {
            var stringValue = value as String;
            if (stringValue.length() == 0) {
                return null;
            }
            var parsed = stringValue.toNumber();
            if (parsed != null && parsed.toString().equals(stringValue)) {
                return parsed;
            }
            return stringValue;
        }

        return null;
    }

    function makeContentRef(value as Object?) as Media.ContentRef? {
        var id = nativeContentRefId(value);
        if (id == null) {
            return null;
        }
        return new Media.ContentRef(id, Media.CONTENT_TYPE_AUDIO);
    }

    private function songStorageKey(songId as String) as String {
        return SONG_KEY_PREFIX + songId;
    }

    private function containsString(values as Array, value as String) as Boolean {
        for (var i = 0; i < values.size(); i++) {
            var existing = safe_string(values[i]);
            if (existing != null && existing.equals(value)) {
                return true;
            }
        }
        return false;
    }

    private function addUniqueString(values as Array, value as String?) as Void {
        if (value == null || value.length() == 0) {
            return;
        }
        if (!containsString(values, value)) {
            values.add(value);
        }
    }

    private function removeString(values as Array, value as String) as Array {
        var kept = [];
        for (var i = 0; i < values.size(); i++) {
            var existing = safe_string(values[i]);
            if (existing != null && !existing.equals(value)) {
                kept.add(existing);
            }
        }
        return kept;
    }

    private function copyPlaylistIds(song as Dictionary?) as Array {
        var playlistIds = [];
        if (song == null) {
            return playlistIds;
        }

        if (song.hasKey("playlists")) {
            var rawPlaylists = song["playlists"];
            if (rawPlaylists instanceof Toybox.Lang.Array) {
                var storedPlaylists = rawPlaylists as Array;
                for (var i = 0; i < storedPlaylists.size(); i++) {
                    addUniqueString(playlistIds, safe_string(storedPlaylists[i]));
                }
            } else {
                addUniqueString(playlistIds, safe_string(rawPlaylists));
            }
        }

        if (song.hasKey("playlistId")) {
            addUniqueString(playlistIds, safe_string(song["playlistId"]));
        }

        return playlistIds;
    }

    private function firstPlaylistId(playlistIds as Array) as String? {
        if (playlistIds.size() == 0) {
            return null;
        }
        return safe_string(playlistIds[0]);
    }

    private function setPlaylistIds(song as Dictionary, playlistIds as Array) as Void {
        song["playlists"] = playlistIds;
        var playlistId = firstPlaylistId(playlistIds);
        if (playlistId != null) {
            song["playlistId"] = playlistId;
        } else if (song.hasKey("playlistId")) {
            song.remove("playlistId");
        }
    }

    private function normalizeDuration(value as Object?) as Number {
        if (value == null) {
            return 0;
        }

        var numberValue = safe_number(value);
        if (numberValue != null) {
            return numberValue;
        }

        var stringValue = safe_string(value);
        if (stringValue != null) {
            var parsed = stringValue.toNumber();
            if (parsed != null) {
                return parsed;
            }
        }

        return 0;
    }

    private function normalizedSong(song as Dictionary?, playlistId as String?) as Dictionary? {
        if (song == null) {
            return null;
        }

        var id = song.hasKey("id") ? safe_string(song["id"]) : null;
        if (id == null || id.length() == 0) {
            return null;
        }

        var title = song.hasKey("title") ? safe_string(song["title"]) : null;
        if (title == null || title.length() == 0) {
            title = "Unknown";
        }

        var artist = song.hasKey("artist") ? safe_string(song["artist"]) : null;
        if (artist == null || artist.length() == 0) {
            artist = "Unknown";
        }

        var album = song.hasKey("album") ? safe_string(song["album"]) : null;
        if (album == null || album.length() == 0) {
            album = "Unknown";
        }

        var duration = 0;
        if (song.hasKey("duration")) {
            duration = normalizeDuration(song["duration"]);
        }

        var playlistIds = copyPlaylistIds(song);
        addUniqueString(playlistIds, playlistId);

        var compactSong = {
            "id"       => id,
            "title"    => title,
            "artist"   => artist,
            "album"    => album,
            "duration" => duration
        };
        setPlaylistIds(compactSong, playlistIds);

        var downloaded = song.hasKey("downloaded") && song["downloaded"] == true;
        if (downloaded && song.hasKey("contentRefId")) {
            var contentRefId = nativeContentRefId(song["contentRefId"]);
            if (contentRefId != null) {
                compactSong["downloaded"] = true;
                compactSong["contentRefId"] = contentRefId;
            }
        }

        return compactSong;
    }

    private function getStoredSongIds() as Array {
        var ids = Storage.getValue(SONG_IDS_KEY) as Array?;
        if (ids == null) {
            return [];
        }
        return ids;
    }

    private function songNeedsRewrite(song as Dictionary?) as Boolean {
        if (song == null) {
            return true;
        }

        if (song.hasKey("url") || song.hasKey("streamUrl")) {
            return true;
        }

        if (!song.hasKey("playlists") && song.hasKey("playlistId")) {
            return true;
        }

        if (song.hasKey("contentRefId")) {
            var rawContentRefId = song["contentRefId"];
            if (rawContentRefId == null || contentRefIdToString(rawContentRefId) == null) {
                return true;
            }
            // Repair libraries written by 1.10.1/1.11.0, which stored numeric
            // media ids as strings and broke playback.
            if (rawContentRefId instanceof String && nativeContentRefId(rawContentRefId) instanceof Number) {
                return true;
            }
        }

        if (song.hasKey("duration")) {
            var rawDuration = song["duration"];
            if (rawDuration != null && safe_number(rawDuration) == null) {
                return true;
            }
        }

        return false;
    }

    function songBelongsToPlaylist(song as Dictionary?, playlistId as String?) as Boolean {
        if (playlistId == null) {
            return true;
        }
        return containsString(copyPlaylistIds(song), playlistId);
    }

    function getPlayableSongCount() as Number {
        var songs = getSongs();
        var count = 0;

        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null || !song.hasKey("contentRefId")) {
                continue;
            }

            if (contentRefIdToString(song["contentRefId"]) != null) {
                count++;
            }
        }

        return count;
    }

    // Check if a song is already persisted in the system media cache.
    // Used by the sync delegate to skip re-downloading tracks that are
    // already on the watch (incremental sync). If the stored flags point
    // to content that no longer exists (e.g. library cleared), the stale
    // flags are reset so the track gets downloaded again.
    function isSongPersisted(song as Dictionary?) as Boolean {
        if (song == null) {
            return false;
        }
        if (!song.hasKey("downloaded") || song["downloaded"] != true) {
            return false;
        }
        if (!song.hasKey("contentRefId")) {
            return false;
        }
        var contentRefId = contentRefIdToString(song["contentRefId"]);
        if (contentRefId == null) {
            return false;
        }
        var content = null;
        try {
            var contentRef = makeContentRef(song["contentRefId"]);
            if (contentRef != null) {
                content = Media.getCachedContentObj(contentRef);
            }
        } catch (ex) {
            content = null;
        }
        if (content == null) {
            // Persisted content is gone; clear stale flags so it re-downloads.
            song["downloaded"] = false;
            song.remove("contentRefId");
            return false;
        }
        return true;
    }

    // Delete a dropped song's cached media, unless another kept entry still
    // references the same persisted content (shared track storage).
    private function deleteCachedIfUnused(song as Dictionary?, keptSongs as Array) as Void {
        if (song == null || !song.hasKey("contentRefId")) {
            return;
        }
        var refId = contentRefIdToString(song["contentRefId"]);
        if (refId == null) {
            return;
        }
        for (var i = 0; i < keptSongs.size(); i++) {
            var kept = keptSongs[i] as Dictionary?;
            if (kept == null || !kept.hasKey("contentRefId")) {
                continue;
            }
            var keptRefId = contentRefIdToString(kept["contentRefId"]);
            if (keptRefId != null && keptRefId.equals(refId)) {
                return;
            }
        }
        try {
            var deleteRef = makeContentRef(song["contentRefId"]);
            if (deleteRef != null) {
                Media.deleteCachedItem(deleteRef);
            }
            System.println("deleted cached item refId=" + refId);
        } catch (ex) {
            // already gone or not persisted; nothing to free
        }
    }

    // Save songs to library
    function saveSongs(songs as Array) as Void {
        var previousIds = getStoredSongIds();
        var songIds = [];
        var songLookup = {};

        for (var i = 0; i < songs.size(); i++) {
            var compactSong = normalizedSong(songs[i] as Dictionary?, null);
            if (compactSong == null) {
                continue;
            }

            var songId = compactSong["id"] as String?;
            if (songId == null) {
                continue;
            }

            if (!songLookup.hasKey(songId)) {
                songIds.add(songId);
            } else {
                var existingSong = songLookup[songId] as Dictionary?;
                if (existingSong != null) {
                    var mergedPlaylists = copyPlaylistIds(existingSong);
                    var newPlaylists = copyPlaylistIds(compactSong);
                    for (var j = 0; j < newPlaylists.size(); j++) {
                        addUniqueString(mergedPlaylists, newPlaylists[j] as String?);
                    }
                    setPlaylistIds(compactSong, mergedPlaylists);

                    if (!compactSong.hasKey("contentRefId") && existingSong.hasKey("contentRefId")) {
                        compactSong["contentRefId"] = existingSong["contentRefId"];
                        compactSong["downloaded"] = true;
                    }
                }
            }

            songLookup[songId] = compactSong;
        }

        for (var k = 0; k < songIds.size(); k++) {
            var id = songIds[k] as String?;
            if (id == null) {
                continue;
            }

            var song = songLookup[id] as Dictionary?;
            if (song != null) {
                Storage.setValue(songStorageKey(id), song as Application.PropertyValueType);
            }
        }

        Storage.setValue(SONG_IDS_KEY, songIds as Array<Application.PropertyValueType>);
        Storage.setValue(SONG_STORAGE_VERSION_KEY, SONG_STORAGE_VERSION);
        Storage.deleteValue(SONGS_KEY);

        for (var oldIndex = 0; oldIndex < previousIds.size(); oldIndex++) {
            var oldId = previousIds[oldIndex] as String?;
            if (oldId != null && !songLookup.hasKey(oldId)) {
                Storage.deleteValue(songStorageKey(oldId));
            }
        }
    }

    function saveSelectedSongsPreservingDownloads(selectedSongs as Array, playlistId as String) as Void {
        var existingSongs = getSongs();
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
            var song = normalizedSong(selectedSongs[j] as Dictionary?, playlistId);
            if (song == null) {
                continue;
            }
            var songId = song["id"] as String?;
            if (songId == null) {
                continue;
            }

            var existing = existingById.hasKey(songId) ? existingById[songId] as Dictionary? : null;
            if (existing != null) {
                var playlistIds = copyPlaylistIds(existing);
                addUniqueString(playlistIds, playlistId);
                setPlaylistIds(song, playlistIds);

                if (existing.hasKey("downloaded") && existing["downloaded"] == true) {
                    song["downloaded"] = true;
                }

                if (existing.hasKey("contentRefId")) {
                    var rawExistingContentRefId = existing["contentRefId"];
                    if (rawExistingContentRefId != null) {
                        var existingContentRefId = contentRefIdToString(rawExistingContentRefId);
                        if (existingContentRefId != null) {
                            song["contentRefId"] = existingContentRefId;
                        }
                    }
                }
            }

            mergedSongs.add(song);
            existingById.remove(songId);
        }

        var droppedSongs = [];
        var keys = existingById.keys();
        for (var k = 0; k < keys.size(); k++) {
            var key = keys[k];
            var oldSong = existingById[key] as Dictionary?;
            if (oldSong != null) {
                var oldPlaylistIds = copyPlaylistIds(oldSong);
                if (containsString(oldPlaylistIds, playlistId)) {
                    oldPlaylistIds = removeString(oldPlaylistIds, playlistId);
                    if (oldPlaylistIds.size() == 0) {
                        droppedSongs.add(oldSong);
                        continue;
                    }
                    setPlaylistIds(oldSong, oldPlaylistIds);
                }
                mergedSongs.add(oldSong);
            }
        }

        saveSongs(mergedSongs);

        // Free the cached media of tracks that were removed from the playlist
        for (var d = 0; d < droppedSongs.size(); d++) {
            deleteCachedIfUnused(droppedSongs[d] as Dictionary?, mergedSongs);
        }
    }

    // Get all songs from library
    function getSongs() as Array {
        var songIds = Storage.getValue(SONG_IDS_KEY) as Array?;
        if (songIds != null) {
            var songs = [];
            var changed = false;
            var seenIds = {};

            for (var i = 0; i < songIds.size(); i++) {
                var id = songIds[i] as String?;
                if (id == null || seenIds.hasKey(id)) {
                    changed = true;
                    continue;
                }
                seenIds[id] = true;

                var storedSong = Storage.getValue(songStorageKey(id)) as Dictionary?;
                var compactSong = normalizedSong(storedSong, null);
                if (compactSong == null) {
                    changed = true;
                    continue;
                }

                if (songNeedsRewrite(storedSong)) {
                    changed = true;
                }
                songs.add(compactSong);
            }

            if (changed) {
                saveSongs(songs);
            }
            return songs;
        }

        var legacySongs = Storage.getValue(SONGS_KEY) as Array?;
        if (legacySongs == null) {
            return [];
        }

        var migratedSongs = [];
        for (var j = 0; j < legacySongs.size(); j++) {
            var migratedSong = normalizedSong(legacySongs[j] as Dictionary?, null);
            if (migratedSong != null) {
                migratedSongs.add(migratedSong);
            }
        }

        saveSongs(migratedSongs);
        return migratedSongs;
    }

    // Save one song without rewriting the full song index.
    function saveSong(song as Dictionary) as Void {
        var compactSong = normalizedSong(song, null);
        if (compactSong == null) {
            return;
        }

        var songId = compactSong["id"] as String?;
        if (songId == null) {
            return;
        }

        Storage.setValue(songStorageKey(songId), compactSong as Application.PropertyValueType);

        var songIds = getStoredSongIds();
        if (!containsString(songIds, songId)) {
            songIds.add(songId);
            Storage.setValue(SONG_IDS_KEY, songIds as Array<Application.PropertyValueType>);
        }

        Storage.setValue(SONG_STORAGE_VERSION_KEY, SONG_STORAGE_VERSION);
        Storage.deleteValue(SONGS_KEY);
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
        var droppedSongs = [];
        
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }
            var id = song["id"] as String?;
            if (id == null || !id.equals(songId)) {
                newSongs.add(song);
            } else {
                droppedSongs.add(song);
            }
        }
        
        saveSongs(newSongs);

        for (var d = 0; d < droppedSongs.size(); d++) {
            deleteCachedIfUnused(droppedSongs[d] as Dictionary?, newSongs);
        }
    }

    // Clear all songs and playlists
    function clearSongs() as Void {
        // Free all cached media before forgetting the library
        var songs = getSongs();
        for (var i = 0; i < songs.size(); i++) {
            deleteCachedIfUnused(songs[i] as Dictionary?, []);
        }
        var songIds = getStoredSongIds();
        for (var j = 0; j < songIds.size(); j++) {
            var songId = songIds[j] as String?;
            if (songId != null) {
                Storage.deleteValue(songStorageKey(songId));
            }
        }
        Storage.deleteValue(SONG_IDS_KEY);
        Storage.deleteValue(SONG_STORAGE_VERSION_KEY);
        Storage.deleteValue(SONGS_KEY);
        Storage.deleteValue(PLAYLISTS_KEY);
        Storage.deleteValue(CURRENT_PLAYLIST_KEY);
    }

    // Remove an entire playlist
    function removePlaylist(playlistId as String) as Void {
        var playlists = getPlaylists();
        var newPlaylists = [];
        for (var i = 0; i < playlists.size(); i++) {
            var p = playlists[i] as Dictionary?;
            if (p != null) {
                var pId = p["id"] as String?;
                if (pId != null && !pId.equals(playlistId)) {
                    newPlaylists.add(p);
                }
            }
        }

        var songs = getSongs();
        var newSongs = [];
        var droppedSongs = [];
        for (var j = 0; j < songs.size(); j++) {
            var song = songs[j] as Dictionary?;
            if (song == null) { continue; }

            var playlistIds = copyPlaylistIds(song);
            if (containsString(playlistIds, playlistId)) {
                playlistIds = removeString(playlistIds, playlistId);
                if (playlistIds.size() == 0) {
                    droppedSongs.add(song);
                    continue;
                }
                setPlaylistIds(song, playlistIds);
            }

            newSongs.add(song);
        }

        saveSongs(newSongs);
        savePlaylists(newPlaylists);

        if (playlistId.equals(getCurrentPlaylist())) {
            Storage.deleteValue(CURRENT_PLAYLIST_KEY);
        }

        // Free the cached media of the removed tracks
        for (var d = 0; d < droppedSongs.size(); d++) {
            deleteCachedIfUnused(droppedSongs[d] as Dictionary?, newSongs);
        }
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

    function clearCurrentPlaylist() as Void {
        Storage.deleteValue(CURRENT_PLAYLIST_KEY);
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
        var storedId = contentRefIdToString(contentRefId);
        if (storedId == null) {
            return;
        }
        Storage.setValue(LAST_PLAYED_CONTENT_REF_ID_KEY, storedId);
    }

    function getLastPlayedContentRefId() as String? {
        var raw = Storage.getValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
        if (raw == null) {
            return null;
        }
        return contentRefIdToString(raw);
    }

    // Create Media.Content object from song data
    function createMediaContent(song as Dictionary) as Media.Content? {
        var contentRefId = null;
        if (song.hasKey("contentRefId")) {
            var rawContentRefId = song["contentRefId"];
            if (rawContentRefId != null) {
                contentRefId = contentRefIdToString(rawContentRefId);
            }
        }
        if (contentRefId == null) {
            return null;
        }

        var content = null;
        try {
            var contentRef = makeContentRef(contentRefId);
            if (contentRef == null) {
                return null;
            }
            content = Media.getCachedContentObj(contentRef);
        } catch (ex) {
            System.println("cached content lookup failed refId=" + contentRefId + ": " + ex.toString());
            return null;
        }

        if (content == null) {
            return null;
        }

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

    // Find a song by the ContentRef ID used by playback.
    function getSongByContentRefId(contentRefId as Object) as Dictionary? {
        var contentRefString = contentRefIdToString(contentRefId);
        var songs = getSongs();
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }

            if (contentRefString != null) {
                var storedString = null;
                if (song.hasKey("contentRefId")) {
                    storedString = contentRefIdToString(song["contentRefId"]);
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
