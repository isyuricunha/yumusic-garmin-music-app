import Toybox.Test;
import Toybox.Lang;

// Unit tests for the pure normalization mappers (no network).

(:test)
function normalizeJellyfinPlaylists_maps_items(logger as Logger) as Boolean {
    var raw = { "Items" => [ { "Id" => "abc", "Name" => "Runs" } ] };
    var out = YuMusicNormalize.jellyfinPlaylists(raw);
    if (out.size() != 1) { return false; }
    var p = out[0] as Dictionary;
    return (p["id"] as String).equals("abc") && (p["name"] as String).equals("Runs");
}

(:test)
function normalizeJellyfinPlaylists_null_safe(logger as Logger) as Boolean {
    return YuMusicNormalize.jellyfinPlaylists(null).size() == 0;
}

(:test)
function normalizeJellyfinSong_maps_fields(logger as Logger) as Boolean {
    // RunTimeTicks 1_200_000_000 (100ns) = 120 s
    var item = { "Id" => "s1", "Name" => "Song", "Album" => "Alb", "Artists" => ["A1"], "RunTimeTicks" => 1200000000 };
    var s = YuMusicNormalize.jellyfinSong(item, "http://x/stream");
    return (s["id"] as String).equals("s1")
        && (s["title"] as String).equals("Song")
        && (s["artist"] as String).equals("A1")
        && (s["album"] as String).equals("Alb")
        && (s["duration"] as Number) == 120
        && (s["url"] as String).equals("http://x/stream");
}

(:test)
function normalizeJellyfinSong_album_null_and_albumartist_fallback(logger as Logger) as Boolean {
    // Album null, no Artists -> falls back to AlbumArtist and "Unknown" album
    var item = { "Id" => "s2", "Name" => "T", "Album" => null, "AlbumArtist" => "AA", "RunTimeTicks" => 0 };
    var s = YuMusicNormalize.jellyfinSong(item, "u");
    return (s["artist"] as String).equals("AA") && (s["album"] as String).equals("Unknown");
}

(:test)
function normalizeSubsonicPlaylists_maps(logger as Logger) as Boolean {
    var raw = { "subsonic-response" => { "playlists" => { "playlist" => [ { "id" => "p1", "name" => "Mix" } ] } } };
    var out = YuMusicNormalize.subsonicPlaylists(raw);
    return out.size() == 1 && ((out[0] as Dictionary)["id"] as String).equals("p1");
}

(:test)
function normalizeSubsonicPlaylists_single_object_coerced(logger as Logger) as Boolean {
    // Subsonic returns a bare object (not array) when there is exactly one playlist
    var raw = { "subsonic-response" => { "playlists" => { "playlist" => { "id" => "solo", "name" => "One" } } } };
    var out = YuMusicNormalize.subsonicPlaylists(raw);
    return out.size() == 1 && ((out[0] as Dictionary)["id"] as String).equals("solo");
}
