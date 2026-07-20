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
    private var _username as String?;   // Jellyfin account name to target (multi-user)
    private var _userId as String?;     // resolved from _username via /Users, then cached

    private var _pingCb as Method?;
    private var _plCb as Method?;
    private var _pl1Cb as Method?;
    private var _pl1Id as String?;      // playlistId pending user-id resolution
    private var _afterUsers as Method?; // action to run once _userId is resolved

    // Paging state. Garmin caps the JSON response size (~tens of KB → -402), so
    // large libraries/playlists are fetched page by page and accumulated.
    private const PAGE = 20;
    private var _plAccum as Array = [];   // playlists accumulated across pages
    private var _plStart as Number = 0;
    private var _songAccum as Array = []; // songs accumulated across pages
    private var _songStart as Number = 0;

    function initialize() { YuMusicBackend.initialize(); }

    // Auth is by apiKey. username is the account name to target: an API key
    // carries no user context, but Jellyfin's user-scoped endpoints (playlist
    // items, favorites) need a userId, so username is resolved to one via /Users.
    function configureJellyfin(serverUrl as String, apiKey as String, username as String?, maxBitRate as String?) as Void {
        _serverUrl = normalize(serverUrl);
        _apiKey = apiKey;
        _username = (username != null && username.length() > 0) ? username : null;
        _userId = null;
        if (maxBitRate != null) { _maxBitRate = maxBitRate; }
    }

    // Resolve _userId from _username (once, cached), then run `next`. If there is
    // no username, or resolution fails, `next` runs anyway (global scope).
    private function ensureUserId(next as Method) as Void {
        if (_userId != null || _username == null) { next.invoke(); return; }
        var b = base();
        if (b == null) { next.invoke(); return; }
        _afterUsers = next;
        Communications.makeWebRequest(b + "/Users", { "api_key" => _apiKey }, jsonOptions(), method(:onUsers));
    }
    function onUsers(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var next = _afterUsers; _afterUsers = null;
        if (code == 200 && data instanceof Lang.Array) {
            var users = data as Lang.Array;
            for (var i = 0; i < users.size(); i++) {
                var u = users[i] as Dictionary?;
                if (u != null && (u["Name"] as String?) != null && (u["Name"] as String).equals(_username)) {
                    _userId = u["Id"] as String?;
                    break;
                }
            }
        }
        if (next != null) { next.invoke(); }
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

    // Neutral: cb(code, [{id,name}]). Paginated: accumulates all pages.
    function getPlaylistsNeutral(callback as Method) as Void {
        var b = base();
        if (b == null) { callback.invoke(0, []); return; }
        _plCb = callback;
        _plAccum = [];
        _plStart = 0;
        ensureUserId(method(:doGetPlaylists));
    }
    // Public (not private): referenced via method(:doGetPlaylists) as a callback,
    // and Monkey C cannot build a method() reference to a private function.
    function doGetPlaylists() as Void {
        var b = base();
        if (b == null) { var cb = _plCb; _plCb = null; if (cb != null) { cb.invoke(0, []); } return; }
        // Params in the dict, not the URL (device proxy strips URL query -> 400).
        // EnableImages/EnableUserData=false + Limit/StartIndex keep each page under
        // Garmin's response-size cap (large libraries otherwise return -402).
        var params = {
            "IncludeItemTypes" => "Playlist",
            "Recursive" => "true",
            "api_key" => _apiKey,
            "EnableImages" => "false",
            "EnableUserData" => "false",
            "Limit" => PAGE.toString(),
            "StartIndex" => _plStart.toString()
        };
        if (_userId != null) { params["userId"] = _userId; }
        Communications.makeWebRequest(b + "/Items", params, jsonOptions(), method(:onPlaylists));
    }
    function onPlaylists(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (code != 200) {
            var cb = _plCb; _plCb = null;
            if (cb != null) { cb.invoke(code, []); }
            return;
        }
        var page = YuMusicNormalize.jellyfinPlaylists(data as Dictionary?);
        for (var i = 0; i < page.size(); i++) { _plAccum.add(page[i]); }
        if (page.size() >= PAGE) {
            _plStart += PAGE;
            doGetPlaylists(); // fetch next page
        } else {
            var cb = _plCb; _plCb = null;
            if (cb != null) { cb.invoke(200, _plAccum); }
        }
    }

    // Neutral: cb(code, {name, songs:[...]}). Paginated: accumulates all pages.
    function getPlaylistNeutral(playlistId as String, callback as Method) as Void {
        var b = base();
        if (b == null) { callback.invoke(0, null); return; }
        _pl1Cb = callback;
        _pl1Id = playlistId;
        _songAccum = [];
        _songStart = 0;
        ensureUserId(method(:doGetPlaylist));
    }
    // Public (not private): referenced via method(:doGetPlaylist) — see doGetPlaylists.
    function doGetPlaylist() as Void {
        var b = base();
        var pid = _pl1Id;
        if (b == null || pid == null) { var cb = _pl1Cb; _pl1Cb = null; if (cb != null) { cb.invoke(0, null); } return; }
        // userId is REQUIRED for /Playlists/{id}/Items under API-key auth (else 400).
        // Limit/StartIndex page the songs under Garmin's response-size cap (-402).
        var params = {
            "api_key" => _apiKey,
            "IncludeItemTypes" => "Audio",
            "Fields" => "RunTimeTicks,Artists,Album,AlbumArtist",
            "EnableImages" => "false",
            "EnableUserData" => "false",
            "Limit" => PAGE.toString(),
            "StartIndex" => _songStart.toString()
        };
        if (_userId != null) { params["userId"] = _userId; }
        Communications.makeWebRequest(b + "/Playlists/" + pid + "/Items", params, jsonOptions(), method(:onPlaylist));
    }
    function onPlaylist(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (code != 200) {
            var cb = _pl1Cb; _pl1Cb = null;
            if (cb != null) { cb.invoke(code, null); }
            return;
        }
        var raw = data as Dictionary?;
        var items = YuMusicNormalize.asArray(raw != null ? raw["Items"] : null);
        for (var i = 0; i < items.size(); i++) {
            var it = items[i] as Dictionary?;
            if (it == null) { continue; }
            var sid = it["Id"] as String?;
            if (sid == null) { continue; }
            _songAccum.add(YuMusicNormalize.jellyfinSong(it, getStreamUrl(sid)));
        }
        if (items.size() >= PAGE) {
            _songStart += PAGE;
            doGetPlaylist(); // fetch next page
        } else {
            var cb = _pl1Cb; _pl1Cb = null;
            if (cb != null) { cb.invoke(200, { "name" => "Playlist", "songs" => _songAccum }); }
        }
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
