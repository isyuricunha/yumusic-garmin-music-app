import Toybox.Lang;

// Common backend base class. Monkey C has no interfaces, so both
// YuMusicSubsonicAPI and YuMusicJellyfinAPI extend this and override the
// neutral-shape methods. Consumers depend on YuMusicBackend, and
// YuMusicApiFactory returns one of the two concrete backends.
class YuMusicBackend {
    function initialize() {}

    // cb(code as Number, errorText as String?)  -> errorText null on success
    function pingNeutral(callback as Method) as Void {}

    // cb(code as Number, playlists as Array)     -> [{ id, name, songCount }]
    function getPlaylistsNeutral(callback as Method) as Void {}

    // cb(code as Number, result as Dictionary?)  -> { name, songs:[{id,title,artist,album,duration,url,streamUrl}] }
    function getPlaylistNeutral(playlistId as String, callback as Method) as Void {}

    // Direct audio URL (mp3) for the ACP download step.
    function getStreamUrl(songId as String) as String { return ""; }
    function getDownloadUrl(songId as String) as String { return ""; }
}
