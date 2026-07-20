import Toybox.Lang;
import Toybox.System;

// Dev-only backend health probe.
//
// Compiled into debug/simulator builds and EXCLUDED from release/store builds via
// the (:debug) annotation, so it never ships. On app start (debug builds) it runs
// the read path against the configured backend and logs each step — no source
// churn, no add/remove cycle. See the devProbeStart() twins in yumusicApp.mc.
//
// A class (not a module) so the async callbacks can use method(); yumusicApp
// keeps a reference alive while the requests are in flight.
(:debug)
class YuMusicDevProbe {
    private var _api as YuMusicBackend?;

    function initialize() {}

    function run(config as Dictionary) as Void {
        var configured = config["configured"] as Boolean?;
        if (configured == null || !configured) {
            System.println("PROBE: not configured — skipping");
            return;
        }
        _api = YuMusicApiFactory.create(config);
        System.println("PROBE: start serverType=" + config["serverType"]);
        _api.getPlaylistsNeutral(method(:onPlaylists));
    }

    function onPlaylists(code as Number, data as Object) as Void {
        var n = (data instanceof Lang.Array) ? (data as Lang.Array).size() : -1;
        System.println("PROBE: getPlaylists code=" + code + " count=" + n);
        if (_api != null && data instanceof Lang.Array && (data as Lang.Array).size() > 0) {
            var pid = ((data as Lang.Array)[0] as Lang.Dictionary)["id"] as Lang.String?;
            if (pid != null) { _api.getPlaylistNeutral(pid, method(:onPlaylist)); }
        }
    }

    function onPlaylist(code as Number, data as Object) as Void {
        var songs = -1;
        if (data instanceof Lang.Dictionary) {
            var s = (data as Lang.Dictionary)["songs"];
            if (s instanceof Lang.Array) { songs = (s as Lang.Array).size(); }
        }
        System.println("PROBE: getPlaylist code=" + code + " songs=" + songs);
    }
}
