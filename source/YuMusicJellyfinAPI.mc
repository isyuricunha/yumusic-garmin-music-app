import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

// Native Jellyfin client. Stateless: the API key travels in the query string,
// which also makes the media download URL self-authenticating for the ACP sync.
// Exposes the same *Neutral method surface as YuMusicSubsonicAPI (duck-typed;
// no formal interface in Monkey C) so YuMusicApiFactory can return either one.
class YuMusicJellyfinAPI extends YuMusicBackend {
    private var _serverUrl as String?;
    private var _apiKey as String?;
    private var _maxBitRate as String = "320";

    private var _pingCb as Method?;
    private var _plCb as Method?;
    private var _pl1Cb as Method?;

    function initialize() { YuMusicBackend.initialize(); }

    // Mirrors the factory's expectation for the Jellyfin backend.
    // username/password/legacyAuth do not exist for Jellyfin; apiKey carries auth.
    function configureJellyfin(serverUrl as String, apiKey as String, maxBitRate as String?) as Void {
        _serverUrl = normalize(serverUrl);
        _apiKey = apiKey;
        if (maxBitRate != null) { _maxBitRate = maxBitRate; }
    }

    private function normalize(u as String) as String {
        if (u.length() > 0 && u.substring(u.length() - 1, u.length()).equals("/")) {
            return u.substring(0, u.length() - 1);
        }
        return u;
    }

    private function base() as String? {
        if (_serverUrl == null || _apiKey == null) { return null; }
        return _serverUrl;
    }

    private function jsonOptions() as Dictionary {
        return { :method => Communications.HTTP_REQUEST_METHOD_GET,
                 :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON };
    }

    // Neutral ping: cb(code, errorText?)  -> errorText null on success
    function pingNeutral(callback as Method) as Void {
        var b = base();
        if (b == null) { callback.invoke(0, "not configured"); return; }
        _pingCb = callback;
        Communications.makeWebRequest(b + "/System/Info/Public", {}, jsonOptions(), method(:onPing));
    }
    function onPing(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var cb = _pingCb; _pingCb = null;
        if (cb != null) { cb.invoke(code, code == 200 ? null : "ping " + code.toString()); }
    }

    // Neutral: cb(code, [{id,name}])
    function getPlaylistsNeutral(callback as Method) as Void {
        var b = base();
        if (b == null) { callback.invoke(0, []); return; }
        _plCb = callback;
        var url = b + "/Items?IncludeItemTypes=Playlist&Recursive=true&api_key=" + _apiKey;
        Communications.makeWebRequest(url, {}, jsonOptions(), method(:onPlaylists));
    }
    function onPlaylists(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var cb = _plCb; _plCb = null;
        if (cb == null) { return; }
        if (code != 200) { cb.invoke(code, []); return; }
        cb.invoke(200, YuMusicNormalize.jellyfinPlaylists(data as Dictionary?));
    }

    // Neutral: cb(code, {name, songs:[...]})
    function getPlaylistNeutral(playlistId as String, callback as Method) as Void {
        var b = base();
        if (b == null) { callback.invoke(0, null); return; }
        _pl1Cb = callback;
        var url = b + "/Playlists/" + playlistId + "/Items?api_key=" + _apiKey
                + "&IncludeItemTypes=Audio&Fields=RunTimeTicks,Artists,Album,AlbumArtist";
        Communications.makeWebRequest(url, {}, jsonOptions(), method(:onPlaylist));
    }
    function onPlaylist(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var cb = _pl1Cb; _pl1Cb = null;
        if (cb == null) { return; }
        if (code != 200) { cb.invoke(code, null); return; }
        var raw = data as Dictionary?;
        var items = YuMusicNormalize.asArray(raw != null ? raw["Items"] : null);
        var songs = [];
        for (var i = 0; i < items.size(); i++) {
            var it = items[i] as Dictionary?;
            if (it == null) { continue; }
            var sid = it["Id"] as String?;
            if (sid == null) { continue; }
            songs.add(YuMusicNormalize.jellyfinSong(it, getStreamUrl(sid)));
        }
        cb.invoke(200, { "name" => "Playlist", "songs" => songs });
    }

    // Direct audio URL (mp3). api_key in query -> usable by the ACP download step.
    // NOTE: exact endpoint pending on-device/NAS validation. /Audio/{id}/universal
    // returned 404 on Jellyfin 10.11; stream.mp3 transcodes to mp3 (or passes
    // through when the source is already mp3). Re-validate once the media NAS is up.
    function getStreamUrl(songId as String) as String {
        var b = base();
        if (b == null) { return ""; }
        return b + "/Audio/" + songId + "/stream.mp3?api_key=" + _apiKey
             + "&AudioCodec=mp3&AudioBitRate=" + _maxBitRate + "000";
    }
    function getDownloadUrl(songId as String) as String { return getStreamUrl(songId); }
}
