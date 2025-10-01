import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// This is the View that is used to configure the server connection
// and sync settings for downloading music from Navidrome/Subsonic
class yumusicConfigureSyncView extends WatchUi.View {
    private var _statusText as String;
    private var _settings as SettingsManager;

    function initialize() {
        View.initialize();
        _settings = new SettingsManager();
        
        if (_settings.isConfigured()) {
            _statusText = "Server: " + _settings.getServerUrl();
        } else {
            _statusText = "Not Configured\nUse Garmin Connect\nMobile App";
        }
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ConfigureSyncLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        
        // Draw status text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2,
            Graphics.FONT_SMALL,
            _statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Update status text
    function setStatusText(text as String) as Void {
        _statusText = text;
        WatchUi.requestUpdate();
    }
}
