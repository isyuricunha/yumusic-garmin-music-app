import Toybox.Lang;
import Toybox.Media;
import Toybox.System;
import Toybox.WatchUi;

class YuMusicRemovePlaylistDelegate extends WatchUi.ConfirmationDelegate {
    private var _playlistId as String;
    private var _library as YuMusicLibrary;

    function initialize(playlistId as String) {
        ConfirmationDelegate.initialize();
        _playlistId = playlistId;
        _library = new YuMusicLibrary();
    }

    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            var contentRefIds = _library.removePlaylist(_playlistId);
            for (var i = 0; i < contentRefIds.size(); i++) {
                var contentRefId = contentRefIds[i] as Number?;
                if (contentRefId == null) {
                    continue;
                }

                try {
                    Media.deleteCachedItem(
                        new Media.ContentRef(contentRefId, Media.CONTENT_TYPE_AUDIO)
                    );
                } catch (ex) {
                    System.println("cached media deletion failed: " + ex.toString());
                }
            }
        }

        return true;
    }
}
