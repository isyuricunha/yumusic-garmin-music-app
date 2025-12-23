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
        // Create ContentRef with song ID
        var id = song["id"] as String?;
        if (id == null) {
            return null;
        }
        var contentRef = new Media.ContentRef(id, Media.CONTENT_TYPE_AUDIO);
        
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
