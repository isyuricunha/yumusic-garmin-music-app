import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class yumusicConfigurePlaybackView extends WatchUi.View {
    private var _menuItems as Array<String>;
    private var _selectedIndex as Number;
    private const ORANGE = 0xFF6600;
    private const DARK_ORANGE = 0xCC5200;

    function initialize() {
        View.initialize();
        _menuItems = [
            "Random Songs",
            "Playlists",
            "Artists",
            "Albums",
            "Search"
        ];
        _selectedIndex = 0;
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
            "SELECT MUSIC",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw orange line under title
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - 50, height * 0.18, centerX + 50, height * 0.18);
        
        // Draw current selection - larger and in orange
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            centerY,
            Graphics.FONT_MEDIUM,
            _menuItems[_selectedIndex],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw previous item hint (dimmed white)
        if (_selectedIndex > 0) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - (height * 0.15),
                Graphics.FONT_TINY,
                "↑ " + _menuItems[_selectedIndex - 1],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
        
        // Draw next item hint (dimmed white)
        if (_selectedIndex < _menuItems.size() - 1) {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + (height * 0.15),
                Graphics.FONT_TINY,
                "↓ " + _menuItems[_selectedIndex + 1],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
        
        // Draw selection indicator at bottom
        dc.setColor(DARK_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            height * 0.85,
            Graphics.FONT_XTINY,
            (_selectedIndex + 1) + " / " + _menuItems.size(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // Move selection up
    function moveUp() as Void {
        if (_selectedIndex > 0) {
            _selectedIndex--;
            WatchUi.requestUpdate();
        }
    }

    // Move selection down
    function moveDown() as Void {
        if (_selectedIndex < _menuItems.size() - 1) {
            _selectedIndex++;
            WatchUi.requestUpdate();
        }
    }

    // Get selected index
    function getSelectedIndex() as Number {
        return _selectedIndex;
    }
}
