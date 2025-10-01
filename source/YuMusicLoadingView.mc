import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Simple loading view with message
class YuMusicLoadingView extends WatchUi.View {
    private var _message as String;

    function initialize(message as String) {
        View.initialize();
        _message = message;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        // Draw loading message
        dc.drawText(centerX, centerY - 20, Graphics.FONT_MEDIUM, _message, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Draw simple loading indicator
        dc.drawText(centerX, centerY + 20, Graphics.FONT_SMALL, "...", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
