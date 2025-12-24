import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.System;

class YuMusicConnectionTestView extends WatchUi.View {
    private var _serverConfig as YuMusicServerConfig;
    private var _api as YuMusicSubsonicAPI;

    private var _results as Array;
    private var _running as Boolean;

    function initialize() {
        View.initialize();
        _serverConfig = new YuMusicServerConfig();
        _api = new YuMusicSubsonicAPI();
        _results = [];
        _running = false;
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

        addResult("Wi-Fi", "pending", null);
        addResult("Public HTTPS", "pending", null);
        addResult("Subsonic ping", "pending", null);
        addResult("Get playlists", "pending", null);

        WatchUi.requestUpdate();

        System.println("connection test: starting");
        Communications.checkWifiConnection(method(:onWifiChecked));
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

    private function onWifiChecked(result as { :wifiAvailable as Boolean, :errorCode as Communications.WifiConnectionStatus }) as Void {
        try {
            var wifiAvailable = result[:wifiAvailable];
            var errorCode = result[:errorCode];
            var errorCodeNumber = errorCode as Number;

            System.println("connection test: wifiAvailable=" + wifiAvailable.toString());
            System.println("connection test: wifiErrorCode=" + errorCodeNumber.toString());

            if (wifiAvailable) {
                setResult(0, "ok", null);
                WatchUi.requestUpdate();
                testPublicHttps();
            } else {
                setResult(0, "fail", "(" + errorCodeNumber.toString() + ")");
                setResult(1, "skipped", "no wifi");
                setResult(2, "skipped", "no wifi");
                setResult(3, "skipped", "no wifi");
                finish();
            }
        } catch (ex) {
            System.println("connection test: wifi exception=" + ex.toString());
            setResult(0, "fail", "exception");
            finish();
        }
    }

    private function testPublicHttps() as Void {
        var url = "https://www.google.com/generate_204";
        System.println("connection test: public url=" + url);

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };

        Communications.makeWebRequest(url, null, options, method(:onPublicHttpsResponse));
    }

    private function onPublicHttpsResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
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
            setResult(2, "skipped", "not configured");
            setResult(3, "skipped", "not configured");
            finish();
            return false;
        }

        var config = _serverConfig.getConfig();
        var serverUrl = config["serverUrl"] as String?;
        var username = config["username"] as String?;
        var password = config["password"] as String?;

        if (serverUrl == null || username == null || password == null) {
            setResult(2, "skipped", "missing config");
            setResult(3, "skipped", "missing config");
            finish();
            return false;
        }

        serverUrl = normalizeServerUrl(serverUrl);
        System.println("connection test: serverUrl=" + serverUrl);
        _api.configure(serverUrl, username, password);
        return true;
    }

    private function testPing() as Void {
        if (!ensureConfiguredAndConfigureApi()) {
            return;
        }

        System.println("connection test: ping");
        _api.ping(method(:onPingResponse));
    }

    private function onPingResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("connection test: ping responseCode=" + responseCode.toString());

        if (responseCode == 200) {
            setResult(2, "ok", null);
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
        _api.getPlaylists(method(:onGetPlaylistsResponse));
    }

    private function onGetPlaylistsResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("connection test: getPlaylists responseCode=" + responseCode.toString());

        if (responseCode == 200) {
            setResult(3, "ok", null);
        } else if (responseCode >= 0) {
            setResult(3, "warn", "(" + responseCode.toString() + ")");
        } else {
            setResult(3, "fail", formatError(responseCode));
        }

        finish();
    }

    private function normalizeServerUrl(url as String) as String {
        if (url.length() > 0 && url.substring(url.length() - 1, url.length()) == "/") {
            return url.substring(0, url.length() - 1);
        }
        return url;
    }

    private function formatError(code as Number) as String {
        if (code == -1001) {
            return "(-1001 https required)";
        }
        if (code == -300) {
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
        y += 40;

        for (var i = 0; i < _results.size(); i++) {
            var row = _results[i] as Dictionary;
            var label = row[:label] as String;
            var status = row[:status] as String;
            var detail = row[:detail] as String?;

            var line = label + ": " + status;
            if (detail != null) {
                line += " " + detail;
            }

            dc.drawText(10, y, Graphics.FONT_TINY, line, Graphics.TEXT_JUSTIFY_LEFT);
            y += 22;
        }

        y += 10;
        var hint = _running ? "Running..." : "Tap to rerun";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Graphics.FONT_TINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
