import Toybox.Lang;
import Toybox.Communications;
import Toybox.Cryptography;
import Toybox.PersistedContent;
import Toybox.StringUtil;
import Toybox.System;

// SubSonic API client for Navidrome/Gonic/AirSonic/SubSonic servers
class YuMusicSubsonicAPI {
    private var _serverUrl as String?;
    private var _username as String?;
    private var _password as String?;
    private var _authMode as Number = YUMUSIC_AUTH_TOKEN;
    private var _apiVersion as String = "1.16.1";
    private var _clientName as String = "YuMusicGarmin";
    private var _maxBitRate as String = "320";

    function initialize() {
    }

    function configure(config as Dictionary) as Boolean {
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        var maxBitRate = config["maxBitRate"] as String?;
        var authMode = config["authMode"] as Number?;

        if (serverUrl == null || password == null) {
            return false;
        }

        var resolvedAuthMode = authMode != null ? authMode : YUMUSIC_AUTH_TOKEN;
        if (resolvedAuthMode != YUMUSIC_AUTH_API_KEY && username == null) {
            return false;
        }

        _serverUrl = serverUrl;
        _username = username;
        _password = password;
        _authMode = resolvedAuthMode;
        if (maxBitRate != null) {
            _maxBitRate = maxBitRate;
        }

        return true;
    }

    function prepare(callback as Method(success as Boolean, error as String?) as Void) as Void {
        callback.invoke(true, null);
    }

    // Generate authentication token using MD5 hash
    private function generateAuthToken() as Dictionary {
        if (_password == null) {
            return {};
        }

        // Generate random salt (simplified version)
        var salt = generateSalt();
        
        // Calculate token = md5(password + salt)
        var tokenString = _password + salt;
        var md5 = new Cryptography.Hash({:algorithm => Cryptography.HASH_MD5});
        md5.update(stringToByteArray(tokenString));
        var hashValue = md5.digest();
        
        var token = bytesToHex(hashValue);

        return {
            "t" => token,
            "s" => salt
        };
    }

    private function generateSalt() as String {
        return bytesToHex(Cryptography.randomBytes(6));
    }

    // Convert byte array to hex string
    private function bytesToHex(bytes as ByteArray) as String {
        var hex = "";
        var hexChars = "0123456789abcdef";
        
        for (var i = 0; i < bytes.size(); i++) {
            var b = bytes[i];
            hex += hexChars.substring((b >> 4) & 0x0F, ((b >> 4) & 0x0F) + 1);
            hex += hexChars.substring(b & 0x0F, (b & 0x0F) + 1);
        }
        
        return hex;
    }
    
    // Convert string to byte array for MD5 hashing
    private function stringToByteArray(str as String) as ByteArray {
        try {
            var converted = StringUtil.convertEncodedString(
                str,
                {
                    :fromRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
                    :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
                    :encoding => StringUtil.CHAR_ENCODING_UTF8
                }
            );

            var bytes = converted as ByteArray?;
            if (bytes != null) {
                return bytes;
            }
        } catch(ex) {
            System.println(ex);
        }

        var utf8 = str.toUtf8Array();
        var bytes = new ByteArray();
        for (var i = 0; i < utf8.size(); i++) {
            var b = utf8[i] as Number?;
            if (b == null) {
                b = utf8[i].toString().toNumber();
            }

            if (b != null) {
                bytes.add(b);
            }
        }

        return bytes;
    }

    function buildRequestUrl(endpoint as String) as String {
        if (_serverUrl == null || _password == null) {
            return "";
        }

        var serverUrl = _serverUrl + "";
        var lastCharacter = serverUrl.length() > 0
            ? serverUrl.substring(serverUrl.length() - 1, serverUrl.length()) as String?
            : null;
        while (lastCharacter != null && lastCharacter.equals("/")) {
            serverUrl = serverUrl.substring(0, serverUrl.length() - 1);
            lastCharacter = serverUrl.length() > 0
                ? serverUrl.substring(serverUrl.length() - 1, serverUrl.length()) as String?
                : null;
        }

        var url = serverUrl + "/rest/" + endpoint + ".view";
        url = appendQueryParameter(url, "v", _apiVersion);
        url = appendQueryParameter(url, "c", _clientName);
        url = appendQueryParameter(url, "f", "json");

        if (_authMode == YUMUSIC_AUTH_API_KEY) {
            return appendQueryParameter(url, "apiKey", _password + "");
        }

        if (_username == null) {
            return "";
        }

        url = appendQueryParameter(url, "u", _username + "");
        if (_authMode == YUMUSIC_AUTH_PASSWORD) {
            return appendQueryParameter(url, "p", _password + "");
        }

        var auth = generateAuthToken();
        var token = auth["t"] as String?;
        var salt = auth["s"] as String?;
        if (token != null && salt != null) {
            url = appendQueryParameter(url, "t", token);
            url = appendQueryParameter(url, "s", salt);
        }

        return url;
    }

    function appendQueryParameter(url as String, name as String, value as String) as String {
        var separator = url.find("?") == null ? "?" : "&";
        return url + separator + name + "=" + Communications.encodeURL(value);
    }

    function getTransportLabel() as String {
        if (_serverUrl == null) {
            return "unknown";
        }

        var lowerUrl = (_serverUrl + "").toLower();
        if (hasPrefix(lowerUrl, "https://")) {
            return "HTTPS";
        }
        if (hasPrefix(lowerUrl, "http://")) {
            return "HTTP";
        }
        return "invalid URL";
    }

    private function hasPrefix(value as String, prefix as String) as Boolean {
        if (value.length() < prefix.length()) {
            return false;
        }

        var candidate = value.substring(0, prefix.length()) as String?;
        return candidate != null && candidate.equals(prefix);
    }

    function getResponseError(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as String? {
        if (responseCode != 200) {
            return formatTransportError(responseCode);
        }

        var dict = data as Dictionary?;
        if (dict == null) {
            return "invalid JSON";
        }

        var response = dict["subsonic-response"] as Dictionary?;
        if (response == null) {
            return "invalid API response";
        }

        var status = response["status"] as String?;
        if (status != null && status.equals("ok")) {
            return null;
        }

        var error = response["error"] as Dictionary?;
        if (error == null) {
            return "Subsonic request failed";
        }

        var errorCode = error["code"];
        var code = errorCode != null ? errorCode.toString() : "?";
        if (code.equals("40")) {
            return "40 wrong credentials";
        }
        if (code.equals("41")) {
            return "41 token unsupported";
        }
        if (code.equals("44")) {
            return "44 not authorized";
        }
        if (code.equals("50")) {
            return "50 server trial expired";
        }

        var messageValue = error["message"];
        if (messageValue != null) {
            return code + " " + messageValue.toString();
        }
        return "Subsonic error " + code;
    }

    function isResponseSuccessful(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Boolean {
        return getResponseError(responseCode, data) == null;
    }

    function formatTransportError(code as Number) as String {
        if (code == -300) {
            return "-300 timeout";
        }
        if (code == -400) {
            return "-400 invalid response body";
        }
        if (code == -402) {
            return "-402 response too large";
        }
        if (code == -403) {
            return "-403 out of memory";
        }
        if (code == -1001) {
            return "-1001 HTTPS required";
        }
        if (code == -1002) {
            return "-1002 unsupported content";
        }
        if (code == 401) {
            return "401 unauthorized";
        }
        if (code == 403) {
            return "403 forbidden";
        }
        if (code == 0) {
            return "0 invalid download response";
        }
        return code.toString();
    }

    // Test server connection
    function ping(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildRequestUrl("ping");
        if (url.length() == 0) {
            callback.invoke(0, null);
            return;
        }
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get all playlists
    function getPlaylists(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildRequestUrl("getPlaylists");
        if (url.length() == 0) {
            callback.invoke(0, null);
            return;
        }
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    function getPlaylist(playlistId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("getPlaylist"), "id", playlistId);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get random songs
    function getRandomSongs(size as Number, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("getRandomSongs"), "size", size.toString());
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get all artists
    function getArtists(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildRequestUrl("getArtists");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get artist albums
    function getArtist(artistId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("getArtist"), "id", artistId);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get album songs
    function getAlbum(albumId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("getAlbum"), "id", albumId);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Search for songs, albums, artists
    function search(query as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("search3"), "query", query);
        url = appendQueryParameter(url, "artistCount", "10");
        url = appendQueryParameter(url, "albumCount", "10");
        url = appendQueryParameter(url, "songCount", "20");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Ensure a value is an Array (useful for Subsonic JSON which returns an object if there's only 1 item)
    function ensureArray(value as Object?) as Array {
        if (value == null) {
            return [];
        }
        if (value instanceof Toybox.Lang.Array) {
            return value as Array;
        }
        return [value];
    }

    function extractPlaylists(data as Dictionary or String or PersistedContent.Iterator or Null) as Array {
        var dict = data as Dictionary?;
        var response = dict != null ? dict["subsonic-response"] as Dictionary? : null;
        var playlistsContainer = response != null ? response["playlists"] as Dictionary? : null;
        return playlistsContainer != null ? ensureArray(playlistsContainer["playlist"]) : [];
    }

    function extractPlaylist(data as Dictionary or String or PersistedContent.Iterator or Null) as Dictionary? {
        var dict = data as Dictionary?;
        var response = dict != null ? dict["subsonic-response"] as Dictionary? : null;
        var playlist = response != null ? response["playlist"] as Dictionary? : null;
        if (playlist == null) {
            return null;
        }

        var entries = ensureArray(playlist["entry"]);
        var songs = [];
        for (var i = 0; i < entries.size(); i++) {
            var sourceSong = entries[i] as Dictionary?;
            if (sourceSong == null) {
                continue;
            }

            var songId = sourceSong["id"] as String?;
            var title = sourceSong["title"] as String?;
            if (songId == null || title == null) {
                continue;
            }

            var duration = sourceSong.hasKey("duration")
                ? readNumber(sourceSong["duration"])
                : null;
            var artist = sourceSong["artist"] as String?;
            var album = sourceSong["album"] as String?;
            var suffix = sourceSong["suffix"] as String?;

            songs.add({
                "id" => songId,
                "sourceId" => songId,
                "backendType" => YUMUSIC_BACKEND_SUBSONIC,
                "title" => title,
                "artist" => artist != null ? artist : "Unknown",
                "album" => album != null ? album : "Unknown",
                "duration" => duration != null ? duration : 0,
                "suffix" => suffix != null ? suffix : "mp3"
            });
        }

        return {
            "playlist" => playlist,
            "songs" => songs
        };
    }

    private function readNumber(value as Object) as Number? {
        if (value instanceof Number) {
            return value as Number;
        }
        if (value instanceof String) {
            return (value as String).toNumber();
        }
        return null;
    }

    // Get download URL for a song
    function getDownloadUrl(songId as String) as String {
        var url = appendQueryParameter(buildRequestUrl("stream"), "id", songId);
        url = appendQueryParameter(url, "format", "mp3");
        url = appendQueryParameter(url, "maxBitRate", _maxBitRate);
        url = appendQueryParameter(url, "estimateContentLength", "true");

        return url;
    }

    function getDownloadUrlForSong(song as Dictionary) as String {
        var sourceId = song["sourceId"] as String?;
        if (sourceId == null) {
            sourceId = song["id"] as String?;
        }
        return sourceId != null ? getDownloadUrl(sourceId) : "";
    }

    // Get stream URL for a song
    function getStreamUrl(songId as String) as String {
        return getDownloadUrl(songId);
    }

    // Get cover art URL
    function getCoverArtUrl(coverArtId as String, size as Number) as String {
        var url = appendQueryParameter(buildRequestUrl("getCoverArt"), "id", coverArtId);
        url = appendQueryParameter(url, "size", size.toString());

        return url;
    }

    // Scrobble a single song with an optional exact UTC timestamp
    function scrobble(songId as String, timestamp as Number?, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("scrobble"), "id", songId);
        
        if (timestamp != null) {
            url = appendQueryParameter(url, "time", timestamp.toString() + "000");
        } else {
            url = appendQueryParameter(url, "time", Toybox.Time.now().value().toString() + "000");
        }
        
        url = appendQueryParameter(url, "submission", "true");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Star a song/album/artist
    function star(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("star"), "id", itemId);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Unstar a song/album/artist
    function unstar(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = appendQueryParameter(buildRequestUrl("unstar"), "id", itemId);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }
}
