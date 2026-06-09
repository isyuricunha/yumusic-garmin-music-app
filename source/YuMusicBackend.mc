import Toybox.Lang;
import Toybox.PersistedContent;

class YuMusicBackend {
    private var _backendType as Number = YUMUSIC_BACKEND_SUBSONIC;
    private var _subsonic as YuMusicSubsonicAPI?;
    private var _jellyfin as YuMusicJellyfinAPI?;

    function initialize() {
    }

    function configure(config as Dictionary) as Boolean {
        var backendType = config["backendType"] as Number?;
        _backendType = backendType != null ? backendType : YUMUSIC_BACKEND_SUBSONIC;

        if (_backendType == YUMUSIC_BACKEND_JELLYFIN) {
            _subsonic = null;
            _jellyfin = new YuMusicJellyfinAPI();
            return _jellyfin.configure(config);
        }

        _jellyfin = null;
        _subsonic = new YuMusicSubsonicAPI();
        return _subsonic.configure(config);
    }

    function prepare(callback as Method(success as Boolean, error as String?) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.prepare(callback);
            return;
        }
        if (_subsonic != null) {
            _subsonic.prepare(callback);
            return;
        }
        callback.invoke(false, "Server not configured");
    }

    function ping(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.ping(callback);
        } else if (_subsonic != null) {
            _subsonic.ping(callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function getPlaylists(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.getPlaylists(callback);
        } else if (_subsonic != null) {
            _subsonic.getPlaylists(callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function getPlaylist(playlistId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.getPlaylist(playlistId, callback);
        } else if (_subsonic != null) {
            _subsonic.getPlaylist(playlistId, callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function extractPlaylists(data as Dictionary or String or PersistedContent.Iterator or Null) as Array {
        if (_jellyfin != null) {
            return _jellyfin.extractPlaylists(data);
        }
        if (_subsonic != null) {
            return _subsonic.extractPlaylists(data);
        }
        return [];
    }

    function extractPlaylist(data as Dictionary or String or PersistedContent.Iterator or Null) as Dictionary? {
        if (_jellyfin != null) {
            return _jellyfin.extractPlaylist(data);
        }
        if (_subsonic != null) {
            return _subsonic.extractPlaylist(data);
        }
        return null;
    }

    function getDownloadUrl(song as Dictionary) as String {
        if (_jellyfin != null) {
            return _jellyfin.getDownloadUrlForSong(song);
        }
        if (_subsonic != null) {
            return _subsonic.getDownloadUrlForSong(song);
        }
        return "";
    }

    function getFallbackDownloadUrl(song as Dictionary) as String {
        if (_jellyfin != null) {
            return _jellyfin.getFallbackDownloadUrlForSong(song);
        }
        if (_subsonic != null) {
            return _subsonic.getFallbackDownloadUrlForSong(song);
        }
        return "";
    }

    function scrobble(songId as String, timestamp as Number?, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.scrobble(songId, timestamp, callback);
        } else if (_subsonic != null) {
            _subsonic.scrobble(songId, timestamp, callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function star(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.star(itemId, callback);
        } else if (_subsonic != null) {
            _subsonic.star(itemId, callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function unstar(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (_jellyfin != null) {
            _jellyfin.unstar(itemId, callback);
        } else if (_subsonic != null) {
            _subsonic.unstar(itemId, callback);
        } else {
            callback.invoke(0, null);
        }
    }

    function getResponseError(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as String? {
        if (_jellyfin != null) {
            return _jellyfin.getResponseError(responseCode, data);
        }
        if (_subsonic != null) {
            return _subsonic.getResponseError(responseCode, data);
        }
        return "Server not configured";
    }

    function isResponseSuccessful(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Boolean {
        return getResponseError(responseCode, data) == null;
    }

    function formatTransportError(code as Number) as String {
        if (_jellyfin != null) {
            return _jellyfin.formatTransportError(code);
        }
        if (_subsonic != null) {
            return _subsonic.formatTransportError(code);
        }
        return code.toString();
    }

    function getTransportLabel() as String {
        if (_jellyfin != null) {
            return _jellyfin.getTransportLabel();
        }
        if (_subsonic != null) {
            return _subsonic.getTransportLabel();
        }
        return "invalid URL";
    }
}
