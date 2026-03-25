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
    private var _apiVersion as String = "1.16.1";
    private var _clientName as String = "YuMusic";

    function initialize() {
    }

    // Configure the server connection
    function configure(serverUrl as String, username as String, password as String) as Void {
        _serverUrl = serverUrl;
        _username = username;
        _password = password;
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

    // Generate a simple salt (6 random characters)
    private function generateSalt() as String {
        var chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        var salt = "";
        var time = System.getTimer();
        
        for (var i = 0; i < 6; i++) {
            var index = (time + i * 7) % chars.length();
            salt += chars.substring(index, index + 1);
        }
        
        return salt;
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

    // Build base URL with authentication parameters
    private function buildBaseUrl(endpoint as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        // Coerce nullable fields into non-null strings after the null guard
        // and normalize the server URL to avoid a double slash before /rest.
        var serverUrl = _serverUrl + "";
        if (serverUrl.length() > 0 && serverUrl.substring(serverUrl.length() - 1, serverUrl.length()) == "/") {
            serverUrl = serverUrl.substring(0, serverUrl.length() - 1);
        }

        var username = _username + "";
        var url = serverUrl + "/rest/" + endpoint + ".view?";
        url += "u=" + username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;
        url += "&f=json";

        var auth = generateAuthToken();
        var token = auth["t"] as String?;
        var salt = auth["s"] as String?;
        if (token != null && salt != null) {
            url += "&t=" + token;
            url += "&s=" + salt;
        }

        return url;
    }

    // Test server connection
    function ping(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("ping");
        System.println("ping url: " + url);
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
        var url = buildBaseUrl("getPlaylists");
        System.println("getPlaylists url: " + url);
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

    // Get playlist details with songs.
    // Supports pagination via optional offset and count (Subsonic API v1.9.0+).
    // Pass count=-1 to request the full playlist without pagination params.
    function getPlaylist(playlistId as String, offset as Number, count as Number, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("getPlaylist") + "&id=" + playlistId;
        if (count >= 0) {
            url += "&offset=" + offset.toString() + "&count=" + count.toString();
        }
        System.println("getPlaylist url: " + url);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get random songs
    function getRandomSongs(size as Number, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("getRandomSongs") + "&size=" + size.toString();
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get all artists
    function getArtists(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("getArtists");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get artist albums
    function getArtist(artistId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("getArtist") + "&id=" + artistId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get album songs
    function getAlbum(albumId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("getAlbum") + "&id=" + albumId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Search for songs, albums, artists
    function search(query as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("search3") + "&query=" + query;
        url += "&artistCount=10&albumCount=10&songCount=20";
        
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

    // Get download URL for a song
    function getDownloadUrl(songId as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var url = _serverUrl + "/rest/download.view?";
        url += "id=" + songId;
        url += "&u=" + _username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;

        var auth = generateAuthToken();
        var token = auth["t"] as String?;
        var salt = auth["s"] as String?;
        if (token != null && salt != null) {
            url += "&t=" + token;
            url += "&s=" + salt;
        }

        return url;
    }

    // Get stream URL for a song
    function getStreamUrl(songId as String) as String {
        // Use download.view instead of stream.view to ensure Content-Length header is present,
        // which is required for Media.makeWebRequest / AudioContentProvider downlaods on Garmin.
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var url = _serverUrl + "/rest/download.view?";
        url += "id=" + songId;
        url += "&u=" + _username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;
        url += "&format=mp3";
        url += "&maxBitRate=320";

        var auth = generateAuthToken();
        var token = auth["t"] as String?;
        var salt = auth["s"] as String?;
        if (token != null && salt != null) {
            url += "&t=" + token;
            url += "&s=" + salt;
        }

        return url;
    }

    // Get cover art URL
    function getCoverArtUrl(coverArtId as String, size as Number) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var url = _serverUrl + "/rest/getCoverArt.view?";
        url += "id=" + coverArtId;
        url += "&size=" + size.toString();
        url += "&u=" + _username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;

        var auth = generateAuthToken();
        var token = auth["t"] as String?;
        var salt = auth["s"] as String?;
        if (token != null && salt != null) {
            url += "&t=" + token;
            url += "&s=" + salt;
        }

        return url;
    }

    // Scrobble a song (mark as played)
    function scrobble(songId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("scrobble") + "&id=" + songId;
        url += "&time=" + Toybox.Time.now().value().toString() + "000"; // Subsonic expects milliseconds
        url += "&submission=true";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Batch scrobble for offline playback sync
    function scrobbleQueue(scrobbles as Array, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        if (scrobbles.size() == 0) {
            return;
        }

        var url = buildBaseUrl("scrobble");
        
        for (var i = 0; i < scrobbles.size(); i++) {
            var item = scrobbles[i] as Dictionary?;
            if (item != null) {
                var id = item["id"] as String?;
                var time = item["time"] as Number?;
                if (id != null && time != null) {
                    url += "&id=" + id;
                    // Subsonic expects milliseconds since 1970
                    url += "&time=" + time.toString() + "000"; 
                }
            }
        }
        
        url += "&submission=true";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Star a song/album/artist
    function star(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("star") + "&id=" + itemId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Unstar a song/album/artist
    function unstar(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var url = buildBaseUrl("unstar") + "&id=" + itemId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }
}
