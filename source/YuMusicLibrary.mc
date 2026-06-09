import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Media;
import Toybox.System;

class YuMusicLibrary {
    private const LEGACY_SONGS_KEY = "songs";
    private const LEGACY_PLAYLISTS_KEY = "playlists";
    private const PLAYLIST_IDS_KEY = "playlistIdsV2";
    private const STORAGE_VERSION_KEY = "libraryStorageVersion";
    private const STORAGE_VERSION = 2;
    private const SONG_KEY_PREFIX = "song:";
    private const PLAYLIST_KEY_PREFIX = "playlist:";
    private const CURRENT_PLAYLIST_KEY = "currentPlaylist";
    private const SHUFFLE_KEY = "shuffle";
    private const LAST_PLAYED_CONTENT_REF_ID_KEY = "lastPlayedContentRefId";
    private const SCROBBLES_KEY = "scrobbles";

    function initialize() {
        migrateLegacyStorage();
    }

    private function songKey(songId as String) as String {
        return SONG_KEY_PREFIX + songId;
    }

    private function playlistKey(playlistId as String) as String {
        return PLAYLIST_KEY_PREFIX + playlistId;
    }

    private function safe_number(value as Object) as Number? {
        if (value instanceof Number) {
            return value as Number;
        }

        if (value instanceof String) {
            return (value as String).toNumber();
        }

        return null;
    }

    private function safeContentRefId(value as Object) as Number? {
        var number = safe_number(value);
        return number != null && number > 0 ? number : null;
    }

    // Garmin returns numeric persisted IDs but requires string IDs for audio ContentRef objects.
    function getAudioContentRefId(value as Object) as String? {
        var contentRefId = safeContentRefId(value);
        return contentRefId != null ? contentRefId.toString() : null;
    }

    function hasCachedMedia(song as Dictionary) as Boolean {
        return getCachedMediaContent(song) != null;
    }

    private function getCachedMediaContent(song as Dictionary) as Media.Content? {
        var contentRefId = song.hasKey("contentRefId")
            ? safeContentRefId(song["contentRefId"])
            : null;
        if (contentRefId == null) {
            return null;
        }

        var audioContentRefId = getAudioContentRefId(contentRefId);
        if (audioContentRefId == null) {
            return null;
        }

        try {
            var contentRef = new Media.ContentRef(audioContentRefId, Media.CONTENT_TYPE_AUDIO);
            return Media.getCachedContentObj(contentRef);
        } catch (ex) {
            markSongCacheMissing(song, contentRefId);
            return null;
        }
    }

    private function markSongCacheMissing(song as Dictionary, contentRefId as Number) as Void {
        if (song.hasKey("contentRefId")) {
            song.remove("contentRefId");
        }
        song["downloaded"] = false;
        saveSong(song);
        if (getLastPlayedContentRefId() == contentRefId) {
            Storage.deleteValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
        }
        refreshPlaylistReadiness();
    }

    private function getPlaylistIds() as Array {
        var playlistIds = Storage.getValue(PLAYLIST_IDS_KEY) as Array?;
        return playlistIds != null ? playlistIds : [];
    }

    private function savePlaylistIds(playlistIds as Array) as Void {
        Storage.setValue(PLAYLIST_IDS_KEY, playlistIds as Array<Application.PropertyValueType>);
    }

    private function addPlaylistId(playlistId as String) as Void {
        var playlistIds = getPlaylistIds();
        for (var i = 0; i < playlistIds.size(); i++) {
            var existingId = playlistIds[i] as String?;
            if (existingId != null && existingId.equals(playlistId)) {
                return;
            }
        }

        playlistIds.add(playlistId);
        savePlaylistIds(playlistIds);
    }

    private function getSongIdsFromPlaylist(playlist as Dictionary?) as Array {
        if (playlist == null) {
            return [];
        }

        var songIds = playlist["songIds"] as Array?;
        return songIds != null ? songIds : [];
    }

    private function sanitizeSong(song as Dictionary) as Boolean {
        var changed = false;

        if (song.hasKey("url")) {
            song.remove("url");
            changed = true;
        }
        if (song.hasKey("streamUrl")) {
            song.remove("streamUrl");
            changed = true;
        }
        if (song.hasKey("playlistId")) {
            song.remove("playlistId");
            changed = true;
        }

        var contentRefId = song.hasKey("contentRefId")
            ? safeContentRefId(song["contentRefId"])
            : null;
        if (contentRefId == null) {
            if (song.hasKey("contentRefId")) {
                song.remove("contentRefId");
                changed = true;
            }
            if (!song.hasKey("downloaded") || song["downloaded"] != false) {
                song["downloaded"] = false;
                changed = true;
            }
        } else {
            if (song["contentRefId"] != contentRefId) {
                song["contentRefId"] = contentRefId;
                changed = true;
            }
            if (!song.hasKey("downloaded") || song["downloaded"] != true) {
                song["downloaded"] = true;
                changed = true;
            }
        }

        if (song.hasKey("duration")) {
            var duration = safe_number(song["duration"]);
            if (duration != null && song["duration"] != duration) {
                song["duration"] = duration;
                changed = true;
            }
        }

        return changed;
    }

    private function migrateLegacyStorage() as Void {
        var version = Storage.getValue(STORAGE_VERSION_KEY) as Number?;
        if (version != null && version >= STORAGE_VERSION) {
            return;
        }

        try {
            var legacySongs = Storage.getValue(LEGACY_SONGS_KEY) as Array?;
            var legacyPlaylists = Storage.getValue(LEGACY_PLAYLISTS_KEY) as Array?;
            var songIdsByPlaylist = {};

            if (legacySongs != null) {
                for (var i = 0; i < legacySongs.size(); i++) {
                    var song = legacySongs[i] as Dictionary?;
                    if (song == null) {
                        continue;
                    }

                    var songId = song["id"] as String?;
                    if (songId == null) {
                        continue;
                    }

                    var playlistId = song["playlistId"] as String?;
                    if (playlistId != null) {
                        var songIds = songIdsByPlaylist[playlistId] as Array?;
                        if (songIds == null) {
                            songIds = [];
                        }
                        songIds.add(songId);
                        songIdsByPlaylist[playlistId] = songIds;
                    }

                    saveSong(song);
                }
            }

            if (legacyPlaylists != null) {
                for (var j = 0; j < legacyPlaylists.size(); j++) {
                    var playlist = legacyPlaylists[j] as Dictionary?;
                    if (playlist == null) {
                        continue;
                    }

                    var playlistId = playlist["id"] as String?;
                    if (playlistId == null) {
                        continue;
                    }

                    var playlistSongIds = songIdsByPlaylist[playlistId] as Array?;
                    playlist["songIds"] = playlistSongIds != null ? playlistSongIds : [];
                    playlist["ready"] = areSongsDownloaded(playlist["songIds"] as Array);
                    saveDownloadedPlaylist(playlist);
                }
            }

            Storage.setValue(STORAGE_VERSION_KEY, STORAGE_VERSION);
            Storage.deleteValue(LEGACY_SONGS_KEY);
            Storage.deleteValue(LEGACY_PLAYLISTS_KEY);
        } catch (ex) {
            System.println("library migration failed: " + ex.toString());
        }
    }

    function saveSong(song as Dictionary) as Void {
        var songId = song["id"] as String?;
        if (songId == null) {
            return;
        }

        sanitizeSong(song);
        Storage.setValue(songKey(songId), song);
    }

    function saveSongs(songs as Array) as Void {
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song != null) {
                saveSong(song);
            }
        }
    }

    function saveSelectedSongsPreservingDownloads(selectedSongs as Array, playlistId as String) as Void {
        var songIds = [];

        for (var i = 0; i < selectedSongs.size(); i++) {
            var song = selectedSongs[i] as Dictionary?;
            if (song == null) {
                continue;
            }

            var songId = song["id"] as String?;
            if (songId == null) {
                continue;
            }

            var existingSong = getSongById(songId);
            if (existingSong != null && existingSong.hasKey("contentRefId")) {
                var existingContentRefId = safeContentRefId(existingSong["contentRefId"]);
                if (existingContentRefId != null) {
                    song["contentRefId"] = existingContentRefId;
                    song["downloaded"] = true;
                }
            }

            songIds.add(songId);
            saveSong(song);
        }

        var playlist = getPlaylistById(playlistId);
        if (playlist == null) {
            playlist = {
                "id" => playlistId,
                "name" => "Unnamed"
            };
        }
        playlist["songIds"] = songIds;
        playlist["songCount"] = songIds.size();
        playlist["ready"] = areSongsDownloaded(songIds);
        saveDownloadedPlaylist(playlist);
    }

    function getSongById(songId as String) as Dictionary? {
        var song = Storage.getValue(songKey(songId)) as Dictionary?;
        if (song != null && sanitizeSong(song)) {
            Storage.setValue(songKey(songId), song);
        }
        return song;
    }

    function getSongsForPlaylist(playlistId as String) as Array {
        var playlist = getPlaylistById(playlistId);
        var songIds = getSongIdsFromPlaylist(playlist);
        var songs = [];

        for (var i = 0; i < songIds.size(); i++) {
            var songId = songIds[i] as String?;
            if (songId == null) {
                continue;
            }

            var song = getSongById(songId);
            if (song != null) {
                songs.add(song);
            }
        }

        return songs;
    }

    function getSongs() as Array {
        var playlists = getPlaylists();
        var seenSongIds = {};
        var songs = [];

        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            var songIds = getSongIdsFromPlaylist(playlist);

            for (var j = 0; j < songIds.size(); j++) {
                var songId = songIds[j] as String?;
                if (songId == null || seenSongIds.hasKey(songId)) {
                    continue;
                }

                seenSongIds[songId] = true;
                var song = getSongById(songId);
                if (song != null) {
                    songs.add(song);
                }
            }
        }

        return songs;
    }

    function getPendingSongs() as Array {
        var songs = getSongs();
        var pendingSongs = [];

        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            if (song == null) {
                continue;
            }

            var contentRefId = song.hasKey("contentRefId")
                ? safeContentRefId(song["contentRefId"])
                : null;
            if (contentRefId == null) {
                pendingSongs.add(song);
            }
        }

        return pendingSongs;
    }

    function addSong(song as Dictionary) as Void {
        saveSong(song);
    }

    function removeSong(songId as String) as Void {
        Storage.deleteValue(songKey(songId));

        var playlists = getPlaylists();
        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist == null) {
                continue;
            }

            var oldSongIds = getSongIdsFromPlaylist(playlist);
            var newSongIds = [];
            for (var j = 0; j < oldSongIds.size(); j++) {
                var existingId = oldSongIds[j] as String?;
                if (existingId != null && !existingId.equals(songId)) {
                    newSongIds.add(existingId);
                }
            }

            playlist["songIds"] = newSongIds;
            playlist["songCount"] = newSongIds.size();
            playlist["ready"] = areSongsDownloaded(newSongIds);
            saveDownloadedPlaylist(playlist);
        }
    }

    function clearSongs() as Void {
        var songs = getSongs();
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            var songId = song != null ? song["id"] as String? : null;
            if (songId != null) {
                Storage.deleteValue(songKey(songId));
            }
        }

        refreshPlaylistReadiness();
    }

    function savePlaylists(playlists as Array) as Void {
        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist != null) {
                saveDownloadedPlaylist(playlist);
            }
        }
    }

    function saveDownloadedPlaylist(playlist as Dictionary) as Void {
        var playlistId = playlist["id"] as String?;
        if (playlistId == null) {
            return;
        }

        var existing = getPlaylistById(playlistId);
        if (existing != null) {
            if (!playlist.hasKey("songIds") && existing.hasKey("songIds")) {
                playlist["songIds"] = existing["songIds"];
            }
            if (!playlist.hasKey("ready") && existing.hasKey("ready")) {
                playlist["ready"] = existing["ready"];
            }
        }

        addPlaylistId(playlistId);
        Storage.setValue(playlistKey(playlistId), playlist);
    }

    function getPlaylistById(playlistId as String) as Dictionary? {
        return Storage.getValue(playlistKey(playlistId)) as Dictionary?;
    }

    function getPlaylists() as Array {
        var playlistIds = getPlaylistIds();
        var playlists = [];

        for (var i = 0; i < playlistIds.size(); i++) {
            var playlistId = playlistIds[i] as String?;
            if (playlistId == null) {
                continue;
            }

            var playlist = getPlaylistById(playlistId);
            if (playlist != null) {
                playlists.add(playlist);
            }
        }

        return playlists;
    }

    function getPlayablePlaylists() as Array {
        var playlists = getPlaylists();
        var playable = [];

        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist != null && playlist["ready"] == true) {
                playable.add(playlist);
            }
        }

        return playable;
    }

    private function isSongReferenced(songId as String) as Boolean {
        var playlists = getPlaylists();
        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            var songIds = getSongIdsFromPlaylist(playlist);
            for (var j = 0; j < songIds.size(); j++) {
                var referencedId = songIds[j] as String?;
                if (referencedId != null && referencedId.equals(songId)) {
                    return true;
                }
            }
        }

        return false;
    }

    function removePlaylist(playlistId as String) as Array {
        var playlist = getPlaylistById(playlistId);
        if (playlist == null) {
            return [];
        }

        var removedSongIds = getSongIdsFromPlaylist(playlist);
        var oldPlaylistIds = getPlaylistIds();
        var newPlaylistIds = [];
        for (var i = 0; i < oldPlaylistIds.size(); i++) {
            var existingId = oldPlaylistIds[i] as String?;
            if (existingId != null && !existingId.equals(playlistId)) {
                newPlaylistIds.add(existingId);
            }
        }

        savePlaylistIds(newPlaylistIds);
        Storage.deleteValue(playlistKey(playlistId));

        var orphanedContentRefIds = [];
        for (var j = 0; j < removedSongIds.size(); j++) {
            var songId = removedSongIds[j] as String?;
            if (songId == null || isSongReferenced(songId)) {
                continue;
            }

            var song = getSongById(songId);
            var contentRefId = song != null && song.hasKey("contentRefId")
                ? safeContentRefId(song["contentRefId"])
                : null;
            if (contentRefId != null) {
                orphanedContentRefIds.add(contentRefId);
                if (getLastPlayedContentRefId() == contentRefId) {
                    Storage.deleteValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
                }
            }
            Storage.deleteValue(songKey(songId));
        }

        var currentPlaylistId = getCurrentPlaylist();
        if (currentPlaylistId != null && currentPlaylistId.equals(playlistId)) {
            var playablePlaylists = getPlayablePlaylists();
            var nextPlaylist = playablePlaylists.size() > 0
                ? playablePlaylists[0] as Dictionary?
                : null;
            var nextPlaylistId = nextPlaylist != null
                ? nextPlaylist["id"] as String?
                : null;
            if (nextPlaylistId != null) {
                setCurrentPlaylist(nextPlaylistId);
            } else {
                Storage.deleteValue(CURRENT_PLAYLIST_KEY);
            }
        }

        return orphanedContentRefIds;
    }

    private function areSongsDownloaded(songIds as Array) as Boolean {
        if (songIds.size() == 0) {
            return false;
        }

        for (var i = 0; i < songIds.size(); i++) {
            var songId = songIds[i] as String?;
            if (songId == null) {
                return false;
            }

            var song = getSongById(songId);
            var contentRefId = song != null && song.hasKey("contentRefId")
                ? safeContentRefId(song["contentRefId"])
                : null;
            if (contentRefId == null) {
                return false;
            }
        }

        return true;
    }

    function refreshPlaylistReadiness() as Void {
        var playlists = getPlaylists();
        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i] as Dictionary?;
            if (playlist == null) {
                continue;
            }

            var songIds = getSongIdsFromPlaylist(playlist);
            playlist["songCount"] = songIds.size();
            playlist["ready"] = areSongsDownloaded(songIds);
            saveDownloadedPlaylist(playlist);
        }
    }

    function setCurrentPlaylist(playlistId as String) as Void {
        Storage.setValue(CURRENT_PLAYLIST_KEY, playlistId);
    }

    function getCurrentPlaylist() as String? {
        return Storage.getValue(CURRENT_PLAYLIST_KEY) as String?;
    }

    function setShuffle(enabled as Boolean) as Void {
        Storage.setValue(SHUFFLE_KEY, enabled);
    }

    function getShuffle() as Boolean {
        var shuffle = Storage.getValue(SHUFFLE_KEY) as Boolean?;
        return shuffle != null && shuffle;
    }

    function setLastPlayedContentRefId(contentRefId as Object) as Void {
        var number = safeContentRefId(contentRefId);
        if (number != null) {
            Storage.setValue(LAST_PLAYED_CONTENT_REF_ID_KEY, number);
        }
    }

    function getLastPlayedContentRefId() as Number? {
        var raw = Storage.getValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
        return raw != null ? safe_number(raw) : null;
    }

    function createMediaContent(song as Dictionary) as Media.Content? {
        var content = getCachedMediaContent(song);
        if (content == null) {
            return null;
        }

        var metadata = content.getMetadata();
        if (metadata != null) {
            var title = song["title"] as String?;
            var artist = song["artist"] as String?;
            var album = song["album"] as String?;
            if (title != null) {
                metadata.title = title;
            }
            if (artist != null) {
                metadata.artist = artist;
            }
            if (album != null) {
                metadata.album = album;
            }
        }

        return content;
    }

    function getSongByContentRefId(contentRefId as Object) as Dictionary? {
        var targetId = safeContentRefId(contentRefId);
        if (targetId == null) {
            return null;
        }

        var songs = getSongs();
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            var storedId = song != null && song.hasKey("contentRefId")
                ? safeContentRefId(song["contentRefId"])
                : null;
            if (storedId != null && storedId == targetId) {
                return song;
            }
        }
        return null;
    }

    function getLibrarySize() as Number {
        return getSongs().size();
    }

    function isEmpty() as Boolean {
        return getLibrarySize() == 0;
    }

    function getStats() as Dictionary {
        var songs = getSongs();
        var totalDuration = 0;

        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            var duration = song != null && song.hasKey("duration")
                ? safe_number(song["duration"])
                : null;
            if (duration != null) {
                totalDuration += duration;
            }
        }

        return {
            "songCount" => songs.size(),
            "totalDuration" => totalDuration,
            "playlistCount" => getPlayablePlaylists().size()
        };
    }

    function clearMetadata() as Void {
        var playlists = getPlaylists();
        var songs = getSongs();

        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i] as Dictionary?;
            var songId = song != null ? song["id"] as String? : null;
            if (songId != null) {
                Storage.deleteValue(songKey(songId));
            }
        }
        for (var j = 0; j < playlists.size(); j++) {
            var playlist = playlists[j] as Dictionary?;
            var playlistId = playlist != null ? playlist["id"] as String? : null;
            if (playlistId != null) {
                Storage.deleteValue(playlistKey(playlistId));
            }
        }

        Storage.deleteValue(PLAYLIST_IDS_KEY);
        Storage.deleteValue(LEGACY_SONGS_KEY);
        Storage.deleteValue(LEGACY_PLAYLISTS_KEY);
        Storage.deleteValue(CURRENT_PLAYLIST_KEY);
        Storage.deleteValue(LAST_PLAYED_CONTENT_REF_ID_KEY);
        Storage.deleteValue(STORAGE_VERSION_KEY);
    }

    function clearAllState() as Void {
        clearMetadata();
        Storage.deleteValue(SHUFFLE_KEY);
        Storage.deleteValue(SCROBBLES_KEY);
    }

    function getScrobbleQueue() as Array {
        var scrobbles = Storage.getValue(SCROBBLES_KEY) as Array?;
        return scrobbles != null ? scrobbles : [];
    }

    function queueScrobble(songId as String, timestamp as Number) as Void {
        var queue = getScrobbleQueue();
        queue.add({
            "id" => songId,
            "time" => timestamp
        });
        Storage.setValue(SCROBBLES_KEY, queue as Array<Application.PropertyValueType>);
    }

    function clearScrobbleQueue() as Void {
        Storage.deleteValue(SCROBBLES_KEY);
    }

    function removeFirstScrobble() as Void {
        var queue = getScrobbleQueue();
        if (queue.size() > 0) {
            queue = queue.slice(1, null);
            Storage.setValue(SCROBBLES_KEY, queue as Array<Application.PropertyValueType>);
        }
    }
}
