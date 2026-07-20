import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicConnectionTestView extends WatchUi.View {
    private var _serverConfig as YuMusicServerConfig;
    // Backend-agnostic: resolved from config via the factory so the test works
    // for both Subsonic and Jellyfin. Null until ensureConfiguredAndConfigureApi.
    private var _api as YuMusicBackend?;

    private var _results as Array;
    private var _running as Boolean;
    // Backend + host summary drawn under the title (e.g. "jellyfin  demo.host/stable").
    private var _subtitle as String;

    function initialize() {
        View.initialize();
        _serverConfig = new YuMusicServerConfig();
        _api = null;
        _results = [];
        _running = false;
        _subtitle = "";
    }

    function onShow() as Void {
        restart();
    }

    function restart() as Void {
        if (_running) {
            return;
        }

        _running = true;
        _results = [];

        addResult("Wi-Fi Check", "skipped", "auto via webReq");
        addResult("Public HTTPS", "pending", null);
        addResult("Server ping", "pending", null);
        addResult("Get playlists", "pending", null);

        WatchUi.requestUpdate();

        System.println("connection test: starting");
        
        // Communications.checkWifiConnection() can crash with Invalid Value on some devices/SDKs if listener is missing 
        // or app is not an audio-provider type in the current context. We skip it and rely on makeWebRequest to 
        // initialize the network connection.
        testPublicHttps();
    }

    private function addResult(label as String, status as String, detail as String?) as Void {
        _results.add({
            :label => label,
            :status => status,
            :detail => detail
        });
    }

    private function setResult(index as Number, status as String, detail as String?) as Void {
        if (index < 0 || index >= _results.size()) {
            return;
        }

        var row = _results[index] as Dictionary;
        row[:status] = status;
        row[:detail] = detail;
        _results[index] = row;
    }

    private function finish() as Void {
        _running = false;
        WatchUi.requestUpdate();
        System.println("connection test: finished");
    }

    private function testPublicHttps() as Void {
        var url = "https://www.google.com/generate_204";
        System.println("connection test: public url=" + url);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, {}, options, method(:onPublicHttpsResponse));
    }

    function onPublicHttpsResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("connection test: public responseCode=" + responseCode.toString());

        if (responseCode >= 0) {
            if (responseCode == 200 || responseCode == 204) {
                setResult(1, "ok", "(" + responseCode.toString() + ")");
            } else {
                setResult(1, "warn", "(" + responseCode.toString() + ")");
            }
        } else {
            setResult(1, "fail", formatError(responseCode));
        }

        WatchUi.requestUpdate();
        testPing();
    }

    private function ensureConfiguredAndConfigureApi() as Boolean {
        if (!_serverConfig.isConfigured()) {
            _subtitle = "not configured";
            setResult(2, "skipped", "not configured");
            setResult(3, "skipped", "not configured");
            finish();
            return false;
        }

        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var serverType = config["serverType"] as String?;

        // Jellyfin authenticates by apiKey (no username/password), so only the
        // serverUrl is universally required here. The factory builds and
        // configures the backend that matches config["serverType"].
        if (serverUrl == null) {
            _subtitle = (serverType != null ? serverType : "?") + "  (no url)";
            setResult(2, "skipped", "missing url");
            setResult(3, "skipped", "missing url");
            finish();
            return false;
        }

        // Show which backend + host the test is actually hitting.
        _subtitle = (serverType != null ? serverType : "?") + "  " + shortHost(serverUrl);
        System.println("connection test: serverType=" + serverType + " serverUrl=" + serverUrl);
        _api = YuMusicApiFactory.create(config);
        return true;
    }

    private function shortHost(url as String) as String {
        var i = url.find("://");
        return (i != null) ? url.substring(i + 3, url.length()) : url;
    }

    private function testPing() as Void {
        if (!ensureConfiguredAndConfigureApi()) {
            return;
        }

        System.println("connection test: ping");
        _api.pingNeutral(method(:onPingResponse));
    }

    // pingNeutral invokes cb(responseCode, errorText?) — errorText is null on success.
    function onPingResponse(responseCode as Number, err as Object) as Void {
        System.println("connection test: ping responseCode=" + responseCode.toString());

        if (responseCode == 200) {
            setResult(2, "ok", "(200)");
        } else if (responseCode >= 0) {
            setResult(2, "warn", "(" + responseCode.toString() + ")");
        } else {
            setResult(2, "fail", formatError(responseCode));
        }

        WatchUi.requestUpdate();
        testGetPlaylists();
    }

    private function testGetPlaylists() as Void {
        System.println("connection test: getPlaylists");
        _api.getPlaylistsNeutral(method(:onGetPlaylistsResponse));
    }

    // getPlaylistsNeutral invokes cb(responseCode, [{id,name}]).
    function onGetPlaylistsResponse(responseCode as Number, data as Object) as Void {
        System.println("connection test: getPlaylists responseCode=" + responseCode.toString());

        if (responseCode == 200) {
            var count = (data instanceof Lang.Array) ? (data as Lang.Array).size() : 0;
            setResult(3, "ok", "(200 n=" + count.toString() + ")");
        } else if (responseCode >= 0) {
            setResult(3, "warn", "(" + responseCode.toString() + ")");
        } else {
            setResult(3, "fail", formatError(responseCode));
        }

        finish();
    }

    private function formatError(code as Number) as String {
        var url = "";
        if (_serverConfig != null && _serverConfig.isConfigured()) {
            var config = _serverConfig.getConfig();
            var rawUrl = config["serverUrl"] as String?;
            if (rawUrl != null) {
                url = rawUrl;
            }
        }

        var isHttp = url.find("http://") == 0;
        var isLocal = url.find("192.168.") != null || url.find("10.") != null || url.find("172.") != null;

        if (code == -1001) {
            return "(-1001 https req)";
        }
        if (code == -400) {
            if (isHttp) {
                return "(-400 http block?)";
            }
            // On a physical device -400 for a JSON request is almost always the
            // server sending "application/json; charset=utf-8" (Jellyfin does),
            // which Garmin rejects. Needs a proxy returning bare "application/json".
            return "(-400 content-type/charset)";
        }
        if (code == -300) {
            if (isLocal) {
                return "(-300 local ip?)";
            }
            if (isHttp) {
                return "(-300 http block?)";
            }
            return "(-300 timeout)";
        }
        if (code == -200) {
            return "(-200 no data)";
        }
        if (code == -100) {
            return "(-100 unknown)";
        }
        return "(" + code.toString() + ")";
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = 30;

        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, "Connection Test", Graphics.TEXT_JUSTIFY_CENTER);
        y += 28;

        // Backend + host summary so the details are visible at a glance.
        if (_subtitle.length() > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_XTINY, _subtitle, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            y += 24;
        } else {
            y += 12;
        }

        for (var i = 0; i < _results.size(); i++) {
            var row = _results[i] as Dictionary;
            var label = row[:label] as String;
            var status = row[:status] as String;
            var detail = row[:detail] as String?;

            var line = label + ": " + status;
            if (detail != null) {
                line += " " + detail;
            }

            // Draw each result row centered so text stays within the round bezel.
            dc.drawText(centerX, y, Graphics.FONT_TINY, line, Graphics.TEXT_JUSTIFY_CENTER);
            y += 22;
        }

        y += 10;
        var hint = _running ? "Running..." : "Tap to rerun";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Graphics.FONT_TINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
