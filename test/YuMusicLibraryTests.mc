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

(:test)
function audioContentRefsUseGarminStringIds(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    var numericId = library.getAudioContentRefId(8123);
    var storedStringId = library.getAudioContentRefId("8123");
    var invalidId = library.getAudioContentRefId("invalid");
    var passed = numericId != null
        && numericId.equals("8123")
        && storedStringId != null
        && storedStringId.equals("8123")
        && invalidId == null;

    logger.debug("audio content ref=" + numericId);
    library.clearMetadata();
    return passed;
}

(:test)
function removingPlaylistKeepsSharedTracks(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    var sharedSong = testSong("shared-removal-song");
    sharedSong["contentRefId"] = 7001;
    sharedSong["downloaded"] = true;

    library.saveDownloadedPlaylist(testPlaylist("remove-a", "Remove A"));
    library.saveSelectedSongsPreservingDownloads([sharedSong], "remove-a");
    library.saveDownloadedPlaylist(testPlaylist("remove-b", "Remove B"));
    library.saveSelectedSongsPreservingDownloads([sharedSong], "remove-b");
    library.setCurrentPlaylist("remove-a");

    var orphanedIds = library.removePlaylist("remove-a");
    var currentPlaylist = library.getCurrentPlaylist();
    var passed = orphanedIds.size() == 0
        && library.getPlaylists().size() == 1
        && library.getSongsForPlaylist("remove-b").size() == 1
        && currentPlaylist != null
        && currentPlaylist.equals("remove-b");

    logger.debug("remaining playlists=" + library.getPlaylists().size().toString());
    library.clearMetadata();
    return passed;
}

(:test)
function removingLastPlaylistReturnsOrphanedMedia(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    var song = testSong("orphan-song");
    song["contentRefId"] = 7002;
    song["downloaded"] = true;

    library.saveDownloadedPlaylist(testPlaylist("last-playlist", "Last"));
    library.saveSelectedSongsPreservingDownloads([song], "last-playlist");
    library.setCurrentPlaylist("last-playlist");

    var orphanedIds = library.removePlaylist("last-playlist");
    var orphanedId = orphanedIds.size() == 1 ? orphanedIds[0] as Number? : null;
    var passed = orphanedId == 7002
        && library.getPlaylists().size() == 0
        && library.getSongs().size() == 0
        && library.getCurrentPlaylist() == null;

    logger.debug("orphaned media=" + orphanedIds.size().toString());
    library.clearMetadata();
    return passed;
}

(:test)
function clearAllStateRemovesLibraryPreferences(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    library.saveDownloadedPlaylist(testPlaylist("clear-playlist", "Clear"));
    library.saveSelectedSongsPreservingDownloads([testSong("clear-song")], "clear-playlist");
    library.setCurrentPlaylist("clear-playlist");
    library.setShuffle(true);
    library.queueScrobble("clear-song", 1234);

    library.clearAllState();
    var passed = library.getPlaylists().size() == 0
        && library.getSongs().size() == 0
        && library.getCurrentPlaylist() == null
        && !library.getShuffle()
        && library.getScrobbleQueue().size() == 0;

    logger.debug("library cleared=" + passed.toString());
    library.clearMetadata();
    return passed;
}

(:test)
function selectedPlaylistSurvivesProviderRecreation(logger) {
    clearLibraryTestState();
    var library = new YuMusicLibrary();
    var song = testSong("playback-song");
    song["contentRefId"] = 8001;
    song["downloaded"] = true;
    library.saveDownloadedPlaylist(testPlaylist("playback-playlist", "Playback"));
    library.saveSelectedSongsPreservingDownloads([song], "playback-playlist");
    library.setCurrentPlaylist("playback-playlist");

    var recreatedLibrary = new YuMusicLibrary();
    var currentPlaylist = recreatedLibrary.getCurrentPlaylist();
    var passed = currentPlaylist != null
        && currentPlaylist.equals("playback-playlist")
        && recreatedLibrary.getSongsForPlaylist("playback-playlist").size() == 1;

    logger.debug("current playlist=" + currentPlaylist);
    recreatedLibrary.clearMetadata();
    return passed;
}
