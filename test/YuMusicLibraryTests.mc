using Toybox.Application;
using Toybox.Application.Storage;
using Toybox.Test;
import Toybox.Lang;

function clearLibraryTestState() as Void {
    var library = new YuMusicLibrary();
    library.clearMetadata();
    Storage.deleteValue("songs");
    Storage.deleteValue("playlists");
    Storage.deleteValue("playlistIdsV2");
    Storage.deleteValue("libraryStorageVersion");
}

function testPlaylist(id as String, name as String) as Dictionary {
    return {
        "id" => id,
        "name" => name,
        "songCount" => 1,
        "ready" => false
    };
}

function testSong(id as String) as Dictionary {
    return {
        "id" => id,
        "title" => "Test Song",
        "artist" => "Test Artist",
        "album" => "Test Album",
        "duration" => 180,
        "suffix" => "mp3"
    };
}

(:test)
function libraryMigratesLegacyAggregateStorage(logger) {
    clearLibraryTestState();
    Storage.setValue("songs", [{
        "id" => "legacy-song",
        "title" => "Legacy Song",
        "artist" => "Legacy Artist",
        "album" => "Legacy Album",
        "duration" => 120,
        "playlistId" => "legacy-playlist",
        "url" => "https://example.com/secret",
        "contentRefId" => 1234,
        "downloaded" => true
    }] as Array<Application.PropertyValueType>);
    Storage.setValue("playlists", [{
        "id" => "legacy-playlist",
        "name" => "Legacy Playlist",
        "songCount" => 1
    }] as Array<Application.PropertyValueType>);

    var library = new YuMusicLibrary();
    var songs = library.getSongs();
    var playlists = library.getPlayablePlaylists();
    var song = songs.size() == 1 ? songs[0] as Dictionary? : null;
    var passed = songs.size() == 1
        && playlists.size() == 1
        && song != null
        && !song.hasKey("url")
        && !song.hasKey("playlistId")
        && Storage.getValue("songs") == null
        && Storage.getValue("playlists") == null;

    logger.debug("migrated songs=" + songs.size().toString());
    library.clearMetadata();
    return passed;
}

(:test)
function sharedSongRemainsInBothPlaylists(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    library.saveDownloadedPlaylist(testPlaylist("playlist-a", "Playlist A"));
    library.saveSelectedSongsPreservingDownloads([testSong("shared-song")], "playlist-a");
    library.saveDownloadedPlaylist(testPlaylist("playlist-b", "Playlist B"));
    library.saveSelectedSongsPreservingDownloads([testSong("shared-song")], "playlist-b");

    var allSongs = library.getSongs();
    var firstPlaylistSongs = library.getSongsForPlaylist("playlist-a");
    var secondPlaylistSongs = library.getSongsForPlaylist("playlist-b");
    var passed = allSongs.size() == 1
        && firstPlaylistSongs.size() == 1
        && secondPlaylistSongs.size() == 1;

    logger.debug("unique songs=" + allSongs.size().toString());
    library.clearMetadata();
    return passed;
}

(:test)
function playlistBecomesPlayableOnlyAfterDownload(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    library.saveDownloadedPlaylist(testPlaylist("pending-playlist", "Pending"));
    library.saveSelectedSongsPreservingDownloads([testSong("pending-song")], "pending-playlist");

    var pendingBefore = library.getPendingSongs().size();
    var playableBefore = library.getPlayablePlaylists().size();
    var song = library.getSongById("pending-song");
    if (song != null) {
        song["contentRefId"] = 5678;
        song["downloaded"] = true;
        library.saveSong(song);
    }
    library.refreshPlaylistReadiness();

    var passed = pendingBefore == 1
        && playableBefore == 0
        && library.getPendingSongs().size() == 0
        && library.getPlayablePlaylists().size() == 1;

    logger.debug("playable=" + library.getPlayablePlaylists().size().toString());
    library.clearMetadata();
    return passed;
}

(:test)
function invalidCachedContentRemainsPending(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    library.saveDownloadedPlaylist(testPlaylist("invalid-playlist", "Invalid"));
    var song = testSong("invalid-song");
    song["contentRefId"] = "not-a-number";
    song["downloaded"] = true;
    library.saveSelectedSongsPreservingDownloads([song], "invalid-playlist");

    var storedSong = library.getSongById("invalid-song");
    var passed = storedSong != null
        && !storedSong.hasKey("contentRefId")
        && library.getPendingSongs().size() == 1
        && library.getPlayablePlaylists().size() == 0;

    logger.debug("pending=" + library.getPendingSongs().size().toString());
    library.clearMetadata();
    return passed;
}
