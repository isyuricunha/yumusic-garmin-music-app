import Toybox.Communications;
import Toybox.Lang;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicJellyfinAPI {
    private const PAGE_SIZE = 20;
    private const ID_PREFIX = "jellyfin:";

    private var _serverUrl as String?;
    private var _username as String?;
    private var _password as String?;
    private var _maxBitRate as String = "320";
    private var _accessToken as String?;
    private var _userId as String?;
    private var _deviceId as String = "yumusic-garmin";
    private var _authenticating as Boolean = false;
    private var _authCallbacks as Array = [];
    private var _lastAuthResponseCode as Number = 401;

    private var _pingCallback as Method?;
    private var _playlistsCallback as Method?;
    private var _playlistCallback as Method?;
    private var _actionCallback as Method?;

    private var _playlistItems as Array = [];
    private var _playlistStartIndex as Number = 0;
    private var _playlistTotal as Number = 0;
    private var _currentPlaylistId as String?;
    private var _currentPlaylist as Dictionary?;
    private var _currentSongs as Array = [];

    private var _actionQueue as Array = [];
    private var _actionInProgress as Boolean = false;
    private var _actionPath as String?;
    private var _actionMethod as Communications.HttpRequestMethod = Communications.HTTP_REQUEST_METHOD_POST;

    function initialize() {
        var uniqueIdentifier = System.getDeviceSettings().uniqueIdentifier;
        if (uniqueIdentifier != null && uniqueIdentifier.length() > 0) {
            _deviceId = uniqueIdentifier;
        }
    }

    function configure(config as Dictionary) as Boolean {
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;
        var maxBitRate = config["maxBitRate"] as String?;

        if (serverUrl == null || username == null || password == null) {
            return false;
        }

        _serverUrl = trimTrailingSlashes(serverUrl);
        _username = username;
        _password = password;
        if (maxBitRate != null) {
            _maxBitRate = maxBitRate;
        }

        _accessToken = null;
        _userId = null;
        return true;
    }

    function prepare(callback as Method(success as Boolean, error as String?) as Void) as Void {
        if (_accessToken != null && _userId != null) {
            callback.invoke(true, null);
            return;
        }

        _authCallbacks.add(callback);
        if (_authenticating) {
            return;
        }

        if (_serverUrl == null || _username == null || _password == null) {
            _lastAuthResponseCode = 0;
            notifyAuthCallbacks(false, "Jellyfin not configured");
            return;
        }

        _authenticating = true;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => buildAuthorizationHeader(null)
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        var parameters = {
            "Username" => _username,
            "Pw" => _password
        };

        Communications.makeWebRequest(
            buildUrl("/Users/AuthenticateByName"),
            parameters,
            options,
            method(:onAuthenticated)
        );
    }

    function onAuthenticated(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        _authenticating = false;
        _lastAuthResponseCode = responseCode;

        var dict = data as Dictionary?;
        var user = dict != null ? dict["User"] as Dictionary? : null;
        var accessToken = dict != null ? dict["AccessToken"] as String? : null;
        var userId = user != null ? user["Id"] as String? : null;

        if (responseCode == 200 && accessToken != null && userId != null) {
            _accessToken = accessToken;
            _userId = userId;
            notifyAuthCallbacks(true, null);
            return;
        }

        if (responseCode == 200) {
            _lastAuthResponseCode = -400;
            notifyAuthCallbacks(false, "invalid Jellyfin authentication response");
            return;
        }

        notifyAuthCallbacks(false, getResponseError(responseCode, data));
    }

    private function notifyAuthCallbacks(success as Boolean, error as String?) as Void {
        var callbacks = _authCallbacks;
        _authCallbacks = [];
        for (var i = 0; i < callbacks.size(); i++) {
            var callback = callbacks[i] as Method?;
            if (callback != null) {
                callback.invoke(success, error);
            }
        }
    }

    function ping(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        _pingCallback = callback;
        prepare(method(:onPingPrepared));
    }

    function onPingPrepared(success as Boolean, error as String?) as Void {
        if (!success) {
            invokeAndClearPing(_lastAuthResponseCode, error);
            return;
        }

        makeAuthenticatedGet(buildUrl("/System/Info"), method(:onPingResponse));
    }

    function onPingResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        invokeAndClearPing(responseCode, data);
    }

    private function invokeAndClearPing(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var callback = _pingCallback;
        _pingCallback = null;
        if (callback != null) {
            callback.invoke(responseCode, data);
        }
    }

    function getPlaylists(callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        _playlistsCallback = callback;
        _playlistItems = [];
        _playlistStartIndex = 0;
        _playlistTotal = 0;
        prepare(method(:onPlaylistsPrepared));
    }

    function onPlaylistsPrepared(success as Boolean, error as String?) as Void {
        if (!success) {
            invokeAndClearPlaylists(_lastAuthResponseCode, error);
            return;
        }
        requestPlaylistPage();
    }

    private function requestPlaylistPage() as Void {
        var url = buildUrl("/Items");
        url = appendQueryParameter(url, "UserId", _userId + "");
        url = appendQueryParameter(url, "IncludeItemTypes", "Playlist");
        url = appendQueryParameter(url, "Recursive", "true");
        url = appendQueryParameter(url, "StartIndex", _playlistStartIndex.toString());
        url = appendQueryParameter(url, "Limit", PAGE_SIZE.toString());
        url = appendQueryParameter(url, "EnableImages", "false");
        url = appendQueryParameter(url, "EnableUserData", "false");
        url = appendQueryParameter(url, "SortBy", "SortName");
        url = appendQueryParameter(url, "SortOrder", "Ascending");
        makeAuthenticatedGet(url, method(:onPlaylistPage));
    }

    function onPlaylistPage(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var error = getResponseError(responseCode, data);
        var dict = data as Dictionary?;
        if (error != null || dict == null) {
            invokeAndClearPlaylists(
                error != null ? responseCode : -400,
                error != null ? error : "invalid Jellyfin response"
            );
            return;
        }

        var items = ensureArray(dict["Items"]);
        for (var i = 0; i < items.size(); i++) {
            var playlist = mapPlaylist(items[i] as Dictionary?);
            if (playlist != null) {
                _playlistItems.add(playlist);
            }
        }

        var total = readNumber(dict["TotalRecordCount"]);
        if (total != null) {
            _playlistTotal = total;
        }
        _playlistStartIndex += items.size();

        if (items.size() > 0 && _playlistStartIndex < _playlistTotal) {
            requestPlaylistPage();
            return;
        }

        invokeAndClearPlaylists(200, {
            "Items" => _playlistItems,
            "TotalRecordCount" => _playlistItems.size()
        });
    }

    private function invokeAndClearPlaylists(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var callback = _playlistsCallback;
        _playlistsCallback = null;
        if (callback != null) {
            callback.invoke(responseCode, data);
        }
    }

    function getPlaylist(playlistId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        _playlistCallback = callback;
        _currentPlaylistId = sourceIdFromStableId(playlistId);
        _currentPlaylist = null;
        _currentSongs = [];
        _playlistStartIndex = 0;
        _playlistTotal = 0;
        prepare(method(:onPlaylistPrepared));
    }

    function onPlaylistPrepared(success as Boolean, error as String?) as Void {
        if (!success) {
            invokeAndClearPlaylist(_lastAuthResponseCode, error);
            return;
        }

        var url = buildUrl("/Items/" + (_currentPlaylistId + ""));
        url = appendQueryParameter(url, "UserId", _userId + "");
        makeAuthenticatedGet(url, method(:onPlaylistMetadata));
    }

    function onPlaylistMetadata(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var error = getResponseError(responseCode, data);
        var item = data as Dictionary?;
        if (error != null || item == null) {
            invokeAndClearPlaylist(
                error != null ? responseCode : -400,
                error != null ? error : "invalid Jellyfin playlist"
            );
            return;
        }

        _currentPlaylist = mapPlaylist(item);
        if (_currentPlaylist == null) {
            invokeAndClearPlaylist(-400, "invalid Jellyfin playlist");
            return;
        }
        requestPlaylistItemsPage();
    }

    private function requestPlaylistItemsPage() as Void {
        var url = buildUrl("/Playlists/" + (_currentPlaylistId + "") + "/Items");
        url = appendQueryParameter(url, "UserId", _userId + "");
        url = appendQueryParameter(url, "StartIndex", _playlistStartIndex.toString());
        url = appendQueryParameter(url, "Limit", PAGE_SIZE.toString());
        url = appendQueryParameter(url, "EnableImages", "false");
        url = appendQueryParameter(url, "EnableUserData", "false");
        makeAuthenticatedGet(url, method(:onPlaylistItemsPage));
    }

    function onPlaylistItemsPage(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var error = getResponseError(responseCode, data);
        var dict = data as Dictionary?;
        if (error != null || dict == null) {
            invokeAndClearPlaylist(
                error != null ? responseCode : -400,
                error != null ? error : "invalid Jellyfin response"
            );
            return;
        }

        var items = ensureArray(dict["Items"]);
        for (var i = 0; i < items.size(); i++) {
            var song = mapSong(items[i] as Dictionary?);
            if (song != null) {
                _currentSongs.add(song);
            }
        }

        var total = readNumber(dict["TotalRecordCount"]);
        if (total != null) {
            _playlistTotal = total;
        }
        _playlistStartIndex += items.size();

        if (items.size() > 0 && _playlistStartIndex < _playlistTotal) {
            requestPlaylistItemsPage();
            return;
        }

        invokeAndClearPlaylist(200, {
            "Playlist" => _currentPlaylist,
            "Items" => _currentSongs
        });
    }

    private function invokeAndClearPlaylist(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var callback = _playlistCallback;
        _playlistCallback = null;
        if (callback != null) {
            callback.invoke(responseCode, data);
        }
    }

    function extractPlaylists(data as Dictionary or String or PersistedContent.Iterator or Null) as Array {
        var dict = data as Dictionary?;
        return dict != null ? ensureArray(dict["Items"]) : [];
    }

    function extractPlaylist(data as Dictionary or String or PersistedContent.Iterator or Null) as Dictionary? {
        var dict = data as Dictionary?;
        var playlist = dict != null ? dict["Playlist"] as Dictionary? : null;
        if (playlist == null) {
            return null;
        }
        return {
            "playlist" => playlist,
            "songs" => ensureArray(dict["Items"])
        };
    }

    function getDownloadUrlForSong(song as Dictionary) as String {
        var sourceId = song["sourceId"] as String?;
        if (sourceId == null) {
            var stableId = song["id"] as String?;
            sourceId = stableId != null ? sourceIdFromStableId(stableId) : null;
        }
        if (sourceId == null || _accessToken == null) {
            return "";
        }

        var bitrate = _maxBitRate.toNumber();
        if (bitrate == null) {
            bitrate = 320;
        }

        var url = buildUrl("/Audio/" + sourceId + "/stream.mp3");
        url = appendQueryParameter(url, "AudioCodec", "mp3");
        url = appendQueryParameter(url, "AudioBitRate", (bitrate * 1000).toString());
        url = appendQueryParameter(url, "AudioChannels", "2");
        url = appendQueryParameter(url, "MaxAudioChannels", "2");
        url = appendQueryParameter(url, "EnableAutoStreamCopy", "false");
        url = appendQueryParameter(url, "AllowAudioStreamCopy", "false");
        url = appendQueryParameter(url, "DeviceId", _deviceId);
        url = appendQueryParameter(url, "api_key", _accessToken + "");
        return url;
    }

    function scrobble(songId as String, timestamp as Number?, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        performAction("/UserPlayedItems/" + sourceIdFromStableId(songId), Communications.HTTP_REQUEST_METHOD_POST, callback);
    }

    function star(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        performAction("/UserFavoriteItems/" + sourceIdFromStableId(itemId), Communications.HTTP_REQUEST_METHOD_POST, callback);
    }

    function unstar(itemId as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        performAction("/UserFavoriteItems/" + sourceIdFromStableId(itemId), Communications.HTTP_REQUEST_METHOD_DELETE, callback);
    }

    private function performAction(path as String, requestMethod as Communications.HttpRequestMethod, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        _actionQueue.add({
            "path" => path,
            "method" => requestMethod,
            "callback" => callback
        });
        startNextAction();
    }

    private function startNextAction() as Void {
        if (_actionInProgress || _actionQueue.size() == 0) {
            return;
        }

        var action = _actionQueue[0] as Dictionary?;
        if (action == null) {
            removeFirstAction();
            startNextAction();
            return;
        }

        var path = action["path"] as String?;
        var methodValue = action["method"] as Communications.HttpRequestMethod?;
        var callback = action["callback"] as Method?;
        if (path == null || methodValue == null || callback == null) {
            removeFirstAction();
            startNextAction();
            return;
        }

        _actionPath = path;
        _actionMethod = methodValue;
        _actionCallback = callback;
        _actionInProgress = true;
        prepare(method(:onActionPrepared));
    }

    private function removeFirstAction() as Void {
        if (_actionQueue.size() > 0) {
            _actionQueue = _actionQueue.slice(1, null);
        }
    }

    function onActionPrepared(success as Boolean, error as String?) as Void {
        if (!success) {
            invokeAndClearAction(_lastAuthResponseCode, error);
            return;
        }

        var options = {
            :method => _actionMethod,
            :headers => getAuthorizationHeaders(),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            buildUrl(_actionPath + ""),
            {},
            options,
            method(:onActionResponse)
        );
    }

    function onActionResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        invokeAndClearAction(responseCode, data);
    }

    private function invokeAndClearAction(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        var callback = _actionCallback;
        _actionCallback = null;
        _actionPath = null;
        _actionInProgress = false;
        removeFirstAction();
        if (callback != null) {
            callback.invoke(responseCode, data);
        }
        startNextAction();
    }

    function getResponseError(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as String? {
        if (responseCode == 200 || responseCode == 204) {
            return null;
        }
        if (responseCode == 401) {
            return "401 invalid Jellyfin credentials";
        }
        if (responseCode == 403) {
            return "403 Jellyfin access denied";
        }
        if (responseCode == 404) {
            return "404 Jellyfin item not found";
        }
        return formatTransportError(responseCode);
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
        if (code == 0) {
            return "0 invalid download response";
        }
        return code.toString();
    }

    function getTransportLabel() as String {
        if (_serverUrl == null) {
            return "unknown";
        }
        var lowerUrl = (_serverUrl + "").toLower();
        if (hasPrefix(lowerUrl, "https://")) {
            return "Jellyfin HTTPS";
        }
        if (hasPrefix(lowerUrl, "http://")) {
            return "Jellyfin HTTP";
        }
        return "invalid URL";
    }

    private function makeAuthenticatedGet(url as String, callback as Method(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void) as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => getAuthorizationHeaders(),
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, {}, options, callback);
    }

    private function getAuthorizationHeaders() as Dictionary {
        return {
            "Authorization" => buildAuthorizationHeader(_accessToken)
        };
    }

    private function buildAuthorizationHeader(accessToken as String?) as String {
        var header = "MediaBrowser Client=\"YuMusic\", Device=\"Garmin\", DeviceId=\"" + _deviceId + "\", Version=\"1.0.0\"";
        if (accessToken != null) {
            header += ", Token=\"" + accessToken + "\"";
        }
        return header;
    }

    private function buildUrl(path as String) as String {
        return (_serverUrl + "") + path;
    }

    private function appendQueryParameter(url as String, name as String, value as String) as String {
        var separator = url.find("?") == null ? "?" : "&";
        return url + separator + name + "=" + Communications.encodeURL(value);
    }

    private function trimTrailingSlashes(value as String) as String {
        var result = value;
        var lastCharacter = result.length() > 0
            ? result.substring(result.length() - 1, result.length()) as String?
            : null;
        while (lastCharacter != null && lastCharacter.equals("/")) {
            result = result.substring(0, result.length() - 1);
            lastCharacter = result.length() > 0
                ? result.substring(result.length() - 1, result.length()) as String?
                : null;
        }
        return result;
    }

    private function mapPlaylist(item as Dictionary?) as Dictionary? {
        if (item == null) {
            return null;
        }
        var sourceId = item["Id"] as String?;
        var name = item["Name"] as String?;
        if (sourceId == null || name == null) {
            return null;
        }
        var childCount = readNumber(item["ChildCount"]);
        return {
            "id" => ID_PREFIX + sourceId,
            "sourceId" => sourceId,
            "backendType" => YUMUSIC_BACKEND_JELLYFIN,
            "name" => name,
            "songCount" => childCount != null ? childCount : 0
        };
    }

    private function mapSong(item as Dictionary?) as Dictionary? {
        if (item == null) {
            return null;
        }
        var sourceId = item["Id"] as String?;
        var title = item["Name"] as String?;
        if (sourceId == null || title == null) {
            return null;
        }
        var mediaType = item["MediaType"] as String?;
        if (mediaType != null && !mediaType.equals("Audio")) {
            return null;
        }

        var artists = ensureArray(item["Artists"]);
        var artist = artists.size() > 0 ? artists[0] as String? : null;
        var album = item["Album"] as String?;
        var duration = readDurationSeconds(item["RunTimeTicks"]);

        return {
            "id" => ID_PREFIX + sourceId,
            "sourceId" => sourceId,
            "backendType" => YUMUSIC_BACKEND_JELLYFIN,
            "title" => title,
            "artist" => artist != null ? artist : "Unknown",
            "album" => album != null ? album : "Unknown",
            "duration" => duration,
            "suffix" => "mp3"
        };
    }

    private function readDurationSeconds(value as Object?) as Number {
        if (value instanceof Long) {
            return ((value as Long) / 10000000).toNumber();
        }
        var ticks = readNumber(value);
        return ticks != null ? (ticks / 10000000).toNumber() : 0;
    }

    private function readNumber(value as Object?) as Number? {
        if (value instanceof Number) {
            return value as Number;
        }
        if (value instanceof Long) {
            return (value as Long).toNumber();
        }
        if (value instanceof String) {
            return (value as String).toNumber();
        }
        return null;
    }

    private function ensureArray(value as Object?) as Array {
        if (value == null) {
            return [];
        }
        if (value instanceof Array) {
            return value as Array;
        }
        return [value];
    }

    private function sourceIdFromStableId(stableId as String) as String {
        if (hasPrefix(stableId, ID_PREFIX)) {
            return stableId.substring(ID_PREFIX.length(), stableId.length()) as String;
        }
        return stableId;
    }

    private function hasPrefix(value as String, prefix as String) as Boolean {
        if (value.length() < prefix.length()) {
            return false;
        }
        var candidate = value.substring(0, prefix.length()) as String?;
        return candidate != null && candidate.equals(prefix);
    }
}
