import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Confirmation/message view
class YuMusicConfirmView extends WatchUi.View {
    private var _title as String;
    private var _message as String;

    function initialize(title as String, message as String) {
        View.initialize();
        _title = title;
        _message = message;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var y = height / 3;

        // Draw title
        dc.drawText(centerX, y, Graphics.FONT_MEDIUM, _title, Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        // Draw message
        dc.drawText(centerX, y, Graphics.FONT_SMALL, _message, Graphics.TEXT_JUSTIFY_CENTER);
        y += 50;

        // Draw instruction
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, Graphics.FONT_TINY, "Press back to continue", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
