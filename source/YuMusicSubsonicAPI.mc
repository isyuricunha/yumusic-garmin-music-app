import Toybox.Lang;
import Toybox.Communications;
import Toybox.Cryptography;
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
        return str.toUtf8Array() as ByteArray;
    }

    // Build base URL with authentication parameters
    private function buildBaseUrl(endpoint as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var url = _serverUrl + "/rest/" + endpoint + ".view?";
        url += "u=" + _username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;
        url += "&f=json";

        var auth = generateAuthToken();
        if (auth.hasKey("t") && auth.hasKey("s")) {
            url += "&t=" + auth["t"];
            url += "&s=" + auth["s"];
        }

        return url;
    }

    // Test server connection
    function ping(callback as Method) as Void {
        var url = buildBaseUrl("ping");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get all playlists
    function getPlaylists(callback as Method) as Void {
        var url = buildBaseUrl("getPlaylists");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get playlist details with songs
    function getPlaylist(playlistId as String, callback as Method) as Void {
        var url = buildBaseUrl("getPlaylist") + "&id=" + playlistId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get random songs
    function getRandomSongs(size as Number, callback as Method) as Void {
        var url = buildBaseUrl("getRandomSongs") + "&size=" + size.toString();
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get all artists
    function getArtists(callback as Method) as Void {
        var url = buildBaseUrl("getArtists");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get artist albums
    function getArtist(artistId as String, callback as Method) as Void {
        var url = buildBaseUrl("getArtist") + "&id=" + artistId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Get album songs
    function getAlbum(albumId as String, callback as Method) as Void {
        var url = buildBaseUrl("getAlbum") + "&id=" + albumId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Search for songs, albums, artists
    function search(query as String, callback as Method) as Void {
        var url = buildBaseUrl("search3") + "&query=" + query;
        url += "&artistCount=10&albumCount=10&songCount=20";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
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
        if (auth.hasKey("t") && auth.hasKey("s")) {
            url += "&t=" + auth["t"];
            url += "&s=" + auth["s"];
        }

        return url;
    }

    // Get stream URL for a song
    function getStreamUrl(songId as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var url = _serverUrl + "/rest/stream.view?";
        url += "id=" + songId;
        url += "&u=" + _username;
        url += "&v=" + _apiVersion;
        url += "&c=" + _clientName;
        url += "&format=mp3";
        url += "&maxBitRate=320";

        var auth = generateAuthToken();
        if (auth.hasKey("t") && auth.hasKey("s")) {
            url += "&t=" + auth["t"];
            url += "&s=" + auth["s"];
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
        if (auth.hasKey("t") && auth.hasKey("s")) {
            url += "&t=" + auth["t"];
            url += "&s=" + auth["s"];
        }

        return url;
    }

    // Scrobble a song (mark as played)
    function scrobble(songId as String, callback as Method) as Void {
        var url = buildBaseUrl("scrobble") + "&id=" + songId;
        url += "&submission=true";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Star a song/album/artist
    function star(itemId as String, callback as Method) as Void {
        var url = buildBaseUrl("star") + "&id=" + itemId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }

    // Unstar a song/album/artist
    function unstar(itemId as String, callback as Method) as Void {
        var url = buildBaseUrl("unstar") + "&id=" + itemId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, callback);
    }
}
