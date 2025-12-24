import Toybox.WatchUi;
import Toybox.Lang;

class YuMusicConnectionTestDelegate extends WatchUi.BehaviorDelegate {
    private var _view as YuMusicConnectionTestView;

    function initialize() {
        BehaviorDelegate.initialize();
        _view = new YuMusicConnectionTestView();
    }

    function setView(view as YuMusicConnectionTestView) as Void {
        _view = view;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onSelect() as Boolean {
        _view.restart();
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        return onSelect();
    }
}
