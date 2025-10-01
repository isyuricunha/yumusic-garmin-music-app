import Toybox.WatchUi;
import Toybox.Lang;

// Delegate for confirmation view
class YuMusicConfirmDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
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
        return true;
    }
}
