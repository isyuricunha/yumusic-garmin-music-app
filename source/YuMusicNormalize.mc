import Toybox.Lang;

// Pure mappers: raw backend JSON dicts -> neutral contract dicts.
// Neutral song dict: { id, title, artist, album, duration(Number, seconds), url, streamUrl }
// Neutral playlist dict: { id, name }
module YuMusicNormalize {

    function asArray(v as Object?) as Array {
        if (v == null) { return []; }
        if (v instanceof Toybox.Lang.Array) { return v as Array; }
        return [v];
    }

    // Jellyfin /Items?IncludeItemTypes=Playlist -> [{id,name}]
    function jellyfinPlaylists(raw as Dictionary?) as Array {
        var out = [];
        if (raw == null) { return out; }
        var items = asArray(raw["Items"]);
        for (var i = 0; i < items.size(); i++) {
            var it = items[i] as Dictionary?;
            if (it == null) { continue; }
            var id = it["Id"] as String?;
            var name = it["Name"] as String?;
            var cc = it.hasKey("ChildCount") ? it["ChildCount"] as Number? : null;
            if (id != null) { out.add({ "id" => id, "name" => name != null ? name : "Unnamed", "songCount" => cc != null ? cc : 0 }); }
        }
        return out;
    }

    // One Jellyfin audio item + a prebuilt stream URL -> neutral song dict.
    // Confirmed fields (Jellyfin 10.11): Id, Name, Album (nullable), Artists[], AlbumArtist, RunTimeTicks (100ns ticks).
    function jellyfinSong(item as Dictionary, streamUrl as String) as Dictionary {
        var id = item["Id"] as String?;
        var title = item["Name"] as String?;
        var album = item.hasKey("Album") ? item["Album"] as String? : null;

        var artist = null;
        if (item.hasKey("Artists")) {
            var arts = asArray(item["Artists"]);
            if (arts.size() > 0) { artist = arts[0] as String?; }
        }
        if (artist == null && item.hasKey("AlbumArtist")) { artist = item["AlbumArtist"] as String?; }

        var duration = 0;
        if (item.hasKey("RunTimeTicks")) {
            var ticks = item["RunTimeTicks"] as Number?;
            if (ticks == null) {
                var lticks = item["RunTimeTicks"] as Long?;
                if (lticks != null) { ticks = (lticks / 10000000l).toNumber(); duration = ticks; }
            } else {
                duration = ticks / 10000000; // ticks (100ns) -> seconds
            }
        }

        return {
            "id" => id != null ? id : "",
            "title" => title != null ? title : "Unknown",
            "artist" => artist != null ? artist : "Unknown",
            "album" => album != null ? album : "Unknown",
            "duration" => duration,
            "url" => streamUrl,
            "streamUrl" => streamUrl
        };
    }

    // Subsonic playlist.entry[] -> neutral songs. `api` builds per-song stream URLs.
    function subsonicSongs(entries as Array, api as YuMusicSubsonicAPI) as Array {
        var out = [];
        for (var i = 0; i < entries.size(); i++) {
            var e = entries[i] as Dictionary?;
            if (e == null) { continue; }
            var id = e["id"] as String?;
            var title = e["title"] as String?;
            if (id == null || title == null) { continue; }
            var duration = 0;
            if (e.hasKey("duration")) {
                var raw = e["duration"];
                var d = raw as Number?;
                if (d == null && raw != null) { var s = raw as String?; if (s != null) { d = s.toNumber(); } }
                if (d != null) { duration = d; }
            }
            var artist = e.hasKey("artist") ? e["artist"] as String? : null;
            var album = e.hasKey("album") ? e["album"] as String? : null;
            var streamUrl = api.getStreamUrl(id);
            out.add({
                "id" => id, "title" => title,
                "artist" => artist != null ? artist : "Unknown",
                "album" => album != null ? album : "Unknown",
                "duration" => duration, "url" => streamUrl, "streamUrl" => streamUrl
            });
        }
        return out;
    }

    // Subsonic getPlaylists -> [{id,name}]
    function subsonicPlaylists(raw as Dictionary?) as Array {
        var out = [];
        if (raw == null) { return out; }
        var resp = raw["subsonic-response"] as Dictionary?;
        var pls = resp != null ? resp["playlists"] as Dictionary? : null;
        var arr = pls != null ? asArray(pls["playlist"]) : [];
        for (var i = 0; i < arr.size(); i++) {
            var p = arr[i] as Dictionary?;
            if (p == null) { continue; }
            var id = p["id"] as String?;
            var name = p["name"] as String?;
            var sc = p.hasKey("songCount") ? p["songCount"] as Number? : null;
            if (id != null) { out.add({ "id" => id, "name" => name != null ? name : "Unnamed", "songCount" => sc != null ? sc : 0 }); }
        }
        return out;
    }
}
