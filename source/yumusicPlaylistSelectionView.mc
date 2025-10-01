import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// View for selecting playlists/albums to download
class yumusicPlaylistSelectionView extends WatchUi.View {
    private var _items as Array<Dictionary>;
    private var _selectedIndex as Number;
    private var _title as String;
    private var _isLoading as Boolean;
    private var _errorMessage as String?;
    private const ORANGE = 0xFF6600;
    private const DARK_ORANGE = 0xCC5200;

    function initialize() {
        View.initialize();
        _items = [] as Array<Dictionary>;
        _selectedIndex = 0;
        _title = "Loading...";
        _isLoading = true;
        _errorMessage = null;
    }

    // Set items to display
    function setItems(items as Array<Dictionary>, title as String) as Void {
        _items = items;
        _title = title;
        _isLoading = false;
        _errorMessage = null;
        _selectedIndex = 0;
        WatchUi.requestUpdate();
    }

    // Set error message
    function setError(message as String) as Void {
        _errorMessage = message;
        _isLoading = false;
        WatchUi.requestUpdate();
    }

    // Set loading state
    function setLoading(loading as Boolean) as Void {
        _isLoading = loading;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Pure black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title at top
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            height * 0.12,
            Graphics.FONT_TINY,
            _title.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw orange line under title
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - 50, height * 0.16, centerX + 50, height * 0.16);
        
        // Show loading, error, or items
        if (_errorMessage != null) {
            // Error state
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 30,
                Graphics.FONT_SMALL,
                "✗ Error",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_XTINY,
                _errorMessage,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.drawText(
                centerX,
                height * 0.85,
                Graphics.FONT_XTINY,
                "BACK to retry",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else if (_isLoading) {
            // Loading state
            dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY,
                Graphics.FONT_MEDIUM,
                "Loading...",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 40,
                Graphics.FONT_XTINY,
                "Fetching from server",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else if (_items.size() == 0) {
            // No items
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 20,
                Graphics.FONT_SMALL,
                "No Items",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 20,
                Graphics.FONT_XTINY,
                "Check your server",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            // Show selected item
            var item = _items[_selectedIndex];
            var name = item.hasKey("name") ? item["name"] : "Unknown";
            
            // Truncate if too long
            if (name instanceof String && (name as String).length() > 20) {
                name = (name as String).substring(0, 17) + "...";
            }
            
            // Draw current selection in orange
            dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY,
                Graphics.FONT_MEDIUM,
                name,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            // Show song count if available
            if (item.hasKey("songCount")) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY + 35,
                    Graphics.FONT_XTINY,
                    item["songCount"].toString() + " songs",
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            
            // Draw previous item hint
            if (_selectedIndex > 0) {
                var prevItem = _items[_selectedIndex - 1];
                var prevName = prevItem.hasKey("name") ? prevItem["name"] : "Unknown";
                if (prevName instanceof String && (prevName as String).length() > 15) {
                    prevName = (prevName as String).substring(0, 12) + "...";
                }
                
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY - (height * 0.18),
                    Graphics.FONT_XTINY,
                    "↑ " + prevName,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            
            // Draw next item hint
            if (_selectedIndex < _items.size() - 1) {
                var nextItem = _items[_selectedIndex + 1];
                var nextName = nextItem.hasKey("name") ? nextItem["name"] : "Unknown";
                if (nextName instanceof String && (nextName as String).length() > 15) {
                    nextName = (nextName as String).substring(0, 12) + "...";
                }
                
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY + (height * 0.18),
                    Graphics.FONT_XTINY,
                    "↓ " + nextName,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            
            // Draw position indicator and instruction
            dc.setColor(DARK_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                height * 0.82,
                Graphics.FONT_XTINY,
                (_selectedIndex + 1) + "/" + _items.size(),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.drawText(
                centerX,
                height * 0.90,
                Graphics.FONT_XTINY,
                "SELECT to download",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    // Move selection up
    function moveUp() as Void {
        if (_items.size() > 0 && _selectedIndex > 0) {
            _selectedIndex--;
            WatchUi.requestUpdate();
        }
    }

    // Move selection down
    function moveDown() as Void {
        if (_items.size() > 0 && _selectedIndex < _items.size() - 1) {
            _selectedIndex++;
            WatchUi.requestUpdate();
        }
    }

    // Get selected item
    function getSelectedItem() as Dictionary? {
        if (_items.size() > 0 && _selectedIndex >= 0 && _selectedIndex < _items.size()) {
            return _items[_selectedIndex];
        }
        return null;
    }

    function onHide() as Void {
    }
}
