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
            } catch (ex) {
                System.println("content cache reset failed: " + ex.toString());
            }
            _library.clearAllState();
        }

        return true;
    }
}
