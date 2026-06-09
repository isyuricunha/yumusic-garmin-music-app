import Toybox.Lang;
import Toybox.Media;
import Toybox.System;
import Toybox.WatchUi;

class YuMusicClearLibraryDelegate extends WatchUi.ConfirmationDelegate {
    private var _library as YuMusicLibrary;

    function initialize() {
        ConfirmationDelegate.initialize();
        _library = new YuMusicLibrary();
    }

    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            try {
                Media.resetContentCache();
                _library.clearAllState();
            } catch (ex) {
                System.println("library clear failed: " + ex.toString());
            }
        }

        return true;
    }
}
