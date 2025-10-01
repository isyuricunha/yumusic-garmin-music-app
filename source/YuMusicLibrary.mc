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
        Storage.setValue(SONGS_KEY, songs);
    }

    // Get all songs from library
    function getSongs() as Array {
        var songs = Storage.getValue(SONGS_KEY);
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
            if (songs[i]["id"] != songId) {
                newSongs.add(songs[i]);
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
            if (songs[i]["id"].equals(songId)) {
                return songs[i];
            }
        }
        
        return null;
    }

    // Save playlists
    function savePlaylists(playlists as Array) as Void {
        Storage.setValue(PLAYLISTS_KEY, playlists);
    }

    // Get all playlists
    function getPlaylists() as Array {
        var playlists = Storage.getValue(PLAYLISTS_KEY);
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
        return Storage.getValue(CURRENT_PLAYLIST_KEY);
    }

    // Set shuffle mode
    function setShuffle(enabled as Boolean) as Void {
        Storage.setValue(SHUFFLE_KEY, enabled);
    }

    // Get shuffle mode
    function getShuffle() as Boolean {
        var shuffle = Storage.getValue(SHUFFLE_KEY);
        return shuffle != null && shuffle == true;
    }

    // Create Media.Content object from song data
    function createMediaContent(song as Dictionary) as Media.Content? {
        if (song == null) {
            return null;
        }

        // Create ContentRef with song ID
        var contentRef = new Media.ContentRef(song["id"], Media.CONTENT_TYPE_AUDIO);
        
        // Set metadata
        var metadata = new Media.ContentMetadata();
        
        if (song.hasKey("title")) {
            metadata.title = song["title"];
        }
        
        if (song.hasKey("artist")) {
            metadata.artist = song["artist"];
        }
        
        if (song.hasKey("album")) {
            metadata.album = song["album"];
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
            if (songs[i].hasKey("duration")) {
                totalDuration += songs[i]["duration"];
            }
        }

        return {
            "songCount" => songs.size(),
            "totalDuration" => totalDuration,
            "playlistCount" => getPlaylists().size()
        };
    }
}
