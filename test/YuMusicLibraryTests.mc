import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.Test;

function yuMusicTestSong(id as String, title as String, url as String?) as Dictionary {
    var song = {
        "id"       => id,
        "title"    => title,
        "artist"   => "Test Artist",
        "album"    => "Test Album",
        "duration" => "123"
    };

    if (url != null) {
        song["url"] = url;
        song["streamUrl"] = url;
    }

    return song;
}

function yuMusicFindSong(songs as Array, songId as String) as Dictionary? {
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

function yuMusicPlaylistContains(song as Dictionary?, playlistId as String) as Boolean {
    if (song == null || !song.hasKey("playlists")) {
        return false;
    }

    var playlists = song["playlists"] as Array?;
    if (playlists == null) {
        return false;
    }

    for (var i = 0; i < playlists.size(); i++) {
        var id = playlists[i] as String?;
        if (id != null && id.equals(playlistId)) {
            return true;
        }
    }

    return false;
}

function yuMusicLongStreamUrl(playlistIndex as Number, songIndex as Number) as String {
    return "https://navidrome.example.test/rest/stream.view?id=song-"
        + playlistIndex.toString()
        + "-"
        + songIndex.toString()
        + "&u=sample-user&t=fake-token-for-storage-test&s=fake-salt&v=1.16.1&c=YuMusicGarmin&format=mp3&maxBitRate=128&estimateContentLength=true";
}

(:test)
function compactStoragePreservesPlaylistMembership(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("shared", "Shared", "https://example.test/stream?token=secret"),
        yuMusicTestSong("p1-only", "P1 Only", "https://example.test/stream?token=secret")
    ], "P1");

    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("shared", "Shared Updated", "https://example.test/stream?token=secret"),
        yuMusicTestSong("p2-only", "P2 Only", null)
    ], "P2");

    var songs = library.getSongs();
    var shared = yuMusicFindSong(songs, "shared");
    var p1Only = yuMusicFindSong(songs, "p1-only");
    var p2Only = yuMusicFindSong(songs, "p2-only");

    if (songs.size() != 3 || shared == null || p1Only == null || p2Only == null) {
        return false;
    }
    if (shared.hasKey("url") || shared.hasKey("streamUrl")) {
        return false;
    }
    if (!yuMusicPlaylistContains(shared, "P1") || !yuMusicPlaylistContains(shared, "P2")) {
        return false;
    }
    if (!library.songBelongsToPlaylist(shared, "P1") || !library.songBelongsToPlaylist(shared, "P2")) {
        return false;
    }

    return !library.songBelongsToPlaylist(p1Only, "P2");
}

(:test)
function removePlaylistKeepsSharedSongs(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.savePlaylists([
        { "id" => "P1", "name" => "P1", "songCount" => 2 },
        { "id" => "P2", "name" => "P2", "songCount" => 2 }
    ]);

    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("shared", "Shared", null),
        yuMusicTestSong("p1-only", "P1 Only", null)
    ], "P1");

    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("shared", "Shared", null),
        yuMusicTestSong("p2-only", "P2 Only", null)
    ], "P2");

    library.removePlaylist("P1");

    var songs = library.getSongs();
    var playlists = library.getPlaylists();
    var shared = yuMusicFindSong(songs, "shared");

    if (songs.size() != 2 || playlists.size() != 1 || shared == null) {
        return false;
    }
    if (yuMusicFindSong(songs, "p1-only") != null || yuMusicFindSong(songs, "p2-only") == null) {
        return false;
    }

    return !yuMusicPlaylistContains(shared, "P1") && yuMusicPlaylistContains(shared, "P2");
}

(:test)
function removePlaylistMigratesLegacySongStorage(logger as Logger) as Boolean {
    Storage.clearValues();

    var legacySongs = [];
    legacySongs.add({
        "id"         => "legacy-p1",
        "title"      => "Legacy P1",
        "artist"     => "Test Artist",
        "album"      => "Test Album",
        "duration"   => "99",
        "playlistId" => "P1",
        "url"        => "https://example.test/stream?token=secret"
    });
    legacySongs.add({
        "id"         => "legacy-p2",
        "title"      => "Legacy P2",
        "artist"     => "Test Artist",
        "album"      => "Test Album",
        "duration"   => "88",
        "playlistId" => "P2",
        "streamUrl"  => "https://example.test/stream?token=secret"
    });
    Storage.setValue("songs", legacySongs as Array<Application.PropertyValueType>);

    var library = new YuMusicLibrary();
    library.savePlaylists([
        { "id" => "P1", "name" => "P1", "songCount" => 1 },
        { "id" => "P2", "name" => "P2", "songCount" => 1 }
    ]);

    library.removePlaylist("P1");

    var songs = library.getSongs();
    var legacyP2 = yuMusicFindSong(songs, "legacy-p2");

    if (songs.size() != 1 || yuMusicFindSong(songs, "legacy-p1") != null || legacyP2 == null) {
        return false;
    }
    if (!yuMusicPlaylistContains(legacyP2, "P2")) {
        return false;
    }

    return !legacyP2.hasKey("url") && !legacyP2.hasKey("streamUrl");
}

(:test)
function savesMultiplePlaylistsWithoutPersistingUrls(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    for (var playlistIndex = 1; playlistIndex <= 6; playlistIndex++) {
        var playlistId = "P" + playlistIndex.toString();
        var selectedSongs = [];
        for (var songIndex = 1; songIndex <= 30; songIndex++) {
            selectedSongs.add(yuMusicTestSong(
                playlistId + "-S" + songIndex.toString(),
                "Song " + songIndex.toString(),
                yuMusicLongStreamUrl(playlistIndex, songIndex)
            ));
        }

        library.saveSelectedSongsPreservingDownloads(selectedSongs, playlistId);
    }

    var songs = library.getSongs();
    if (songs.size() != 180) {
        return false;
    }

    for (var i = 0; i < songs.size(); i++) {
        var song = songs[i] as Dictionary?;
        if (song == null || song.hasKey("url") || song.hasKey("streamUrl")) {
            return false;
        }
    }

    return true;
}

(:test)
function saveSongPersistsDownloadState(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("downloaded", "Downloaded", null)
    ], "P1");

    var song = library.getSongById("downloaded");
    if (song == null) {
        return false;
    }

    song["downloaded"] = true;
    song["contentRefId"] = "persisted-12345";
    library.saveSong(song);

    var saved = library.getSongById("downloaded");
    if (saved == null || !saved.hasKey("contentRefId")) {
        return false;
    }

    var contentRefId = saved["contentRefId"] as String?;
    var byContentRef = library.getSongByContentRefId("persisted-12345");

    return saved.hasKey("downloaded")
        && saved["downloaded"] == true
        && contentRefId != null
        && contentRefId.equals("persisted-12345")
        && byContentRef != null
        && yuMusicPlaylistContains(saved, "P1");
}

(:test)
function numericContentRefIdsStayNumeric(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    var song = yuMusicTestSong("legacy-downloaded", "Legacy Downloaded", null);
    song["downloaded"] = true;
    song["contentRefId"] = 12345;

    library.saveSelectedSongsPreservingDownloads([song], "P1");

    var saved = library.getSongById("legacy-downloaded");
    if (saved == null || !saved.hasKey("contentRefId")) {
        return false;
    }

    var raw = saved["contentRefId"];

    return (raw instanceof Number)
        && (raw as Number) == 12345
        && library.getSongByContentRefId(12345) != null
        && library.getSongByContentRefId("12345") != null;
}

(:test)
function stringifiedContentRefIdsAreRepaired(logger as Logger) as Boolean {
    Storage.clearValues();

    // Simulate a library written by 1.10.1/1.11.0: numeric id stored as a string.
    Storage.setValue("songIds", ["broken"] as Array<Application.PropertyValueType>);
    Storage.setValue("song:broken", {
        "id" => "broken",
        "title" => "Broken",
        "artist" => "A",
        "album" => "B",
        "duration" => 1,
        "playlists" => ["P1"],
        "playlistId" => "P1",
        "downloaded" => true,
        "contentRefId" => "777"
    } as Application.PropertyValueType);

    var library = new YuMusicLibrary();
    library.getSongs();

    var stored = Storage.getValue("song:broken") as Dictionary?;
    if (stored == null) {
        return false;
    }
    var raw = stored["contentRefId"];
    return (raw instanceof Number) && (raw as Number) == 777;
}

(:test)
function nonNumericContentRefIdsAreKept(logger as Logger) as Boolean {
    var library = new YuMusicLibrary();
    var opaque = library.nativeContentRefId("persisted-12345");
    var padded = library.nativeContentRefId("0123");
    return (opaque instanceof String)
        && (opaque as String).equals("persisted-12345")
        && (padded instanceof String)
        && library.nativeContentRefId(null) == null
        && library.nativeContentRefId("") == null;
}

(:test)
function removeSongDropsOnlySelectedTrack(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("keep", "Keep", null),
        yuMusicTestSong("drop", "Drop", null)
    ], "P1");

    library.removeSong("drop");

    var songs = library.getSongs();

    return songs.size() == 1
        && yuMusicFindSong(songs, "keep") != null
        && yuMusicFindSong(songs, "drop") == null;
}

(:test)
function clearCurrentPlaylistSelectsWholeLibrary(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("p1-only", "P1 Only", null)
    ], "P1");
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("p2-only", "P2 Only", null)
    ], "P2");

    var p2Only = yuMusicFindSong(library.getSongs(), "p2-only");
    if (p2Only == null) {
        return false;
    }

    library.setCurrentPlaylist("P1");
    if (library.getCurrentPlaylist() == null || library.songBelongsToPlaylist(p2Only, library.getCurrentPlaylist())) {
        return false;
    }

    library.clearCurrentPlaylist();

    return library.getCurrentPlaylist() == null
        && library.songBelongsToPlaylist(p2Only, library.getCurrentPlaylist());
}

(:test)
function playableSongCountUsesPersistedContentRefs(logger as Logger) as Boolean {
    Storage.clearValues();

    var library = new YuMusicLibrary();
    library.saveSelectedSongsPreservingDownloads([
        yuMusicTestSong("downloaded", "Downloaded", null),
        yuMusicTestSong("pending", "Pending", null)
    ], "P1");

    var downloaded = library.getSongById("downloaded");
    if (downloaded == null) {
        return false;
    }

    downloaded["downloaded"] = true;
    downloaded["contentRefId"] = "content-1";
    library.saveSong(downloaded);

    return library.getPlayableSongCount() == 1;
}
