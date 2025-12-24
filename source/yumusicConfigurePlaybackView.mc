import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConfigurePlaybackView extends WatchUi.View {
    private var _serverConfig as YuMusicServerConfig;
    private var _library as YuMusicLibrary;

    function initialize() {
        View.initialize();
        _serverConfig = new YuMusicServerConfig();
        _library = new YuMusicLibrary();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConfigurePlaybackLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var width = dc.getWidth();
        var centerX = width / 2;
        var y = 40;

        // Draw title
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, "Playback Settings", Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        // Show library stats
        var stats = _library.getStats();
        var songCount = stats["songCount"] as Number?;
        if (songCount == null) {
            songCount = 0;
        }
        dc.drawText(centerX, y, Graphics.FONT_SMALL, songCount.toString() + " songs", Graphics.TEXT_JUSTIFY_CENTER);
        y += 30;

        if (songCount > 0) {
            var totalDuration = stats["totalDuration"] as Number?;
            if (totalDuration == null) {
                totalDuration = 0;
            }
            var minutes = (totalDuration / 60).toNumber();
            dc.drawText(centerX, y, Graphics.FONT_TINY, minutes.toString() + " minutes", Graphics.TEXT_JUSTIFY_CENTER);
            y += 40;
        }

        // Show shuffle status
        var shuffleText = _library.getShuffle() ? "Shuffle: ON" : "Shuffle: OFF";
        dc.drawText(centerX, y, Graphics.FONT_SMALL, shuffleText, Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;

        // Show server status
        if (_serverConfig.isConfigured()) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_TINY, "Server: Configured", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_TINY, "Server: Not configured", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
