import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

class yumusicConfigurePlaybackView extends WatchUi.View {
    private var _menuItems as Array<String>;
    private var _selectedIndex as Number;

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
        setLayout(Rez.Layouts.ConfigurePlaybackLayout(dc));
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
        
        // Draw menu items
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerY = height / 2;
        var itemHeight = 40;
        
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        // Draw title
        dc.drawText(
            width / 2,
            20,
            Graphics.FONT_SMALL,
            "Select Music Source",
            Graphics.TEXT_JUSTIFY_CENTER
        );
        
        // Draw current selection
        dc.drawText(
            width / 2,
            centerY,
            Graphics.FONT_MEDIUM,
            _menuItems[_selectedIndex],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw navigation hints
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        if (_selectedIndex > 0) {
            dc.drawText(
                width / 2,
                centerY - itemHeight,
                Graphics.FONT_TINY,
                "▲ " + _menuItems[_selectedIndex - 1],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        
        if (_selectedIndex < _menuItems.size() - 1) {
            dc.drawText(
                width / 2,
                centerY + itemHeight,
                Graphics.FONT_TINY,
                "▼ " + _menuItems[_selectedIndex + 1],
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
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
