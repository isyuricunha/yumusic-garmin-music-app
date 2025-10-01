import Toybox.Lang;
import Toybox.Media;

// Music library manager for storing and managing songs, albums, and playlists
class MusicLibrary {
    private var _songs as Array<Dictionary>;
    private var _albums as Array<Dictionary>;
    private var _artists as Array<Dictionary>;
    private var _playlists as Array<Dictionary>;
    private var _currentQueue as Array<Dictionary>;
    private var _currentIndex as Number;
    private var _shuffleMode as Boolean;

    function initialize() {
        _songs = [] as Array<Dictionary>;
        _albums = [] as Array<Dictionary>;
        _artists = [] as Array<Dictionary>;
        _playlists = [] as Array<Dictionary>;
        _currentQueue = [] as Array<Dictionary>;
        _currentIndex = 0;
        _shuffleMode = false;
    }

    // Add songs to library
    function addSongs(songs as Array) as Void {
        for (var i = 0; i < songs.size(); i++) {
            var song = songs[i];
            if (song != null) {
                _songs.add(song as Dictionary);
            }
        }
    }

    // Add albums to library
    function addAlbums(albums as Array) as Void {
        for (var i = 0; i < albums.size(); i++) {
            var album = albums[i];
            if (album != null) {
                _albums.add(album as Dictionary);
            }
        }
    }

    // Add artists to library
    function addArtists(artists as Array) as Void {
        for (var i = 0; i < artists.size(); i++) {
            var artist = artists[i];
            if (artist != null) {
                _artists.add(artist as Dictionary);
            }
        }
    }

    // Add playlists to library
    function addPlaylists(playlists as Array) as Void {
        for (var i = 0; i < playlists.size(); i++) {
            var playlist = playlists[i];
            if (playlist != null) {
                _playlists.add(playlist as Dictionary);
            }
        }
    }

    // Get all songs
    function getSongs() as Array<Dictionary> {
        return _songs;
    }

    // Get all albums
    function getAlbums() as Array<Dictionary> {
        return _albums;
    }

    // Get all artists
    function getArtists() as Array<Dictionary> {
        return _artists;
    }

    // Get all playlists
    function getPlaylists() as Array<Dictionary> {
        return _playlists;
    }

    // Set current playback queue
    function setQueue(songs as Array<Dictionary>) as Void {
        _currentQueue = songs;
        _currentIndex = 0;
    }

    // Get current queue
    function getQueue() as Array<Dictionary> {
        return _currentQueue;
    }

    // Get current song
    function getCurrentSong() as Dictionary? {
        if (_currentQueue.size() > 0 && _currentIndex >= 0 && _currentIndex < _currentQueue.size()) {
            return _currentQueue[_currentIndex];
        }
        return null;
    }

    // Move to next song
    function nextSong() as Dictionary? {
        if (_currentQueue.size() == 0) {
            return null;
        }

        _currentIndex++;
        if (_currentIndex >= _currentQueue.size()) {
            _currentIndex = 0; // Loop back to start
        }

        return getCurrentSong();
    }

    // Move to previous song
    function previousSong() as Dictionary? {
        if (_currentQueue.size() == 0) {
            return null;
        }

        _currentIndex--;
        if (_currentIndex < 0) {
            _currentIndex = _currentQueue.size() - 1; // Loop to end
        }

        return getCurrentSong();
    }

    // Peek next song without changing index
    function peekNext() as Dictionary? {
        if (_currentQueue.size() == 0) {
            return null;
        }

        var nextIndex = _currentIndex + 1;
        if (nextIndex >= _currentQueue.size()) {
            nextIndex = 0;
        }

        return _currentQueue[nextIndex];
    }

    // Peek previous song without changing index
    function peekPrevious() as Dictionary? {
        if (_currentQueue.size() == 0) {
            return null;
        }

        var prevIndex = _currentIndex - 1;
        if (prevIndex < 0) {
            prevIndex = _currentQueue.size() - 1;
        }

        return _currentQueue[prevIndex];
    }

    // Get current index
    function getCurrentIndex() as Number {
        return _currentIndex;
    }

    // Set current index
    function setCurrentIndex(index as Number) as Void {
        if (index >= 0 && index < _currentQueue.size()) {
            _currentIndex = index;
        }
    }

    // Enable/disable shuffle mode
    function setShuffleMode(enabled as Boolean) as Void {
        _shuffleMode = enabled;
        if (enabled && _currentQueue.size() > 0) {
            shuffleQueue();
        }
    }

    // Get shuffle mode status
    function isShuffleEnabled() as Boolean {
        return _shuffleMode;
    }

    // Shuffle the current queue
    private function shuffleQueue() as Void {
        // Fisher-Yates shuffle algorithm
        for (var i = _currentQueue.size() - 1; i > 0; i--) {
            var j = (System.getTimer() % (i + 1)).toNumber();
            var temp = _currentQueue[i];
            _currentQueue[i] = _currentQueue[j];
            _currentQueue[j] = temp;
        }
        _currentIndex = 0;
    }

    // Clear library
    function clear() as Void {
        _songs = [] as Array<Dictionary>;
        _albums = [] as Array<Dictionary>;
        _artists = [] as Array<Dictionary>;
        _playlists = [] as Array<Dictionary>;
        _currentQueue = [] as Array<Dictionary>;
        _currentIndex = 0;
    }

    // Get queue size
    function getQueueSize() as Number {
        return _currentQueue.size();
    }
}
