import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// This is the View that is used to configure the server connection
// and sync settings for downloading music from Navidrome/Subsonic
class yumusicConfigureSyncView extends WatchUi.View {
    private var _statusText as String;
    private var _settings as SettingsManager;
    private const ORANGE = 0xFF6600;
    private const DARK_ORANGE = 0xCC5200;

    function initialize() {
        View.initialize();
        _settings = new SettingsManager();
        
        if (_settings.isConfigured()) {
            var url = _settings.getServerUrl();
            // Truncate URL for display if too long
            if (url != null && url.length() > 30) {
                url = url.substring(0, 27) + "...";
            }
            _statusText = "Connected\n" + url;
        } else {
            _statusText = "Not Configured";
        }
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        // Don't use XML layout, draw everything manually
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Pure black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title at top with orange accent
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            height * 0.15,
            Graphics.FONT_TINY,
            "SYNC SETTINGS",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw orange line under title
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - 50, height * 0.18, centerX + 50, height * 0.18);
        
        // Check configuration status
        if (_settings.isConfigured()) {
            // Show test result if available
            if (_statusText.equals("testing")) {
                dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY,
                    Graphics.FONT_SMALL,
                    "Testing...",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else if (_statusText.equals("success")) {
                dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY - 20,
                    Graphics.FONT_SMALL,
                    "✓ Success!",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY + 20,
                    Graphics.FONT_XTINY,
                    "Ready to sync",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else if (_statusText.equals("failed")) {
                dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY - 20,
                    Graphics.FONT_SMALL,
                    "✗ Failed",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY + 20,
                    Graphics.FONT_XTINY,
                    "Check settings",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else {
                // Draw status - configured (default)
                dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY - 30,
                    Graphics.FONT_SMALL,
                    "✓ Configured",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
                
                // Draw server URL (truncated)
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                var url = _settings.getServerUrl();
                if (url != null) {
                    if (url.length() > 25) {
                        url = url.substring(0, 22) + "...";
                    }
                    dc.drawText(
                        centerX,
                        centerY + 10,
                        Graphics.FONT_XTINY,
                        url,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                    );
                }
            }
            
            // Instructions at bottom
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                height * 0.85,
                Graphics.FONT_XTINY,
                "SELECT to test connection",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            // Draw status - not configured
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 40,
                Graphics.FONT_SMALL,
                "Not Configured",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            // Instructions with better spacing
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_XTINY,
                "Configure in",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 30,
                Graphics.FONT_XTINY,
                "Garmin Connect",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 50,
                Graphics.FONT_XTINY,
                "Mobile App",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
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
    
    // Get status text for display
    function getStatusText() as String {
        return _statusText;
    }
}
