import Toybox.Lang;
import Toybox.Communications;
import Toybox.Cryptography;
import Toybox.StringUtil;

// Subsonic API Client for Navidrome/Gonic/AirSonic/SubSonic
class SubsonicAPI {
    private var _serverUrl as String?;
    private var _username as String?;
    private var _password as String?;
    private const API_VERSION = "1.16.1";
    private const CLIENT_NAME = "yumusic";

    function initialize() {
        _serverUrl = null;
        _username = null;
        _password = null;
    }

    // Configure the API with server credentials
    function configure(serverUrl as String, username as String, password as String) as Void {
        _serverUrl = serverUrl;
        _username = username;
        _password = password;
    }

    // Generate MD5 hash for authentication token
    private function generateMD5(input as String) as String {
        var hash = new Cryptography.Hash({
            :algorithm => Cryptography.HASH_MD5
        });
        var inputBytes = input.toUtf8Array() as ByteArray;
        hash.update(inputBytes);
        var digest = hash.digest();
        return bytesToHex(digest);
    }

    // Convert byte array to hex string
    private function bytesToHex(bytes as ByteArray) as String {
        var hex = "";
        for (var i = 0; i < bytes.size(); i++) {
            var byte = bytes[i];
            var h = (byte >> 4) & 0x0F;
            var l = byte & 0x0F;
            hex += h.format("%x") + l.format("%x");
        }
        return hex;
    }

    // Generate authentication token (MD5 of password + salt)
    private function generateAuthToken(salt as String) as String {
        if (_password == null) {
            return "";
        }
        return generateMD5(_password + salt);
    }

    // Generate random salt for authentication
    private function generateSalt() as String {
        var time = System.getTimer();
        var random = time % 999999;
        return random.format("%06d");
    }

    // Build base URL with authentication parameters
    private function buildBaseUrl(endpoint as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var salt = generateSalt();
        var token = generateAuthToken(salt);
        
        var url = _serverUrl + "/rest/" + endpoint + ".view";
        url += "?u=" + _username;
        url += "&t=" + token;
        url += "&s=" + salt;
        url += "&v=" + API_VERSION;
        url += "&c=" + CLIENT_NAME;
        url += "&f=json";
        
        return url;
    }

    // Ping server to test connection
    function ping(callback as Method) as Void {
        var url = buildBaseUrl("ping");
        
        System.println("SubsonicAPI: Pinging server at: " + url);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get list of artists
    function getArtists(callback as Method) as Void {
        var url = buildBaseUrl("getArtists");
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get artist details
    function getArtist(artistId as String, callback as Method) as Void {
        var url = buildBaseUrl("getArtist") + "&id=" + artistId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get album details
    function getAlbum(albumId as String, callback as Method) as Void {
        var url = buildBaseUrl("getAlbum") + "&id=" + albumId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Search for music
    function search(query as String, callback as Method) as Void {
        var url = buildBaseUrl("search3");
        url += "&query=" + query;
        url += "&artistCount=10&albumCount=10&songCount=20";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get random songs
    function getRandomSongs(size as Number, callback as Method) as Void {
        var url = buildBaseUrl("getRandomSongs") + "&size=" + size.toString();
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get playlists
    function getPlaylists(callback as Method) as Void {
        var url = buildBaseUrl("getPlaylists");
        
        System.println("SubsonicAPI: Getting playlists from: " + url);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get playlist details
    function getPlaylist(playlistId as String, callback as Method) as Void {
        var url = buildBaseUrl("getPlaylist") + "&id=" + playlistId;
        
        System.println("SubsonicAPI: Getting playlist " + playlistId + " from: " + url);
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Get stream URL for a song
    function getStreamUrl(songId as String) as String {
        if (_serverUrl == null || _username == null) {
            System.println("SubsonicAPI: ERROR - Server URL or username not configured");
            return "";
        }

        var salt = generateSalt();
        var token = generateAuthToken(salt);
        
        var url = _serverUrl + "/rest/stream.view";
        url += "?id=" + songId;
        url += "&u=" + _username;
        url += "&t=" + token;
        url += "&s=" + salt;
        url += "&v=" + API_VERSION;
        url += "&c=" + CLIENT_NAME;
        
        System.println("SubsonicAPI: Generated stream URL for song " + songId + ": " + url);
        
        return url;
    }

    // Get cover art URL
    function getCoverArtUrl(coverArtId as String) as String {
        if (_serverUrl == null || _username == null) {
            return "";
        }

        var salt = generateSalt();
        var token = generateAuthToken(salt);
        
        var url = _serverUrl + "/rest/getCoverArt.view";
        url += "?id=" + coverArtId;
        url += "&u=" + _username;
        url += "&t=" + token;
        url += "&s=" + salt;
        url += "&v=" + API_VERSION;
        url += "&c=" + CLIENT_NAME;
        url += "&size=300";
        
        return url;
    }

    // Scrobble a song (mark as played)
    function scrobble(songId as String, callback as Method) as Void {
        var url = buildBaseUrl("scrobble");
        url += "&id=" + songId;
        url += "&submission=true";
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Star/favorite a song
    function star(songId as String, callback as Method) as Void {
        var url = buildBaseUrl("star") + "&id=" + songId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }

    // Unstar/unfavorite a song
    function unstar(songId as String, callback as Method) as Void {
        var url = buildBaseUrl("unstar") + "&id=" + songId;
        
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, {}, options, callback);
    }
}
