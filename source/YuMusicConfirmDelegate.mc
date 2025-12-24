import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Media;

// Delegate for confirmation view
class YuMusicConfirmDelegate extends WatchUi.BehaviorDelegate {

    private var _startSyncOnSelect as Boolean;

    function initialize(startSyncOnSelect as Boolean?) {
        BehaviorDelegate.initialize();

        if (startSyncOnSelect != null) {
            _startSyncOnSelect = startSyncOnSelect;
        } else {
            _startSyncOnSelect = false;
        }
    }

    // Handle back button - pop all views back to main
    function onBack() as Boolean {
        // Pop back to main configuration view
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    // Handle select button
    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);

        if (_startSyncOnSelect) {
            Media.startSync();
        }
        return true;
    }

    // Handle touch tap (Venu 2 is primarily touch)
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        return onSelect();
    }
}
