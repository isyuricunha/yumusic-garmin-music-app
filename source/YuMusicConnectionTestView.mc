import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
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

        addResult("Server", "pending", null);
        addResult("Ping", "pending", null);
        addResult("Playlists", "pending", null);

        WatchUi.requestUpdate();

        System.println("connection test: starting");
        testPing();
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

    private function ensureConfiguredAndConfigureApi() as Boolean {
        if (!_serverConfig.isConfigured()) {
            setResult(0, "fail", "not configured");
            setResult(1, "skipped", null);
            setResult(2, "skipped", null);
            finish();
            return false;
        }

        var config = _serverConfig.getConfig();
        if (!_api.configure(config)) {
            setResult(0, "fail", "missing credentials");
            setResult(1, "skipped", null);
            setResult(2, "skipped", null);
            finish();
            return false;
        }

        var transport = _api.getTransportLabel();
        if (transport.equals("invalid URL")) {
            setResult(0, "fail", transport);
            setResult(1, "skipped", null);
            setResult(2, "skipped", null);
            finish();
            return false;
        }

        setResult(0, "ok", transport);
        WatchUi.requestUpdate();
        return true;
    }

    private function testPing() as Void {
        if (!ensureConfiguredAndConfigureApi()) {
            return;
        }

        System.println("connection test: ping");
        _api.ping(method(:onPingResponse));
    }

    function onPingResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("connection test: ping responseCode=" + responseCode.toString());

        var error = _api.getResponseError(responseCode, data);
        if (error == null) {
            setResult(1, "ok", null);
            WatchUi.requestUpdate();
            testGetPlaylists();
            return;
        }

        setResult(1, "fail", error);
        setResult(2, "skipped", null);
        WatchUi.requestUpdate();
        finish();
    }

    private function testGetPlaylists() as Void {
        System.println("connection test: getPlaylists");
        _api.getPlaylists(method(:onGetPlaylistsResponse));
    }

    function onGetPlaylistsResponse(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        System.println("connection test: getPlaylists responseCode=" + responseCode.toString());

        var error = _api.getResponseError(responseCode, data);
        if (error == null) {
            var count = getPlaylistCount(data);
            setResult(2, "ok", count.toString() + " found");
        } else {
            setResult(2, "fail", error);
        }

        finish();
    }

    private function getPlaylistCount(data as Dictionary or String or PersistedContent.Iterator or Null) as Number {
        var dict = data as Dictionary?;
        var response = dict != null ? dict["subsonic-response"] as Dictionary? : null;
        var container = response != null ? response["playlists"] as Dictionary? : null;
        if (container == null) {
            return 0;
        }

        return _api.ensureArray(container["playlist"]).size();
    }

    private function truncate(text as String, maxLength as Number) as String {
        if (text.length() <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength - 3) + "...";
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = 22;

        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, "Connection Test", Graphics.TEXT_JUSTIFY_CENTER);
        y += 34;

        for (var i = 0; i < _results.size(); i++) {
            var row = _results[i] as Dictionary;
            var label = row[:label] as String;
            var status = row[:status] as String;
            var detail = row[:detail] as String?;

            var line = truncate(label + ": " + status, 24);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, line, Graphics.TEXT_JUSTIFY_CENTER);
            y += 18;
            if (detail != null) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(centerX, y, Graphics.FONT_TINY, truncate(detail, 28), Graphics.TEXT_JUSTIFY_CENTER);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            y += 24;
        }

        var hint = _running ? "Running..." : "Tap to rerun";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, height - 30, Graphics.FONT_TINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
